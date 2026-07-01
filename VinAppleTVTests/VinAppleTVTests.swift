//
//  VinAppleTVTests.swift
//  VinAppleTVTests
//
//  Created by Vinh Nguyen on 29/6/26.
//

import Testing
import AVFoundation
import Foundation
import TVDomain
import VPAppTheme
import VPCommon
import VPLocalStorage
import VPPlayer
@testable import VinAppleTV

@MainActor
struct VinAppleTVTests {

    @Test func appContainerBuildsHomeViewModelWithMockServices() async throws {
        let repository = MockContentRepository()
        let analyticsTracker = SpyAnalyticsTracker()
        let container = AppContainer(
            analyticsTracker: analyticsTracker,
            contentRepository: repository
        )

        let viewModel = container.makeHomeViewModel()
        await viewModel.load()

        #expect(viewModel.loadState == .loaded)
        #expect(viewModel.featuredContent.map(\.title) == ["Injected Featured"])
        #expect(viewModel.trendingContent.map(\.title) == ["Injected Featured", "Injected Trending"])
        #expect(analyticsTracker.events == [.screenViewed(.home)])
    }

    @Test func homeViewModelLoadsEverySectionFromItsDependency() async {
        let featured = makeContent(id: "featured")
        let continueWatching = makeContent(id: "continue")
        let trending = makeContent(id: "trending")
        let recommended = makeContent(id: "recommended")
        let analyticsTracker = SpyAnalyticsTracker()
        let viewModel = HomeViewModel(
            featuredContentUseCase: MockContentUseCase(content: [featured]),
            continueWatchingUseCase: MockContentUseCase(content: [continueWatching]),
            trendingContentUseCase: MockContentUseCase(content: [trending]),
            recommendedContentUseCase: MockContentUseCase(content: [recommended]),
            analyticsTracker: analyticsTracker
        )

        await viewModel.load()

        #expect(viewModel.loadState == .loaded)
        #expect(viewModel.featuredContent == [featured])
        #expect(viewModel.continueWatchingContent == [continueWatching])
        #expect(viewModel.trendingContent == [trending])
        #expect(viewModel.recommendedContent == [recommended])
        #expect(analyticsTracker.events == [.screenViewed(.home)])
    }

    @Test func homeViewModelPublishesFailureAndCanRetry() async {
        let analyticsTracker = SpyAnalyticsTracker()
        let useCase = FailingThenSucceedingContentUseCase(
            content: [makeContent(id: "recovered")]
        )
        let viewModel = HomeViewModel(
            featuredContentUseCase: useCase,
            continueWatchingUseCase: useCase,
            trendingContentUseCase: useCase,
            recommendedContentUseCase: useCase,
            analyticsTracker: analyticsTracker
        )

        await viewModel.load()
        guard case .failed(let message) = viewModel.loadState else {
            Issue.record("Expected the first load to fail")
            return
        }

        #expect(message == TestLoadError.unavailable.localizedDescription)

        await viewModel.load()

        #expect(viewModel.loadState == .loaded)
        #expect(viewModel.featuredContent.map(\.id) == ["recovered"])
        #expect(analyticsTracker.events == [.screenViewed(.home)])
    }

    @Test func homeViewModelTracksSelectedContent() {
        let analyticsTracker = SpyAnalyticsTracker()
        let viewModel = HomeViewModel(
            featuredContentUseCase: MockContentUseCase(content: []),
            continueWatchingUseCase: MockContentUseCase(content: []),
            trendingContentUseCase: MockContentUseCase(content: []),
            recommendedContentUseCase: MockContentUseCase(content: []),
            analyticsTracker: analyticsTracker
        )

        viewModel.selectContent(id: "selected")

        #expect(analyticsTracker.events == [.contentSelected(contentID: "selected")])
    }

    @Test func rootViewAcceptsReplacementCompositionRoot() {
        let rootView = RootView(container: MockAppDependencyProvider())

        #expect(String(describing: type(of: rootView)).contains("RootView"))
    }

    @Test func rootViewModelStartsOnSplash() {
        let viewModel = RootViewModel()

        #expect(viewModel.phase == .splash)
    }

    @Test func rootViewModelTransitionsToHomeWhenSplashCompletes() async {
        let viewModel = RootViewModel(
            minimumSplashDuration: .zero,
            sleep: { _ in }
        )

        await viewModel.start()

        #expect(viewModel.phase == .home)
    }

    @Test func rootViewModelOnlyRunsStartupOnce() async {
        let callCount = CallCount()
        let viewModel = RootViewModel(
            minimumSplashDuration: .zero,
            sleep: { _ in await callCount.increment() }
        )

        await viewModel.start()
        await viewModel.start()

        let finalCallCount = await callCount.value
        #expect(finalCallCount == 1)
    }

    @Test func contentDetailLoadsFavoriteAndResumeState() async {
        let content = makeContent(id: "detail", streamURL: testStreamURL)
        let progress = PlaybackProgress(
            contentID: content.id,
            positionSeconds: 754,
            durationSeconds: content.durationSeconds,
            updatedAt: .now
        )
        let favoriteService = MockFavoriteStateService(isFavorite: true)
        let analyticsTracker = SpyAnalyticsTracker()
        let viewModel = ContentDetailViewModel(
            contentID: content.id,
            contentDetailUseCase: MockContentDetailUseCase(content: content),
            playbackProgressUseCase: MockPlaybackProgressUseCase(progress: progress),
            favoriteService: favoriteService,
            analyticsTracker: analyticsTracker
        )

        await viewModel.load()

        #expect(viewModel.loadState == .loaded)
        #expect(viewModel.content == content)
        #expect(viewModel.isFavorite)
        #expect(viewModel.resumeButtonTitle == "Resume from 12:34")
        #expect(
            analyticsTracker.events == [.screenViewed(.detail, contentID: content.id)]
        )
    }

    @Test func contentDetailReportsMissingContent() async {
        let viewModel = ContentDetailViewModel(
            contentID: "missing",
            contentDetailUseCase: MockContentDetailUseCase(content: nil),
            playbackProgressUseCase: MockPlaybackProgressUseCase(progress: nil),
            favoriteService: MockFavoriteStateService(),
            analyticsTracker: SpyAnalyticsTracker()
        )

        await viewModel.load()

        #expect(viewModel.loadState == .notFound)
        #expect(viewModel.content == nil)
    }

    @Test func contentDetailTogglesFavoriteState() async {
        let content = makeContent(id: "favorite")
        let favoriteService = MockFavoriteStateService()
        let viewModel = ContentDetailViewModel(
            contentID: content.id,
            contentDetailUseCase: MockContentDetailUseCase(content: content),
            playbackProgressUseCase: MockPlaybackProgressUseCase(progress: nil),
            favoriteService: favoriteService,
            analyticsTracker: SpyAnalyticsTracker()
        )

        await viewModel.load()
        viewModel.toggleFavorite()
        #expect(viewModel.isFavorite)

        viewModel.toggleFavorite()
        #expect(!viewModel.isFavorite)
    }

    @Test func localFavoriteStatePersistsAcrossServiceInstances() {
        let store = InMemoryKeyValueStore()
        let firstService = LocalFavoriteStateService(store: store)

        firstService.addFavorite(contentID: "saved")
        #expect(firstService.isFavorite(contentID: "saved"))

        let reloadedService = LocalFavoriteStateService(store: store)
        #expect(reloadedService.isFavorite(contentID: "saved"))
        reloadedService.removeFavorite(contentID: "saved")
        #expect(!reloadedService.isFavorite(contentID: "saved"))

        let secondReload = LocalFavoriteStateService(store: store)
        #expect(!secondReload.isFavorite(contentID: "saved"))
    }

    @Test func favoritesViewModelResolvesStoredIDsThroughContentUseCase() async {
        let content = makeContent(id: "favorite")
        let favoriteService = MockFavoriteStateService(isFavorite: true)
        let viewModel = FavoritesViewModel(
            favoriteService: favoriteService,
            contentDetailUseCase: MockContentDetailUseCase(content: content)
        )

        await viewModel.load()

        #expect(viewModel.loadState == .loaded)
        #expect(viewModel.content == [content])
    }

    @Test func favoritesViewModelAddsFavoriteAndReloadsContent() async {
        let content = makeContent(id: "favorite")
        let favoriteService = MockFavoriteStateService()
        let viewModel = FavoritesViewModel(
            favoriteService: favoriteService,
            contentDetailUseCase: MockContentDetailUseCase(content: content)
        )

        await viewModel.addFavorite(contentID: content.id)

        #expect(favoriteService.isFavorite(contentID: content.id))
        #expect(viewModel.loadState == .loaded)
        #expect(viewModel.content == [content])
    }

    @Test func favoritesViewModelRemovesFavoriteAndReloadsContent() async {
        let favoriteService = MockFavoriteStateService(isFavorite: true)
        let viewModel = FavoritesViewModel(
            favoriteService: favoriteService,
            contentDetailUseCase: MockContentDetailUseCase(content: makeContent(id: "favorite"))
        )

        await viewModel.load()
        await viewModel.removeFavorite(contentID: "favorite")

        #expect(!favoriteService.isFavorite(contentID: "favorite"))
        #expect(viewModel.loadState == .loaded)
        #expect(viewModel.content.isEmpty)
    }

    @Test func searchViewModelFiltersCaseInsensitively() async {
        let result = makeContent(id: "paper-dragons")
        let viewModel = SearchViewModel(
            searchContentUseCase: MockSearchContentUseCase(content: [result])
        )

        viewModel.query = "  DRAGONS  "
        await viewModel.search(query: viewModel.query)

        #expect(viewModel.state == .results)
        #expect(viewModel.results == [result])
    }

    @Test func searchViewModelHandlesEmptyQuery() async {
        let viewModel = SearchViewModel(
            searchContentUseCase: MockSearchContentUseCase(content: [makeContent(id: "unused")])
        )

        viewModel.query = " \n "
        await viewModel.search(query: viewModel.query)

        #expect(viewModel.state == .emptyQuery)
        #expect(viewModel.results.isEmpty)
    }

    @Test func searchViewModelHandlesNoResults() async {
        let viewModel = SearchViewModel(
            searchContentUseCase: MockSearchContentUseCase(content: [])
        )

        viewModel.query = "missing"
        await viewModel.search(query: viewModel.query)

        #expect(viewModel.state == .noResults)
        #expect(viewModel.results.isEmpty)
    }

    @Test func contentDetailLaunchesResumeAndStartOverPlayback() async {
        let content = makeContent(id: "playable", streamURL: testStreamURL)
        let progress = PlaybackProgress(
            contentID: content.id,
            positionSeconds: 3_661,
            durationSeconds: content.durationSeconds,
            updatedAt: .now
        )
        let viewModel = ContentDetailViewModel(
            contentID: content.id,
            contentDetailUseCase: MockContentDetailUseCase(content: content),
            playbackProgressUseCase: MockPlaybackProgressUseCase(progress: progress),
            favoriteService: MockFavoriteStateService(),
            analyticsTracker: SpyAnalyticsTracker()
        )

        await viewModel.load()
        let resumeRequest = viewModel.play()

        #expect(viewModel.resumeButtonTitle == "Resume from 1:01:01")
        #expect(resumeRequest?.startSeconds == 3_661)
        let startOverRequest = viewModel.startOver()
        #expect(startOverRequest?.startSeconds == 0)
    }

    @Test func playerViewModelResumesFromSavedProgress() {
        let content = makeContent(id: "resume", streamURL: testStreamURL)
        let player = SpyVideoPlayerService()
        let progressStore = MockPlaybackProgressStore(
            stored: StoredPlaybackProgress(
                positionSeconds: 321,
                durationSeconds: content.durationSeconds,
                lastWatchedAt: .now,
                isCompleted: false
            )
        )
        let viewModel = PlayerViewModel(
            content: content,
            startSeconds: 0,
            playerService: player,
            progressStore: progressStore,
            analyticsTracker: SpyAnalyticsTracker()
        )

        viewModel.start()

        #expect(player.loadedURL == testStreamURL)
        #expect(player.seekSeconds == 321)
        #expect(player.didPlay)
    }

    @Test func playerViewModelSavesProgressWhenPlaybackStops() {
        let content = makeContent(id: "save", streamURL: testStreamURL)
        let player = SpyVideoPlayerService()
        let progressStore = MockPlaybackProgressStore()
        let watchedAt = Date(timeIntervalSince1970: 123)
        let viewModel = PlayerViewModel(
            content: content,
            startSeconds: 0,
            playerService: player,
            progressStore: progressStore,
            analyticsTracker: SpyAnalyticsTracker(),
            now: { watchedAt }
        )

        viewModel.start()
        player.sendProgress(position: 45, duration: content.durationSeconds)
        viewModel.stop()

        #expect(
            progressStore.saved == StoredPlaybackProgress(
                positionSeconds: 45,
                durationSeconds: content.durationSeconds,
                lastWatchedAt: watchedAt,
                isCompleted: false
            )
        )
        #expect(progressStore.savedContentID == content.id)
    }

    @Test func playerViewModelTracksPlaybackActionsWithPositions() {
        let content = makeContent(id: "tracked", streamURL: testStreamURL)
        let player = SpyVideoPlayerService()
        let analyticsTracker = SpyAnalyticsTracker()
        let viewModel = PlayerViewModel(
            content: content,
            startSeconds: 0,
            playerService: player,
            progressStore: MockPlaybackProgressStore(),
            analyticsTracker: analyticsTracker
        )

        viewModel.start()
        player.sendProgress(position: 25, duration: content.durationSeconds)
        viewModel.playPause()
        viewModel.playPause()
        viewModel.seek(by: 10)
        player.sendState(.completed)

        #expect(
            analyticsTracker.events == [
                .screenViewed(.player, contentID: content.id),
                .playbackStarted(contentID: content.id, positionSeconds: 0),
                .playbackPaused(contentID: content.id, positionSeconds: 25),
                .playbackResumed(contentID: content.id, positionSeconds: 25),
                .playbackSeeked(contentID: content.id, fromSeconds: 25, toSeconds: 35),
                .playbackCompleted(
                    contentID: content.id,
                    positionSeconds: content.durationSeconds
                )
            ]
        )
    }
}

private let testStreamURL = URL(string: "https://example.com/master.m3u8")!

private func makeContent(id: String, streamURL: URL? = nil) -> Content {
    Content(
        id: id,
        title: id.capitalized,
        description: "Test content.",
        category: Category(id: "test", title: "Test"),
        genre: "Drama",
        durationSeconds: 1_200,
        artworkReference: "artwork/\(id)",
        streamURL: streamURL
    )
}

private actor CallCount {
    private(set) var value = 0

    func increment() {
        value += 1
    }
}

private struct MockAppDependencyProvider: AppDependencyProviding {
    let theme = VPTheme()
    let favoriteService = LocalFavoriteStateService(store: InMemoryKeyValueStore())

    func makeHomeViewModel() -> HomeViewModel {
        HomeViewModel(
            featuredContentUseCase: MockContentUseCase(content: []),
            continueWatchingUseCase: MockContentUseCase(content: []),
            trendingContentUseCase: MockContentUseCase(content: []),
            recommendedContentUseCase: MockContentUseCase(content: []),
            analyticsTracker: SpyAnalyticsTracker()
        )
    }

    func makeContentDetailViewModel(contentID: String) -> ContentDetailViewModel {
        ContentDetailViewModel(
            contentID: contentID,
            contentDetailUseCase: MockContentDetailUseCase(content: nil),
            playbackProgressUseCase: MockPlaybackProgressUseCase(progress: nil),
            favoriteService: MockFavoriteStateService(),
            analyticsTracker: SpyAnalyticsTracker()
        )
    }

    func makeFavoritesViewModel() -> FavoritesViewModel {
        FavoritesViewModel(
            favoriteService: favoriteService,
            contentDetailUseCase: MockContentDetailUseCase(content: nil)
        )
    }

    func makeSearchViewModel() -> SearchViewModel {
        SearchViewModel(searchContentUseCase: MockSearchContentUseCase(content: []))
    }

    func makePlayerViewModel(
        request: ContentDetailViewModel.PlaybackRequest
    ) -> PlayerViewModel {
        PlayerViewModel(
            content: request.content,
            startSeconds: request.startSeconds,
            playerService: SpyVideoPlayerService(),
            progressStore: MockPlaybackProgressStore(),
            analyticsTracker: SpyAnalyticsTracker()
        )
    }
}

private struct MockContentRepository: ContentRepositoryProtocol {
    private let featured = Content(
        id: "featured",
        title: "Injected Featured",
        description: "Mock featured content.",
        category: Category(id: "featured", title: "Featured"),
        genre: "Drama",
        durationSeconds: 1_200,
        artworkReference: "artwork/featured"
    )

    private let trending = Content(
        id: "trending",
        title: "Injected Trending",
        description: "Mock trending content.",
        category: Category(id: "trending", title: "Trending"),
        genre: "Drama",
        durationSeconds: 1_800,
        artworkReference: "artwork/trending"
    )

    func featuredContent() async throws -> [Content] {
        [featured]
    }

    func trendingContent() async throws -> [Content] {
        [featured, trending]
    }

    func recommendedContent() async throws -> [Content] {
        [trending]
    }

    func continueWatchingContent() async throws -> [Content] {
        []
    }

    func content(id: String) async throws -> Content? {
        [featured, trending].first { $0.id == id }
    }

    func playbackProgress(contentID: String) async throws -> PlaybackProgress? {
        nil
    }

    func searchContent(matching query: String) async throws -> [Content] {
        [featured, trending].filter {
            $0.title.localizedCaseInsensitiveContains(query)
        }
    }
}

private struct MockContentUseCase: GetFeaturedContentUseCase, GetContinueWatchingUseCase, GetTrendingContentUseCase, GetRecommendedContentUseCase {
    let content: [Content]

    func execute() async throws -> [Content] {
        content
    }
}

private enum TestLoadError: LocalizedError {
    case unavailable

    var errorDescription: String? {
        "Content is temporarily unavailable."
    }
}

private actor FailingThenSucceedingContentUseCase: GetFeaturedContentUseCase, GetContinueWatchingUseCase, GetTrendingContentUseCase, GetRecommendedContentUseCase {
    private let content: [Content]
    private var remainingFailures = 4

    init(content: [Content]) {
        self.content = content
    }

    func execute() async throws -> [Content] {
        if remainingFailures > 0 {
            remainingFailures -= 1
            throw TestLoadError.unavailable
        }

        return content
    }
}

private struct MockContentDetailUseCase: GetContentDetailUseCase {
    let content: Content?

    func execute(id: String) async throws -> Content? {
        content
    }
}

private struct MockSearchContentUseCase: SearchContentUseCase {
    let content: [Content]

    func execute(query: String) async throws -> [Content] {
        content.filter {
            $0.title.localizedCaseInsensitiveContains(query)
        }
    }
}

private struct MockPlaybackProgressUseCase: GetPlaybackProgressUseCase {
    let progress: PlaybackProgress?

    func execute(contentID: String) async throws -> PlaybackProgress? {
        progress
    }
}

@MainActor
private final class MockFavoriteStateService: FavoriteStateServicing {
    private var favorite: Bool
    var favoriteContentIDs: Set<String> {
        favorite ? ["favorite"] : []
    }

    init(isFavorite: Bool = false) {
        favorite = isFavorite
    }

    func isFavorite(contentID: String) -> Bool {
        favorite
    }

    func addFavorite(contentID: String) {
        favorite = true
    }

    func removeFavorite(contentID: String) {
        favorite = false
    }

    func toggleFavorite(contentID: String) -> Bool {
        favorite.toggle()
        return favorite
    }
}

@MainActor
private final class SpyVideoPlayerService: VideoPlayerServicing {
    let player = AVPlayer()
    private(set) var state: VideoPlaybackState = .idle
    var metrics = PlaybackMetrics()
    var onStateChange: ((VideoPlaybackState) -> Void)?
    var onProgress: ((TimeInterval, TimeInterval) -> Void)?
    var onEvent: ((PlaybackEvent) -> Void)?
    var onMetricsChange: ((PlaybackMetrics) -> Void)?
    private(set) var loadedURL: URL?
    private(set) var seekSeconds: TimeInterval?
    private(set) var didPlay = false

    func load(url: URL) {
        loadedURL = url
        state = .ready
        onStateChange?(.ready)
    }

    func play() {
        didPlay = true
        state = .playing
        onStateChange?(.playing)
    }

    func pause() {
        state = .paused
        onStateChange?(.paused)
    }

    func seek(to seconds: TimeInterval) {
        seekSeconds = seconds
    }

    func retry() {
        state = .loading
        onStateChange?(.loading)
    }

    func stop() {
        state = .idle
        onStateChange?(.idle)
    }

    func sendProgress(position: TimeInterval, duration: TimeInterval) {
        onProgress?(position, duration)
    }

    func sendState(_ state: VideoPlaybackState) {
        self.state = state
        onStateChange?(state)
    }
}

@MainActor
private final class MockPlaybackProgressStore: PlaybackProgressStoring {
    let stored: StoredPlaybackProgress?
    private(set) var saved: StoredPlaybackProgress?
    private(set) var savedContentID: String?

    init(stored: StoredPlaybackProgress? = nil) {
        self.stored = stored
    }

    func progress(contentID: String) -> StoredPlaybackProgress? {
        stored
    }

    func save(_ progress: StoredPlaybackProgress, contentID: String) {
        saved = progress
        savedContentID = contentID
    }
}

private final class InMemoryKeyValueStore: KeyValueStoring {
    private var values: [String: String] = [:]

    func string(forKey key: String) -> String? {
        values[key]
    }

    func set(_ value: String?, forKey key: String) {
        values[key] = value
    }
}

private final class SpyAnalyticsTracker: AnalyticsTracking, @unchecked Sendable {
    private(set) var events: [AnalyticsEvent] = []

    func track(_ event: AnalyticsEvent) {
        events.append(event)
    }
}
