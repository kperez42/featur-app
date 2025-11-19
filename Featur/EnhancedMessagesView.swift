import SwiftUI
import FirebaseAuth
import FirebaseFirestore
struct EnhancedMessagesView: View {
    @StateObject private var viewModel = MessagesViewModel()
    @EnvironmentObject var auth: AuthViewModel
    @State private var showNewChat = false
    @State private var openConversation: Conversation? = nil

    
    var body: some View {
        Group {
            if auth.user == nil {
                signInPrompt
            } else if viewModel.isLoading {
                ProgressView()
            } else if viewModel.conversations.isEmpty && viewModel.newMatches.isEmpty {
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
        .onChange(of: auth.user?.uid ?? "") { newValue in
            guard !newValue.isEmpty else { return }
            Task { await viewModel.loadConversations(userId: newValue) }
        
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
                    ForEach(viewModel.newMatches.indices, id: \.self) { index in
                        if let profile = viewModel.newMatches[index].profile,
                           let currentUserId = auth.user?.uid {
                            Button {
                                Task {
                                    do {
                                        let match = viewModel.newMatches[index].match
                                        let otherId = (match.userId1 == currentUserId)
                                            ? match.userId2
                                            : match.userId1

                                        let conversation = try await viewModel.service.getOrCreateConversation(
                                            between: currentUserId,
                                            and: otherId
                                        )

                                        await viewModel.service.markMatchAsMessaged(
                                            userA: currentUserId,
                                            userB: otherId
                                        )

                                        openConversation = conversation
                                    } catch {
                                        print("❌ Failed to open conversation: \(error)")
                                    }
                                }
                            } label: {
                                NewMatchCard(profile: profile)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 16)
        .background(AppTheme.card)
        .overlay(                // ✅ simpler than .background for navigation trigger
            NavigationLink(
                destination: Group {
                    if let conv = openConversation {
                        ChatView(conversation: conv)
                    } else {
                        EmptyView()
                    }
                },
                isActive: Binding(
                    get: { openConversation != nil },
                    set: { if !$0 { openConversation = nil } }
                ),
                label: { EmptyView() }      // required label View
            )
            .opacity(0)                     // invisible, but keeps NavigationLink valid
        )
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
        AsyncImage(url: URL(string: (profile.mediaURLs ?? []).first ?? "")) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill() //
                    .clipped()      //
                    .frame(width: 56, height: 56)
                    .clipShape(Circle())

            case .failure(_):
                placeholderAvatar(profile)

            case .empty:
                ProgressView()
                    .frame(width: 56, height: 56)

            @unknown default:
                EmptyView()
            }
        }
    }

    @ViewBuilder
    private func placeholderAvatar(_ profile: UserProfile) -> some View {
        Circle()
            .fill(AppTheme.accent.opacity(0.2))
            .overlay {
                Text(String(profile.displayName.prefix(1)))
                    .font(.headline)
                    .foregroundStyle(AppTheme.accent)
            }
            .frame(width: 56, height: 56)
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
            AsyncImage(url: URL(string: (profile.mediaURLs ?? []).first ?? "")) { image in
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
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 8) {
                    if let profile = conversation.participantProfiles?.values.first,
                       let urlString = (profile.mediaURLs ?? []).first,
                       let url = URL(string: urlString) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .scaledToFill()
                                .clipped()
                        } placeholder: {
                            Circle()
                                .fill(AppTheme.accent.opacity(0.2))
                        }
                        .frame(width: 44, height: 44) // or 32 if you want smaller
                        .clipShape(Circle())          // ✅ makes it perfectly round

                    }
                    
                    Text(conversation.participantProfiles?.values.first?.displayName ?? "Chat")
                        .font(.headline)
                }
            }
        }
        .background(AppTheme.bg)
        .onAppear {
            guard let conversationId = conversation.id else { return }

            // Load initial messages
            Task {
                await viewModel.loadMessages(conversationId: conversationId)
                await viewModel.markAsRead(conversationId: conversationId)
            }

            // Start real-time listener for new messages
            viewModel.startListening(conversationId: conversationId)
        }
        .onDisappear {
            // Clean up listener to prevent memory leaks
            viewModel.stopListening()
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
    
    internal let service = FirebaseService()
    
    func loadConversations(userId: String) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            conversations = try await service.fetchConversations(forUser: userId)
            print(" Conversations fetched: \(conversations.count)")
            // Attach other user's profile for display
            for i in 0..<conversations.count {
                if let otherId = conversations[i].participantIds.first(where: { $0 != userId }),
                   let profile = try? await service.fetchProfile(uid: otherId) {
                    conversations[i].participantProfiles = [otherId: profile]
                }
            }

            let matches = try await service.fetchMatches(forUser: userId)
            print(" Matches fetched: \(matches.count)")
            
            let unmessaged = matches.filter { !$0.hasMessaged && $0.isActive }
            print(" Unmessaged active matches: \(unmessaged.count)")
            
            var matchesWithProfiles: [(Match, UserProfile?)] = []
            for match in unmessaged {
                let otherId = (match.userId1 == userId) ? match.userId2 : match.userId1
                let profile = try? await service.fetchProfile(uid: otherId)
                print("  • Match otherId=\(otherId) profileFound=\(profile != nil)")
                matchesWithProfiles.append((match, profile))
            }
            newMatches = matchesWithProfiles
            
        } catch {
            print(" Error loading conversations: \(error)")
        }
    }
}

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []

    private let service = FirebaseService()
    private var listener: ListenerRegistration?

    // Start firestore listener
    func startListening(conversationId: String) {
        // Stop any existing listener first to prevent duplicates
        stopListening()

        // Debug statement to confirm we actively listen for messages
        print(" Listening for messages in conversation: \(conversationId)")
        listener = service.listenForMessages(conversationId: conversationId) { [weak self] newMessages in
            Task { @MainActor in
                // print this to confirm Firestore pushed new data
                print("📨 Received snapshot with \(newMessages.count) messages")
                self?.messages = newMessages
            }
        }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
        print("🔇 Stopped listening for messages")
    }

    // Ensure cleanup happens even if view is dismissed abruptly
    deinit {
        listener?.remove()
        print("🧹 ChatViewModel deinitialized - listener cleaned up")
    }
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
            // print confirmation a message was sent
            print(" Message sent: \(content) to \(recipientId) in \(conversationId)")

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
    @StateObject private var viewModel = NewChatViewModel()
    @State private var searchText = ""

    var filteredMatches: [(match: Match, profile: UserProfile?)] {
        if searchText.isEmpty {
            return viewModel.matches
        } else {
            return viewModel.matches.filter { match in
                guard let profile = match.profile else { return false }
                return profile.displayName.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                SearchBar(text: $searchText, placeholder: "Search connections")
                    .padding()

                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxHeight: .infinity)
                } else if viewModel.matches.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "person.2.slash")
                            .font(.system(size: 50))
                            .foregroundStyle(.secondary)
                        Text("No Matches Yet")
                            .font(.headline)
                        Text("Start swiping to find collaborators!")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(filteredMatches.indices, id: \.self) { index in
                                if let profile = filteredMatches[index].profile {
                                    Button {
                                        Task {
                                            await viewModel.createConversation(with: profile)
                                            dismiss()
                                        }
                                    } label: {
                                        HStack(spacing: 12) {
                                            // Profile Photo
                                            AsyncImage(url: URL(string: profile.profilePhotoURL ?? "")) { image in
                                                image
                                                    .resizable()
                                                    .scaledToFill()
                                            } placeholder: {
                                                Circle()
                                                    .fill(AppTheme.accent.opacity(0.2))
                                                    .overlay {
                                                        Text(profile.displayName.prefix(1))
                                                            .font(.title2.bold())
                                                            .foregroundStyle(AppTheme.accent)
                                                    }
                                            }
                                            .frame(width: 50, height: 50)
                                            .clipShape(Circle())

                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(profile.displayName)
                                                    .font(.headline)
                                                    .foregroundStyle(.primary)

                                                if !profile.bio.isEmpty {
                                                    Text(profile.bio)
                                                        .font(.caption)
                                                        .foregroundStyle(.secondary)
                                                        .lineLimit(1)
                                                }
                                            }

                                            Spacer()

                                            Image(systemName: "chevron.right")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        .padding()
                                    }
                                    .buttonStyle(.plain)

                                    Divider()
                                        .padding(.leading, 76)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("New Message")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .background(AppTheme.bg)
            .task {
                await viewModel.loadMatches()
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage)
            }
        }
    }
}

// MARK: - New Chat View Model

@MainActor
final class NewChatViewModel: ObservableObject {
    @Published var matches: [(match: Match, profile: UserProfile?)] = []
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""

    private let service = FirebaseService()

    func loadMatches() async {
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "Please sign in to continue"
            showError = true
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            // Fetch all active matches
            let fetchedMatches = try await service.fetchMatches(userId: userId)
            print("✅ Loaded \(fetchedMatches.count) matches for new chat")

            // Fetch profiles for each match
            var matchesWithProfiles: [(match: Match, profile: UserProfile?)] = []
            for match in fetchedMatches {
                let otherUserId = match.userId1 == userId ? match.userId2 : match.userId1
                let profile = try? await service.fetchProfile(forUser: otherUserId)
                matchesWithProfiles.append((match: match, profile: profile))
            }

            matches = matchesWithProfiles

        } catch {
            errorMessage = "Failed to load matches: \(error.localizedDescription)"
            showError = true
            print("❌ Error loading matches: \(error)")
        }
    }

    func createConversation(with profile: UserProfile) async {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }

        do {
            let conversation = try await service.getOrCreateConversation(
                userA: currentUserId,
                userB: profile.uid
            )

            print("✅ Conversation created/retrieved: \(conversation.id ?? "unknown")")

            // Track analytics
            AnalyticsManager.shared.trackConversationStarted(withUserId: profile.uid)

        } catch {
            errorMessage = "Failed to create conversation: \(error.localizedDescription)"
            showError = true
            print("❌ Error creating conversation: \(error)")
        }
    }
}
