//
//  PlaybackProgressService.swift
//  VinAppleTV
//
//  Created by Vinh Nguyen on 28/6/26.
//

import Foundation
import VPLocalStorage
import Combine

struct StoredPlaybackProgress: Codable, Equatable {
    let positionSeconds: TimeInterval
    let durationSeconds: TimeInterval
    let lastWatchedAt: Date
    let isCompleted: Bool
}

@MainActor
protocol PlaybackProgressStoring {
    var progressDidChangePublisher: AnyPublisher<String, Never> { get }
    func progress(contentID: String) -> StoredPlaybackProgress?
    func allProgress() -> [String: StoredPlaybackProgress]
    func save(_ progress: StoredPlaybackProgress, contentID: String)
}

@MainActor
final class LocalPlaybackProgressService: PlaybackProgressStoring {
    private let store: KeyValueStoring
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let progressDidChange = PassthroughSubject<String, Never>()

    var progressDidChangePublisher: AnyPublisher<String, Never> {
        progressDidChange.eraseToAnyPublisher()
    }

    init(store: KeyValueStoring) {
        self.store = store
    }

    func progress(contentID: String) -> StoredPlaybackProgress? {
        guard let value = store.string(forKey: key(contentID)),
              let data = value.data(using: .utf8) else {
            return nil
        }
        return try? decoder.decode(StoredPlaybackProgress.self, from: data)
    }

    func allProgress() -> [String: StoredPlaybackProgress] {
        guard let indexValue = store.string(forKey: Keys.contentIDs) else { return [:] }

        return Dictionary(
            uniqueKeysWithValues: indexValue
                .split(separator: ",")
                .compactMap { contentID -> (String, StoredPlaybackProgress)? in
                    let id = String(contentID)
                    return progress(contentID: id).map { (id, $0) }
                }
        )
    }

    func save(_ progress: StoredPlaybackProgress, contentID: String) {
        guard let data = try? encoder.encode(progress),
              let value = String(data: data, encoding: .utf8) else {
            return
        }
        store.set(value, forKey: key(contentID))
        var contentIDs = Set(
            store.string(forKey: Keys.contentIDs)?
                .split(separator: ",")
                .map(String.init) ?? []
        )
        contentIDs.insert(contentID)
        store.set(contentIDs.sorted().joined(separator: ","), forKey: Keys.contentIDs)
        progressDidChange.send(contentID)
    }

    private func key(_ contentID: String) -> String {
        "playback_progress.\(contentID)"
    }

    private enum Keys {
        static let contentIDs = "playback_progress.content_ids"
    }
}
