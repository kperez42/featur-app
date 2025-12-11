import SwiftUI

struct AppTheme {
    // MARK: - Primary Colors
    static let accent = Color(red: 0.55, green: 0.35, blue: 0.95) // Vibrant purple
    static let accentLight = Color(red: 0.7, green: 0.5, blue: 1.0)
    static let accentDark = Color(red: 0.4, green: 0.25, blue: 0.8)

    // MARK: - Semantic Colors
    static let success = Color(red: 0.2, green: 0.8, blue: 0.4)
    static let warning = Color(red: 1.0, green: 0.7, blue: 0.2)
    static let error = Color(red: 0.95, green: 0.3, blue: 0.3)
    static let like = Color(red: 1.0, green: 0.4, blue: 0.5) // Pink for likes
    static let superLike = Color(red: 0.2, green: 0.7, blue: 1.0) // Blue for super likes

    // MARK: - Background Colors
    static let bg = Color(UIColor.systemBackground)
    static let card = Color(UIColor.secondarySystemBackground)
    static let cardElevated = Color(UIColor.tertiarySystemBackground)

    // MARK: - Text Colors
    static let textPrimary = Color(UIColor.label)
    static let textSecondary = Color(UIColor.secondaryLabel)
    static let textTertiary = Color(UIColor.tertiaryLabel)

    // MARK: - Primary Gradient
    static let gradient = LinearGradient(
        colors: [
            Color(red: 0.45, green: 0.25, blue: 0.9),
            Color(red: 0.65, green: 0.4, blue: 0.95)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: - Vibrant Gradient (for featured content)
    static let vibrantGradient = LinearGradient(
        colors: [
            Color(red: 0.95, green: 0.3, blue: 0.5),
            Color(red: 0.55, green: 0.35, blue: 0.95),
            Color(red: 0.2, green: 0.6, blue: 1.0)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: - Subtle Gradient (for cards)
    static let subtleGradient = LinearGradient(
        colors: [
            Color.white.opacity(0.1),
            Color.white.opacity(0.05)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: - Shadow Styles
    static let shadowLight = Color.black.opacity(0.08)
    static let shadowMedium = Color.black.opacity(0.15)
    static let shadowAccent = Color(red: 0.55, green: 0.35, blue: 0.95).opacity(0.3)

    // MARK: - Corner Radii
    static let radiusSmall: CGFloat = 8
    static let radiusMedium: CGFloat = 12
    static let radiusLarge: CGFloat = 16
    static let radiusXL: CGFloat = 24

    // MARK: - Animation Durations
    static let animFast: Double = 0.15
    static let animMedium: Double = 0.25
    static let animSlow: Double = 0.4
}
 
