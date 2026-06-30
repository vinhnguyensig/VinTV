//
//  VPAppThemeTests.swift
//  VinAppleTV
//
//  Created by Vinh Nguyen on 26/6/26.
//

import SwiftUI
import Testing
@testable import VPAppTheme

@Test
func defaultThemeProvidesExpectedMetrics() {
    let theme = VPTheme()

    #expect(theme.spacing.xxSmall == 8)
    #expect(theme.spacing.xxLarge == 80)
    #expect(theme.radii.small == 14)
    #expect(theme.radii.pill == 999)
    #expect(theme.focus.focusedScale == 1.08)
    #expect(theme.focus.borderWidth == 5)
    #expect(theme.focus.animationDuration == 0.18)
    #expect(theme.focus.springResponse == 0.28)
    #expect(theme.focus.springDampingFraction == 0.72)
    #expect(theme.layout.horizontalScreenInset == 80)
    #expect(theme.layout.cardWidth == 320)
    #expect(theme.layout.cardHeight == 180)
    #expect(theme.layout.heroHeight == 430)
    #expect(theme.layout.railSpacing == 24)
    #expect(theme.layout.heroBottomSpacing == 60)
    #expect(theme.layout.sectionSpacing == 56)
    #expect(theme.layout.artworkTitleSpacing == 16)
    #expect(theme.layout.focusedCardClearance == 24)
}

@Test
func customThemeCanBeConstructed() {
    let spacing = VPThemeSpacing(
        xxSmall: 1,
        xSmall: 2,
        small: 3,
        medium: 4,
        large: 5,
        xLarge: 6,
        xxLarge: 7
    )
    let radii = VPThemeRadii(small: 1, medium: 2, large: 3, pill: 4)
    let focus = VPThemeFocus(
        focusedScale: 1.2,
        unfocusedScale: 0.9,
        borderWidth: 7,
        shadowRadius: 9,
        shadowOpacity: 0.4,
        focusedOpacity: 0.95,
        animationDuration: 0.3
    )
    let layout = VPThemeLayout(
        horizontalScreenInset: 10,
        verticalScreenInset: 11,
        railSpacing: 12,
        gridSpacing: 13,
        cardWidth: 14,
        cardHeight: 15,
        heroHeight: 16,
        controlOverlayInset: 17
    )
    let theme = VPTheme(
        colors: .default,
        fonts: .default,
        spacing: spacing,
        radii: radii,
        focus: focus,
        layout: layout
    )

    #expect(theme.spacing.medium == 4)
    #expect(theme.radii.large == 3)
    #expect(theme.focus.focusedScale == 1.2)
    #expect(theme.layout.controlOverlayInset == 17)
    #expect(theme.layout.focusedCardClearance == 24)
}
