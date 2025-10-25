import SwiftUI
import FirebaseAuth

struct EnhancedMessagesView: View {
    @StateObject private var viewModel = MessagesViewModel()
    @EnvironmentObject var auth: AuthViewModel
    @State private var showNewChat = false
    
    var body: some View {
        Group {
            if auth.user == nil {
                signInPrompt
            } else if viewModel.isLoading {
                ProgressView()
            } else if viewModel.conversations.isEmpty {
                emptyState
            } else {
                conversationsList
            }
        }
        .navigationTitle("Messages")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showNewChat = true
                } label: {
                    Image(systemName: "square.and.pencil")
                        .foregroundStyle(AppTheme.accent)
                }
            }
        }
        .sheet(isPresented: $showNewChat) {
            NewChatView()
        }
        .task {
            if let userId = auth.user?.uid {
                await viewModel.loadConversations(userId: userId)
            }
        }
    }
    
    private var conversationsList: some View {
        ScrollView {
            VStack(spacing: 0) {
                // New Connections
                if !viewModel.newMatches.isEmpty {
                    newConnectionsSection
                }
                
                // Active Conversations
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.conversations) { conversation in
                        NavigationLink(destination: ChatView(conversation: conversation)) {
                            ConversationRow(conversation: conversation)
                        }
                        .buttonStyle(.plain)
                        
                        Divider()
                            .padding(.leading, 76)
                    }
                }
            }
        }
        .background(AppTheme.bg)
    }
    
    // ✅ FIXED: Use indices instead of iterating over tuples directly
    private var newConnectionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("New Connections")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    // ✅ FIXED VERSION:
                    ForEach(Array(viewModel.newMatches.enumerated()), id: \.offset) { index, match in
                        if let profile = match.profile {
                            NewMatchCard(profile: profile)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 16)
        .background(AppTheme.card)
    }
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            
            Text("No Messages Yet")
                .font(.title2.bold())
            
            Text("Start swiping to match with creators and begin conversations")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxHeight: .infinity)
        .background(AppTheme.bg)
    }
    
    private var signInPrompt: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.shield")
                .font(.system(size: 56))
                .foregroundStyle(AppTheme.accent)
            
            Text("Sign In Required")
                .font(.title2.bold())
            
            Text("Create an account to send and receive messages")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
        .background(AppTheme.bg)
    }
}

// MARK: - Conversation Row

struct ConversationRow: View {
    let conversation: Conversation
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            if conversation.isGroupChat {
                groupAvatar
            } else if let otherProfile = conversation.participantProfiles?.values.first {
                profileAvatar(otherProfile)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(displayName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    Text(timeString)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                HStack {
                    Text(conversation.lastMessage ?? "Start chatting")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if unreadCount > 0 {
                        Text("\(unreadCount)")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(AppTheme.accent, in: Capsule())
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(AppTheme.bg)
    }
    
    private var displayName: String {
        if conversation.isGroupChat {
            return conversation.groupName ?? "Group Chat"
        } else if let profile = conversation.participantProfiles?.values.first {
            return profile.displayName
        }
        return "Unknown"
    }
    
    private var unreadCount: Int {
        guard let userId = Auth.auth().currentUser?.uid else { return 0 }
        return conversation.unreadCount[userId] ?? 0
    }
    
    private var timeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: conversation.lastMessageAt, relativeTo: Date())
    }
    
    private func profileAvatar(_ profile: UserProfile) -> some View {
        AsyncImage(url: URL(string: profile.mediaURLs.first ?? "")) { image in
            image.resizable()
        } placeholder: {
            Circle()
                .fill(AppTheme.accent.opacity(0.2))
                .overlay {
                    Text(String(profile.displayName.prefix(1)))
                        .font(.headline)
                        .foregroundStyle(AppTheme.accent)
                }
        }
        .frame(width: 56, height: 56)
        .clipShape(Circle())
    }
    
    private var groupAvatar: some View {
        ZStack {
            Circle()
                .fill(AppTheme.card)
                .frame(width: 56, height: 56)
            
            Image(systemName: "person.3.fill")
                .foregroundStyle(AppTheme.accent)
        }
    }
}

// MARK: - New Match Card

struct NewMatchCard: View {
    let profile: UserProfile
    
    var body: some View {
        VStack(spacing: 8) {
            AsyncImage(url: URL(string: profile.mediaURLs.first ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(AppTheme.accent.opacity(0.2))
            }
            .frame(width: 80, height: 80)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(AppTheme.accent, lineWidth: 3)
            )
            
            Text(profile.displayName)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
                .frame(width: 80)
        }
    }
}

// MARK: - Chat View

struct ChatView: View {
    let conversation: Conversation
    @StateObject private var viewModel = ChatViewModel()
    @State private var messageText = ""
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Messages List
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.messages) { message in
                            MessageBubble(message: message, isFromCurrentUser: message.senderId == Auth.auth().currentUser?.uid)
                        }
                    }
                    .padding()
                    .onChange(of: viewModel.messages.count) { _ in
                        if let lastMessage = viewModel.messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
            }
            
            // Input Bar
            HStack(spacing: 12) {
                Button {
                    // Add media
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(AppTheme.accent)
                }
                
                TextField("Message", text: $messageText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .padding(10)
                    .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 20))
                    .focused($isInputFocused)
                    .lineLimit(1...5)
                
                Button {
                    sendMessage()
                } label: {
                    Image(systemName: messageText.isEmpty ? "mic.fill" : "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundStyle(messageText.isEmpty ? .secondary : AppTheme.accent)
                }
                .disabled(messageText.isEmpty)
            }
            .padding()
            .background(AppTheme.bg.opacity(0.95))
        }
        .navigationTitle(conversation.isGroupChat ? (conversation.groupName ?? "Group") : (conversation.participantProfiles?.values.first?.displayName ?? "Chat"))
        .navigationBarTitleDisplayMode(.inline)
        .background(AppTheme.bg)
        .task {
            await viewModel.loadMessages(conversationId: conversation.id ?? "")
            await viewModel.markAsRead(conversationId: conversation.id ?? "")
        }
    }
    
    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let currentUserId = Auth.auth().currentUser?.uid,
              let conversationId = conversation.id else { return }
        
        let recipientId = conversation.participantIds.first { $0 != currentUserId } ?? ""
        
        Task {
            await viewModel.sendMessage(
                conversationId: conversationId,
                senderId: currentUserId,
                recipientId: recipientId,
                content: messageText
            )
            messageText = ""
            Haptics.impact(.light)
        }
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: Message
    let isFromCurrentUser: Bool
    
    var body: some View {
        HStack {
            if isFromCurrentUser { Spacer(minLength: 60) }
            
            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        isFromCurrentUser ? AppTheme.accent : AppTheme.card,
                        in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                    )
                    .foregroundStyle(isFromCurrentUser ? .white : .primary)
                
                Text(timeString)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
            }
            
            if !isFromCurrentUser { Spacer(minLength: 60) }
        }
    }
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: message.sentAt)
    }
}

// MARK: - View Models

@MainActor
final class MessagesViewModel: ObservableObject {
    @Published var conversations: [Conversation] = []
    @Published var newMatches: [(match: Match, profile: UserProfile?)] = []
    @Published var isLoading = false
    
    private let service = FirebaseService()
    
    func loadConversations(userId: String) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            conversations = try await service.fetchConversations(forUser: userId)
            
            // Load new matches
            let matches = try await service.fetchMatches(forUser: userId)
            let unmessaged = matches.filter { !$0.hasMessaged }
            
            var matchesWithProfiles: [(Match, UserProfile?)] = []
            for match in unmessaged {
                let otherId = match.userId1 == userId ? match.userId2 : match.userId1
                let profile = try? await service.fetchProfile(uid: otherId)
                matchesWithProfiles.append((match, profile))
            }
            newMatches = matchesWithProfiles
            
        } catch {
            print("Error loading conversations: \(error)")
        }
    }
}

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    
    private let service = FirebaseService()
    
    func loadMessages(conversationId: String) async {
        do {
            messages = try await service.fetchMessages(conversationId: conversationId, limit: 100)
            messages.reverse()
        } catch {
            print("Error loading messages: \(error)")
        }
    }
    
    func sendMessage(conversationId: String, senderId: String, recipientId: String, content: String) async {
        let message = Message(
            conversationId: conversationId,
            senderId: senderId,
            recipientId: recipientId,
            content: content,
            sentAt: Date(),
            readAt: nil
        )
        
        do {
            try await service.sendMessage(message)
            messages.append(message)
        } catch {
            print("Error sending message: \(error)")
        }
    }
    
    func markAsRead(conversationId: String) async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        try? await service.markMessagesAsRead(conversationId: conversationId, userId: userId)
    }
}

// MARK: - New Chat View

struct NewChatView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    
    var body: some View {
        NavigationStack {
            VStack {
                SearchBar(text: $searchText, placeholder: "Search connections")
                
                Text("Select from your matches")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                
                // List matches here
                Spacer()
            }
            .navigationTitle("New Message")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .background(AppTheme.bg)
        }
    }
}
