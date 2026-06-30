//
//  SearchView.swift
//  VinAppleTV
//
//  Created by Vinh Nguyen on 29/6/26.
//

import SwiftUI
import TVDomain
import VPAppTheme

private enum SearchFocusTarget: Hashable {
    case result(String)
}

struct SearchView: View {
    @Environment(\.vpTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ObservedObject var viewModel: SearchViewModel
    @State private var favoriteContentIDs: Set<String>
    let favoriteService: FavoriteStateServicing
    @FocusState private var focusedTarget: SearchFocusTarget?
    @State private var rememberedResultID: String?
    let makeContentDetailViewModel: @MainActor (String) -> ContentDetailViewModel
    let makePlayerViewModel:
        @MainActor (ContentDetailViewModel.PlaybackRequest) -> PlayerViewModel

    init(
        viewModel: SearchViewModel,
        favoriteService: FavoriteStateServicing,
        makeContentDetailViewModel: @escaping @MainActor (String) -> ContentDetailViewModel,
        makePlayerViewModel:
            @escaping @MainActor (ContentDetailViewModel.PlaybackRequest) -> PlayerViewModel
    ) {
        self.viewModel = viewModel
        self.favoriteService = favoriteService
        _favoriteContentIDs = State(initialValue: favoriteService.favoriteContentIDs)
        self.makeContentDetailViewModel = makeContentDetailViewModel
        self.makePlayerViewModel = makePlayerViewModel
    }

    var body: some View {
        Group {
            switch viewModel.state {
            case .emptyQuery:
                ContentUnavailableView(
                    "Search VinAppleTV",
                    systemImage: "magnifyingglass",
                    description: Text("Enter a title to browse the local catalog.")
                )
            case .loading:
                loadingGrid
                    .transition(.opacity)
            case .results:
                resultsGrid
                    .transition(.opacity)
            case .noResults:
                ContentUnavailableView.search(text: viewModel.query)
            case .failed(let message):
                ContentUnavailableView(
                    "Unable to Search",
                    systemImage: "exclamationmark.triangle",
                    description: Text(message)
                )
            }
        }
        .animation(
            reduceMotion ? nil : .easeInOut(duration: 0.28),
            value: viewModel.state
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .vpThemedBackground()
        .navigationTitle("Search")
        .searchable(
            text: $viewModel.query,
            placement: .automatic,
            prompt: "Search titles"
        )
        .onChange(of: focusedTarget) { _, target in
            if case let .result(id)? = target {
                rememberedResultID = id
            }
        }
        .onChange(of: viewModel.results.map(\.id)) { _, ids in
            guard let firstID = ids.first else { return }
            let targetID = rememberedResultID.flatMap { ids.contains($0) ? $0 : nil } ?? firstID
            focusedTarget = .result(targetID)
        }
        .onReceive(favoriteService.favoriteContentIDsPublisher) {
            favoriteContentIDs = $0
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
        .accessibilityLabel("Loading Search results")
    }

    private var resultsGrid: some View {
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
                ForEach(viewModel.results) { item in
                    NavigationLink {
                        ContentDetailView(
                            viewModel: makeContentDetailViewModel(item.id),
                            makePlayerViewModel: makePlayerViewModel
                        )
                    } label: {
                        ContentPosterCard(
                            content: item,
                            isFavorite: favoriteContentIDs.contains(item.id)
                        )
                    }
                    .buttonStyle(.plain)
                    .focused($focusedTarget, equals: .result(item.id))
                    .accessibilityHint("Opens details for \(item.title)")
                }
            }
            .padding(.horizontal, theme.layout.horizontalScreenInset)
            .padding(.vertical, theme.layout.verticalScreenInset)
        }
    }

    private var focusedCardSpacing: CGFloat {
        max(theme.layout.gridSpacing, theme.layout.focusedCardClearance * 2)
    }
}
