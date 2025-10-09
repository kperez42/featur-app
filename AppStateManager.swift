import SwiftUI

@MainActor
final class AppStateManager: ObservableObject {
    @Published var selectedTab: Tab = .home
    
    enum Tab {
        case home
        case discover
        case featured
        case messages
        case profile
    }
}
