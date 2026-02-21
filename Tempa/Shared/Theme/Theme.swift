import SwiftUI

/// Centralized theme definitions for colors and fonts used across the app.
struct AppTheme {
    struct Colors {
        static let background = Color.white
        static let backgroundSecondary = Color.white
        static let primary = Color.black
        static let onPrimary = Color.white
        static let accent = Color.black
        static let textPrimary = Color.black
        static let textSecondary = Color.gray
        static let textOnAccent = Color.white
        static let cardBackground = Color.white
        static let success = Color.green
        static let failure = Color.red
        static let error = Color.red
    }

    struct Fonts {
        static let largeTitle = Font.largeTitle
        static let largeTitleBold = Font.largeTitle.weight(.bold)
        static let title = Font.title
        static let title3 = Font.title3
        static let headline = Font.headline
        static let subheadline = Font.subheadline
        static let body = Font.body
        static let caption = Font.caption
    }
}
