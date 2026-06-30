//
//  RootView.swift
//  VinAppleTV
//
//  Created by Vinh Nguyen on 29/6/26.
//

import SwiftUI
import VPAppTheme

@MainActor
struct RootView<Container: AppDependencyProviding>: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let container: Container
    @StateObject private var viewModel: RootViewModel

    init(container: Container) {
        self.container = container
        _viewModel = StateObject(wrappedValue: RootViewModel())
    }

    init(container: Container, viewModel: RootViewModel) {
        self.container = container
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            switch viewModel.phase {
            case .splash:
                SplashView()
                    .transition(.opacity)
            case .home:
                HomeView(
                    viewModel: container.makeHomeViewModel(),
                    favoritesViewModel: container.makeFavoritesViewModel(),
                    searchViewModel: container.makeSearchViewModel(),
                    favoriteService: container.favoriteService,
                    makeContentDetailViewModel: container.makeContentDetailViewModel,
                    makePlayerViewModel: container.makePlayerViewModel
                )
                    .transition(.opacity)
            }
        }
        .animation(
            reduceMotion
                ? .easeOut(duration: container.theme.focus.animationDuration)
                : .easeInOut(duration: 0.36),
            value: viewModel.phase
        )
        .vpTheme(container.theme)
        .task {
            await viewModel.start()
        }
    }
}

#Preview {
    RootView(container: AppContainer())
}
