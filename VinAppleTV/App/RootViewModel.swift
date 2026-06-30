//
//  RootViewModel.swift
//  VinAppleTV
//
//  Created by Vinh Nguyen on 26/6/26.
//

import Combine
import Foundation

@MainActor
final class RootViewModel: ObservableObject {
    enum Phase: Equatable {
        case splash
        case home
    }

    @Published private(set) var phase: Phase = .splash

    private let minimumSplashDuration: Duration
    private let sleep: @Sendable (Duration) async throws -> Void
    private var hasStarted = false

    init(
        minimumSplashDuration: Duration = .seconds(1.5),
        sleep: @escaping @Sendable (Duration) async throws -> Void = {
            try await Task.sleep(for: $0)
        }
    ) {
        self.minimumSplashDuration = minimumSplashDuration
        self.sleep = sleep
    }

    func start() async {
        guard !hasStarted else { return }
        hasStarted = true

        do {
            try await sleep(minimumSplashDuration)
        } catch is CancellationError {
            return
        } catch {
            // The splash delay is presentation-only, so it must never block Home.
        }

        phase = .home
    }
}
