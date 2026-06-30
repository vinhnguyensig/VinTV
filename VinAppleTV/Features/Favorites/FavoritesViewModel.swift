//
//  FavoritesViewModel.swift
//  VinAppleTV
//
//  Created by Vinh Nguyen on 28/6/26.
//

import Combine
import Foundation
import TVDomain

@MainActor
final class FavoritesViewModel: ObservableObject {
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    @Published private(set) var content: [Content] = []
    @Published private(set) var loadState: LoadState = .idle

    private let favoriteService: FavoriteStateServicing
    private let contentDetailUseCase: GetContentDetailUseCase
    private var favoriteObservation: AnyCancellable?

    init(
        favoriteService: FavoriteStateServicing,
        contentDetailUseCase: GetContentDetailUseCase
    ) {
        self.favoriteService = favoriteService
        self.contentDetailUseCase = contentDetailUseCase

        favoriteObservation = favoriteService.favoriteContentIDsPublisher
            .dropFirst()
            .sink { [weak self] _ in
                Task { await self?.load() }
            }
    }

    func load() async {
        loadState = .loading

        do {
            var resolved: [Content] = []
            for id in favoriteService.favoriteContentIDs.sorted() {
                if let item = try await contentDetailUseCase.execute(id: id) {
                    resolved.append(item)
                }
            }
            content = resolved.sorted {
                $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
            }
            loadState = .loaded
        } catch {
            loadState = .failed(error.localizedDescription)
        }
    }

    func addFavorite(contentID: String) async {
        favoriteService.addFavorite(contentID: contentID)
        await load()
    }

    func removeFavorite(contentID: String) async {
        favoriteService.removeFavorite(contentID: contentID)
        await load()
    }
}
