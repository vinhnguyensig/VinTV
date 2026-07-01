//
//  AppContainer.swift
//  VinAppleTV
//
//  Created by Vinh Nguyen on 27/6/26.
//

import Foundation
import TVData
import TVDomain
import VPAppTheme
import VPCommon
import VPLocalStorage
import VPPlayer

@MainActor
protocol AppDependencyProviding {
    var theme: VPTheme { get }
    var favoriteService: LocalFavoriteStateService { get }
    func makeHomeViewModel() -> HomeViewModel
    func makeFavoritesViewModel() -> FavoritesViewModel
    func makeSearchViewModel() -> SearchViewModel
    func makeContentDetailViewModel(contentID: String) -> ContentDetailViewModel
    func makePlayerViewModel(request: ContentDetailViewModel.PlaybackRequest) -> PlayerViewModel
}

@MainActor
final class AppContainer: AppDependencyProviding {
    private let analyticsTracker: AnalyticsTracking
    private let contentRepository: ContentRepositoryProtocol
    private let keyValueStore: KeyValueStoring
    private let playerService: VideoPlayerServicing
    let favoriteService: LocalFavoriteStateService
    let theme: VPTheme

    init(
        analyticsTracker: AnalyticsTracking = ConsoleAnalyticsTracker(),
        contentRepository: ContentRepositoryProtocol = ContentRepository(
            dataSource: MockContentDataSource()
        ),
        keyValueStore: KeyValueStoring = UserDefaultsKeyValueStore(),
        playerService: VideoPlayerServicing? = nil,
        theme: VPTheme = VPTheme()
    ) {
        self.analyticsTracker = analyticsTracker
        self.contentRepository = contentRepository
        self.keyValueStore = keyValueStore
        self.favoriteService = LocalFavoriteStateService(store: keyValueStore)
        self.playerService = playerService ?? VideoPlayerService()
        self.theme = theme
    }

    func makeHomeViewModel() -> HomeViewModel {
        HomeViewModel(
            featuredContentUseCase: DefaultGetFeaturedContentUseCase(repository: contentRepository),
            continueWatchingUseCase: DefaultGetContinueWatchingUseCase(repository: contentRepository),
            trendingContentUseCase: DefaultGetTrendingContentUseCase(repository: contentRepository),
            recommendedContentUseCase: DefaultGetRecommendedContentUseCase(repository: contentRepository),
            playbackProgressUseCase: DefaultGetPlaybackProgressUseCase(
                repository: contentRepository
            ),
            analyticsTracker: analyticsTracker
        )
    }

    func makeContentDetailViewModel(contentID: String) -> ContentDetailViewModel {
        ContentDetailViewModel(
            contentID: contentID,
            contentDetailUseCase: DefaultGetContentDetailUseCase(repository: contentRepository),
            playbackProgressUseCase: DefaultGetPlaybackProgressUseCase(
                repository: contentRepository
            ),
            favoriteService: favoriteService,
            analyticsTracker: analyticsTracker,
            localProgressStore: LocalPlaybackProgressService(store: keyValueStore)
        )
    }

    func makeFavoritesViewModel() -> FavoritesViewModel {
        FavoritesViewModel(
            favoriteService: favoriteService,
            contentDetailUseCase: DefaultGetContentDetailUseCase(repository: contentRepository)
        )
    }

    func makeSearchViewModel() -> SearchViewModel {
        SearchViewModel(
            searchContentUseCase: DefaultSearchContentUseCase(repository: contentRepository)
        )
    }

    func makePlayerViewModel(
        request: ContentDetailViewModel.PlaybackRequest
    ) -> PlayerViewModel {
        PlayerViewModel(
            content: request.content,
            startSeconds: request.startSeconds,
            playerService: playerService,
            progressStore: LocalPlaybackProgressService(store: keyValueStore),
            analyticsTracker: analyticsTracker
        )
    }
}
