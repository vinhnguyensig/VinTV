//
//  FavoriteBadge.swift
//  VinAppleTV
//
//  Created by Vinh Nguyen on 30/6/26.
//

import SwiftUI
import VPAppTheme

struct FavoriteBadge: View {
    @Environment(\.vpTheme) private var theme

    var body: some View {
        Label("Favorite", systemImage: "heart.fill")
            .font(theme.fonts.badge)
            .foregroundStyle(theme.colors.primaryText)
            .padding(.horizontal, theme.spacing.xSmall)
            .padding(.vertical, theme.spacing.xxSmall)
            .background(
                theme.colors.favoriteBadgeBackground,
                in: RoundedRectangle(cornerRadius: theme.radii.pill)
            )
            .accessibilityLabel("Favorite")
    }
}
