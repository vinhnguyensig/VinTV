import AVFoundation
import Foundation

@MainActor
public final class PlaybackMetricsCollector {
    public private(set) var metrics = PlaybackMetrics()
    private let now: () -> TimeInterval
    private var requestTime: TimeInterval?
    private var bufferStartTime: TimeInterval?
    private var lastObservedBitrate: Double?
    private var milestones: Set<Int> = []

    public init(now: @escaping () -> TimeInterval = { ProcessInfo.processInfo.systemUptime }) {
        self.now = now
    }

    public func beginSession() {
        metrics = PlaybackMetrics()
        requestTime = now()
        bufferStartTime = nil
        lastObservedBitrate = nil
        milestones = []
    }

    public func recordFirstFrame() -> PlaybackEvent? {
        guard metrics.startupDuration == nil, let requestTime else { return nil }
        let duration = max(0, now() - requestTime)
        metrics.startupDuration = duration
        return .startup(duration: duration)
    }

    public func beginBuffering(position: TimeInterval) -> PlaybackEvent? {
        guard bufferStartTime == nil else { return nil }
        bufferStartTime = now()
        metrics.bufferCount += 1
        return .bufferStarted(position: position)
    }

    public func endBuffering(position: TimeInterval) -> PlaybackEvent? {
        guard let bufferStartTime else { return nil }
        let duration = max(0, now() - bufferStartTime)
        self.bufferStartTime = nil
        metrics.totalBufferDuration += duration
        return .bufferEnded(position: position, duration: duration)
    }

    public func recordStall(position: TimeInterval) -> PlaybackEvent {
        metrics.stallCount += 1
        return .stalled(position: position)
    }

    public func progress(position: TimeInterval, duration: TimeInterval) -> [PlaybackEvent] {
        guard duration > 0 else { return [] }
        let percent = Int((max(0, position) / duration) * 100)
        return [25, 50, 75].compactMap { milestone in
            guard percent >= milestone, milestones.insert(milestone).inserted else { return nil }
            return .milestone(percent: milestone)
        }
    }

    public func ingest(accessLogEvent event: AVPlayerItemAccessLogEvent) {
        let observed = max(0, event.observedBitrate)
        var switches = metrics.quality.bitrateSwitchCount
        if let lastObservedBitrate, observed > 0, observed != lastObservedBitrate {
            switches += 1
        }
        if observed > 0 {
            lastObservedBitrate = observed
        }
        metrics.quality = PlaybackQuality(
            observedBitrate: observed,
            indicatedBitrate: max(0, event.indicatedBitrate),
            transferDuration: max(0, event.transferDuration),
            throughput: max(0, event.observedBitrate),
            bitrateSwitchCount: switches
        )
    }
}
