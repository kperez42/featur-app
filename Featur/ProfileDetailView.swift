// ProfileDetailView.swift - View Other Creators' Profiles
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ProfileDetailView: View {
    let profile: UserProfile
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = ProfileDetailViewModel()
    @State private var showMessageSheet = false
    @State private var showReportSheet = false
    @State private var selectedImageIndex = 0
    @State private var showImageViewer = false

    private var mediaURLs: [String] {
        if let urls = profile.mediaURLs, !urls.isEmpty {
            return urls
        } else if let profileImage = profile.profileImageURL {
            return [profileImage]
        }
        return []
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Photo Gallery Carousel
                if !mediaURLs.isEmpty {
                    ImageGalleryHeader(
                        mediaURLs: mediaURLs,
                        selectedIndex: $selectedImageIndex,
                        onTapImage: { showImageViewer = true }
                    )
                } else {
                    AppTheme.gradient
                        .frame(height: 500)
                }

                // Profile Content
                VStack(spacing: 24) {
                    // Header with Name, Verified, Online Status
                    ProfileHeaderInfo(profile: profile)

                    // Stats Row (Followers, Posts, Styles)
                    StatsRow(profile: profile)

                    // Action Buttons (Like, Message, Share)
                    ActionButtonsRow(
                        profile: profile,
                        isLiked: viewModel.isLiked,
                        onLike: { viewModel.toggleLike(profile: profile) },
                        onMessage: { showMessageSheet = true },
                        onShare: { viewModel.shareProfile(profile: profile) },
                        viewModel: viewModel
                    )

                    // Bio Section
                    if let bio = profile.bio, !bio.isEmpty {
                        BioSection(bio: bio)
                    }

                    // Looking to Collaborate Section
                    if let prefs = profile.collaborationPreferences?.lookingFor, !prefs.isEmpty {
                        CollaborationSection(preferences: prefs)
                    }

                    // Content Styles
                    if !profile.contentStyles.isEmpty {
                        ContentStylesSection(styles: profile.contentStyles)
                    }

                    // Social Links
                    if profile.socialLinks != nil {
                        SocialLinksGrid(profile: profile)
                    }

                    // Report Button
                    Button {
                        showReportSheet = true
                    } label: {
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                            Text("Report Profile")
                        }
                        .font(.caption)
                        .foregroundStyle(.red)
                    }
                    .padding(.top, 20)
                }
                .padding()
                .padding(.bottom, 100)
            }
        }
        .background(AppTheme.bg)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showMessageSheet) {
            MessageSheet(recipientProfile: profile)
        }
        .sheet(isPresented: $showReportSheet) {
            ReportSheet(profile: profile)
        }
        .sheet(isPresented: $showImageViewer) {
            ImageViewerSheet(mediaURLs: mediaURLs, selectedIndex: $selectedImageIndex)
        }
        .task {
            if let currentUserId = Auth.auth().currentUser?.uid {
                await viewModel.loadLikeStatus(currentUserId: currentUserId, targetUserId: profile.uid)
            }
        }
    }
}

// MARK: - Image Gallery Header
private struct ImageGalleryHeader: View {
    let mediaURLs: [String]
    @Binding var selectedIndex: Int
    let onTapImage: () -> Void
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedIndex) {
                ForEach(Array(mediaURLs.enumerated()), id: \.offset) { index, url in
                    AsyncImage(url: URL(string: url)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(height: 500)
                                .clipped()
                        default:
                            AppTheme.gradient
                                .frame(height: 500)
                        }
                    }
                    .tag(index)
                    .onTapGesture(perform: onTapImage)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 500)
            
            // Custom Page Indicator
            if mediaURLs.count > 1 {
                HStack(spacing: 6) {
                    ForEach(0..<mediaURLs.count, id: \.self) { index in
                        Capsule()
                            .fill(selectedIndex == index ? Color.white : Color.white.opacity(0.5))
                            .frame(width: selectedIndex == index ? 20 : 6, height: 6)
                            .animation(.spring(response: 0.3), value: selectedIndex)
                    }
                }
                .padding(.bottom, 16)
            }
        }
    }
}

// MARK: - Profile Header Info
private struct ProfileHeaderInfo: View {
    let profile: UserProfile
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(profile.displayName)
                            .font(.system(size: 32, weight: .bold))
                        
                        if profile.isVerified ?? false {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.title2)
                                .foregroundStyle(.blue)
                        }
                        
                        if PresenceManager.shared.isOnline(userId: profile.uid) {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(.green)
                                    .frame(width: 8, height: 8)
                                Text("Online")
                                    .font(.caption)
                                    .foregroundStyle(.green)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.green.opacity(0.15), in: Capsule())
                        }
                    }
                    
                    if let age = profile.age {
                        Text("\(age) years old")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
            }
        }
    }
}

// MARK: - Action Buttons Row
private struct ActionButtonsRow: View {
    let profile: UserProfile
    let isLiked: Bool
    let onLike: () -> Void
    let onMessage: () -> Void
    let onShare: () -> Void
    @ObservedObject var viewModel: ProfileDetailViewModel

    var body: some View {
        HStack(spacing: 12) {
            // Like Button
            Button(action: onLike) {
                HStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(isLiked ? .white : AppTheme.accent)
                    } else {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                        Text(isLiked ? "Liked" : "Like")
                    }
                }
                .font(.headline)
                .foregroundStyle(isLiked ? .white : AppTheme.accent)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    isLiked ? AppTheme.accent : AppTheme.card,
                    in: RoundedRectangle(cornerRadius: 16)
                )
            }
            .disabled(viewModel.isLoading)
            
            // Message Button
            Button(action: onMessage) {
                HStack {
                    Image(systemName: "message.fill")
                    Text("Message")
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(AppTheme.accent, in: RoundedRectangle(cornerRadius: 16))
            }
            
            // Share Button
            Button(action: onShare) {
                Image(systemName: "square.and.arrow.up")
                    .font(.title3)
                    .foregroundStyle(AppTheme.accent)
                    .frame(width: 56, height: 56)
                    .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
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
            
            if bio.count > 100 {
                Button(isExpanded ? "Show Less" : "Read More") {
                    withAnimation {
                        isExpanded.toggle()
                    }
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.accent)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Content Styles Section
private struct ContentStylesSection: View {
    let styles: [UserProfile.ContentStyle]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Content Styles")
                .font(.headline)
            
            FlowLayout(spacing: 10) {
                ForEach(styles, id: \.self) { style in
                    HStack(spacing: 6) {
                        Image(systemName: style.icon)
                        Text(style.rawValue)
                    }
                    .font(.subheadline.weight(.medium))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        LinearGradient(
                            colors: [AppTheme.accent.opacity(0.2), AppTheme.accent.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: Capsule()
                    )
                    .overlay(Capsule().stroke(AppTheme.accent.opacity(0.3), lineWidth: 1))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Social Links Grid
private struct SocialLinksGrid: View {
    let profile: UserProfile
    
    var socialLinks: [(platform: String, account: UserProfile.SocialLinks.SocialAccount?, icon: String, color: Color)] {
        [
            ("Instagram", profile.socialLinks?.instagram, "camera", .pink),
            ("TikTok", profile.socialLinks?.tiktok, "music.note", .black),
            ("YouTube", profile.socialLinks?.youtube, "play.rectangle", .red),
            ("Twitch", profile.socialLinks?.twitch, "gamecontroller", .purple)
        ]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Social Links")
                .font(.headline)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(socialLinks.filter { $0.account != nil }, id: \.platform) { link in
                    if let account = link.account {
                        SocialLinkCard(
                            platform: link.platform,
                            username: account.username,
                            followers: account.followerCount,
                            verified: account.isVerified,
                            icon: link.icon,
                            color: link.color
                        )
                    }
                }
            }
        }
    }
}

private struct SocialLinkCard: View {
    let platform: String
    let username: String
    let followers: Int?
    let verified: Bool
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Spacer()
                if verified {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.caption)
                        .foregroundStyle(.blue)
                }
            }

            Text(platform)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("@\(username)")
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)

            if let followers = followers {
                Text(formatNumber(followers))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Stats Row
private struct StatsRow: View {
    let profile: UserProfile

    private var postsCount: Int {
        profile.mediaURLs?.count ?? 0
    }

    private var stylesCount: Int {
        profile.contentStyles?.count ?? 0
    }

    var body: some View {
        HStack(spacing: 0) {
            // Followers
            StatItem(
                value: formatNumber(profile.followerCount ?? 0),
                label: "Followers"
            )

            Divider()
                .frame(height: 40)

            // Posts
            StatItem(
                value: "\(postsCount)",
                label: "Posts"
            )

            Divider()
                .frame(height: 40)

            // Styles
            StatItem(
                value: "\(stylesCount)",
                label: "Styles"
            )
        }
        .padding(.vertical, 16)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct StatItem: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.weight(.bold))
                .foregroundStyle(AppTheme.accent)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Collaboration Section
private struct CollaborationSection: View {
    let preferences: [UserProfile.CollaborationPreferences.CollabType]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.2.fill")
                    .foregroundStyle(AppTheme.accent)
                Text("Looking to Collaborate")
                    .font(.headline)
            }

            FlowLayout(spacing: 10) {
                ForEach(preferences, id: \.self) { type in
                    HStack(spacing: 6) {
                        Image(systemName: collabIcon(for: type))
                        Text(type.rawValue)
                    }
                    .font(.subheadline.weight(.medium))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(AppTheme.card, in: Capsule())
                    .overlay(Capsule().stroke(AppTheme.accent.opacity(0.3), lineWidth: 1))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            LinearGradient(
                colors: [AppTheme.accent.opacity(0.1), AppTheme.accent.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 16)
        )
    }

    private func collabIcon(for type: UserProfile.CollaborationPreferences.CollabType) -> String {
        switch type {
        case .twitchStream: return "gamecontroller.fill"
        case .musicCollab: return "music.note"
        case .podcastGuest: return "mic.fill"
        case .tiktokLive: return "video.fill"
        case .brandDeal: return "bag.fill"
        case .contentSeries: return "film.fill"
        }
    }
}

// MARK: - View Model
@MainActor
final class ProfileDetailViewModel: ObservableObject {
    @Published var isLiked = false
    @Published var isLoading = false

    private let service = FirebaseService()

    func loadLikeStatus(currentUserId: String, targetUserId: String) async {
        do {
            isLiked = try await service.checkLikeStatus(userId: currentUserId, targetUserId: targetUserId)
        } catch {
            print("❌ Error loading like status: \(error)")
        }
    }

    func toggleLike(profile: UserProfile) {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            print("⚠️ No current user - cannot like")
            return
        }

        // Optimistic UI update
        withAnimation(.spring(response: 0.3)) {
            isLiked.toggle()
        }
        Haptics.impact(isLiked ? .medium : .light)

        // Save to Firebase
        Task {
            isLoading = true

            do {
                if isLiked {
                    _ = try await service.saveLike(userId: currentUserId, targetUserId: profile.uid)
                } else {
                    try await service.removeLike(userId: currentUserId, targetUserId: profile.uid)
                }
            } catch {
                print("❌ Error toggling like: \(error)")
                // Revert UI on error
                withAnimation {
                    isLiked.toggle()
                }
            }

            isLoading = false
        }
    }

    func shareProfile(profile: UserProfile) {
        Haptics.impact(.light)

        // Create shareable content
        let profileURL = URL(string: "https://featur.app/profile/\(profile.uid)")!
        let shareText = "Check out \(profile.displayName) on Featur! 🎬"

        // Present iOS share sheet
        let activityVC = UIActivityViewController(
            activityItems: [shareText, profileURL],
            applicationActivities: nil
        )

        // For iPad compatibility
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {

            // Find the topmost view controller
            var topVC = rootVC
            while let presented = topVC.presentedViewController {
                topVC = presented
            }

            // For iPad - set popover presentation controller
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = topVC.view
                popover.sourceRect = CGRect(x: topVC.view.bounds.midX, y: topVC.view.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }

            topVC.present(activityVC, animated: true)
        }
    }

}

// MARK: - Message Sheet
struct MessageSheet: View {
    let recipientProfile: UserProfile
    @Environment(\.dismiss) var dismiss
    @State private var messageText = ""
    @State private var isSending = false
    @State private var showError = false
    @State private var errorMessage = ""

    private let service = FirebaseService()

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Recipient Info
                VStack(spacing: 12) {
                    if let imageURL = recipientProfile.profileImageURL, let url = URL(string: imageURL) {
                        AsyncImage(url: url) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            Color.gray
                        }
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                    }
                    
                    Text(recipientProfile.displayName)
                        .font(.headline)
                }
                .padding(.top, 20)
                
                // Message Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Message")
                        .font(.subheadline.weight(.semibold))
                    
                    TextEditor(text: $messageText)
                        .frame(height: 150)
                        .padding(8)
                        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                }
                .padding(.horizontal)
                
                Spacer()
                
                Button {
                    Task {
                        await sendMessage()
                    }
                } label: {
                    HStack {
                        if isSending {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Send Message")
                                .font(.headline)
                        }
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppTheme.accent, in: RoundedRectangle(cornerRadius: 16))
                }
                .disabled(messageText.isEmpty || isSending)
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .background(AppTheme.bg)
            .navigationTitle("New Message")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    private func sendMessage() async {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            errorMessage = "Please sign in to send messages"
            showError = true
            return
        }

        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }

        isSending = true

        do {
            // Get or create conversation
            let conversation = try await service.getOrCreateConversation(
                between: currentUserId,
                and: recipientProfile.uid
            )

            guard let conversationId = conversation.id else {
                throw NSError(domain: "MessageSheet", code: -1,
                             userInfo: [NSLocalizedDescriptionKey: "Conversation ID not found"])
            }

            // Create and send message
            let message = Message(
                id: UUID().uuidString,
                conversationId: conversationId,
                senderId: currentUserId,
                recipientId: recipientProfile.uid,
                content: messageText.trimmingCharacters(in: .whitespacesAndNewlines),
                mediaURL: nil,
                sentAt: Date(),
                readAt: nil
            )

            try await service.sendMessage(message)

            // Mark match as messaged
            await service.markMatchAsMessaged(userA: currentUserId, userB: recipientProfile.uid)

            print("✅ Message sent successfully to \(recipientProfile.displayName)")

            // Dismiss on success
            isSending = false
            dismiss()

        } catch {
            isSending = false
            errorMessage = "Failed to send message: \(error.localizedDescription)"
            showError = true
            print("❌ Error sending message: \(error)")
        }
    }
}

// MARK: - Report Sheet
struct ReportSheet: View {
    let profile: UserProfile
    @Environment(\.dismiss) var dismiss
    @State private var selectedReason = ""
    @State private var details = ""
    @State private var isSubmitting = false
    @State private var showError = false
    @State private var errorMessage = ""

    private let service = FirebaseService()

    let reasons = [
        "Inappropriate content",
        "Spam or scam",
        "Harassment",
        "Fake profile",
        "Other"
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Reason") {
                    Picker("Select a reason", selection: $selectedReason) {
                        Text("Select...").tag("")
                        ForEach(reasons, id: \.self) { reason in
                            Text(reason).tag(reason)
                        }
                    }
                }
                
                Section("Additional Details") {
                    TextEditor(text: $details)
                        .frame(height: 100)
                }
            }
            .navigationTitle("Report Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Submit") {
                        Task {
                            await submitReport()
                        }
                    }
                    .disabled(selectedReason.isEmpty || isSubmitting)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    private func submitReport() async {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }

        isSubmitting = true
        defer { isSubmitting = false }

        do {
            // Create report document in Firestore
            let report: [String: Any] = [
                "reportedUserId": profile.uid,
                "reportedBy": currentUserId,
                "reason": selectedReason,
                "details": details,
                "timestamp": FieldValue.serverTimestamp(),
                "status": "pending"
            ]

            try await Firestore.firestore().collection("reports").addDocument(data: report)

            print("✅ Report submitted successfully")

            // Track analytics
            AnalyticsManager.shared.trackError(error: "profile_reported", context: selectedReason)

            Haptics.notify(.success)
            dismiss()

        } catch {
            errorMessage = "Failed to submit report: \(error.localizedDescription)"
            showError = true
            print("❌ Error submitting report: \(error)")
        }
    }
}

// MARK: - Image Viewer Sheet
struct ImageViewerSheet: View {
    let mediaURLs: [String]
    @Binding var selectedIndex: Int
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            TabView(selection: $selectedIndex) {
                ForEach(Array(mediaURLs.enumerated()), id: \.offset) { index, url in
                    AsyncImage(url: URL(string: url)) { phase in
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
            .tabViewStyle(.page(indexDisplayMode: .always))
            
            VStack {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
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

// MARK: - Utilities
private func formatNumber(_ number: Int) -> String {
    if number >= 1_000_000 {
        return String(format: "%.1fM", Double(number) / 1_000_000)
    } else if number >= 1_000 {
        return String(format: "%.1fK", Double(number) / 1_000)
    }
    return "\(number)"
}
