import Foundation
import Network

@MainActor
public protocol PlaybackNetworkMonitoring: AnyObject {
    var isAvailable: Bool { get }
    var onAvailabilityChange: ((Bool) -> Void)? { get set }
    func start()
    func stop()
}

@MainActor
public final class PlaybackNetworkMonitor: PlaybackNetworkMonitoring {
    public private(set) var isAvailable = true
    public var onAvailabilityChange: ((Bool) -> Void)?

    private let monitor: NWPathMonitor
    private let queue = DispatchQueue(label: "com.vinappletv.player.network")

    public init(monitor: NWPathMonitor = NWPathMonitor()) {
        self.monitor = monitor
    }

    public func start() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                guard let self else { return }
                let available = path.status == .satisfied
                guard available != self.isAvailable else { return }
                self.isAvailable = available
                self.onAvailabilityChange?(available)
            }
        }
        monitor.start(queue: queue)
    }

    public func stop() {
        monitor.pathUpdateHandler = nil
        monitor.cancel()
    }
}

public protocol PlaybackAuthorizationRefreshing: Sendable {
    func refreshedURL(for url: URL) async throws -> URL
}
