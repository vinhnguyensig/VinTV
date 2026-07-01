import AVFoundation
import Foundation

@MainActor
public protocol VideoPlayerServicing: AnyObject {
    var player: AVPlayer { get }
    var state: VideoPlaybackState { get }
    var metrics: PlaybackMetrics { get }
    var onStateChange: ((VideoPlaybackState) -> Void)? { get set }
    var onProgress: ((TimeInterval, TimeInterval) -> Void)? { get set }
    var onEvent: ((PlaybackEvent) -> Void)? { get set }
    var onMetricsChange: ((PlaybackMetrics) -> Void)? { get set }

    func load(url: URL)
    func play()
    func pause()
    func seek(to seconds: TimeInterval)
    func retry()
    func stop()
}

@MainActor
public final class VideoPlayerService: VideoPlayerServicing {
    public let player: AVPlayer
    public private(set) var state: VideoPlaybackState = .idle
    public var metrics: PlaybackMetrics { metricsCollector.metrics }
    public var onStateChange: ((VideoPlaybackState) -> Void)?
    public var onProgress: ((TimeInterval, TimeInterval) -> Void)?
    public var onEvent: ((PlaybackEvent) -> Void)?
    public var onMetricsChange: ((PlaybackMetrics) -> Void)?

    nonisolated(unsafe) private var timeObserver: Any?
    nonisolated(unsafe) private var notificationObservers: [NSObjectProtocol] = []
    private var observations: [NSKeyValueObservation] = []
    private var retryTask: Task<Void, Never>?
    private let stateMachine = PlayerStateMachine()
    private let metricsCollector: PlaybackMetricsCollector
    private let retryPolicy: RetryPolicy
    private let networkMonitor: PlaybackNetworkMonitoring
    private let authorizationRefresher: PlaybackAuthorizationRefreshing?
    private var currentURL: URL?
    private var retryAttempt = 0
    private var intendedToPlay = false
    private var wasPlayingBeforeInterruption = false
    private var recoveryStartedAt: TimeInterval?
    private let uptime: () -> TimeInterval

    public init(
        player: AVPlayer = AVPlayer(),
        retryPolicy: RetryPolicy = RetryPolicy(),
        networkMonitor: PlaybackNetworkMonitoring? = nil,
        authorizationRefresher: PlaybackAuthorizationRefreshing? = nil,
        uptime: @escaping () -> TimeInterval = { ProcessInfo.processInfo.systemUptime }
    ) {
        self.player = player
        self.retryPolicy = retryPolicy
        self.networkMonitor = networkMonitor ?? PlaybackNetworkMonitor()
        self.authorizationRefresher = authorizationRefresher
        self.uptime = uptime
        self.metricsCollector = PlaybackMetricsCollector(now: uptime)
        player.automaticallyWaitsToMinimizeStalling = true
        self.networkMonitor.onAvailabilityChange = { [weak self] available in
            self?.networkChanged(isAvailable: available)
        }
        self.networkMonitor.start()
    }

    deinit {
        retryTask?.cancel()
        if let timeObserver {
            player.removeTimeObserver(timeObserver)
        }
        notificationObservers.forEach(NotificationCenter.default.removeObserver)
    }

    public func load(url: URL) {
        retryTask?.cancel()
        retryAttempt = 0
        currentURL = url
        intendedToPlay = false
        prepareItem(url: url, beginSession: true)
    }

    public func play() {
        guard player.currentItem != nil else { return }
        intendedToPlay = true
        player.play()
        updateFromTimeControlStatus()
    }

    public func pause() {
        guard player.currentItem != nil else { return }
        intendedToPlay = false
        player.pause()
        transition(to: .paused)
        publishProgress()
    }

    public func seek(to seconds: TimeInterval) {
        guard seconds.isFinite else { return }
        let shouldResume = intendedToPlay
        transition(to: .seeking)
        player.seek(
            to: CMTime(seconds: max(0, seconds), preferredTimescale: 600),
            toleranceBefore: .zero,
            toleranceAfter: .zero
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.publishProgress()
                self.transition(to: shouldResume ? .playing : .paused)
            }
        }
    }

    public func retry() {
        guard let currentURL else { return }
        retryTask?.cancel()
        retryAttempt = 0
        prepareItem(url: currentURL, beginSession: false)
    }

    public func stop() {
        retryTask?.cancel()
        retryTask = nil
        intendedToPlay = false
        let position = currentPosition
        player.pause()
        removeItemObservers()
        player.replaceCurrentItem(with: nil)
        transition(to: .idle)
        onEvent?(.stopped(position: position))
    }

    private func prepareItem(url: URL, beginSession: Bool) {
        removeItemObservers()
        if beginSession {
            metricsCollector.beginSession()
            publishMetrics()
        }
        transition(to: .loading)

        let item = AVPlayerItem(url: url)
        player.replaceCurrentItem(with: item)
        observe(item: item)
    }

    private func observe(item: AVPlayerItem) {
        observations = [
            item.observe(\.status, options: [.initial, .new]) { [weak self] item, _ in
                Task { @MainActor [weak self] in self?.itemStatusChanged(item) }
            },
            item.observe(\.isPlaybackBufferEmpty, options: [.new]) { [weak self] item, _ in
                Task { @MainActor [weak self] in
                    if item.isPlaybackBufferEmpty { self?.beginBuffering() }
                }
            },
            item.observe(\.isPlaybackLikelyToKeepUp, options: [.new]) { [weak self] item, _ in
                Task { @MainActor [weak self] in
                    guard item.isPlaybackLikelyToKeepUp else { return }
                    self?.bufferRecovered()
                }
            },
            player.observe(\.timeControlStatus, options: [.new]) { [weak self] _, _ in
                Task { @MainActor [weak self] in self?.updateFromTimeControlStatus() }
            }
        ]

        notificationObservers = [
            NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime, object: item, queue: .main
            ) { [weak self] _ in
                MainActor.assumeIsolated { self?.completed() }
            },
            NotificationCenter.default.addObserver(
                forName: .AVPlayerItemPlaybackStalled, object: item, queue: .main
            ) { [weak self] _ in
                MainActor.assumeIsolated { self?.stalled() }
            },
            NotificationCenter.default.addObserver(
                forName: .AVPlayerItemNewAccessLogEntry, object: item, queue: .main
            ) { [weak self] _ in
                MainActor.assumeIsolated {
                    guard let event = item.accessLog()?.events.last else { return }
                    self?.metricsCollector.ingest(accessLogEvent: event)
                    self?.publishMetrics()
                }
            }
        ]

        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.5, preferredTimescale: 600),
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.publishProgress()
                self?.detectFirstFrame()
            }
        }
    }

    private func itemStatusChanged(_ item: AVPlayerItem) {
        switch item.status {
        case .readyToPlay:
            retryAttempt = 0
            transition(to: .ready)
            publishProgress()
        case .failed:
            handle(failure: classify(error: item.error))
        case .unknown:
            break
        @unknown default:
            break
        }
    }

    private func updateFromTimeControlStatus() {
        switch player.timeControlStatus {
        case .playing:
            endBuffering()
            transition(to: .playing)
            detectFirstFrame()
        case .waitingToPlayAtSpecifiedRate:
            if intendedToPlay { beginBuffering() }
        case .paused:
            if !intendedToPlay, state != .completed { transition(to: .paused) }
        @unknown default:
            break
        }
    }

    private func beginBuffering() {
        guard state != .loading, state != .retrying(attempt: retryAttempt) else { return }
        wasPlayingBeforeInterruption = intendedToPlay
        if let event = metricsCollector.beginBuffering(position: currentPosition) {
            onEvent?(event)
            publishMetrics()
        }
        transition(to: .buffering)
    }

    private func bufferRecovered() {
        endBuffering()
        guard wasPlayingBeforeInterruption, intendedToPlay else {
            transition(to: .paused)
            return
        }
        player.play()
        transition(to: .playing)
    }

    private func endBuffering() {
        if let event = metricsCollector.endBuffering(position: currentPosition) {
            onEvent?(event)
            publishMetrics()
        }
    }

    private func stalled() {
        onEvent?(metricsCollector.recordStall(position: currentPosition))
        publishMetrics()
        recoveryStartedAt = uptime()
        beginBuffering()
    }

    private func detectFirstFrame() {
        guard player.timeControlStatus == .playing,
              player.currentTime().isValid else { return }
        if let event = metricsCollector.recordFirstFrame() {
            onEvent?(event)
            publishMetrics()
        }
        if let recoveryStartedAt {
            onEvent?(
                .recovered(
                    position: currentPosition,
                    duration: max(0, uptime() - recoveryStartedAt)
                )
            )
            self.recoveryStartedAt = nil
        }
    }

    private func completed() {
        publishProgress()
        intendedToPlay = false
        transition(to: .completed)
    }

    private func handle(failure: PlaybackFailure) {
        if failure == .authorization,
           let authorizationRefresher,
           let currentURL {
            let position = currentPosition
            transition(to: .retrying(attempt: max(1, retryAttempt + 1)))
            retryTask = Task { [weak self] in
                do {
                    let refreshedURL = try await authorizationRefresher.refreshedURL(
                        for: currentURL
                    )
                    guard !Task.isCancelled, let self else { return }
                    self.currentURL = refreshedURL
                    self.prepareItem(url: refreshedURL, beginSession: false)
                    self.seek(to: position)
                    if self.intendedToPlay { self.play() }
                } catch {
                    guard let self else { return }
                    self.transition(to: .failed(PlaybackFailure.authorization.userMessage))
                    self.onEvent?(
                        .error(
                            message: PlaybackFailure.authorization.userMessage,
                            position: position
                        )
                    )
                }
            }
            return
        }
        guard failure.isRecoverable, retryAttempt < retryPolicy.delays.count else {
            transition(to: .failed(failure.userMessage))
            onEvent?(.error(message: failure.userMessage, position: currentPosition))
            return
        }
        let delay = retryPolicy.delays[retryAttempt]
        retryAttempt += 1
        transition(to: .retrying(attempt: retryAttempt))
        onEvent?(.retry(attempt: retryAttempt, position: currentPosition))
        let position = currentPosition
        retryTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled, let self, let url = self.currentURL else { return }
            self.prepareItem(url: url, beginSession: false)
            self.seek(to: position)
            if self.intendedToPlay { self.play() }
        }
    }

    private func networkChanged(isAvailable: Bool) {
        onEvent?(.networkChanged(isAvailable: isAvailable))
        if !isAvailable {
            wasPlayingBeforeInterruption = intendedToPlay
            player.pause()
            transition(to: .reconnecting)
        } else if state == .reconnecting, let currentURL {
            let position = currentPosition
            prepareItem(url: currentURL, beginSession: false)
            seek(to: position)
            if wasPlayingBeforeInterruption { play() }
        }
    }

    private func publishProgress() {
        let position = currentPosition
        let rawDuration = player.currentItem?.duration.seconds ?? 0
        let duration = rawDuration.isFinite ? max(0, rawDuration) : 0
        onProgress?(position, duration)
        metricsCollector.progress(position: position, duration: duration).forEach {
            onEvent?($0)
        }
    }

    private var currentPosition: TimeInterval {
        let seconds = player.currentTime().seconds
        return seconds.isFinite ? max(0, seconds) : 0
    }

    private func transition(to newState: VideoPlaybackState) {
        guard stateMachine.transition(to: newState) else { return }
        state = stateMachine.state
        onStateChange?(state)
    }

    private func publishMetrics() {
        onMetricsChange?(metricsCollector.metrics)
    }

    private func removeItemObservers() {
        observations = []
        if let timeObserver {
            player.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }
        notificationObservers.forEach(NotificationCenter.default.removeObserver)
        notificationObservers = []
    }

    private func classify(error: Error?) -> PlaybackFailure {
        guard let error = error as NSError? else {
            return .unknown("Unable to play this video.")
        }
        switch error.code {
        case NSURLErrorTimedOut: return .timedOut
        case NSURLErrorNotConnectedToInternet, NSURLErrorNetworkConnectionLost:
            return .network
        case NSURLErrorUserAuthenticationRequired: return .authorization
        case NSURLErrorUnsupportedURL, NSURLErrorBadURL: return .invalidURL
        default: return .unknown(error.localizedDescription)
        }
    }
}
