import SwiftUI

@MainActor
final class AppStateManager: ObservableObject {
    @Published var selectedTab: Tab = .home
    @Published var pendingConversation: Conversation?
    @Published var pendingMatchedUserId: String?

    enum Tab {
        case home
        case discover
        case featured
        case messages
        case profile
    }

    /// Navigate to messages tab and open a conversation with a specific user
    func navigateToChat(withUserId userId: String) {
        pendingMatchedUserId = userId
        selectedTab = .messages
    }
}
