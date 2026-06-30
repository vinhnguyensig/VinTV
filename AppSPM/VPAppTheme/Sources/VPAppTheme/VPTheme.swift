//
//  VPTheme.swift
//  VinAppleTV
//
//  Created by Vinh Nguyen on 27/6/26.
//

import SwiftUI

/// The immutable design-system value injected at the app composition root.
public struct VPTheme: Sendable {
    public let colors: VPThemeColors
    public let fonts: VPThemeFonts
    public let spacing: VPThemeSpacing
    public let radii: VPThemeRadii
    public let focus: VPThemeFocus
    public let layout: VPThemeLayout

    public init(
        colors: VPThemeColors = .default,
        fonts: VPThemeFonts = .default,
        spacing: VPThemeSpacing = .default,
        radii: VPThemeRadii = .default,
        focus: VPThemeFocus = .default,
        layout: VPThemeLayout = .default
    ) {
        self.colors = colors
        self.fonts = fonts
        self.spacing = spacing
        self.radii = radii
        self.focus = focus
        self.layout = layout
    }
}

public struct VPThemeColors: Sendable {
    public let background: Color
    public let elevatedBackground: Color
    public let overlayBackground: Color
    public let primaryText: Color
    public let secondaryText: Color
    public let accent: Color
    public let focusBorder: Color
    public let placeholderStart: Color
    public let placeholderEnd: Color
    public let favoriteBadgeBackground: Color
    public let playerForeground: Color
    public let playerBackground: Color
    public let error: Color

    public init(
        background: Color,
        elevatedBackground: Color,
        overlayBackground: Color,
        primaryText: Color,
        secondaryText: Color,
        accent: Color,
        focusBorder: Color,
        placeholderStart: Color,
        placeholderEnd: Color,
        favoriteBadgeBackground: Color,
        playerForeground: Color,
        playerBackground: Color,
        error: Color
    ) {
        self.background = background
        self.elevatedBackground = elevatedBackground
        self.overlayBackground = overlayBackground
        self.primaryText = primaryText
        self.secondaryText = secondaryText
        self.accent = accent
        self.focusBorder = focusBorder
        self.placeholderStart = placeholderStart
        self.placeholderEnd = placeholderEnd
        self.favoriteBadgeBackground = favoriteBadgeBackground
        self.playerForeground = playerForeground
        self.playerBackground = playerBackground
        self.error = error
    }

    public static let `default` = VPThemeColors(
        background: Color(red: 0.04, green: 0.05, blue: 0.06),
        elevatedBackground: Color(red: 0.08, green: 0.09, blue: 0.12),
        overlayBackground: Color.black.opacity(0.78),
        primaryText: .white,
        secondaryText: Color(red: 0.78, green: 0.82, blue: 0.88),
        accent: Color(red: 0.16, green: 0.23, blue: 0.32),
        focusBorder: .white,
        placeholderStart: Color(red: 0.11, green: 0.16, blue: 0.23),
        placeholderEnd: Color(red: 0.12, green: 0.15, blue: 0.18),
        favoriteBadgeBackground: Color(red: 0.18, green: 0.25, blue: 0.32),
        playerForeground: .white,
        playerBackground: .black,
        error: Color(red: 1, green: 0.35, blue: 0.28)
    )
}

public struct VPThemeFonts: Sendable {
    public let display: Font
    public let screenTitle: Font
    public let sectionTitle: Font
    public let cardTitle: Font
    public let metadata: Font
    public let body: Font
    public let button: Font
    public let badge: Font
    public let playerControl: Font

    public init(
        display: Font,
        screenTitle: Font,
        sectionTitle: Font,
        cardTitle: Font,
        metadata: Font,
        body: Font,
        button: Font,
        badge: Font,
        playerControl: Font
    ) {
        self.display = display
        self.screenTitle = screenTitle
        self.sectionTitle = sectionTitle
        self.cardTitle = cardTitle
        self.metadata = metadata
        self.body = body
        self.button = button
        self.badge = badge
        self.playerControl = playerControl
    }

    public static let `default` = VPThemeFonts(
        display: .system(size: 86, weight: .black, design: .rounded),
        screenTitle: .system(size: 54, weight: .heavy, design: .rounded),
        sectionTitle: .system(size: 34, weight: .semibold, design: .rounded),
        cardTitle: .system(size: 26, weight: .semibold, design: .rounded),
        metadata: .system(size: 20, weight: .semibold, design: .monospaced),
        body: .system(size: 24, weight: .regular, design: .rounded),
        button: .system(size: 25, weight: .semibold, design: .rounded),
        badge: .system(size: 16, weight: .heavy, design: .monospaced),
        playerControl: .system(size: 24, weight: .semibold, design: .rounded)
    )
}

public struct VPThemeSpacing: Sendable {
    public let xxSmall: CGFloat
    public let xSmall: CGFloat
    public let small: CGFloat
    public let medium: CGFloat
    public let large: CGFloat
    public let xLarge: CGFloat
    public let xxLarge: CGFloat

    public init(
        xxSmall: CGFloat,
        xSmall: CGFloat,
        small: CGFloat,
        medium: CGFloat,
        large: CGFloat,
        xLarge: CGFloat,
        xxLarge: CGFloat
    ) {
        self.xxSmall = xxSmall
        self.xSmall = xSmall
        self.small = small
        self.medium = medium
        self.large = large
        self.xLarge = xLarge
        self.xxLarge = xxLarge
    }

    public static let `default` = VPThemeSpacing(
        xxSmall: 8,
        xSmall: 12,
        small: 18,
        medium: 24,
        large: 34,
        xLarge: 48,
        xxLarge: 80
    )
}

public struct VPThemeRadii: Sendable {
    public let small: CGFloat
    public let medium: CGFloat
    public let large: CGFloat
    public let pill: CGFloat

    public init(small: CGFloat, medium: CGFloat, large: CGFloat, pill: CGFloat) {
        self.small = small
        self.medium = medium
        self.large = large
        self.pill = pill
    }

    public static let `default` = VPThemeRadii(
        small: 14,
        medium: 22,
        large: 28,
        pill: 999
    )
}

public struct VPThemeFocus: Sendable {
    public let focusedScale: CGFloat
    public let unfocusedScale: CGFloat
    public let borderWidth: CGFloat
    public let shadowRadius: CGFloat
    public let shadowOpacity: Double
    public let focusedOpacity: Double
    public let animationDuration: Double
    public let springResponse: Double
    public let springDampingFraction: Double

    public init(
        focusedScale: CGFloat,
        unfocusedScale: CGFloat,
        borderWidth: CGFloat,
        shadowRadius: CGFloat,
        shadowOpacity: Double,
        focusedOpacity: Double,
        animationDuration: Double,
        springResponse: Double = 0.28,
        springDampingFraction: Double = 0.72
    ) {
        self.focusedScale = focusedScale
        self.unfocusedScale = unfocusedScale
        self.borderWidth = borderWidth
        self.shadowRadius = shadowRadius
        self.shadowOpacity = shadowOpacity
        self.focusedOpacity = focusedOpacity
        self.animationDuration = animationDuration
        self.springResponse = springResponse
        self.springDampingFraction = springDampingFraction
    }

    public static let `default` = VPThemeFocus(
        focusedScale: 1.08,
        unfocusedScale: 1,
        borderWidth: 5,
        shadowRadius: 24,
        shadowOpacity: 0.65,
        focusedOpacity: 1,
        animationDuration: 0.18,
        springResponse: 0.28,
        springDampingFraction: 0.72
    )
}

public struct VPThemeLayout: Sendable {
    public let horizontalScreenInset: CGFloat
    public let verticalScreenInset: CGFloat
    public let railSpacing: CGFloat
    public let gridSpacing: CGFloat
    public let cardWidth: CGFloat
    public let cardHeight: CGFloat
    public let heroHeight: CGFloat
    public let controlOverlayInset: CGFloat
    public let heroBottomSpacing: CGFloat
    public let sectionSpacing: CGFloat
    public let artworkTitleSpacing: CGFloat
    public let focusedCardClearance: CGFloat

    public init(
        horizontalScreenInset: CGFloat,
        verticalScreenInset: CGFloat,
        railSpacing: CGFloat,
        gridSpacing: CGFloat,
        cardWidth: CGFloat,
        cardHeight: CGFloat,
        heroHeight: CGFloat,
        controlOverlayInset: CGFloat,
        heroBottomSpacing: CGFloat = 60,
        sectionSpacing: CGFloat = 56,
        artworkTitleSpacing: CGFloat = 16,
        focusedCardClearance: CGFloat = 24
    ) {
        self.horizontalScreenInset = horizontalScreenInset
        self.verticalScreenInset = verticalScreenInset
        self.railSpacing = railSpacing
        self.gridSpacing = gridSpacing
        self.cardWidth = cardWidth
        self.cardHeight = cardHeight
        self.heroHeight = heroHeight
        self.controlOverlayInset = controlOverlayInset
        self.heroBottomSpacing = heroBottomSpacing
        self.sectionSpacing = sectionSpacing
        self.artworkTitleSpacing = artworkTitleSpacing
        self.focusedCardClearance = focusedCardClearance
    }

    public static let `default` = VPThemeLayout(
        horizontalScreenInset: 80,
        verticalScreenInset: 48,
        railSpacing: 24,
        gridSpacing: 34,
        cardWidth: 320,
        cardHeight: 180,
        heroHeight: 430,
        controlOverlayInset: 48,
        heroBottomSpacing: 60,
        sectionSpacing: 56,
        artworkTitleSpacing: 16,
        focusedCardClearance: 24
    )
}

private struct VPThemeEnvironmentKey: EnvironmentKey {
    static let defaultValue = VPTheme()
}

public extension EnvironmentValues {
    var vpTheme: VPTheme {
        get { self[VPThemeEnvironmentKey.self] }
        set { self[VPThemeEnvironmentKey.self] = newValue }
    }
}

public extension View {
    func vpTheme(_ theme: VPTheme) -> some View {
        environment(\.vpTheme, theme)
    }

    func vpThemedBackground() -> some View {
        modifier(VPThemedBackgroundModifier())
    }

    func vpFocusCard(isFocused: Bool, cornerRadius: CGFloat) -> some View {
        modifier(VPFocusCardModifier(isFocused: isFocused, cornerRadius: cornerRadius))
    }
}

private struct VPThemedBackgroundModifier: ViewModifier {
    @Environment(\.vpTheme) private var theme

    func body(content: Content) -> some View {
        content
            .background(theme.colors.background)
            .foregroundStyle(theme.colors.primaryText)
    }
}

private struct VPFocusCardModifier: ViewModifier {
    @Environment(\.vpTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let isFocused: Bool
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .overlay {
                if isFocused {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(theme.colors.accent.opacity(0.8), lineWidth: theme.focus.borderWidth + 4)
                        .blur(radius: reduceMotion ? 0 : 12)
                }
            }
            .scaleEffect(
                isFocused && !reduceMotion
                    ? theme.focus.focusedScale
                    : theme.focus.unfocusedScale
            )
            .opacity(isFocused ? theme.focus.focusedOpacity : 1)
            .shadow(
                color: theme.colors.accent.opacity(isFocused ? 0.3 : 0),
                radius: isFocused ? theme.focus.shadowRadius * 1.5 : 0,
                y: isFocused ? 15 : 0
            )
            .shadow(
                color: Color.black.opacity(isFocused ? theme.focus.shadowOpacity : 0),
                radius: isFocused ? theme.focus.shadowRadius : 0,
                y: isFocused ? 20 : 0
            )
            .zIndex(isFocused ? 1 : 0)
            .animation(
                reduceMotion
                    ? nil
                    : .interactiveSpring(
                        response: theme.focus.springResponse,
                        dampingFraction: theme.focus.springDampingFraction,
                        blendDuration: 0
                    ),
                value: isFocused
            )
    }
}
