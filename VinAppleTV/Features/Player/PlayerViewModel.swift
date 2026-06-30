//
//  PlayerViewModel.swift
//  VinAppleTV
//
//  Created by Vinh Nguyen on 25/6/26.
//

import AVFoundation
import Combine
import Foundation
import TVDomain
import VPCommon
import VPPlayer

@MainActor
final class PlayerViewModel: ObservableObject {
    @Published private(set) var state: VideoPlaybackState = .idle
    @Published private(set) var positionSeconds: TimeInterval = 0
    @Published private(set) var durationSeconds: TimeInterval = 0

    let content: Content
    var player: AVPlayer { playerService.player }
    var isPlaying: Bool { state == .playing }

    private let requestedStartSeconds: TimeInterval
    private let playerService: VideoPlayerServicing
    private let progressStore: PlaybackProgressStoring
    private let analyticsTracker: AnalyticsTracking
    private let now: () -> Date
    private var hasStarted = false
    private var didApplyInitialPosition = false

    init(
        content: Content,
        startSeconds: TimeInterval,
        playerService: VideoPlayerServicing,
        progressStore: PlaybackProgressStoring,
        analyticsTracker: AnalyticsTracking,
        now: @escaping () -> Date = Date.init
    ) {
        self.content = content
        self.requestedStartSeconds = startSeconds
        self.playerService = playerService
        self.progressStore = progressStore
        self.analyticsTracker = analyticsTracker
        self.now = now
    }

    func start() {
        guard !hasStarted, let streamURL = content.streamURL else { return }
        hasStarted = true
        analyticsTracker.track(.screenViewed(.player, contentID: content.id))

        playerService.onStateChange = { [weak self] state in
            self?.handleStateChange(state)
        }
        playerService.onProgress = { [weak self] position, duration in
            self?.handleProgress(position: position, duration: duration)
        }
        playerService.load(url: streamURL)
    }

    func playPause() {
        if isPlaying {
            playerService.pause()
            analyticsTracker.track(
                .playbackPaused(contentID: content.id, positionSeconds: positionSeconds)
            )
            saveProgress()
        } else {
            let isResuming = state == .paused
            playerService.play()
            analyticsTracker.track(
                isResuming
                    ? .playbackResumed(contentID: content.id, positionSeconds: positionSeconds)
                    : .playbackStarted(contentID: content.id, positionSeconds: positionSeconds)
            )
        }
    }

    func seek(by offset: TimeInterval) {
        let previousPosition = positionSeconds
        let upperBound = durationSeconds > 0 ? durationSeconds : content.durationSeconds
        let target = min(max(0, previousPosition + offset), upperBound)
        playerService.seek(to: target)
        positionSeconds = target
        analyticsTracker.track(
            .playbackSeeked(
                contentID: content.id,
                fromSeconds: previousPosition,
                toSeconds: target
            )
        )
        saveProgress()
    }

    func stop() {
        guard hasStarted else { return }
        playerService.pause()
        saveProgress()
        playerService.onStateChange = nil
        playerService.onProgress = nil
        hasStarted = false
    }

    private func handleStateChange(_ newState: VideoPlaybackState) {
        state = newState

        switch newState {
        case .ready:
            let savedPosition = progressStore.progress(contentID: content.id)
                .flatMap { $0.isCompleted ? nil : $0.positionSeconds }
            let initialPosition = requestedStartSeconds > 0
                ? requestedStartSeconds
                : (savedPosition ?? 0)

            if initialPosition > 0, !didApplyInitialPosition {
                didApplyInitialPosition = true
                positionSeconds = initialPosition
                playerService.seek(to: initialPosition)
            }
            playerService.play()
            analyticsTracker.track(
                .playbackStarted(contentID: content.id, positionSeconds: initialPosition)
            )
        case .completed:
            positionSeconds = max(durationSeconds, content.durationSeconds)
            progressStore.save(
                StoredPlaybackProgress(
                    positionSeconds: positionSeconds,
                    durationSeconds: positionSeconds,
                    lastWatchedAt: now(),
                    isCompleted: true
                ),
                contentID: content.id
            )
            analyticsTracker.track(
                .playbackCompleted(contentID: content.id, positionSeconds: positionSeconds)
            )
        default:
            break
        }
    }

    private func handleProgress(position: TimeInterval, duration: TimeInterval) {
        positionSeconds = position
        durationSeconds = duration > 0 ? duration : content.durationSeconds
    }

    private func saveProgress() {
        guard durationSeconds > 0 else { return }
        progressStore.save(
            StoredPlaybackProgress(
                positionSeconds: positionSeconds,
                durationSeconds: durationSeconds,
                lastWatchedAt: now(),
                isCompleted: state == .completed
            ),
            contentID: content.id
        )
    }

}
