//
//  ContentDetailStateService.swift
//  VinAppleTV
//
//  Created by Vinh Nguyen on 27/6/26.
//

import Foundation
import VPLocalStorage
import Combine

@MainActor
protocol FavoriteStateServicing: AnyObject {
    var favoriteContentIDs: Set<String> { get }
    var favoriteContentIDsPublisher: AnyPublisher<Set<String>, Never> { get }
    func isFavorite(contentID: String) -> Bool
    func addFavorite(contentID: String)
    func removeFavorite(contentID: String)
    @discardableResult
    func toggleFavorite(contentID: String) -> Bool
}

@MainActor
final class LocalFavoriteStateService: ObservableObject, FavoriteStateServicing {
    private enum Keys {
        static let favoriteContentIDs = "favorite_content_ids"
    }

    private let store: KeyValueStoring
    @Published private(set) var favoriteContentIDs: Set<String>

    var favoriteContentIDsPublisher: AnyPublisher<Set<String>, Never> {
        $favoriteContentIDs.eraseToAnyPublisher()
    }

    init(store: KeyValueStoring) {
        self.store = store
        favoriteContentIDs = Self.loadFavoriteIDs(from: store)
    }

    func isFavorite(contentID: String) -> Bool {
        favoriteContentIDs.contains(contentID)
    }

    func addFavorite(contentID: String) {
        guard favoriteContentIDs.insert(contentID).inserted else { return }
        persist()
    }

    func removeFavorite(contentID: String) {
        guard favoriteContentIDs.remove(contentID) != nil else { return }
        persist()
    }

    func toggleFavorite(contentID: String) -> Bool {
        if favoriteContentIDs.contains(contentID) {
            removeFavorite(contentID: contentID)
            return false
        } else {
            addFavorite(contentID: contentID)
            return true
        }
    }

    private func persist() {
        store.set(
            favoriteContentIDs.sorted().joined(separator: ","),
            forKey: Keys.favoriteContentIDs
        )
    }

    private static func loadFavoriteIDs(from store: KeyValueStoring) -> Set<String> {
        guard let storedValue = store.string(forKey: Keys.favoriteContentIDs) else {
            return []
        }

        return Set(storedValue.split(separator: ",").map(String.init))
    }
}
