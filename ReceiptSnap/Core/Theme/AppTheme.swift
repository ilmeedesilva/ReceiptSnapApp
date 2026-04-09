import SwiftUI

enum AppTheme {

    // MARK: - Corner Radii
    enum Radius {
        static let xs:     CGFloat = 4
        static let sm:     CGFloat = 8
        static let md:     CGFloat = 12
        static let lg:     CGFloat = 16
        static let button: CGFloat = 12
        static let card:   CGFloat = 16
        static let pill:   CGFloat = 50
    }

    // MARK: - Spacing
    enum Spacing {
        static let xs:  CGFloat = 4
        static let sm:  CGFloat = 8
        static let md:  CGFloat = 16
        static let lg:  CGFloat = 24
        static let xl:  CGFloat = 32
        static let xxl: CGFloat = 48
    }

    // MARK: - Font Sizes
    enum Font {
        static let caption:    CGFloat = 12
        static let body:       CGFloat = 14
        static let bodyLg:     CGFloat = 16
        static let headline:   CGFloat = 18
        static let title:      CGFloat = 22
        static let largeTitle: CGFloat = 28
    }

    // MARK: - Component Heights
    enum Height {
        static let button: CGFloat = 52
        static let input:  CGFloat = 52
        static let smallButton: CGFloat = 44
    }
}
