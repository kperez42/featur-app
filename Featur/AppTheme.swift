import SwiftUI

struct AppTheme {
    // MARK: - Colors
    static let accent = Color(red: 0.5, green: 0.4, blue: 0.9) // Purple accent
    static let bg = Color(UIColor.systemBackground)
    static let card = Color(UIColor.secondarySystemBackground)
    
    // MARK: - Gradient
    static let gradient = LinearGradient(
        colors: [
            Color(red: 0.4, green: 0.3, blue: 0.8),
            Color(red: 0.6, green: 0.4, blue: 0.9)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
 
