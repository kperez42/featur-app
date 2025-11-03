// ProfileDetailView.swift - Complete Profile Detail Screen
import SwiftUI
import FirebaseAuth

struct ProfileDetailView: View {
    let profile: UserProfile
    @Environment(\.dismiss) var dismiss
    @State private var selectedMediaIndex = 0
    @State private var showMessageSheet = false
    @State private var showLikeAnimation = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Media Gallery with Page Control
                mediaGallery
                
                // Profile Content
                VStack(alignment: .leading, spacing: 20) {
                    // Name, Age, and Verification
                    headerSection
                    
                    // Bio
                    if let bio = profile.bio {
                        bioSection(bio)
                    }
                    
                    // Stats
                    statsSection
                    
                    // Content Styles
                    contentStylesSection
                    
                    // Location
                    if let location = profile.location {
                        locationSection(location)
                    }
                    
                    // Social Links
                    socialLinksSection
                    
                    // Collaboration Preferences
                    collaborationSection
                    
                    // Interests
                    if !profile.interests.isEmpty {
                        interestsSection
                    }
                    
                    // Action Buttons
                    actionButtons
                }
                .padding()
            }
        }
        .ignoresSafeArea(edges: .top)
        .overlay(alignment: .topLeading) {
            // Back Button
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(12)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .padding()
        }
        .overlay(alignment: .topTrailing) {
            // More Menu
            Menu {
                Button {
                    // Share profile
                } label: {
                    Label("Share Profile", systemImage: "square.and.arrow.up")
                }
                
                Button(role: .destructive) {
                    // Report user
                } label: {
                    Label("Report", systemImage: "exclamationmark.triangle")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(12)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .padding()
        }
        .sheet(isPresented: $showMessageSheet) {
            MessageComposeView(recipient: profile)
        }
    }
    
    // MARK: - Media Gallery
    
    private var mediaGallery: some View {
        TabView(selection: $selectedMediaIndex) {
            if !profile.mediaURLs.isEmpty {
                ForEach(Array(profile.mediaURLs.enumerated()), id: \.offset) { index, url in
                    AsyncImage(url: URL(string: url)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure:
                            Rectangle()
                                .fill(AppTheme.gradient)
                        case .empty:
                            ProgressView()
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .frame(height: 500)
                    .clipped()
                    .tag(index)
                }
            } else if let profileImageURL = profile.profileImageURL {
                AsyncImage(url: URL(string: profileImageURL)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure, .empty:
                        Rectangle()
                            .fill(AppTheme.gradient)
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(height: 500)
                .clipped()
                .tag(0)
            } else {
                Rectangle()
                    .fill(AppTheme.gradient)
                    .frame(height: 500)
                    .overlay {
                        VStack(spacing: 16) {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 80))
                                .foregroundStyle(.white.opacity(0.5))
                            
                            Text(profile.displayName)
                                .font(.title.bold())
                                .foregroundStyle(.white)
                        }
                    }
                    .tag(0)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .frame(height: 500)
        .overlay(alignment: .bottomTrailing) {
            if !profile.mediaURLs.isEmpty {
                Text("\(selectedMediaIndex + 1)/\(profile.mediaURLs.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding()
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    Text(profile.displayName)
                        .font(.largeTitle.bold())
                    
                    if let age = profile.age {
                        Text("\(age)")
                            .font(.title.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                    
                    if profile.isVerified {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.title2)
                            .foregroundStyle(.blue)
                    }
                }
                
                // Follower Count
                Text("\(formatFollowerCount(profile.followerCount)) followers")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Bio Section
    
    private func bioSection(_ bio: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("About")
                .font(.headline)
            
            Text(bio)
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Stats Section
    
    private var statsSection: some View {
        HStack(spacing: 20) {
            StatCard(
                icon: "person.3.fill",
                value: formatFollowerCount(profile.followerCount),
                label: "Followers"
            )
            
            StatCard(
                icon: "video.fill",
                value: "\(profile.mediaURLs.count)",
                label: "Posts"
            )
            
            StatCard(
                icon: "clock.fill",
                value: profile.collaborationPreferences.responseTime.displayText,
                label: "Response"
            )
        }
    }
    
    // MARK: - Content Styles Section
    
    private var contentStylesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Content Styles")
                .font(.headline)
            
            FlowLayout(spacing: 8) {
                ForEach(profile.contentStyles, id: \.self) { style in
                    HStack(spacing: 6) {
                        Image(systemName: style.icon)
                            .font(.caption)
                        Text(style.rawValue)
                            .font(.caption.weight(.semibold))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(AppTheme.accent.opacity(0.15), in: Capsule())
                    .foregroundStyle(AppTheme.accent)
                }
            }
        }
    }
    
    // MARK: - Location Section
    
    private func locationSection(_ location: UserProfile.Location) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Location")
                .font(.headline)
            
            HStack(spacing: 8) {
                Image(systemName: "mappin.circle.fill")
                    .foregroundStyle(AppTheme.accent)
                
                if let city = location.city, let state = location.state {
                    Text("\(city), \(state)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else if let country = location.country {
                    Text(country)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                if location.isNearby {
                    Spacer()
                    Text("Nearby")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.green)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(.green.opacity(0.15), in: Capsule())
                }
            }
        }
    }
    
    // MARK: - Social Links Section
    
    private var socialLinksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Social Media")
                .font(.headline)
            
            VStack(spacing: 12) {
                if let tiktok = profile.socialLinks.tiktok {
                    ProfileSocialLinkRow(
                        platform: "TikTok",
                        icon: "music.note",
                        username: tiktok.username,
                        followers: tiktok.followerCount,
                        isVerified: tiktok.isVerified
                    )
                }
                
                if let instagram = profile.socialLinks.instagram {
                    ProfileSocialLinkRow(
                        platform: "Instagram",
                        icon: "camera.fill",
                        username: instagram.username,
                        followers: instagram.followerCount,
                        isVerified: instagram.isVerified
                    )
                }
                
                if let youtube = profile.socialLinks.youtube {
                    ProfileSocialLinkRow(
                        platform: "YouTube",
                        icon: "play.rectangle.fill",
                        username: youtube.username,
                        followers: youtube.followerCount,
                        isVerified: youtube.isVerified
                    )
                }
                
                if let twitch = profile.socialLinks.twitch {
                    ProfileSocialLinkRow(
                        platform: "Twitch",
                        icon: "tv.fill",
                        username: twitch.username,
                        followers: twitch.followerCount,
                        isVerified: twitch.isVerified
                    )
                }
                
                if let spotify = profile.socialLinks.spotify {
                    ProfileSocialLinkRow(
                        platform: "Spotify",
                        icon: "music.note.list",
                        username: spotify,
                        followers: nil,
                        isVerified: false
                    )
                }
            }
        }
    }
    
    // MARK: - Collaboration Section
    
    private var collaborationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Looking to Collaborate On")
                .font(.headline)
            
            FlowLayout(spacing: 8) {
                ForEach(profile.collaborationPreferences.lookingFor, id: \.self) { collab in
                    Text(collab.rawValue)
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(AppTheme.card, in: Capsule())
                        .overlay(Capsule().stroke(AppTheme.accent.opacity(0.3), lineWidth: 1))
                }
            }
            
            // Availability
            if !profile.collaborationPreferences.availability.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .foregroundStyle(.secondary)
                    
                    Text(profile.collaborationPreferences.availability
                        .map { $0.rawValue.capitalized }
                        .joined(separator: ", "))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 4)
            }
        }
    }
    
    // MARK: - Interests Section
    
    private var interestsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Interests")
                .font(.headline)
            
            FlowLayout(spacing: 8) {
                ForEach(profile.interests, id: \.self) { interest in
                    Text(interest)
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(AppTheme.card, in: Capsule())
                }
            }
        }
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            // Primary Action - Message
            Button {
                showMessageSheet = true
                Haptics.impact(.medium)
            } label: {
                HStack {
                    Image(systemName: "message.fill")
                    Text("Send Message")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(AppTheme.accent, in: RoundedRectangle(cornerRadius: 14))
                .foregroundStyle(.white)
            }
            
            HStack(spacing: 12) {
                // Like Button
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        showLikeAnimation = true
                    }
                    Haptics.notify(.success)
                    
                    // Handle like action
                    Task {
                        await handleLike()
                    }
                } label: {
                    HStack {
                        Image(systemName: showLikeAnimation ? "heart.fill" : "heart")
                        Text("Like")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(showLikeAnimation ? .red : .primary)
                }
                
                // Collaborate Button
                Button {
                    Haptics.impact(.medium)
                    // Handle collaborate request
                } label: {
                    HStack {
                        Image(systemName: "person.2.fill")
                        Text("Collab")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(.primary)
                }
            }
        }
        .padding(.top, 8)
    }
    
    // MARK: - Helper Methods
    
    private func formatFollowerCount(_ count: Int) -> String {
        if count >= 1_000_000 {
            return String(format: "%.1fM", Double(count) / 1_000_000)
        } else if count >= 1_000 {
            return String(format: "%.1fK", Double(count) / 1_000)
        } else {
            return "\(count)"
        }
    }
    
    private func handleLike() async {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        let swipe = SwipeAction(
            userId: currentUserId,
            targetUserId: profile.uid,
            action: .like,
            timestamp: Date()
        )
        
        do {
            let service = FirebaseService()
            try await service.recordSwipe(swipe)
        } catch {
            print("Error recording like: \(error)")
        }
        
        // Reset animation after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showLikeAnimation = false
            }
        }
    }
}

// MARK: - Supporting Views (Private to ProfileDetailView)

private struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(AppTheme.accent)
            
            Text(value)
                .font(.headline)
            
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 12))
    }
}

// ✅ RENAMED to avoid conflicts
private struct ProfileSocialLinkRow: View {
    let platform: String
    let icon: String
    let username: String
    let followers: Int?
    let isVerified: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(AppTheme.accent)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(platform)
                        .font(.subheadline.weight(.semibold))
                    
                    if isVerified {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                }
                
                Text("@\(username)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if let followers = followers {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(formatFollowerCount(followers))
                        .font(.subheadline.weight(.semibold))
                    Text("followers")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 12))
    }
    
    private func formatFollowerCount(_ count: Int) -> String {
        if count >= 1_000_000 {
            return String(format: "%.1fM", Double(count) / 1_000_000)
        } else if count >= 1_000 {
            return String(format: "%.1fK", Double(count) / 1_000)
        } else {
            return "\(count)"
        }
    }
}

// MARK: - Message Compose View

struct MessageComposeView: View {
    let recipient: UserProfile
    @Environment(\.dismiss) var dismiss
    @State private var messageText = ""
    @State private var isSending = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Recipient Header
                HStack(spacing: 12) {
                    Circle()
                        .fill(AppTheme.gradient)
                        .frame(width: 50, height: 50)
                        .overlay {
                            Text(recipient.displayName.prefix(1))
                                .font(.title3.bold())
                                .foregroundStyle(.white)
                        }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(recipient.displayName)
                            .font(.headline)
                        Text("Usually responds \(recipient.collaborationPreferences.responseTime.displayText)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                }
                .padding()
                .background(AppTheme.card)
                
                Divider()
                
                // Message Input
                TextEditor(text: $messageText)
                    .padding()
                    .frame(minHeight: 200, maxHeight: .infinity)
                
                Spacer()
                
                // Send Button
                Button {
                    Task {
                        await sendMessage()
                    }
                } label: {
                    Text(isSending ? "Sending..." : "Send Message")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(messageText.isEmpty ? Color.gray : AppTheme.accent, in: RoundedRectangle(cornerRadius: 14))
                        .foregroundStyle(.white)
                }
                .disabled(messageText.isEmpty || isSending)
                .padding()
            }
            .navigationTitle("New Message")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func sendMessage() async {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        isSending = true
        
        // Create message
        let message = Message(
            conversationId: "\(currentUserId)_\(recipient.uid)",
            senderId: currentUserId,
            recipientId: recipient.uid,
            content: messageText,
            sentAt: Date()
        )
        
        do {
            let service = FirebaseService()
            try await service.sendMessage(message)
            Haptics.notify(.success)
            dismiss()
        } catch {
            print("Error sending message: \(error)")
            Haptics.notify(.error)
        }
        
        isSending = false
    }
}

 
