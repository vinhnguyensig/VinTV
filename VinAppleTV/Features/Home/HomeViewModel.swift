//
//  HomeViewModel.swift
//  VinAppleTV
//
//  Created by Vinh Nguyen on 29/6/26.
//

import Combine
import Foundation
import TVDomain
import VPCommon

struct HomeContentSnapshot: Equatable {
    let featured: [Content]
    let continueWatching: [Content]
    let trending: [Content]
    let recommended: [Content]
    let progressByContentID: [String: PlaybackProgress]
}

@MainActor
protocol HomeContentLoading {
    var updates: AnyPublisher<String, Never> { get }
    func execute() async throws -> HomeContentSnapshot
}

@MainActor
struct DefaultHomeContentLoader: HomeContentLoading {
    private let featuredContentUseCase: GetFeaturedContentUseCase
    private let continueWatchingUseCase: GetContinueWatchingUseCase
    private let trendingContentUseCase: GetTrendingContentUseCase
    private let recommendedContentUseCase: GetRecommendedContentUseCase
    private let playbackProgressUseCase: GetPlaybackProgressUseCase?
    private let localProgressStore: PlaybackProgressStoring?

    var updates: AnyPublisher<String, Never> {
        localProgressStore?.progressDidChangePublisher
            ?? Empty(completeImmediately: false).eraseToAnyPublisher()
    }

    init(
        featuredContentUseCase: GetFeaturedContentUseCase,
        continueWatchingUseCase: GetContinueWatchingUseCase,
        trendingContentUseCase: GetTrendingContentUseCase,
        recommendedContentUseCase: GetRecommendedContentUseCase,
        playbackProgressUseCase: GetPlaybackProgressUseCase? = nil,
        localProgressStore: PlaybackProgressStoring? = nil
    ) {
        self.featuredContentUseCase = featuredContentUseCase
        self.continueWatchingUseCase = continueWatchingUseCase
        self.trendingContentUseCase = trendingContentUseCase
        self.recommendedContentUseCase = recommendedContentUseCase
        self.playbackProgressUseCase = playbackProgressUseCase
        self.localProgressStore = localProgressStore
    }

    func execute() async throws -> HomeContentSnapshot {
        async let featured = featuredContentUseCase.execute()
        async let seededContinueWatching = continueWatchingUseCase.execute()
        async let trending = trendingContentUseCase.execute()
        async let recommended = recommendedContentUseCase.execute()

        let sections = try await (
            featured,
            seededContinueWatching,
            trending,
            recommended
        )
        let candidates = uniqueContent(
            sections.0 + sections.1 + sections.2 + sections.3
        )
        let repositoryProgress = await loadRepositoryProgress(for: candidates)
        var persistedProgress = localProgressStore?.allProgress() ?? [:]
        for item in candidates {
            if let progress = localProgressStore?.progress(contentID: item.id) {
                persistedProgress[item.id] = progress
            }
        }
        var reconciledProgress = repositoryProgress

        for (contentID, stored) in persistedProgress {
            reconciledProgress[contentID] = PlaybackProgress(
                contentID: contentID,
                positionSeconds: stored.positionSeconds,
                durationSeconds: stored.durationSeconds,
                updatedAt: stored.lastWatchedAt
            )
        }

        let contentByID = Dictionary(uniqueKeysWithValues: candidates.map { ($0.id, $0) })
        let resolvedContinueWatching = reconciledProgress.values
            .filter {
                $0.positionSeconds > 0
                    && $0.durationSeconds > 0
                    && $0.positionSeconds < $0.durationSeconds
            }
            .sorted { $0.updatedAt > $1.updatedAt }
            .compactMap { contentByID[$0.contentID] }
        let resolvedIDs = Set(resolvedContinueWatching.map(\.id))
        let unresolvedSeededContent = sections.1.filter {
            reconciledProgress[$0.id] == nil && !resolvedIDs.contains($0.id)
        }
        let continueWatching = resolvedContinueWatching + unresolvedSeededContent

        return HomeContentSnapshot(
            featured: sections.0,
            continueWatching: continueWatching,
            trending: sections.2,
            recommended: sections.3,
            progressByContentID: reconciledProgress
        )
    }

    private func loadRepositoryProgress(
        for content: [Content]
    ) async -> [String: PlaybackProgress] {
        guard let playbackProgressUseCase else { return [:] }

        return await withTaskGroup(
            of: (String, PlaybackProgress?).self,
            returning: [String: PlaybackProgress].self
        ) { group in
            for item in content {
                group.addTask {
                    let progress = try? await playbackProgressUseCase.execute(contentID: item.id)
                    return (item.id, progress)
                }
            }

            var result: [String: PlaybackProgress] = [:]
            for await (contentID, progress) in group {
                result[contentID] = progress
            }
            return result
        }
    }

    private func uniqueContent(_ content: [Content]) -> [Content] {
        var seenIDs: Set<String> = []
        return content.filter { seenIDs.insert($0.id).inserted }
    }
}

@MainActor
final class HomeViewModel: ObservableObject {
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    @Published private(set) var featuredContent: [Content] = []
    @Published private(set) var continueWatchingContent: [Content] = []
    @Published private(set) var trendingContent: [Content] = []
    @Published private(set) var recommendedContent: [Content] = []
    @Published private(set) var playbackProgressByContentID: [String: PlaybackProgress] = [:]
    @Published private(set) var loadState: LoadState = .idle

    private let contentLoader: HomeContentLoading
    private let analyticsTracker: AnalyticsTracking
    private var contentObservation: AnyCancellable?
    private var hasTrackedScreenView = false

    init(
        featuredContentUseCase: GetFeaturedContentUseCase,
        continueWatchingUseCase: GetContinueWatchingUseCase,
        trendingContentUseCase: GetTrendingContentUseCase,
        recommendedContentUseCase: GetRecommendedContentUseCase,
        playbackProgressUseCase: GetPlaybackProgressUseCase? = nil,
        localProgressStore: PlaybackProgressStoring? = nil,
        analyticsTracker: AnalyticsTracking
    ) {
        self.contentLoader = DefaultHomeContentLoader(
            featuredContentUseCase: featuredContentUseCase,
            continueWatchingUseCase: continueWatchingUseCase,
            trendingContentUseCase: trendingContentUseCase,
            recommendedContentUseCase: recommendedContentUseCase,
            playbackProgressUseCase: playbackProgressUseCase,
            localProgressStore: localProgressStore
        )
        self.analyticsTracker = analyticsTracker
        observeContentUpdates()
    }

    init(contentLoader: HomeContentLoading, analyticsTracker: AnalyticsTracking) {
        self.contentLoader = contentLoader
        self.analyticsTracker = analyticsTracker
        observeContentUpdates()
    }

    func load() async {
        guard loadState != .loading else { return }

        loadState = .loading
        if !hasTrackedScreenView {
            analyticsTracker.track(.screenViewed(.home))
            hasTrackedScreenView = true
        }

        do {
            let snapshot = try await contentLoader.execute()
            featuredContent = snapshot.featured
            continueWatchingContent = snapshot.continueWatching
            trendingContent = snapshot.trending
            recommendedContent = snapshot.recommended
            playbackProgressByContentID = snapshot.progressByContentID
            loadState = .loaded
        } catch {
            loadState = .failed(error.localizedDescription)
        }
    }

    func selectContent(id: String) {
        analyticsTracker.track(.contentSelected(contentID: id))
    }

    private func observeContentUpdates() {
        contentObservation = contentLoader.updates
            .sink { [weak self] _ in
                Task { await self?.load() }
            }
    }
}
