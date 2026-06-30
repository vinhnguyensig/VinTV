//
//  Content.swift
//  VinAppleTV
//
//  Created by Vinh Nguyen on 27/6/26.
//

import Foundation

public struct Content: Identifiable, Sendable, Equatable {
    public let id: String
    public let title: String
    public let description: String
    public let category: Category
    public let genre: String
    public let durationSeconds: TimeInterval
    public let artworkReference: String
    public let sections: Set<ContentSection>
    public let streamURL: URL?

    public init(
        id: String,
        title: String,
        description: String,
        category: Category,
        genre: String,
        durationSeconds: TimeInterval,
        artworkReference: String,
        sections: Set<ContentSection> = [],
        streamURL: URL? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.category = category
        self.genre = genre
        self.durationSeconds = durationSeconds
        self.artworkReference = artworkReference
        self.sections = sections
        self.streamURL = streamURL
    }

    public var durationDisplayText: String {
        let totalMinutes = max(0, Int(durationSeconds) / 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if hours == 0 {
            return "\(minutes) min"
        }

        if minutes == 0 {
            return "\(hours)h"
        }

        return "\(hours)h \(minutes)m"
    }
}

public enum ContentSection: String, Sendable, Hashable, CaseIterable {
    case featured
    case trending
    case recommended
}

public struct Category: Identifiable, Sendable, Equatable {
    public let id: String
    public let title: String

    public init(id: String, title: String) {
        self.id = id
        self.title = title
    }
}

public struct PlaybackProgress: Sendable, Equatable {
    public let contentID: String
    public let positionSeconds: TimeInterval
    public let durationSeconds: TimeInterval
    public let updatedAt: Date

    public init(
        contentID: String,
        positionSeconds: TimeInterval,
        durationSeconds: TimeInterval,
        updatedAt: Date
    ) {
        self.contentID = contentID
        self.positionSeconds = positionSeconds
        self.durationSeconds = durationSeconds
        self.updatedAt = updatedAt
    }
}
