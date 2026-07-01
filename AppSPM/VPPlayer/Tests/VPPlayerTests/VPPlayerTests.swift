import AVFoundation
import Foundation
import Testing
@testable import VPPlayer

@Test
@MainActor
func playerStartsIdle() {
    #expect(VideoPlayerService(networkMonitor: TestNetworkMonitor()).state == .idle)
}

@Test
@MainActor
func stateMachineAcceptsProductionPlaybackFlow() {
    let machine = PlayerStateMachine()

    #expect(machine.transition(to: .loading))
    #expect(machine.transition(to: .ready))
    #expect(machine.transition(to: .playing))
    #expect(machine.transition(to: .buffering))
    #expect(machine.transition(to: .playing))
    #expect(machine.transition(to: .seeking))
    #expect(machine.transition(to: .playing))
    #expect(machine.transition(to: .completed))
    #expect(machine.state == .completed)
}

@Test
@MainActor
func stateMachineRejectsInvalidAndDuplicateTransitions() {
    let machine = PlayerStateMachine()

    #expect(!machine.transition(to: .playing))
    #expect(machine.transition(to: .loading))
    #expect(!machine.transition(to: .loading))
    #expect(machine.state == .loading)
}

@Test
@MainActor
func metricsMeasureStartupAndBufferingWithInjectedClock() {
    var time: TimeInterval = 10
    let collector = PlaybackMetricsCollector(now: { time })

    collector.beginSession()
    time = 10.5
    #expect(collector.recordFirstFrame() == .startup(duration: 0.5))
    #expect(collector.recordFirstFrame() == nil)

    time = 11
    #expect(collector.beginBuffering(position: 20) == .bufferStarted(position: 20))
    #expect(collector.beginBuffering(position: 20) == nil)
    time = 13.25
    #expect(
        collector.endBuffering(position: 20)
            == .bufferEnded(position: 20, duration: 2.25)
    )
    #expect(collector.metrics.bufferCount == 1)
    #expect(collector.metrics.totalBufferDuration == 2.25)
}

@Test
@MainActor
func metricsEmitCompletionMilestonesOnlyOnce() {
    let collector = PlaybackMetricsCollector()
    collector.beginSession()

    #expect(collector.progress(position: 26, duration: 100) == [.milestone(percent: 25)])
    #expect(collector.progress(position: 49, duration: 100).isEmpty)
    #expect(collector.progress(position: 76, duration: 100) == [
        .milestone(percent: 50),
        .milestone(percent: 75)
    ])
    #expect(collector.progress(position: 90, duration: 100).isEmpty)
}

@Test
func retryPolicySanitizesNegativeDelays() {
    #expect(RetryPolicy(delays: [-1, 2, 4]).delays == [0, 2, 4])
}

@Test
@MainActor
func nextItemPreloaderHonorsThresholdAndReturnsPreparedItem() async {
    let provider = TestNextItemProvider(
        item: PreloadItem(
            id: "next",
            url: URL(string: "https://example.com/next.m3u8")!
        )
    )
    let preloader = NextItemPreloader()

    preloader.update(currentID: "current", position: 79, duration: 100, provider: provider)
    await Task.yield()
    #expect(provider.requests.isEmpty)

    preloader.update(currentID: "current", position: 80, duration: 100, provider: provider)
    await Task.yield()
    await Task.yield()

    #expect(provider.requests == ["current"])
    #expect(preloader.preparedID == "next")
    #expect(preloader.takePreparedItem()?.id == "next")
    #expect(preloader.preparedItem == nil)
}

@MainActor
private final class TestNetworkMonitor: PlaybackNetworkMonitoring {
    var isAvailable = true
    var onAvailabilityChange: ((Bool) -> Void)?

    func start() {}
    func stop() {}
}

@MainActor
private final class TestNextItemProvider: NextPlaybackItemProviding {
    let item: PreloadItem?
    private(set) var requests: [String] = []

    init(item: PreloadItem?) {
        self.item = item
    }

    func nextItem(after currentID: String) async -> PreloadItem? {
        requests.append(currentID)
        return item
    }
}
