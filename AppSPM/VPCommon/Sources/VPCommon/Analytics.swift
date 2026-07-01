//
//  Analytics.swift
//  VinAppleTV
//
//  Created by Vinh Nguyen on 29/6/26.
//

import Foundation

public enum AnalyticsEvent: Sendable, Equatable {
    public enum Screen: String, Sendable {
        case home
        case detail
        case player
    }

    case screenViewed(Screen, contentID: String? = nil)
    case contentSelected(contentID: String)
    case playbackStarted(contentID: String, positionSeconds: TimeInterval)
    case playbackCompleted(contentID: String, positionSeconds: TimeInterval)
    case playbackPaused(contentID: String, positionSeconds: TimeInterval)
    case playbackResumed(contentID: String, positionSeconds: TimeInterval)
    case playbackSeeked(contentID: String, fromSeconds: TimeInterval, toSeconds: TimeInterval)
    case playbackBufferStarted(contentID: String, positionSeconds: TimeInterval)
    case playbackBufferEnded(
        contentID: String,
        positionSeconds: TimeInterval,
        durationSeconds: TimeInterval
    )
    case playbackStalled(contentID: String, positionSeconds: TimeInterval)
    case playbackRetried(contentID: String, attempt: Int, positionSeconds: TimeInterval)
    case playbackRecovered(
        contentID: String,
        positionSeconds: TimeInterval,
        durationSeconds: TimeInterval
    )
    case playbackStartup(contentID: String, durationSeconds: TimeInterval)
    case playbackMilestone(contentID: String, percent: Int)
    case playbackStopped(contentID: String, positionSeconds: TimeInterval)
    case playbackError(contentID: String, message: String, positionSeconds: TimeInterval)

    public var name: String {
        switch self {
        case .screenViewed(let screen, _): "screen_view_\(screen.rawValue)"
        case .contentSelected: "content_selected"
        case .playbackStarted: "playback_started"
        case .playbackCompleted: "playback_completed"
        case .playbackPaused: "playback_pause"
        case .playbackResumed: "playback_resume"
        case .playbackSeeked: "playback_seek"
        case .playbackBufferStarted: "playback_buffer_start"
        case .playbackBufferEnded: "playback_buffer_end"
        case .playbackStalled: "playback_stall"
        case .playbackRetried: "playback_retry"
        case .playbackRecovered: "playback_recovered"
        case .playbackStartup: "playback_startup"
        case .playbackMilestone: "playback_milestone"
        case .playbackStopped: "playback_stop"
        case .playbackError: "playback_error"
        }
    }

    public var properties: [String: String] {
        switch self {
        case .screenViewed(_, let contentID):
            contentID.map { ["content_id": $0] } ?? [:]
        case .contentSelected(let contentID):
            ["content_id": contentID]
        case .playbackStarted(let contentID, let position),
             .playbackCompleted(let contentID, let position),
             .playbackPaused(let contentID, let position),
             .playbackResumed(let contentID, let position):
            ["content_id": contentID, "position_seconds": Self.seconds(position)]
        case .playbackSeeked(let contentID, let from, let to):
            [
                "content_id": contentID,
                "from_seconds": Self.seconds(from),
                "to_seconds": Self.seconds(to)
            ]
        case .playbackBufferStarted(let contentID, let position),
             .playbackStalled(let contentID, let position),
             .playbackStopped(let contentID, let position):
            ["content_id": contentID, "position_seconds": Self.seconds(position)]
        case .playbackBufferEnded(let contentID, let position, let duration),
             .playbackRecovered(let contentID, let position, let duration):
            [
                "content_id": contentID,
                "position_seconds": Self.seconds(position),
                "duration_seconds": Self.milliseconds(duration)
            ]
        case .playbackRetried(let contentID, let attempt, let position):
            [
                "content_id": contentID,
                "attempt": String(attempt),
                "position_seconds": Self.seconds(position)
            ]
        case .playbackStartup(let contentID, let duration):
            ["content_id": contentID, "duration_seconds": Self.milliseconds(duration)]
        case .playbackMilestone(let contentID, let percent):
            ["content_id": contentID, "percent": String(percent)]
        case .playbackError(let contentID, let message, let position):
            [
                "content_id": contentID,
                "message": message,
                "position_seconds": Self.seconds(position)
            ]
        }
    }

    private static func seconds(_ value: TimeInterval) -> String {
        String(Int(max(0, value)))
    }

    private static func milliseconds(_ value: TimeInterval) -> String {
        String(format: "%.3f", max(0, value))
    }
}

public protocol AnalyticsTracking: Sendable {
    func track(_ event: AnalyticsEvent)
}

public final class ConsoleAnalyticsTracker: AnalyticsTracking {
    public init() {}

    public func track(_ event: AnalyticsEvent) {
        #if DEBUG
        let details = event.properties
            .sorted { $0.key < $1.key }
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: ", ")
        print("[analytics] \(event.name)\(details.isEmpty ? "" : " | \(details)")")
        #endif
    }
}
