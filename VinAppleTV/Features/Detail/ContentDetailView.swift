//
//  ContentDetailView.swift
//  VinAppleTV
//
//  Created by Vinh Nguyen on 29/6/26.
//

import SwiftUI
import TVDomain
import VPAppTheme

private enum DetailFocusTarget: Hashable {
    case play
    case startOver
    case favorite
    case retry
}

struct ContentDetailView: View {
    @Environment(\.vpTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var viewModel: ContentDetailViewModel
    @FocusState private var focusedTarget: DetailFocusTarget?
    @State private var playbackRequest: ContentDetailViewModel.PlaybackRequest?
    @State private var isShowingPlayer = false
    @State private var presentationStage = 0
    private let makePlayerViewModel: (ContentDetailViewModel.PlaybackRequest) -> PlayerViewModel

    init(
        viewModel: ContentDetailViewModel,
        makePlayerViewModel: @escaping (ContentDetailViewModel.PlaybackRequest) -> PlayerViewModel
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.makePlayerViewModel = makePlayerViewModel
    }

    var body: some View {
        ZStack {
            dynamicBackground

            switch viewModel.loadState {
            case .idle, .loading:
                detailLoadingView
                    .transition(.opacity)
            case .loaded:
                if let content = viewModel.content {
                    detail(content)
                        .transition(.opacity)
                }
            case .notFound:
                unavailable(
                    title: "Content Not Found",
                    message: "This title is no longer available."
                )
                .transition(.opacity)
            case .failed(let message):
                unavailable(title: "Unable to Load Details", message: message)
                    .transition(.opacity)
            }
        }
        .animation(
            reduceMotion ? nil : .easeInOut(duration: 0.28),
            value: viewModel.loadState
        )
        .navigationDestination(isPresented: $isShowingPlayer) {
            if let playbackRequest {
                PlayerView(viewModel: makePlayerViewModel(playbackRequest))
            }
        }
        .onAppear {
            Task {
                await viewModel.load()
                await focusInitialControl()
                presentLoadedContent()
            }
        }
    }

    private var detailLoadingView: some View {
        HStack(alignment: .center, spacing: theme.spacing.xxLarge) {
            VPSkeletonSurface(cornerRadius: theme.radii.large)
                .frame(width: 510, height: 680)

            VStack(alignment: .leading, spacing: theme.spacing.medium) {
                VPSkeletonSurface(cornerRadius: theme.radii.small)
                    .frame(width: 620, height: 60)
                VPSkeletonSurface(cornerRadius: theme.radii.small)
                    .frame(width: 360, height: 34)
                VPSkeletonSurface(cornerRadius: theme.radii.small)
                    .frame(width: 820, height: 28)
                VPSkeletonSurface(cornerRadius: theme.radii.small)
                    .frame(width: 760, height: 28)
                VPSkeletonSurface(cornerRadius: theme.radii.small)
                    .frame(width: 640, height: 28)

                HStack(spacing: theme.spacing.medium) {
                    VPSkeletonSurface(cornerRadius: theme.radii.pill)
                        .frame(width: 180, height: 64)
                    VPSkeletonSurface(cornerRadius: theme.radii.pill)
                        .frame(width: 240, height: 64)
                }
                .padding(.top, theme.spacing.xSmall)
            }
            .padding(theme.spacing.xLarge)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, theme.layout.horizontalScreenInset)
        .padding(.vertical, theme.layout.verticalScreenInset)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Loading content details")
    }

    private var dynamicBackground: some View {
        GeometryReader { proxy in
            ZStack {
                theme.colors.background

                if let content = viewModel.content {
                    AsyncImage(url: URL(string: content.artworkReference)) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        LinearGradient(
                            colors: [
                                theme.colors.placeholderStart,
                                theme.colors.placeholderEnd
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    }
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()
                    .blur(radius: 22)
                    .scaleEffect(1.04)
                    .opacity(0.42)
                    .accessibilityHidden(true)
                }

                ZStack {
                    LinearGradient(
                        colors: [
                            theme.colors.background.opacity(0.28),
                            theme.colors.background.opacity(0.76),
                            theme.colors.background
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    LinearGradient(
                        colors: [
                            theme.colors.background.opacity(0.94),
                            theme.colors.background.opacity(0.4),
                            theme.colors.background.opacity(0.72)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                }
                .accessibilityHidden(true)
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }

    private func detail(_ content: Content) -> some View {
        ScrollView {
            HStack(alignment: .center, spacing: theme.spacing.xLarge) {
                artwork(content)

                VStack(alignment: .leading, spacing: theme.spacing.small) {
                    if viewModel.isFavorite {
                        FavoriteBadge()
                    }

                    Text(content.title)
                        .font(theme.fonts.display)
                        .foregroundStyle(theme.colors.primaryText)
                        .lineLimit(2)
                        .minimumScaleFactor(0.72)
                        .accessibilitySortPriority(5)

                    metadata(content)
                        .accessibilitySortPriority(4)

                    Text(content.description)
                        .font(theme.fonts.body)
                        .foregroundStyle(theme.colors.secondaryText)
                        .lineLimit(6)
                        .lineSpacing(5)
                        .frame(maxWidth: 760, alignment: .leading)
                        .accessibilitySortPriority(3)

                    actionButtons
                        .padding(.top, theme.spacing.small)
                        .accessibilitySortPriority(2)
                }
                .frame(maxWidth: 900, alignment: .leading)
                .padding(.vertical, theme.spacing.xLarge)
                .opacity(presentationStage >= 2 ? 1 : 0)
                .offset(y: presentationStage >= 2 || reduceMotion ? 0 : 18)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, theme.layout.horizontalScreenInset)
            .padding(.top, theme.spacing.large)
            .padding(.bottom, theme.layout.verticalScreenInset)
        }
        .scrollIndicators(.hidden)
        .navigationTitle(content.title)
    }

    private func metadata(_ content: Content) -> some View {
        HStack(spacing: theme.spacing.xSmall) {
            Text(content.genre)

            Circle()
                .frame(width: 5, height: 5)
                .accessibilityHidden(true)

            Text(content.durationDisplayText)
        }
        .font(theme.fonts.metadata)
        .foregroundStyle(theme.colors.secondaryText)
        .accessibilityElement(children: .combine)
    }

    private func artwork(_ content: Content) -> some View {
        AsyncImage(url: URL(string: content.artworkReference)) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
        } placeholder: {
            RoundedRectangle(cornerRadius: theme.radii.large)
                .fill(
                    LinearGradient(
                        colors: [
                            theme.colors.placeholderStart,
                            theme.colors.placeholderEnd
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    VStack(spacing: theme.spacing.medium) {
                        Image(systemName: "play.rectangle.fill")
                            .font(.system(size: 120, weight: .bold))
                        Text(content.title)
                            .font(theme.fonts.screenTitle)
                            .multilineTextAlignment(.center)
                            .lineLimit(3)
                    }
                    .foregroundStyle(theme.colors.primaryText)
                    .padding(theme.spacing.large)
                }
        }
        .frame(width: 510, height: 680)
        .clipShape(RoundedRectangle(cornerRadius: theme.radii.large))
        .accessibilityLabel("Poster for \(content.title)")
        .shadow(color: .black.opacity(0.65), radius: 34, y: 20)
        .overlay {
            RoundedRectangle(cornerRadius: theme.radii.large)
                .stroke(theme.colors.primaryText.opacity(0.14), lineWidth: 1)
        }
        .opacity(presentationStage >= 1 ? 1 : 0)
        .scaleEffect(presentationStage >= 1 || reduceMotion ? 1 : 0.97)
    }

    private var actionButtons: some View {
        HStack(spacing: theme.spacing.medium) {
            Button {
                launch(viewModel.play())
            } label: {
                Label(
                    viewModel.hasCompletedPlayback
                        ? "Start Over"
                        : (viewModel.resumeButtonTitle ?? "Play"),
                    systemImage: viewModel.hasCompletedPlayback
                        ? "arrow.counterclockwise"
                        : "play.fill"
                )
                .frame(minWidth: 210)
            }
            .buttonStyle(.borderedProminent)
            .tint(theme.colors.accent)
            .controlSize(.large)
            .focused($focusedTarget, equals: .play)
            .accessibilityHint(
                viewModel.resumablePositionSeconds == nil
                    ? "Starts playback"
                    : "Continues playback from your saved position"
            )

            if viewModel.resumablePositionSeconds != nil {
                Button {
                    launch(viewModel.startOver())
                } label: {
                    Label("Start Over", systemImage: "arrow.counterclockwise")
                        .frame(minWidth: 180)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .focused($focusedTarget, equals: .startOver)
                .accessibilityHint("Plays this title from the beginning")
            }

            Button {
                viewModel.toggleFavorite()
            } label: {
                Label(
                    viewModel.isFavorite ? "Remove Favorite" : "Add Favorite",
                    systemImage: viewModel.isFavorite ? "heart.slash" : "heart"
                )
                .frame(minWidth: 190)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .focused($focusedTarget, equals: .favorite)
            .accessibilityHint(
                viewModel.isFavorite
                    ? "Removes this title from Favorites"
                    : "Adds this title to Favorites"
            )
        }
        .font(theme.fonts.button)
        .focusSection()
    }

    private func unavailable(title: String, message: String) -> some View {
        ContentUnavailableView {
            Label(title, systemImage: "exclamationmark.triangle")
        } description: {
            Text(message)
        } actions: {
            Button("Try Again") {
                Task {
                    await viewModel.load()
                    await focusInitialControl()
                }
            }
            .focused($focusedTarget, equals: .retry)
        }
        .foregroundStyle(theme.colors.primaryText)
    }

    private func launch(_ request: ContentDetailViewModel.PlaybackRequest?) {
        guard let request else { return }
        playbackRequest = request
        isShowingPlayer = true
    }

    private func focusInitialControl() async {
        await Task.yield()
        focusedTarget = viewModel.loadState == .loaded ? .play : .retry
    }

    private func presentLoadedContent() {
        guard viewModel.loadState == .loaded else { return }

        if reduceMotion {
            presentationStage = 2
            return
        }

        withAnimation(.easeOut(duration: theme.focus.animationDuration)) {
            presentationStage = 1
        }

        Task {
            try? await Task.sleep(for: .milliseconds(90))
            withAnimation(.easeOut(duration: theme.focus.animationDuration)) {
                presentationStage = 2
            }
        }
    }
}
