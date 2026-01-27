import SwiftUI

struct AppTheme {
    struct Colors {
        static let background = Color(red: 0.96, green: 0.90, blue: 0.80)
        static let backgroundSecondary = Color(red: 0.91, green: 0.86, blue: 0.77)
        static let primary = Color.brown
        static let onPrimary = Color.white
        static let accent = Color.yellow
        static let textPrimary = Color.black
        static let textSecondary = Color.gray
        static let textOnAccent = Color.black
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
