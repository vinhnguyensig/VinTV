//
//  VideoPlayerService.swift
//  VinAppleTV
//
//  Created by Vinh Nguyen on 27/6/26.
//

import AVFoundation
import Foundation

public enum VideoPlaybackState: Sendable, Equatable {
    case idle
    case ready
    case playing
    case paused
    case completed
    case failed(String)
}

@MainActor
public protocol VideoPlayerServicing: AnyObject {
    var player: AVPlayer { get }
    var state: VideoPlaybackState { get }
    var onStateChange: ((VideoPlaybackState) -> Void)? { get set }
    var onProgress: ((TimeInterval, TimeInterval) -> Void)? { get set }

    func load(url: URL)
    func play()
    func pause()
    func seek(to seconds: TimeInterval)
}

@MainActor
public final class VideoPlayerService: VideoPlayerServicing {
    public let player: AVPlayer
    public private(set) var state: VideoPlaybackState = .idle {
        didSet {
            guard state != oldValue else { return }
            onStateChange?(state)
        }
    }

    public var onStateChange: ((VideoPlaybackState) -> Void)?
    public var onProgress: ((TimeInterval, TimeInterval) -> Void)?

    nonisolated(unsafe) private var timeObserver: Any?
    private var itemStatusObservation: NSKeyValueObservation?
    nonisolated(unsafe) private var completionObserver: NSObjectProtocol?

    public init(player: AVPlayer = AVPlayer()) {
        self.player = player
    }

    deinit {
        if let timeObserver {
            player.removeTimeObserver(timeObserver)
        }
        if let completionObserver {
            NotificationCenter.default.removeObserver(completionObserver)
        }
    }

    public func load(url: URL) {
        removeObservers()

        let item = AVPlayerItem(url: url)
        player.replaceCurrentItem(with: item)
        state = .idle

        itemStatusObservation = item.observe(\.status, options: [.initial, .new]) { [weak self] item, _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                switch item.status {
                case .readyToPlay:
                    self.state = .ready
                    self.publishProgress()
                case .failed:
                    self.state = .failed(
                        item.error?.localizedDescription ?? "Unable to load this video."
                    )
                case .unknown:
                    break
                @unknown default:
                    break
                }
            }
        }

        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 1, preferredTimescale: 600),
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.publishProgress()
            }
        }

        completionObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                self.publishProgress()
                self.state = .completed
            }
        }
    }

    public func play() {
        guard player.currentItem != nil else { return }
        player.play()
        state = .playing
    }

    public func pause() {
        guard player.currentItem != nil else { return }
        player.pause()
        state = .paused
        publishProgress()
    }

    public func seek(to seconds: TimeInterval) {
        guard seconds.isFinite else { return }
        let target = max(0, seconds)
        player.seek(
            to: CMTime(seconds: target, preferredTimescale: 600),
            toleranceBefore: .zero,
            toleranceAfter: .zero
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.publishProgress()
            }
        }
    }

    private func publishProgress() {
        let position = player.currentTime().seconds
        let duration = player.currentItem?.duration.seconds ?? 0
        onProgress?(
            position.isFinite ? max(0, position) : 0,
            duration.isFinite ? max(0, duration) : 0
        )
    }

    private func removeObservers() {
        itemStatusObservation = nil

        if let timeObserver {
            player.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }

        if let completionObserver {
            NotificationCenter.default.removeObserver(completionObserver)
            self.completionObserver = nil
        }
    }
}
