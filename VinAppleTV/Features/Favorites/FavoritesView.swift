//
//  FavoritesView.swift
//  VinAppleTV
//
//  Created by Vinh Nguyen on 27/6/26.
//

import SwiftUI
import TVDomain
import VPAppTheme

private enum FavoritesFocusTarget: Hashable {
    case content(String)
}

struct FavoritesView: View {
    @Environment(\.vpTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ObservedObject var viewModel: FavoritesViewModel
    @ObservedObject var favoriteService: LocalFavoriteStateService
    @FocusState private var focusedTarget: FavoritesFocusTarget?
    @State private var rememberedContentID: String?
    let makeContentDetailViewModel: @MainActor (String) -> ContentDetailViewModel
    let makePlayerViewModel:
        @MainActor (ContentDetailViewModel.PlaybackRequest) -> PlayerViewModel

    var body: some View {
        Group {
            switch viewModel.loadState {
            case .idle, .loading:
                loadingGrid
                    .transition(.opacity)
            case .loaded where viewModel.content.isEmpty:
                ContentUnavailableView(
                    "No Favorites Yet",
                    systemImage: "heart",
                    description: Text("Add titles from Home or a content detail screen.")
                )
            case .loaded:
                ScrollView {
                    LazyVGrid(
                        columns: [
                            GridItem(
                                .adaptive(minimum: theme.layout.cardWidth),
                                spacing: focusedCardSpacing
                            )
                        ],
                        spacing: focusedCardSpacing
                    ) {
                        ForEach(viewModel.content) { item in
                            NavigationLink {
                                ContentDetailView(
                                    viewModel: makeContentDetailViewModel(item.id),
                                    makePlayerViewModel: makePlayerViewModel
                                )
                            } label: {
                                ContentPosterCard(
                                    content: item,
                                    isFavorite: favoriteService.isFavorite(contentID: item.id)
                                )
                            }
                            .buttonStyle(.plain)
                            .focused($focusedTarget, equals: .content(item.id))
                        }
                    }
                    .padding(.horizontal, theme.layout.horizontalScreenInset)
                    .padding(.vertical, theme.layout.verticalScreenInset)
                }
                .transition(.opacity)
            case .failed(let message):
                ContentUnavailableView(
                    "Unable to Load Favorites",
                    systemImage: "exclamationmark.triangle",
                    description: Text(message)
                )
            }
        }
        .animation(
            reduceMotion ? nil : .easeInOut(duration: 0.28),
            value: viewModel.loadState
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .vpThemedBackground()
        .navigationTitle("Favorites")
        .task { await viewModel.load() }
        .onChange(of: focusedTarget) { _, target in
            if case let .content(id)? = target {
                rememberedContentID = id
            }
        }
        .onChange(of: viewModel.content.map(\.id)) { _, ids in
            guard let firstID = ids.first else { return }
            let targetID = rememberedContentID.flatMap { ids.contains($0) ? $0 : nil } ?? firstID
            focusedTarget = .content(targetID)
        }
        .onAppear {
            guard let targetID = rememberedContentID ?? viewModel.content.first?.id else { return }
            focusedTarget = .content(targetID)
        }
    }

    private var loadingGrid: some View {
        ScrollView {
            LazyVGrid(
                columns: [
                    GridItem(
                        .adaptive(minimum: theme.layout.cardWidth),
                        spacing: focusedCardSpacing
                    )
                ],
                spacing: focusedCardSpacing
            ) {
                ForEach(0..<10, id: \.self) { _ in
                    PosterLoadingView()
                }
            }
            .padding(.horizontal, theme.layout.horizontalScreenInset)
            .padding(.vertical, theme.layout.verticalScreenInset)
        }
        .scrollDisabled(true)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Loading Favorites")
    }

    private var focusedCardSpacing: CGFloat {
        max(theme.layout.gridSpacing, theme.layout.focusedCardClearance * 2)
    }
}
