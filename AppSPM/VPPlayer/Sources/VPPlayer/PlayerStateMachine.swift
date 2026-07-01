import Foundation

@MainActor
public final class PlayerStateMachine {
    public private(set) var state: VideoPlaybackState = .idle

    public init() {}

    @discardableResult
    public func transition(to newState: VideoPlaybackState) -> Bool {
        guard newState != state, Self.canTransition(from: state, to: newState) else {
            return false
        }
        state = newState
        return true
    }

    private static func canTransition(
        from current: VideoPlaybackState,
        to next: VideoPlaybackState
    ) -> Bool {
        if case .failed = next { return true }
        if next == .idle || next == .loading { return true }

        switch (current, next) {
        case (.idle, .ready),
             (.loading, .ready),
             (.loading, .buffering),
             (.ready, .playing),
             (.ready, .paused),
             (.ready, .seeking),
             (.buffering, .playing),
             (.buffering, .paused),
             (.playing, .buffering),
             (.playing, .paused),
             (.playing, .seeking),
             (.playing, .completed),
             (.paused, .playing),
             (.paused, .seeking),
             (.paused, .completed),
             (.seeking, .playing),
             (.seeking, .paused),
             (.seeking, .buffering),
             (.retrying, .loading),
             (.retrying, .failed),
             (.reconnecting, .loading),
             (.reconnecting, .paused),
             (.completed, .seeking):
            return true
        default:
            if case .retrying = next { return true }
            if next == .reconnecting { return true }
            return false
        }
    }
}
