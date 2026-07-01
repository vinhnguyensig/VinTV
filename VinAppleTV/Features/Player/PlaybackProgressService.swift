//
//  PlaybackProgressService.swift
//  VinAppleTV
//
//  Created by Vinh Nguyen on 28/6/26.
//

import Foundation
import VPLocalStorage

struct StoredPlaybackProgress: Codable, Equatable {
    let positionSeconds: TimeInterval
    let durationSeconds: TimeInterval
    let lastWatchedAt: Date
    let isCompleted: Bool
}

@MainActor
protocol PlaybackProgressStoring {
    func progress(contentID: String) -> StoredPlaybackProgress?
    func save(_ progress: StoredPlaybackProgress, contentID: String)
}

@MainActor
final class LocalPlaybackProgressService: PlaybackProgressStoring {
    private let store: KeyValueStoring
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

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

    func save(_ progress: StoredPlaybackProgress, contentID: String) {
        guard let data = try? encoder.encode(progress),
              let value = String(data: data, encoding: .utf8) else {
            return
        }
        store.set(value, forKey: key(contentID))
    }

    private func key(_ contentID: String) -> String {
        "playback_progress.\(contentID)"
    }
}
