import SwiftUI
import FirebaseAuth

// MARK: - Identifiable wrapper for Int
struct IdentifiableInt: Identifiable {
    let id: Int
}

struct ProfileDetailView: View {
    let profile: UserProfile
    @Environment(\.dismiss) var dismiss
    @State private var showingMessageSheet = false
    @State private var selectedMediaIndex: IdentifiableInt?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Hero Media Section
                HeroMediaSection(
                    mediaURLs: profile.mediaURLs,
                    profileImageURL: profile.profileImageURL,
                    selectedIndex: $selectedMediaIndex
                )
                
                // Profile Content
                VStack(spacing: 20) {
                    // Name and Verification
                    ProfileHeaderInfo(profile: profile)
                    
                    // Quick Stats
                    QuickStatsRow(profile: profile)
                    
                    // Action Buttons
                    ActionButtonsRow(
                        onMessage: { showingMessageSheet = true },
                        onCollaborate: { /* Handle collab request */ }
                    )
                    
                    Divider()
                    
                    // Bio
                    if let bio = profile.bio, !bio.isEmpty {
                        BioSection(bio: bio)
                    }
                    
                    // Content Styles
                    if !profile.contentStyles.isEmpty {
                        ContentStylesDetailSection(styles: profile.contentStyles)
                    }
                    
                    // Collaboration Info
                    if !profile.collaborationPreferences.lookingFor.isEmpty {
                        CollaborationDetailSection(preferences: profile.collaborationPreferences)
                    }
                    
                    // Social Accounts
                    if hasSocialLinks(profile.socialLinks) {
                        SocialAccountsSection(socialLinks: profile.socialLinks)
                    }
                    
                    // Location
                    if let location = profile.location, location.city != nil {
                        LocationDetailSection(location: location)
                    }
                    
                    // Full Media Grid
                    if profile.mediaURLs.count > 1 {
                        FullMediaGrid(
                            mediaURLs: profile.mediaURLs,
                            selectedIndex: $selectedMediaIndex
                        )
                    }
                }
                .padding()
            }
        }
        .background(AppTheme.bg)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 2) {
                    Text(profile.displayName)
                        .font(.headline)
                    
                    if profile.isVerified {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.caption2)
                            Text("Verified Creator")
                                .font(.caption2)
                        }
                        .foregroundStyle(.blue)
                    }
                }
            }
            
            ToolbarItem(placement: .topBarTrailing) {
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
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingMessageSheet) {
            MessageComposeSheet(recipientProfile: profile)
        }
        .fullScreenCover(item: $selectedMediaIndex) { identifiableIndex in
            MediaGalleryViewer(
                mediaURLs: profile.mediaURLs,
                selectedIndex: identifiableIndex.id,
                onDismiss: { selectedMediaIndex = nil }
            )
        }
    }
    
    private func hasSocialLinks(_ links: UserProfile.SocialLinks) -> Bool {
        links.instagram != nil || links.tiktok != nil ||
        links.youtube != nil || links.twitch != nil
    }
}

// MARK: - Hero Media Section
private struct HeroMediaSection: View {
    let mediaURLs: [String]
    let profileImageURL: String?
    @Binding var selectedIndex: IdentifiableInt?
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if let firstMedia = mediaURLs.first,
               let url = URL(string: firstMedia) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(height: 400)
                            .clipped()
                    default:
                        AppTheme.gradient
                            .frame(height: 400)
                    }
                }
                .onTapGesture {
                    selectedIndex = IdentifiableInt(id: 0)
                }
            } else {
                AppTheme.gradient
                    .frame(height: 400)
            }
            
            // Gradient overlay
            LinearGradient(
                colors: [.clear, .black.opacity(0.7)],
                startPoint: .center,
                endPoint: .bottom
            )
            .frame(height: 400)
            
            // Media count indicator
            if mediaURLs.count > 1 {
                HStack(spacing: 6) {
                    Image(systemName: "photo.stack")
                    Text("\(mediaURLs.count)")
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.black.opacity(0.5), in: Capsule())
                .padding()
            }
        }
    }
}

// MARK: - Profile Header Info
private struct ProfileHeaderInfo: View {
    let profile: UserProfile
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(profile.displayName)
                            .font(.title.bold())
                        
                        if profile.isVerified {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(.blue)
                                .font(.title3)
                        }
                    }
                    
                    if let age = profile.age {
                        Text("\(age) years old")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                // Online status indicator
                if profile.isOnline {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(.green)
                            .frame(width: 8, height: 8)
                        Text("Active")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

// MARK: - Quick Stats Row
private struct QuickStatsRow: View {
    let profile: UserProfile
    
    var body: some View {
        HStack(spacing: 0) {
            QuickStatItem(
                icon: "person.2.fill",
                value: formatFollowerCount(profile.followerCount),
                label: "Followers"
            )
            
            Divider()
                .frame(height: 40)
            
            QuickStatItem(
                icon: "photo.stack.fill",
                value: "\(profile.mediaURLs.count)",
                label: "Posts"
            )
            
            Divider()
                .frame(height: 40)
            
            QuickStatItem(
                icon: "checkmark.seal.fill",
                value: "\(profile.contentStyles.count)",
                label: "Styles"
            )
        }
        .padding()
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct QuickStatItem: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundStyle(AppTheme.accent)
                .font(.title3)
            
            Text(value)
                .font(.headline)
            
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Action Buttons Row
private struct ActionButtonsRow: View {
    let onMessage: () -> Void
    let onCollaborate: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: onMessage) {
                Label("Message", systemImage: "bubble.left.and.bubble.right.fill")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppTheme.accent, in: RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(.white)
            }
            
            Button(action: onCollaborate) {
                Label("Collab", systemImage: "person.2.badge.gearshape")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(AppTheme.accent)
            }
        }
    }
}

// MARK: - Bio Section
private struct BioSection: View {
    let bio: String
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("About")
                .font(.headline)
            
            Text(bio)
                .font(.body)
                .foregroundStyle(.secondary)
                .lineLimit(isExpanded ? nil : 3)
            
            if bio.count > 150 {
                Button(isExpanded ? "Show Less" : "Show More") {
                    withAnimation {
                        isExpanded.toggle()
                    }
                }
                .font(.caption.weight(.medium))
                .foregroundStyle(AppTheme.accent)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Content Styles Detail Section
private struct ContentStylesDetailSection: View {
    let styles: [UserProfile.ContentStyle]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "star.circle.fill")
                    .foregroundStyle(AppTheme.accent)
                Text("Content Specialties")
                    .font(.headline)
            }
            
            FlowLayout(spacing: 8) {
                ForEach(styles, id: \.self) { style in
                    HStack(spacing: 8) {
                        Image(systemName: style.icon)
                        Text(style.rawValue)
                    }
                    .font(.subheadline.weight(.medium))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        LinearGradient(
                            colors: [AppTheme.accent.opacity(0.2), AppTheme.accent.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: RoundedRectangle(cornerRadius: 12)
                    )
                    .foregroundStyle(AppTheme.accent)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppTheme.accent.opacity(0.3), lineWidth: 1)
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Collaboration Detail Section
private struct CollaborationDetailSection: View {
    let preferences: UserProfile.CollaborationPreferences
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.2.badge.gearshape.fill")
                    .foregroundStyle(AppTheme.accent)
                Text("Open to Collaborate")
                    .font(.headline)
            }
            
            VStack(spacing: 12) {
                ForEach(preferences.lookingFor, id: \.self) { collab in
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.title3)
                        
                        Text(collab.rawValue)
                            .font(.subheadline.weight(.medium))
                        
                        Spacer()
                    }
                    .padding()
                    .background(AppTheme.bg, in: RoundedRectangle(cornerRadius: 10))
                }
                
                Divider()
                
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundStyle(.secondary)
                    
                    Text("Response time: \(preferences.responseTime.displayText)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                }
                .padding(.horizontal, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Social Accounts Section
private struct SocialAccountsSection: View {
    let socialLinks: UserProfile.SocialLinks
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "link.circle.fill")
                    .foregroundStyle(AppTheme.accent)
                Text("Connect on Social")
                    .font(.headline)
            }
            
            VStack(spacing: 10) {
                if let instagram = socialLinks.instagram {
                    SocialAccountRow(
                        platform: "Instagram",
                        icon: "camera.fill",
                        color: .pink,
                        username: instagram.username,
                        followerCount: instagram.followerCount,
                        isVerified: instagram.isVerified
                    )
                }
                
                if let tiktok = socialLinks.tiktok {
                    SocialAccountRow(
                        platform: "TikTok",
                        icon: "music.note",
                        color: .black,
                        username: tiktok.username,
                        followerCount: tiktok.followerCount,
                        isVerified: tiktok.isVerified
                    )
                }
                
                if let youtube = socialLinks.youtube {
                    SocialAccountRow(
                        platform: "YouTube",
                        icon: "play.rectangle.fill",
                        color: .red,
                        username: youtube.username,
                        followerCount: youtube.followerCount,
                        isVerified: youtube.isVerified
                    )
                }
                
                if let twitch = socialLinks.twitch {
                    SocialAccountRow(
                        platform: "Twitch",
                        icon: "tv.fill",
                        color: .purple,
                        username: twitch.username,
                        followerCount: twitch.followerCount,
                        isVerified: twitch.isVerified
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct SocialAccountRow: View {
    let platform: String
    let icon: String
    let color: Color
    let username: String
    let followerCount: Int?
    let isVerified: Bool
    
    var body: some View {
        Button {
            // Open social profile
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: icon)
                        .foregroundStyle(color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(platform)
                            .font(.subheadline.weight(.semibold))
                        
                        if isVerified {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.caption2)
                                .foregroundStyle(.blue)
                        }
                    }
                    
                    HStack(spacing: 4) {
                        Text("@\(username)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        if let count = followerCount {
                            Text("•")
                                .foregroundStyle(.tertiary)
                            Text("\(formatFollowerCount(count))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding()
            .background(AppTheme.bg, in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Location Detail Section
private struct LocationDetailSection: View {
    let location: UserProfile.Location
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "location.circle.fill")
                    .foregroundStyle(AppTheme.accent)
                Text("Location")
                    .font(.headline)
            }
            
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(AppTheme.accent.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundStyle(AppTheme.accent)
                }
                
                if let city = location.city, let state = location.state {
                    Text("\(city), \(state)")
                        .font(.subheadline)
                } else if let city = location.city {
                    Text(city)
                        .font(.subheadline)
                }
                
                Spacer()
            }
            .padding()
            .background(AppTheme.bg, in: RoundedRectangle(cornerRadius: 12))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Full Media Grid
private struct FullMediaGrid: View {
    let mediaURLs: [String]
    @Binding var selectedIndex: IdentifiableInt?
    
    private let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("All Content")
                .font(.headline)
            
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(Array(mediaURLs.enumerated()), id: \.offset) { index, urlString in
                    if let url = URL(string: urlString) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 120)
                                    .clipped()
                            default:
                                Rectangle()
                                    .fill(AppTheme.card)
                                    .frame(height: 120)
                            }
                        }
                        .clipShape(Rectangle())
                        .onTapGesture {
                            selectedIndex = IdentifiableInt(id: index)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Media Gallery Viewer
private struct MediaGalleryViewer: View {
    let mediaURLs: [String]
    let selectedIndex: Int
    let onDismiss: () -> Void
    
    @State private var currentIndex: Int
    
    init(mediaURLs: [String], selectedIndex: Int, onDismiss: @escaping () -> Void) {
        self.mediaURLs = mediaURLs
        self.selectedIndex = selectedIndex
        self.onDismiss = onDismiss
        _currentIndex = State(initialValue: selectedIndex)
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            TabView(selection: $currentIndex) {
                ForEach(Array(mediaURLs.enumerated()), id: \.offset) { index, urlString in
                    if let url = URL(string: urlString) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFit()
                            default:
                                ProgressView()
                            }
                        }
                        .tag(index)
                    }
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            
            VStack {
                HStack {
                    Spacer()
                    
                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(.white)
                            .padding()
                    }
                }
                
                Spacer()
            }
        }
    }
}

// MARK: - Message Compose Sheet
private struct MessageComposeSheet: View {
    let recipientProfile: UserProfile
    @Environment(\.dismiss) var dismiss
    @State private var messageText = ""
    
    var body: some View {
        NavigationStack {
            VStack {
                ScrollView {
                    VStack(spacing: 20) {
                        // Recipient info
                        HStack(spacing: 12) {
                            if let profileImageURL = recipientProfile.profileImageURL,
                               let url = URL(string: profileImageURL) {
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 50, height: 50)
                                            .clipShape(Circle())
                                    default:
                                        Circle()
                                            .fill(AppTheme.card)
                                            .frame(width: 50, height: 50)
                                    }
                                }
                            } else {
                                Circle()
                                    .fill(AppTheme.card)
                                    .frame(width: 50, height: 50)
                            }
                            
                            VStack(alignment: .leading) {
                                Text(recipientProfile.displayName)
                                    .font(.headline)
                                Text("Start a conversation")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                        }
                        .padding()
                        
                        // Message field
                        TextEditor(text: $messageText)
                            .frame(minHeight: 200)
                            .padding()
                            .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(AppTheme.accent.opacity(0.3), lineWidth: 1)
                            )
                            .padding(.horizontal)
                    }
                }
                
                // Send button
                Button {
                    // Send message
                    dismiss()
                } label: {
                    Text("Send Message")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppTheme.accent, in: RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(.white)
                }
                .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .padding()
            }
            .navigationTitle("New Message")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
