//
//  HomeView.swift
//  VinAppleTV
//
//  Created by Vinh Nguyen on 25/6/26.
//

import SwiftUI
import TVDomain
import VPAppTheme

private enum HomeFocusTarget: Hashable {
    case heroPlay
    case heroMoreInformation
    case content(String)
    case retry
}

private enum HomeScrollTarget: Hashable {
    case hero
}

struct HomeView: View {
    @Environment(\.vpTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.resetFocus) private var resetFocus
    @StateObject private var viewModel: HomeViewModel
    @StateObject private var favoritesViewModel: FavoritesViewModel
    @StateObject private var searchViewModel: SearchViewModel
    @State private var favoriteContentIDs: Set<String>
    @FocusState private var focusedTarget: HomeFocusTarget?
    @State private var rememberedTarget: HomeFocusTarget = .heroPlay
    @State private var isHeroPresented = false
    @State private var hasAppliedInitialHeroFocus = false
    @Namespace private var homeFocusNamespace
    private let favoriteService: FavoriteStateServicing
    private let makeContentDetailViewModel: @MainActor (String) -> ContentDetailViewModel
    private let makePlayerViewModel:
        @MainActor (ContentDetailViewModel.PlaybackRequest) -> PlayerViewModel

    init(
        viewModel: HomeViewModel,
        favoritesViewModel: FavoritesViewModel,
        searchViewModel: SearchViewModel,
        favoriteService: LocalFavoriteStateService,
        makeContentDetailViewModel: @escaping @MainActor (String) -> ContentDetailViewModel,
        makePlayerViewModel:
            @escaping @MainActor (ContentDetailViewModel.PlaybackRequest) -> PlayerViewModel
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        _favoritesViewModel = StateObject(wrappedValue: favoritesViewModel)
        _searchViewModel = StateObject(wrappedValue: searchViewModel)
        _favoriteContentIDs = State(initialValue: favoriteService.favoriteContentIDs)
        self.favoriteService = favoriteService
        self.makeContentDetailViewModel = makeContentDetailViewModel
        self.makePlayerViewModel = makePlayerViewModel
    }

    var body: some View {
        ZStack {
            dynamicBackground

            Group {
                switch viewModel.loadState {
                case .idle, .loading:
                    HomeLoadingView()
                        .transition(.opacity)
                case .loaded:
                    content
                        .transition(.opacity)
                case .failed(let message):
                    errorView(message)
                        .transition(.opacity)
                }
            }
        }
        .animation(
            reduceMotion ? nil : .easeInOut(duration: 0.28),
            value: viewModel.loadState
        )
        .task {
            await viewModel.load()
        }
        .onAppear {
            guard viewModel.loadState == .loaded else { return }
            focusedTarget = rememberedTarget
        }
        .onChange(of: focusedTarget) { _, newValue in
            if let newValue {
                rememberedTarget = newValue
            }
        }
        .onReceive(favoriteService.favoriteContentIDsPublisher) {
            favoriteContentIDs = $0
        }
        .focusScope(homeFocusNamespace)
    }

    private var dynamicBackground: some View {
        ZStack {
            theme.colors.background.ignoresSafeArea()
            
            LinearGradient(
                colors: [
                    theme.colors.placeholderStart.opacity(0.4),
                    theme.colors.background
                ],
                startPoint: .topLeading,
                endPoint: .bottom
            )
            .blur(radius: 80)
            .ignoresSafeArea()
            .opacity(focusedTarget != nil ? 1 : 0)
            .animation(
                reduceMotion ? nil : .easeInOut(duration: 0.36),
                value: focusedTarget
            )
        }
    }

    private var content: some View {
        TabView {
            NavigationStack {
                ScrollViewReader { scrollProxy in
                    ScrollView(.vertical) {
                        VStack(alignment: .leading, spacing: theme.layout.sectionSpacing) {
                            heroSection
                                .id(HomeScrollTarget.hero)
                                .padding(
                                    .bottom,
                                    theme.layout.heroBottomSpacing - theme.layout.sectionSpacing
                                )

                            if !viewModel.continueWatchingContent.isEmpty {
                                ContentRail(
                                    title: "Continue Watching",
                                    content: viewModel.continueWatchingContent,
                                    favoriteContentIDs: favoriteContentIDs,
                                    playbackProgressByContentID: viewModel.playbackProgressByContentID,
                                    focusedTarget: $focusedTarget,
                                    onSelectContent: viewModel.selectContent,
                                    makeContentDetailViewModel: makeContentDetailViewModel,
                                    makePlayerViewModel: makePlayerViewModel
                                )
                                .padding(.horizontal, theme.layout.horizontalScreenInset)
                            }

                            ContentRail(
                                title: "Trending",
                                content: viewModel.trendingContent,
                                favoriteContentIDs: favoriteContentIDs,
                                playbackProgressByContentID: [:],
                                focusedTarget: $focusedTarget,
                                onSelectContent: viewModel.selectContent,
                                makeContentDetailViewModel: makeContentDetailViewModel,
                                makePlayerViewModel: makePlayerViewModel
                            )
                            .padding(.horizontal, theme.layout.horizontalScreenInset)

                            ContentRail(
                                title: "Recommended",
                                content: viewModel.recommendedContent,
                                favoriteContentIDs: favoriteContentIDs,
                                playbackProgressByContentID: [:],
                                focusedTarget: $focusedTarget,
                                onSelectContent: viewModel.selectContent,
                                makeContentDetailViewModel: makeContentDetailViewModel,
                                makePlayerViewModel: makePlayerViewModel
                            )
                            .padding(.horizontal, theme.layout.horizontalScreenInset)
                        }
                        .padding(.top, 0)
                        .padding(.bottom, theme.spacing.xxLarge)
                    }
                    .scrollIndicators(.hidden)
                    .background(theme.colors.background)
                    .onAppear {
                        requestInitialHeroFocusIfNeeded(scrollProxy: scrollProxy)
                    }
                }
            }
            .defaultFocus($focusedTarget, .heroPlay)
            .tabItem { Label("Home", systemImage: "house.fill") }

            NavigationStack {
                FavoritesView(
                    viewModel: favoritesViewModel,
                    favoriteService: favoriteService,
                    makeContentDetailViewModel: makeContentDetailViewModel,
                    makePlayerViewModel: makePlayerViewModel
                )
            }
            .tabItem { Label("Favorites", systemImage: "heart.fill") }

            NavigationStack {
                SearchView(
                    viewModel: searchViewModel,
                    favoriteService: favoriteService,
                    makeContentDetailViewModel: makeContentDetailViewModel,
                    makePlayerViewModel: makePlayerViewModel
                )
            }
            .tabItem { Label("Search", systemImage: "magnifyingglass") }
        }
    }

    private var heroSection: some View {
        let featured = viewModel.featuredContent.first ?? viewModel.trendingContent.first

        return Group {
            if let featured {
                HeroBanner(
                    content: featured,
                    isFavorite: favoriteContentIDs.contains(featured.id),
                    focusedTarget: $focusedTarget,
                    focusNamespace: homeFocusNamespace,
                    onSelectContent: viewModel.selectContent,
                    makeContentDetailViewModel: makeContentDetailViewModel,
                    makePlayerViewModel: makePlayerViewModel
                )
            } else {
                ContentUnavailableView(
                    "No Featured Content",
                    systemImage: "play.tv",
                    description: Text("Featured titles will appear here.")
                )
                .frame(height: 400)
            }
        }
        .focusSection()
        .opacity(isHeroPresented ? 1 : 0)
        .scaleEffect(isHeroPresented || reduceMotion ? 1 : 0.985)
        .onAppear {
            withAnimation(.easeOut(duration: theme.focus.animationDuration)) {
                isHeroPresented = true
            }
        }
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: theme.spacing.medium) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 64, weight: .semibold))
                .foregroundStyle(theme.colors.error)

            Text("Unable to load content")
                .font(theme.fonts.sectionTitle)
                .foregroundStyle(theme.colors.primaryText)

            Text(message)
                .font(theme.fonts.body)
                .foregroundStyle(theme.colors.secondaryText)

            Button("Try Again") {
                Task {
                    await viewModel.load()
                    await focusFeaturedContent()
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(theme.colors.accent)
            .focused($focusedTarget, equals: .retry)
        }
    }

    private func focusFeaturedContent() async {
        guard viewModel.loadState == .loaded else {
            focusedTarget = .retry
            return
        }

        await Task.yield()
        focusedTarget = rememberedTarget
        if rememberedTarget == .heroPlay {
            resetFocus(in: homeFocusNamespace)
        }
    }

    private func requestInitialHeroFocusIfNeeded(scrollProxy: ScrollViewProxy) {
        guard !hasAppliedInitialHeroFocus else { return }
        hasAppliedInitialHeroFocus = true

        Task { @MainActor in
            await Task.yield()
            await focusFeaturedContent()
            try? await Task.sleep(nanoseconds: 50_000_000)
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                scrollProxy.scrollTo(HomeScrollTarget.hero, anchor: .top)
            }
        }
    }
}

private struct HomeLoadingView: View {
    @Environment(\.vpTheme) private var theme

    var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: theme.layout.sectionSpacing) {
                VStack(alignment: .leading, spacing: theme.spacing.small) {
                    VPSkeletonSurface(cornerRadius: theme.radii.small)
                        .frame(width: 130, height: 20)
                    VPSkeletonSurface(cornerRadius: theme.radii.medium)
                        .frame(width: 620, height: 84)
                    VPSkeletonSurface(cornerRadius: theme.radii.small)
                        .frame(width: 760, height: 28)
                    HStack(spacing: theme.spacing.medium) {
                        VPSkeletonSurface(cornerRadius: theme.radii.pill)
                            .frame(width: 150, height: 62)
                        VPSkeletonSurface(cornerRadius: theme.radii.pill)
                            .frame(width: 250, height: 62)
                    }
                    .padding(.top, theme.spacing.xSmall)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .padding(.horizontal, theme.layout.horizontalScreenInset)
                .frame(height: theme.layout.heroHeight)

                ForEach(0..<2, id: \.self) { _ in
                    VStack(alignment: .leading, spacing: theme.spacing.small) {
                        VPSkeletonSurface(cornerRadius: theme.radii.small)
                            .frame(width: 230, height: 34)

                        HStack(spacing: theme.layout.railSpacing) {
                            ForEach(0..<5, id: \.self) { _ in
                                PosterLoadingView()
                            }
                        }
                    }
                    .padding(.horizontal, theme.layout.horizontalScreenInset)
                }
            }
            .padding(.bottom, theme.spacing.xxLarge)
        }
        .scrollDisabled(true)
        .scrollIndicators(.hidden)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Loading Home")
    }
}

struct PosterLoadingView: View {
    @Environment(\.vpTheme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xSmall) {
            VPSkeletonSurface(cornerRadius: theme.radii.small)
                .frame(width: theme.layout.cardWidth, height: theme.layout.cardHeight)
            VPSkeletonSurface(cornerRadius: theme.radii.small)
                .frame(width: theme.layout.cardWidth * 0.72, height: 26)
            VPSkeletonSurface(cornerRadius: theme.radii.small)
                .frame(width: theme.layout.cardWidth * 0.46, height: 20)
        }
        .frame(width: theme.layout.cardWidth, alignment: .leading)
    }
}

private struct ContentRail: View {
    @Environment(\.vpTheme) private var theme

    let title: String
    let content: [Content]
    let favoriteContentIDs: Set<String>
    let playbackProgressByContentID: [String: PlaybackProgress]
    let focusedTarget: FocusState<HomeFocusTarget?>.Binding
    let onSelectContent: (String) -> Void
    let makeContentDetailViewModel: @MainActor (String) -> ContentDetailViewModel
    let makePlayerViewModel:
        @MainActor (ContentDetailViewModel.PlaybackRequest) -> PlayerViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.small) {
            Text(title)
                .font(theme.fonts.sectionTitle)
                .foregroundStyle(theme.colors.primaryText)

            ScrollView(.horizontal) {
                LazyHStack(spacing: focusedCardSpacing) {
                    ForEach(content) { item in
                        NavigationLink {
                            ContentDetailView(
                                viewModel: makeContentDetailViewModel(item.id),
                                makePlayerViewModel: makePlayerViewModel
                            )
                            .onAppear {
                                onSelectContent(item.id)
                            }
                        } label: {
                            ContentPosterCard(
                                content: item,
                                isFavorite: favoriteContentIDs.contains(item.id),
                                playbackProgress: playbackProgressByContentID[item.id]
                            )
                        }
                        .buttonStyle(.plain)
                        .focused(focusedTarget, equals: .content(item.id))
                        .accessibilityHint("Opens details for \(item.title)")
                    }
                    .padding(.vertical, theme.spacing.small)
                }
            }
            .scrollClipDisabled()
            .scrollIndicators(.hidden)
        }
        .focusSection()
    }

    private var focusedCardSpacing: CGFloat {
        max(theme.layout.railSpacing, theme.layout.focusedCardClearance * 2)
    }
}

struct ContentPosterCard: View {
    @Environment(\.vpTheme) private var theme
    @Environment(\.isFocused) private var isFocused

    let content: Content
    let isFavorite: Bool
    let playbackProgress: PlaybackProgress?

    init(
        content: Content,
        isFavorite: Bool,
        playbackProgress: PlaybackProgress? = nil
    ) {
        self.content = content
        self.isFavorite = isFavorite
        self.playbackProgress = playbackProgress
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            AsyncImage(url: URL(string: content.artworkReference)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                RoundedRectangle(cornerRadius: theme.radii.small)
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
                    .overlay(alignment: .bottomLeading) {
                        Image(systemName: "play.tv")
                            .font(.system(size: 42, weight: .semibold))
                            .foregroundStyle(theme.colors.primaryText)
                            .padding(theme.spacing.medium)
                    }
            }
            .frame(width: theme.layout.cardWidth, height: theme.layout.cardHeight)
            .clipShape(RoundedRectangle(cornerRadius: theme.radii.small))
            .overlay {
                LinearGradient(
                    colors: [.clear, theme.colors.background.opacity(0.5)],
                    startPoint: .center,
                    endPoint: .bottom
                )
                .clipShape(RoundedRectangle(cornerRadius: theme.radii.small))
            }
            .overlay(alignment: .topTrailing) {
                if isFavorite {
                    FavoriteBadge()
                        .padding(theme.spacing.xSmall)
                }
            }
            .overlay(alignment: .bottom) {
                if let progressFraction {
                    ProgressView(value: progressFraction)
                        .tint(theme.colors.accent)
                        .padding(.horizontal, theme.spacing.xSmall)
                        .padding(.bottom, theme.spacing.xSmall)
                }
            }
            .shadow(color: .black.opacity(0.45), radius: 18, y: 12)

            Text(content.title)
                .font(theme.fonts.cardTitle)
                .foregroundStyle(theme.colors.primaryText)
                .lineLimit(2)
                .padding(.top, theme.layout.artworkTitleSpacing)

            Text("\(content.genre) • \(durationText)")
                .font(theme.fonts.metadata)
                .foregroundStyle(theme.colors.secondaryText)
                .lineLimit(1)
        }
        .frame(width: theme.layout.cardWidth, alignment: .topLeading)
        .vpFocusCard(isFocused: isFocused, cornerRadius: theme.radii.small)
    }

    private var durationText: String {
        content.durationDisplayText
    }

    private var progressFraction: Double? {
        guard let playbackProgress,
              playbackProgress.durationSeconds > 0,
              playbackProgress.positionSeconds > 0,
              playbackProgress.positionSeconds < playbackProgress.durationSeconds else {
            return nil
        }
        return playbackProgress.positionSeconds / playbackProgress.durationSeconds
    }
}

private struct HeroBanner: View {
    @Environment(\.vpTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.isFocused) private var isFocused

    let content: Content
    let isFavorite: Bool
    let focusedTarget: FocusState<HomeFocusTarget?>.Binding
    let focusNamespace: Namespace.ID
    let onSelectContent: (String) -> Void
    let makeContentDetailViewModel: @MainActor (String) -> ContentDetailViewModel
    let makePlayerViewModel:
        @MainActor (ContentDetailViewModel.PlaybackRequest) -> PlayerViewModel

    var body: some View {
        ZStack(alignment: .leading) {
            AsyncImage(url: URL(string: content.artworkReference)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(theme.colors.placeholderStart)
            }
            .scaleEffect(isFocused && !reduceMotion ? 1.015 : 1)
            .overlay {
                ZStack {
                    LinearGradient(
                        colors: [
                            theme.colors.background.opacity(0.94),
                            theme.colors.background.opacity(0.35),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    LinearGradient(
                        colors: [
                            .clear,
                            theme.colors.background.opacity(0.18),
                            theme.colors.background
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
            }
            .clipped()

            Image(systemName: "play.rectangle.fill")
                .font(.system(size: 300, weight: .bold))
                .foregroundStyle(theme.colors.primaryText.opacity(0.08))
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.trailing, theme.layout.horizontalScreenInset)
                .offset(y: -50)

            VStack(alignment: .leading, spacing: theme.spacing.small) {
                Text("FEATURED")
                    .font(theme.fonts.badge)
                    .tracking(4)
                    .foregroundStyle(theme.colors.accent)

                Text(content.title)
                    .font(theme.fonts.display)
                    .foregroundStyle(theme.colors.primaryText)
                    .lineLimit(1)

                Text(content.description)
                    .font(theme.fonts.body)
                    .foregroundStyle(theme.colors.secondaryText)
                    .lineLimit(2)
                    .frame(maxWidth: 760, alignment: .leading)

                HStack(spacing: theme.spacing.medium) {
                    NavigationLink {
                        PlayerView(
                            viewModel: makePlayerViewModel(
                                ContentDetailViewModel.PlaybackRequest(
                                    content: content,
                                    startSeconds: 0
                                )
                            )
                        )
                        .onAppear { onSelectContent(content.id) }
                    } label: {
                        Label("Play", systemImage: "play.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(theme.colors.accent)
                    .focused(focusedTarget, equals: .heroPlay)
                    .prefersDefaultFocus(true, in: focusNamespace)

                    NavigationLink {
                        ContentDetailView(
                            viewModel: makeContentDetailViewModel(content.id),
                            makePlayerViewModel: makePlayerViewModel
                        )
                        .onAppear { onSelectContent(content.id) }
                    } label: {
                        Label("More Information", systemImage: "info.circle.fill")
                    }
                    .buttonStyle(.bordered)
                    .focused(focusedTarget, equals: .heroMoreInformation)
                }
                .font(theme.fonts.button)
                .padding(.top, theme.spacing.xSmall)
            }
            .padding(.horizontal, theme.layout.horizontalScreenInset)
            .padding(.vertical, theme.spacing.xLarge)
            .padding(.bottom, theme.layout.verticalScreenInset) // extra padding to clear gradient bottom
        }
        .frame(height: theme.layout.heroHeight)
        .overlay(alignment: .topTrailing) {
            if isFavorite {
                FavoriteBadge()
                    .padding(.trailing, theme.layout.horizontalScreenInset)
                    .padding(.top, theme.layout.verticalScreenInset)
            }
        }
        .animation(
            reduceMotion ? nil : .easeOut(duration: theme.focus.animationDuration),
            value: isFocused
        )
    }
}
