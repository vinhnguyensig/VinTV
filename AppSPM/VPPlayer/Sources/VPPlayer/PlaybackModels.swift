import Foundation

public enum VideoPlaybackState: Sendable, Equatable {
    case idle
    case loading
    case ready
    case buffering
    case playing
    case paused
    case seeking
    case retrying(attempt: Int)
    case reconnecting
    case completed
    case failed(String)
}

public enum PlaybackFailure: Error, Sendable, Equatable {
    case invalidURL
    case unsupportedMedia
    case drm
    case authorization
    case network
    case timedOut
    case playlist
    case unknown(String)

    public var isRecoverable: Bool {
        switch self {
        case .network, .timedOut, .playlist, .authorization:
            true
        case .invalidURL, .unsupportedMedia, .drm, .unknown:
            false
        }
    }

    public var userMessage: String {
        switch self {
        case .network: "The network connection was interrupted."
        case .timedOut: "The video took too long to respond."
        case .playlist: "The stream is temporarily unavailable."
        case .authorization: "Your playback session needs to be refreshed."
        case .invalidURL: "This video address is invalid."
        case .unsupportedMedia: "This video format is not supported."
        case .drm: "This video cannot be authorized for playback."
        case .unknown(let message): message
        }
    }
}

public enum PlaybackEvent: Sendable, Equatable {
    case startup(duration: TimeInterval)
    case bufferStarted(position: TimeInterval)
    case bufferEnded(position: TimeInterval, duration: TimeInterval)
    case stalled(position: TimeInterval)
    case retry(attempt: Int, position: TimeInterval)
    case recovered(position: TimeInterval, duration: TimeInterval)
    case networkChanged(isAvailable: Bool)
    case milestone(percent: Int)
    case stopped(position: TimeInterval)
    case error(message: String, position: TimeInterval)
}

public struct PlaybackQuality: Sendable, Equatable {
    public var observedBitrate: Double
    public var indicatedBitrate: Double
    public var transferDuration: TimeInterval
    public var throughput: Double
    public var bitrateSwitchCount: Int

    public init(
        observedBitrate: Double = 0,
        indicatedBitrate: Double = 0,
        transferDuration: TimeInterval = 0,
        throughput: Double = 0,
        bitrateSwitchCount: Int = 0
    ) {
        self.observedBitrate = observedBitrate
        self.indicatedBitrate = indicatedBitrate
        self.transferDuration = transferDuration
        self.throughput = throughput
        self.bitrateSwitchCount = bitrateSwitchCount
    }
}

public struct PlaybackMetrics: Sendable, Equatable {
    public let sessionID: UUID
    public var startupDuration: TimeInterval?
    public var bufferCount: Int
    public var totalBufferDuration: TimeInterval
    public var stallCount: Int
    public var quality: PlaybackQuality

    public init(
        sessionID: UUID = UUID(),
        startupDuration: TimeInterval? = nil,
        bufferCount: Int = 0,
        totalBufferDuration: TimeInterval = 0,
        stallCount: Int = 0,
        quality: PlaybackQuality = PlaybackQuality()
    ) {
        self.sessionID = sessionID
        self.startupDuration = startupDuration
        self.bufferCount = bufferCount
        self.totalBufferDuration = totalBufferDuration
        self.stallCount = stallCount
        self.quality = quality
    }
}

public struct RetryPolicy: Sendable, Equatable {
    public let delays: [TimeInterval]

    public init(delays: [TimeInterval] = [2, 4, 8]) {
        self.delays = delays.map { max(0, $0) }
    }
}
