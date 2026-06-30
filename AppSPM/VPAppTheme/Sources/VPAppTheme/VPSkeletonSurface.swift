//
//  VPSkeletonSurface.swift
//  VinAppleTV
//
//  Created by Vinh Nguyen on 28/6/26.
//

import SwiftUI

/// A themed, non-interactive placeholder for content that has not loaded yet.
public struct VPSkeletonSurface: View {
    @Environment(\.vpTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let cornerRadius: CGFloat

    public init(cornerRadius: CGFloat) {
        self.cornerRadius = cornerRadius
    }

    public var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(theme.colors.elevatedBackground)
            .overlay {
                if !reduceMotion {
                    TimelineView(.animation(minimumInterval: 1 / 20)) { context in
                        shimmer(at: context.date)
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .accessibilityHidden(true)
    }

    private func shimmer(at date: Date) -> some View {
        let progress = date.timeIntervalSinceReferenceDate
            .truncatingRemainder(dividingBy: 1.8) / 1.8

        return GeometryReader { proxy in
            LinearGradient(
                colors: [
                    .clear,
                    theme.colors.secondaryText.opacity(0.12),
                    theme.colors.primaryText.opacity(0.18),
                    theme.colors.secondaryText.opacity(0.12),
                    .clear
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: proxy.size.width * 0.8)
            .offset(
                x: (proxy.size.width * 1.8 * CGFloat(progress))
                    - (proxy.size.width * 0.8)
            )
        }
        .allowsHitTesting(false)
    }
}
