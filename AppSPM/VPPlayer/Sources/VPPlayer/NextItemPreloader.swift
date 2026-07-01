import AVFoundation
import Foundation

public struct PreloadItem: Sendable, Equatable {
    public let id: String
    public let url: URL

    public init(id: String, url: URL) {
        self.id = id
        self.url = url
    }
}

@MainActor
public protocol NextPlaybackItemProviding: AnyObject {
    func nextItem(after currentID: String) async -> PreloadItem?
}

@MainActor
public final class NextItemPreloader {
    public let threshold: Double
    public private(set) var preparedItem: AVPlayerItem?
    public private(set) var preparedID: String?
    private var task: Task<Void, Never>?

    public init(threshold: Double = 0.8) {
        self.threshold = min(max(threshold, 0), 1)
    }

    public func update(
        currentID: String,
        position: TimeInterval,
        duration: TimeInterval,
        provider: NextPlaybackItemProviding
    ) {
        guard duration > 0, position / duration >= threshold,
              preparedItem == nil, task == nil else { return }
        task = Task { [weak self] in
            guard let next = await provider.nextItem(after: currentID),
                  !Task.isCancelled else {
                self?.task = nil
                return
            }
            self?.preparedID = next.id
            self?.preparedItem = AVPlayerItem(url: next.url)
            self?.task = nil
        }
    }

    public func takePreparedItem() -> (id: String, item: AVPlayerItem)? {
        guard let preparedID, let preparedItem else { return nil }
        cancel()
        return (preparedID, preparedItem)
    }

    public func cancel() {
        task?.cancel()
        task = nil
        preparedID = nil
        preparedItem = nil
    }
}
