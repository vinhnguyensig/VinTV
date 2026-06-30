//
//  ContentRepository.swift
//  VinAppleTV
//
//  Created by Vinh Nguyen on 29/6/26.
//

public protocol ContentRepositoryProtocol: Sendable {
    func featuredContent() async throws -> [Content]
    func trendingContent() async throws -> [Content]
    func recommendedContent() async throws -> [Content]
    func continueWatchingContent() async throws -> [Content]
    func content(id: String) async throws -> Content?
    func playbackProgress(contentID: String) async throws -> PlaybackProgress?
    func searchContent(matching query: String) async throws -> [Content]
}

public protocol GetFeaturedContentUseCase: Sendable {
    func execute() async throws -> [Content]
}

public protocol GetTrendingContentUseCase: Sendable {
    func execute() async throws -> [Content]
}

public protocol GetRecommendedContentUseCase: Sendable {
    func execute() async throws -> [Content]
}

public protocol GetContinueWatchingUseCase: Sendable {
    func execute() async throws -> [Content]
}

public protocol GetContentDetailUseCase: Sendable {
    func execute(id: String) async throws -> Content?
}

public protocol GetPlaybackProgressUseCase: Sendable {
    func execute(contentID: String) async throws -> PlaybackProgress?
}

public protocol SearchContentUseCase: Sendable {
    func execute(query: String) async throws -> [Content]
}

public struct DefaultGetFeaturedContentUseCase: GetFeaturedContentUseCase {
    private let repository: ContentRepositoryProtocol

    public init(repository: ContentRepositoryProtocol) {
        self.repository = repository
    }

    public func execute() async throws -> [Content] {
        try await repository.featuredContent()
    }
}

public struct DefaultGetTrendingContentUseCase: GetTrendingContentUseCase {
    private let repository: ContentRepositoryProtocol

    public init(repository: ContentRepositoryProtocol) {
        self.repository = repository
    }

    public func execute() async throws -> [Content] {
        try await repository.trendingContent()
    }
}

public struct DefaultGetRecommendedContentUseCase: GetRecommendedContentUseCase {
    private let repository: ContentRepositoryProtocol

    public init(repository: ContentRepositoryProtocol) {
        self.repository = repository
    }

    public func execute() async throws -> [Content] {
        try await repository.recommendedContent()
    }
}

public struct DefaultGetContinueWatchingUseCase: GetContinueWatchingUseCase {
    private let repository: ContentRepositoryProtocol

    public init(repository: ContentRepositoryProtocol) {
        self.repository = repository
    }

    public func execute() async throws -> [Content] {
        try await repository.continueWatchingContent()
    }
}

public struct DefaultGetContentDetailUseCase: GetContentDetailUseCase {
    private let repository: ContentRepositoryProtocol

    public init(repository: ContentRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(id: String) async throws -> Content? {
        try await repository.content(id: id)
    }
}

public struct DefaultGetPlaybackProgressUseCase: GetPlaybackProgressUseCase {
    private let repository: ContentRepositoryProtocol

    public init(repository: ContentRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(contentID: String) async throws -> PlaybackProgress? {
        try await repository.playbackProgress(contentID: contentID)
    }
}

public struct DefaultSearchContentUseCase: SearchContentUseCase {
    private let repository: ContentRepositoryProtocol

    public init(repository: ContentRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(query: String) async throws -> [Content] {
        try await repository.searchContent(matching: query)
    }
}
