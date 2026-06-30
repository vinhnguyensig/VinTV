//
//  TVDomainTests.swift
//  VinAppleTV
//
//  Created by Vinh Nguyen on 27/6/26.
//

import Foundation
import Testing
@testable import TVDomain

@Test
func contentStoresPresentationMetadataAndFormatsDuration() {
    let content = makeContent(durationSeconds: 5_580)

    #expect(content.genre == "Drama")
    #expect(content.artworkReference == "artwork/foundation")
    #expect(content.sections == [.featured, .recommended])
    #expect(content.durationDisplayText == "1h 33m")
}

@Test
func durationFormattingHandlesShortAndWholeHourContent() {
    #expect(makeContent(durationSeconds: 2_700).durationDisplayText == "45 min")
    #expect(makeContent(durationSeconds: 7_200).durationDisplayText == "2h")
}

@Test
func detailUseCaseForwardsStableID() async throws {
    let repository = RepositoryStub(content: makeContent())
    let result = try await DefaultGetContentDetailUseCase(repository: repository)
        .execute(id: "foundation")

    #expect(result?.id == "foundation")
}

@Test
func searchUseCaseForwardsQuery() async throws {
    let repository = RepositoryStub(content: makeContent())
    let result = try await DefaultSearchContentUseCase(repository: repository)
        .execute(query: "FOUND")

    #expect(result.map(\.id) == ["foundation"])
}

private func makeContent(durationSeconds: TimeInterval = 60) -> Content {
    Content(
        id: "foundation",
        title: "Foundation",
        description: "Ready",
        category: Category(id: "series", title: "Series"),
        genre: "Drama",
        durationSeconds: durationSeconds,
        artworkReference: "artwork/foundation",
        sections: [.featured, .recommended]
    )
}

private struct RepositoryStub: ContentRepositoryProtocol {
    let content: Content

    func featuredContent() async throws -> [Content] { [content] }
    func trendingContent() async throws -> [Content] { [content] }
    func recommendedContent() async throws -> [Content] { [content] }
    func continueWatchingContent() async throws -> [Content] { [] }
    func content(id: String) async throws -> Content? {
        id == content.id ? content : nil
    }

    func playbackProgress(contentID: String) async throws -> PlaybackProgress? {
        nil
    }
    func searchContent(matching query: String) async throws -> [Content] {
        content.title.localizedCaseInsensitiveContains(query) ? [content] : []
    }
}
