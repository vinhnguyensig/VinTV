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

    private let featuredContentUseCase: GetFeaturedContentUseCase
    private let continueWatchingUseCase: GetContinueWatchingUseCase
    private let trendingContentUseCase: GetTrendingContentUseCase
    private let recommendedContentUseCase: GetRecommendedContentUseCase
    private let playbackProgressUseCase: GetPlaybackProgressUseCase?
    private let analyticsTracker: AnalyticsTracking
    private var hasTrackedScreenView = false

    init(
        featuredContentUseCase: GetFeaturedContentUseCase,
        continueWatchingUseCase: GetContinueWatchingUseCase,
        trendingContentUseCase: GetTrendingContentUseCase,
        recommendedContentUseCase: GetRecommendedContentUseCase,
        playbackProgressUseCase: GetPlaybackProgressUseCase? = nil,
        analyticsTracker: AnalyticsTracking
    ) {
        self.featuredContentUseCase = featuredContentUseCase
        self.continueWatchingUseCase = continueWatchingUseCase
        self.trendingContentUseCase = trendingContentUseCase
        self.recommendedContentUseCase = recommendedContentUseCase
        self.playbackProgressUseCase = playbackProgressUseCase
        self.analyticsTracker = analyticsTracker
    }

    func load() async {
        guard loadState != .loading else { return }

        loadState = .loading
        if !hasTrackedScreenView {
            analyticsTracker.track(.screenViewed(.home))
            hasTrackedScreenView = true
        }

        do {
            async let featured = featuredContentUseCase.execute()
            async let continueWatching = continueWatchingUseCase.execute()
            async let trending = trendingContentUseCase.execute()
            async let recommended = recommendedContentUseCase.execute()

            let results = try await (
                featured,
                continueWatching,
                trending,
                recommended
            )

            featuredContent = results.0
            continueWatchingContent = results.1
            trendingContent = results.2
            recommendedContent = results.3
            playbackProgressByContentID = await loadProgress(for: results.1)
            loadState = .loaded
        } catch {
            loadState = .failed(error.localizedDescription)
        }
    }

    func selectContent(id: String) {
        analyticsTracker.track(.contentSelected(contentID: id))
    }

    private func loadProgress(for content: [Content]) async -> [String: PlaybackProgress] {
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
                if let progress {
                    result[contentID] = progress
                }
            }
            return result
        }
    }
}
