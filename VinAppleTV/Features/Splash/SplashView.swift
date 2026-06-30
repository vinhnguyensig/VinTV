//
//  SplashView.swift
//  VinAppleTV
//
//  Created by Vinh Nguyen on 25/6/26.
//

import SwiftUI
import VPAppTheme

struct SplashView: View {
    @Environment(\.vpTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isPresented = false

    var body: some View {
        ZStack {
            theme.colors.background
                .ignoresSafeArea()

            RadialGradient(
                colors: [
                    theme.colors.accent.opacity(0.24),
                    theme.colors.background.opacity(0)
                ],
                center: .center,
                startRadius: 40,
                endRadius: 620
            )
            .ignoresSafeArea()

            VStack(spacing: theme.spacing.large) {
                Image(systemName: "play.rectangle.fill")
                    .font(theme.fonts.display)
                    .foregroundStyle(theme.colors.accent)
                    .shadow(
                        color: theme.colors.accent.opacity(theme.focus.shadowOpacity),
                        radius: theme.focus.shadowRadius
                    )

                Text("VinAppleTV")
                    .font(theme.fonts.display)
                    .foregroundStyle(theme.colors.primaryText)

                VPSkeletonSurface(cornerRadius: theme.radii.pill)
                    .frame(width: 220, height: 8)
                    .accessibilityLabel("Loading VinAppleTV")
            }
            .scaleEffect(isPresented || reduceMotion ? theme.focus.unfocusedScale : 0.96)
            .opacity(isPresented ? 1 : 0)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("VinAppleTV, loading")
        }
        .onAppear {
            withAnimation(.easeOut(duration: theme.focus.animationDuration)) {
                isPresented = true
            }
        }
    }
}

#Preview {
    SplashView()
        .vpTheme(VPTheme())
}
