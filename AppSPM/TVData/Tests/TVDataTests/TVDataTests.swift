//
//  TVDataTests.swift
//  VinAppleTV
//
//  Created by Vinh Nguyen on 26/6/26.
//

import Foundation
import Testing
import TVDomain
@testable import TVData

@Test
func mockDataProvidesStableRichContent() async throws {
    let content = try await MockContentDataSource().allContent()

    #expect(content.count == 16)
    #expect(Set(content.map(\.id)).count == content.count)
    #expect(content.allSatisfy { !$0.genre.isEmpty && !$0.artworkReference.isEmpty })
    #expect(content.allSatisfy { $0.category.id == "series" })
    #expect(content.allSatisfy { $0.artworkReference.hasPrefix("https://shahid.mbc.net/mediaObject/") })
}

@Test
func repositoryReturnsLatestProgressForContent() async throws {
    let progress = [
        PlaybackProgress(
            contentID: "gawla-akheera",
            positionSeconds: 20,
            durationSeconds: 100,
            updatedAt: Date(timeIntervalSince1970: 100)
        ),
        PlaybackProgress(
            contentID: "gawla-akheera",
            positionSeconds: 40,
            durationSeconds: 100,
            updatedAt: Date(timeIntervalSince1970: 200)
        )
    ]
    let repository = ContentRepository(
        dataSource: MockContentDataSource(),
        progressDataSource: MockPlaybackProgressDataSource(progress: progress)
    )

    let result = try await repository.playbackProgress(contentID: "gawla-akheera")

    #expect(result?.positionSeconds == 40)
}

@Test
func repositoryReturnsDistinctPopulatedSections() async throws {
    let repository = ContentRepository(dataSource: MockContentDataSource())
    let featured = try await repository.featuredContent()
    let trending = try await repository.trendingContent()
    let recommended = try await repository.recommendedContent()

    #expect(featured.count >= 3)
    #expect(trending.count >= 3)
    #expect(recommended.count >= 3)
    #expect(featured.allSatisfy { $0.sections.contains(.featured) })
    #expect(trending.allSatisfy { $0.sections.contains(.trending) })
    #expect(recommended.allSatisfy { $0.sections.contains(.recommended) })
    #expect(recommended.map(\.id) == [
        "efrag",
        "bil-haram",
        "aynak-kal-bahr-al-aswad",
        "kayd-al-hareem",
        "mawlana",
        "el-set-monalisa",
        "bimbo",
        "share-al-asha"
    ])
}

@Test
func repositoryLooksUpContentByStableID() async throws {
    let repository = ContentRepository(dataSource: MockContentDataSource())

    #expect(try await repository.content(id: "al-hayba-ras-al-jabal")?.title == "Al Hayba: Ras Al Jabal")
    #expect(try await repository.content(id: "missing") == nil)
}

@Test
func repositorySearchIsTrimmedCaseInsensitiveAndTitleOnly() async throws {
    let repository = ContentRepository(dataSource: MockContentDataSource())

    #expect(try await repository.searchContent(matching: "  EIGHT  ").map(\.id) == ["the-eight"])
    #expect(try await repository.searchContent(matching: "   ").isEmpty)
    #expect(try await repository.searchContent(matching: "not a title").isEmpty)
}

@Test
func continueWatchingMapsValidProgressInRecencyOrder() async throws {
    let progress = [
        PlaybackProgress(contentID: "gawla-akheera", positionSeconds: 20, durationSeconds: 100, updatedAt: Date(timeIntervalSince1970: 100)),
        PlaybackProgress(contentID: "al-ameel", positionSeconds: 30, durationSeconds: 100, updatedAt: Date(timeIntervalSince1970: 300)),
        PlaybackProgress(contentID: "missing", positionSeconds: 10, durationSeconds: 100, updatedAt: Date(timeIntervalSince1970: 400)),
        PlaybackProgress(contentID: "the-eight", positionSeconds: 100, durationSeconds: 100, updatedAt: Date(timeIntervalSince1970: 200)),
        PlaybackProgress(contentID: "the-king", positionSeconds: 0, durationSeconds: 100, updatedAt: Date(timeIntervalSince1970: 500))
    ]
    let repository = ContentRepository(
        dataSource: MockContentDataSource(),
        progressDataSource: MockPlaybackProgressDataSource(progress: progress)
    )

    #expect(try await repository.continueWatchingContent().map(\.id) == [
        "al-ameel",
        "gawla-akheera"
    ])
}
