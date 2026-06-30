//
//  ContentRepository.swift
//  VinAppleTV
//
//  Created by Vinh Nguyen on 30/6/26.
//

import Foundation
import TVDomain

public protocol ContentDataSourcing: Sendable {
    func allContent() async throws -> [Content]
}

public protocol PlaybackProgressDataSourcing: Sendable {
    func allProgress() async throws -> [PlaybackProgress]
}

public struct MockContentDataSource: ContentDataSourcing {
    public init() {}

    public func allContent() async throws -> [Content] {
        Self.content
    }

    private static let streamURL = URL(
        string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_ts/master.m3u8"
    )

    private static let series = Category(id: "series", title: "Series")

    private static let content: [Content] = [
        item("gawla-akheera", "Gawla Akheera", "A dramatic final round forces its players to confront the choices that brought them together.", "Drama", 3_000, "https://shahid.mbc.net/mediaObject/5f6412ec-f3bf-4524-83e2-6f5ccd5d6ce4?width=464&version=1&type=avif&q=80", [.featured, .trending]),
        item("the-eight", "The Eight", "Eight lives become entangled in a dangerous mystery where loyalty is tested at every turn.", "Action Drama", 3_120, "https://shahid.mbc.net/mediaObject/06282c7e-5402-4123-8295-6853516f356f?width=464&version=1&type=avif&q=80", [.featured]),
        item("al-hayba-ras-al-jabal", "Al Hayba: Ras Al Jabal", "Power, family, and revenge collide as Jabal faces a threat that reaches the heart of Al Hayba.", "Drama", 3_240, "https://shahid.mbc.net/mediaObject/2ff3278e-9782-424a-bb6d-71e29866690a?width=464&version=1&type=avif&q=80", [.featured, .trending]),
        item("the-king", "The King", "A determined leader fights to protect his people while rivals close in from every side.", "Historical Drama", 3_180, "https://shahid.mbc.net/mediaObject/d8da0b6c-ebfb-41af-916f-f0504d63678c?width=464&version=1&type=avif&q=80", [.featured]),
        item("al-ameel", "Al Ameel", "An undercover agent navigates shifting alliances while pursuing a mission that cannot be exposed.", "Thriller", 3_060, "https://shahid.mbc.net/mediaObject/2024/Hanin/Sep/Thump_Al_Amel_en/original/Thump_Al_Amel_en.jpg?width=464&version=1&type=avif&q=80", [.trending]),
        item("bi-khams-arwah", "Bi Khams Arwah", "Five intertwined souls discover how far they will go for survival, justice, and redemption.", "Drama", 2_940, "https://shahid.mbc.net/mediaObject/3479acd8-2c09-4e8b-afef-288ed14f4186?width=464&version=1&type=avif&q=80", [.trending]),
        item("al-zind-thib-al-assi", "Al Zind: Thi'b Al Assi", "A fearless man returns home to challenge injustice and reclaim what was taken from his family.", "Period Drama", 3_300, "https://shahid.mbc.net/mediaObject/2023/Ramadan_2023/AlZind/ThumpEN_AlZind/original/ThumpEN_AlZind.jpg?width=464&version=1&type=avif&q=80", [.trending]),
        item("lobat-hob", "Lo'bat Hob", "Love becomes a complicated game as secrets and ambitions reshape several connected relationships.", "Romance", 3_000, "https://shahid.mbc.net/mediaObject/2024/Hanin/Aug/thump_Loabet_Hob/original/thump_Loabet_Hob.jpg?width=464&version=1&type=avif&q=80", []),
        item("efrag", "Efrag", "A family is pushed to its limits when buried secrets begin to reshape every relationship.", "Drama", 3_000, "https://shahid.mbc.net/mediaObject/aadde73f-d6c0-4b62-bd84-d7eecb97d4e1?width=464&version=1&type=avif&q=80", [.recommended]),
        item("bil-haram", "Bil Haram", "A web of forbidden choices draws several lives into an escalating struggle for truth.", "Drama", 3_060, "https://shahid.mbc.net/mediaObject/dad9eb16-60e9-44e7-99e1-c534410c69f2?width=464&version=1&type=avif&q=80", [.recommended]),
        item("aynak-kal-bahr-al-aswad", "Aynak Kal Bahr Al Aswad", "Lives converge beside the Black Sea as memory, love, and loss pull them toward an uncertain future.", "Drama", 3_120, "https://shahid.mbc.net/mediaObject/564ab703-cc65-4177-b58b-9257d2657b67?width=464&version=1&type=avif&q=80", [.recommended]),
        item("kayd-al-hareem", "Kayd Al Hareem", "Rivalries and hidden motives turn an extended family's everyday life into a battle of wits.", "Comedy Drama", 2_880, "https://shahid.mbc.net/mediaObject/2021/Bedour/bedour2/bedour/Thump_Kayd_Al_Hareem_EN/original/Thump_Kayd_Al_Hareem_EN.jpg?width=464&version=1&type=avif&q=80", [.recommended]),
        item("mawlana", "Mawlana", "A charismatic figure faces the consequences of influence when public faith and private truth collide.", "Social Drama", 3_180, "https://shahid.mbc.net/mediaObject/914cb5fc-e408-4991-8857-438758be8d83?width=464&version=1&type=avif&q=80", [.recommended]),
        item("el-set-monalisa", "El Set Monalisa", "An unconventional woman charts her own course through family expectations and surprising new alliances.", "Comedy Drama", 2_940, "https://shahid.mbc.net/mediaObject/28e30e2d-8a33-435b-9d95-5359f3acf4ad?width=464&version=1&type=avif&q=80", [.recommended]),
        item("bimbo", "Bimbo", "A reckless plan pulls two unlikely partners into a fast-moving mystery filled with comic detours.", "Comedy Thriller", 2_760, "https://shahid.mbc.net/mediaObject/cea6b805-2ae4-484c-afcf-38c61381cb5d?width=464&version=1&type=avif&q=80", [.recommended]),
        item("share-al-asha", "Share' Al A'sha", "The residents of a close-knit street navigate love, ambition, and change across generations.", "Period Drama", 3_240, "https://shahid.mbc.net/mediaObject/9fae0824-2fb7-4811-b81d-aa29b85f3ffc?width=464&version=1&type=avif&q=80", [.recommended])
    ]

    private static func item(
        _ id: String,
        _ title: String,
        _ description: String,
        _ genre: String,
        _ durationSeconds: TimeInterval,
        _ artworkReference: String,
        _ sections: Set<ContentSection>
    ) -> Content {
        Content(
            id: id,
            title: title,
            description: description,
            category: series,
            genre: genre,
            durationSeconds: durationSeconds,
            artworkReference: artworkReference,
            sections: sections,
            streamURL: streamURL
        )
    }
}

public struct MockPlaybackProgressDataSource: PlaybackProgressDataSourcing {
    private let progress: [PlaybackProgress]

    public init(progress: [PlaybackProgress]? = nil) {
        self.progress = progress ?? [
            PlaybackProgress(
                contentID: "al-ameel",
                positionSeconds: 1_240,
                durationSeconds: 3_420,
                updatedAt: Date(timeIntervalSince1970: 1_719_792_000)
            ),
            PlaybackProgress(
                contentID: "gawla-akheera",
                positionSeconds: 2_100,
                durationSeconds: 5_640,
                updatedAt: Date(timeIntervalSince1970: 1_719_705_600)
            ),
            PlaybackProgress(
                contentID: "the-eight",
                positionSeconds: 640,
                durationSeconds: 3_300,
                updatedAt: Date(timeIntervalSince1970: 1_719_619_200)
            )
        ]
    }

    public func allProgress() async throws -> [PlaybackProgress] {
        progress
    }
}

public struct ContentRepository: ContentRepositoryProtocol {
    private let dataSource: ContentDataSourcing
    private let progressDataSource: PlaybackProgressDataSourcing

    public init(
        dataSource: ContentDataSourcing,
        progressDataSource: PlaybackProgressDataSourcing = MockPlaybackProgressDataSource()
    ) {
        self.dataSource = dataSource
        self.progressDataSource = progressDataSource
    }

    public func featuredContent() async throws -> [Content] {
        try await content(in: .featured)
    }

    public func trendingContent() async throws -> [Content] {
        try await content(in: .trending)
    }

    public func recommendedContent() async throws -> [Content] {
        try await content(in: .recommended)
    }

    public func continueWatchingContent() async throws -> [Content] {
        let allContent = try await dataSource.allContent()
        let contentByID = Dictionary(uniqueKeysWithValues: allContent.map { ($0.id, $0) })
        let progress = try await progressDataSource.allProgress()

        return progress
            .filter { $0.positionSeconds > 0 && $0.positionSeconds < $0.durationSeconds }
            .sorted { $0.updatedAt > $1.updatedAt }
            .compactMap { contentByID[$0.contentID] }
    }

    public func content(id: String) async throws -> Content? {
        try await dataSource.allContent().first { $0.id == id }
    }

    public func playbackProgress(contentID: String) async throws -> PlaybackProgress? {
        try await progressDataSource.allProgress()
            .filter { $0.contentID == contentID }
            .max { $0.updatedAt < $1.updatedAt }
    }

    public func searchContent(matching query: String) async throws -> [Content] {
        let normalizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedQuery.isEmpty else { return [] }

        return try await dataSource.allContent().filter {
            $0.title.localizedCaseInsensitiveContains(normalizedQuery)
        }
    }

    private func content(in section: ContentSection) async throws -> [Content] {
        try await dataSource.allContent().filter { $0.sections.contains(section) }
    }
}
