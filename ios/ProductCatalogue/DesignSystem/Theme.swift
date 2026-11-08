import SwiftUI

/// Single place for look and feel. The creative work in progress lands here,
/// not scattered across screens.
enum Theme {
    enum Spacing {
        static let xs: CGFloat = 4
        static let s: CGFloat = 8
        static let m: CGFloat = 12
        static let l: CGFloat = 16
        static let xl: CGFloat = 24
    }

    enum Radius {
        static let card: CGFloat = 12
        static let control: CGFloat = 10
    }

    enum Colors {
        static let accent = Color.indigo
        static let cardBackground = Color(.secondarySystemBackground)
        static let imageBackground = Color.white
        static let rating = Color.orange
        static let error = Color.red
        static let secondaryText = Color.secondary
    }

    enum Fonts {
        static let sectionTitle = Font.title3.weight(.semibold)
        static let cardTitle = Font.subheadline.weight(.medium)
        static let price = Font.headline
        static let detailTitle = Font.title2.weight(.semibold)
    }

    enum Layout {
        static let gridColumns = [GridItem(.adaptive(minimum: 150), spacing: Spacing.m)]
        static let cardImageHeight: CGFloat = 140
        static let detailImageHeight: CGFloat = 280
    }
}
