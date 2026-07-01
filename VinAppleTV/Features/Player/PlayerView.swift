//
//  PlayerView.swift
//  VinAppleTV
//
//  Created by Vinh Nguyen on 25/6/26.
//

import AVKit
import SwiftUI
import TVDomain
import VPAppTheme
import VPPlayer

private enum PlayerFocusTarget: Hashable {
    case back
    case playPause
    case forward
    case retry
    case dismiss
}

struct PlayerView: View {
    @Environment(\.vpTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: PlayerViewModel
    @FocusState private var focusedTarget: PlayerFocusTarget?
    @State private var controlsArePresented = false
    @State private var autoHideTask: Task<Void, Never>?

    init(viewModel: PlayerViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            VideoPlayer(player: viewModel.player)
                .ignoresSafeArea()

            controlContrastGradient
            stateOverlay

            controls
                .padding(.horizontal, theme.layout.horizontalScreenInset)
                .padding(.bottom, theme.layout.controlOverlayInset)
        }
        .background(theme.colors.playerBackground)
        .navigationTitle(viewModel.content.title)
        .toolbar(.hidden, for: .tabBar)
        .onMoveCommand { _ in
            presentControls()
        }
        .onPlayPauseCommand {
            viewModel.playPause()
            presentControls()
        }
        .onChange(of: focusedTarget) { _, target in
            guard target != nil else { return }
            scheduleAutoHide()
        }
        .onChange(of: viewModel.state) { _, state in
            if state == .playing {
                scheduleAutoHide()
            } else {
                presentControls(automaticallyHide: false)
            }
        }
        .task {
            viewModel.start()
            await Task.yield()
            presentControls()
        }
        .onDisappear {
            autoHideTask?.cancel()
            viewModel.stop()
        }
    }

    private var controlContrastGradient: some View {
        LinearGradient(
            stops: [
                .init(color: .clear, location: 0.36),
                .init(color: .black.opacity(0.3), location: 0.62),
                .init(color: .black.opacity(0.92), location: 1)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
        .opacity(controlsArePresented ? 1 : 0)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: theme.spacing.medium) {
            HStack(alignment: .firstTextBaseline, spacing: theme.spacing.medium) {
                VStack(alignment: .leading, spacing: theme.spacing.xxSmall) {
                    Text(viewModel.content.title)
                        .font(theme.fonts.sectionTitle)
                        .lineLimit(1)

                    Label(playbackStatus, systemImage: playbackStatusIcon)
                        .font(theme.fonts.metadata)
                        .foregroundStyle(theme.colors.secondaryText)
                }

                Spacer()

                if let qualityLabel = viewModel.qualityLabel {
                    Text(qualityLabel)
                        .font(theme.fonts.metadata)
                        .padding(.horizontal, theme.spacing.small)
                        .padding(.vertical, theme.spacing.xxSmall)
                        .background(.white.opacity(0.14), in: Capsule())
                        .accessibilityLabel("Playback quality \(qualityLabel)")
                }

                Text("\(elapsedTime)  •  \(remainingTime) remaining")
                    .font(theme.fonts.metadata)
                    .foregroundStyle(theme.colors.secondaryText)
                    .monospacedDigit()
                    .accessibilityLabel("\(elapsedTime) elapsed, \(remainingTime) remaining")
            }

            playerProgress

            HStack(spacing: theme.spacing.large) {
                playerButton(
                    title: "Back 10 Seconds",
                    systemImage: "gobackward.10",
                    target: .back
                ) {
                    viewModel.seek(by: -10)
                }

                playerButton(
                    title: viewModel.isPlaying ? "Pause" : "Play",
                    systemImage: viewModel.isPlaying ? "pause.fill" : "play.fill",
                    target: .playPause,
                    isPrimary: true
                ) {
                    viewModel.playPause()
                }

                playerButton(
                    title: "Forward 10 Seconds",
                    systemImage: "goforward.10",
                    target: .forward
                ) {
                    viewModel.seek(by: 10)
                }

                Spacer()
            }
        }
        .padding(theme.spacing.large)
        .background(
            theme.colors.overlayBackground.opacity(0.9),
            in: RoundedRectangle(cornerRadius: theme.radii.large)
        )
        .overlay {
            RoundedRectangle(cornerRadius: theme.radii.large)
                .stroke(.white.opacity(0.14), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.55), radius: 28, y: 14)
        .foregroundStyle(theme.colors.playerForeground)
        .opacity(controlsArePresented ? 1 : 0)
        .offset(y: controlsArePresented || reduceMotion ? 0 : 16)
        .allowsHitTesting(controlsArePresented)
        .accessibilityHidden(!controlsArePresented)
        .focusSection()
        .animation(
            .easeOut(duration: reduceMotion ? 0.16 : theme.focus.animationDuration),
            value: controlsArePresented
        )
    }

    @ViewBuilder
    private var stateOverlay: some View {
        switch viewModel.state {
        case .loading, .buffering, .seeking, .retrying, .reconnecting:
            VStack(spacing: theme.spacing.medium) {
                ProgressView()
                    .controlSize(.large)
                Text(playbackStatus)
                    .font(theme.fonts.sectionTitle)
            }
            .padding(theme.spacing.large)
            .background(.black.opacity(0.72), in: RoundedRectangle(cornerRadius: theme.radii.large))
            .foregroundStyle(.white)
            .accessibilityElement(children: .combine)
        case .failed(let message):
            VStack(spacing: theme.spacing.medium) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 48))
                Text("Playback Unavailable")
                    .font(theme.fonts.sectionTitle)
                Text(message)
                    .font(theme.fonts.metadata)
                    .foregroundStyle(theme.colors.secondaryText)
                    .multilineTextAlignment(.center)
                HStack(spacing: theme.spacing.medium) {
                    playerButton(
                        title: "Try Again",
                        systemImage: "arrow.clockwise",
                        target: .retry,
                        isPrimary: true
                    ) {
                        viewModel.retry()
                    }
                    playerButton(
                        title: "Dismiss",
                        systemImage: "xmark",
                        target: .dismiss
                    ) {
                        dismiss()
                    }
                }
            }
            .padding(theme.spacing.large)
            .frame(maxWidth: 680)
            .background(.black.opacity(0.86), in: RoundedRectangle(cornerRadius: theme.radii.large))
            .foregroundStyle(.white)
        default:
            EmptyView()
        }
    }

    private var playerProgress: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.white.opacity(0.24))

                Capsule()
                    .fill(theme.colors.accent)
                    .frame(width: proxy.size.width * progressFraction)

                Circle()
                    .fill(.white)
                    .frame(width: 18, height: 18)
                    .shadow(color: .black.opacity(0.4), radius: 4)
                    .offset(x: max(0, (proxy.size.width - 18) * progressFraction))
            }
        }
        .frame(height: 18)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Playback progress")
        .accessibilityValue("\(elapsedTime) of \(durationTime)")
    }

    private func playerButton(
        title: String,
        systemImage: String,
        target: PlayerFocusTarget,
        isPrimary: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        let isFocused = focusedTarget == target

        return Button {
            action()
            presentControls()
        } label: {
            Label(title, systemImage: systemImage)
                .font(theme.fonts.playerControl)
                .padding(.horizontal, theme.spacing.medium)
                .frame(minHeight: 64)
                .background(
                    isFocused
                        ? theme.colors.playerForeground
                        : (isPrimary
                            ? theme.colors.accent
                            : theme.colors.elevatedBackground.opacity(0.96)),
                    in: Capsule()
                )
                .foregroundStyle(
                    isFocused ? theme.colors.playerBackground : theme.colors.playerForeground
                )
                .overlay {
                    Capsule()
                        .stroke(
                            isFocused ? theme.colors.focusBorder : .white.opacity(0.16),
                            lineWidth: isFocused ? theme.focus.borderWidth : 1
                        )
                }
                .shadow(
                    color: isFocused ? .white.opacity(0.28) : .black.opacity(0.3),
                    radius: isFocused ? 18 : 8,
                    y: 6
                )
                .scaleEffect(isFocused && !reduceMotion ? 1.06 : 1)
                .animation(
                    reduceMotion
                        ? .easeOut(duration: 0.12)
                        : .interactiveSpring(
                            response: theme.focus.springResponse,
                            dampingFraction: theme.focus.springDampingFraction
                        ),
                    value: isFocused
                )
        }
        .buttonStyle(.plain)
        .focused($focusedTarget, equals: target)
        .accessibilityHint(target == .playPause ? "Toggles playback" : "Seeks the video")
    }

    private var progressFraction: Double {
        guard viewModel.durationSeconds > 0 else { return 0 }
        return min(max(viewModel.positionSeconds / viewModel.durationSeconds, 0), 1)
    }

    private var elapsedTime: String {
        ContentDetailViewModel.formatTime(viewModel.positionSeconds)
    }

    private var durationTime: String {
        ContentDetailViewModel.formatTime(viewModel.durationSeconds)
    }

    private var remainingTime: String {
        ContentDetailViewModel.formatTime(
            max(0, viewModel.durationSeconds - viewModel.positionSeconds)
        )
    }

    private var playbackStatus: String {
        switch viewModel.state {
        case .idle:
            return "Idle"
        case .loading:
            return "Loading"
        case .ready:
            return "Ready"
        case .buffering:
            return "Buffering"
        case .playing:
            return "Playing"
        case .paused:
            return "Paused"
        case .seeking:
            return "Seeking"
        case .retrying(let attempt):
            return "Retrying · Attempt \(attempt)"
        case .reconnecting:
            return "Reconnecting"
        case .completed:
            return "Finished"
        case .failed:
            return "Playback unavailable"
        }
    }

    private var playbackStatusIcon: String {
        switch viewModel.state {
        case .idle:
            return "clock"
        case .loading, .buffering, .seeking, .retrying, .reconnecting:
            return "arrow.triangle.2.circlepath"
        case .ready:
            return "checkmark.circle.fill"
        case .playing:
            return "play.fill"
        case .paused:
            return "pause.fill"
        case .completed:
            return "checkmark.circle.fill"
        case .failed:
            return "exclamationmark.triangle.fill"
        }
    }

    private func presentControls(automaticallyHide: Bool = true) {
        autoHideTask?.cancel()

        withAnimation(.easeOut(duration: reduceMotion ? 0.16 : theme.focus.animationDuration)) {
            controlsArePresented = true
        }

        if focusedTarget == nil {
            focusedTarget = .playPause
        }

        if automaticallyHide {
            scheduleAutoHide()
        }
    }

    private func scheduleAutoHide() {
        autoHideTask?.cancel()
        guard viewModel.isPlaying else { return }

        autoHideTask = Task {
            try? await Task.sleep(for: .seconds(4))
            guard !Task.isCancelled else { return }

            focusedTarget = nil
            withAnimation(
                .easeOut(duration: reduceMotion ? 0.16 : theme.focus.animationDuration)
            ) {
                controlsArePresented = false
            }
        }
    }
}
