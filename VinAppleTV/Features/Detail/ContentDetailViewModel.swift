//
//  ContentDetailViewModel.swift
//  VinAppleTV
//
//  Created by Vinh Nguyen on 25/6/26.
//

import Combine
import Foundation
import TVDomain
import VPCommon
import VPPlayer

@MainActor
final class ContentDetailViewModel: ObservableObject {
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case notFound
        case failed(String)
    }

    struct PlaybackRequest: Equatable {
        let content: Content
        let startSeconds: TimeInterval
    }

    @Published private(set) var content: Content?
    @Published private(set) var playbackProgress: PlaybackProgress?
    @Published private(set) var isFavorite = false
    @Published private(set) var loadState: LoadState = .idle

    let contentID: String

    private let contentDetailUseCase: GetContentDetailUseCase
    private let playbackProgressUseCase: GetPlaybackProgressUseCase
    private let favoriteService: FavoriteStateServicing
    private let analyticsTracker: AnalyticsTracking
    private let localProgressStore: PlaybackProgressStoring?
    private var favoriteObservation: AnyCancellable?
    private var hasTrackedScreenView = false

    init(
        contentID: String,
        contentDetailUseCase: GetContentDetailUseCase,
        playbackProgressUseCase: GetPlaybackProgressUseCase,
        favoriteService: FavoriteStateServicing,
        analyticsTracker: AnalyticsTracking,
        localProgressStore: PlaybackProgressStoring? = nil
    ) {
        self.contentID = contentID
        self.contentDetailUseCase = contentDetailUseCase
        self.playbackProgressUseCase = playbackProgressUseCase
        self.favoriteService = favoriteService
        self.analyticsTracker = analyticsTracker
        self.localProgressStore = localProgressStore
        favoriteObservation = favoriteService.favoriteContentIDsPublisher
            .map { $0.contains(contentID) }
            .removeDuplicates()
            .sink { [weak self] isFavorite in
                self?.isFavorite = isFavorite
            }
    }

    var resumablePositionSeconds: TimeInterval? {
        guard let progress = playbackProgress,
              progress.positionSeconds > 0,
              progress.positionSeconds < progress.durationSeconds else {
            return nil
        }

        return progress.positionSeconds
    }

    var resumeButtonTitle: String? {
        resumablePositionSeconds.map { "Resume from \(Self.formatTime($0))" }
    }

    var hasCompletedPlayback: Bool {
        guard let playbackProgress else { return false }
        return playbackProgress.durationSeconds > 0
            && playbackProgress.positionSeconds >= playbackProgress.durationSeconds
    }

    func load() async {
        guard loadState != .loading else { return }
        loadState = .loading

        do {
            async let loadedContent = contentDetailUseCase.execute(id: contentID)
            async let progress = playbackProgressUseCase.execute(contentID: contentID)

            guard let loadedContent = try await loadedContent else {
                content = nil
                playbackProgress = nil
                loadState = .notFound
                return
            }

            content = loadedContent
            if let stored = localProgressStore?.progress(contentID: contentID) {
                playbackProgress = PlaybackProgress(
                    contentID: contentID,
                    positionSeconds: stored.positionSeconds,
                    durationSeconds: stored.durationSeconds,
                    updatedAt: stored.lastWatchedAt
                )
            } else {
                playbackProgress = try await progress
            }
            isFavorite = favoriteService.isFavorite(contentID: contentID)
            loadState = .loaded

            if !hasTrackedScreenView {
                analyticsTracker.track(.screenViewed(.detail, contentID: contentID))
                hasTrackedScreenView = true
            }
        } catch {
            loadState = .failed(error.localizedDescription)
        }
    }

    func toggleFavorite() {
        isFavorite = favoriteService.toggleFavorite(contentID: contentID)
    }

    func play() -> PlaybackRequest? {
        makePlaybackRequest(startSeconds: hasCompletedPlayback ? 0 : (resumablePositionSeconds ?? 0))
    }

    func startOver() -> PlaybackRequest? {
        makePlaybackRequest(startSeconds: 0)
    }

    static func formatTime(_ seconds: TimeInterval) -> String {
        let totalSeconds = max(0, Int(seconds))
        let hours = totalSeconds / 3_600
        let minutes = (totalSeconds % 3_600) / 60
        let remainingSeconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, remainingSeconds)
        }

        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }

    private func makePlaybackRequest(startSeconds: TimeInterval) -> PlaybackRequest? {
        guard let content, content.streamURL != nil else { return nil }
        return PlaybackRequest(content: content, startSeconds: startSeconds)
    }
}
