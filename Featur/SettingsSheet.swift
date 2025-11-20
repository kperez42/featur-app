// SettingsSheet.swift - Premium Settings Page
import SwiftUI
import FirebaseAuth
import UserNotifications
import PhotosUI
import FirebaseFirestore

struct SettingsSheet: View {
    @EnvironmentObject var auth: AuthViewModel
    @StateObject private var viewModel = SettingsViewModel()
    @Environment(\.dismiss) var dismiss
    
    @State private var showDeleteConfirmation = false
    @State private var showLogoutConfirmation = false
    @State private var showBlockedUsers = false
    @State private var showPrivacyPolicy = false
    @State private var showTerms = false
    
    var body: some View {
        NavigationStack {
            List {
                // Account Section
                Section {
                    NavigationLink {
                        EditAccountView()
                    } label: {
                        SettingRow(icon: "person.circle", title: "Edit Profile", color: .blue)
                    }
                    
                    NavigationLink {
                        ChangePasswordView()
                    } label: {
                        SettingRow(icon: "lock.shield", title: "Change Password", color: .green)
                    }
                    
                    NavigationLink {
                        BlockedUsersView()
                    } label: {
                        SettingRow(icon: "hand.raised.fill", title: "Blocked Users", color: .red)
                    }
                } header: {
                    Text("Account")
                } footer: {
                    if let email = Auth.auth().currentUser?.email {
                        Text("Signed in as \(email)")
                    }
                }
                
                // Privacy Section
                Section("Privacy") {
                    NavigationLink {
                        PrivacySettingsView()
                    } label: {
                        SettingRow(icon: "eye.slash", title: "Privacy Settings", color: .purple)
                    }
                    
                    Toggle(isOn: $viewModel.profileVisible) {
                        SettingRow(icon: "person.fill.viewfinder", title: "Profile Visible", color: .orange)
                    }
                    
                    Toggle(isOn: $viewModel.showOnlineStatus) {
                        SettingRow(icon: "circle.fill", title: "Show Online Status", color: .green)
                    }
                    
                    Toggle(isOn: $viewModel.allowMessagesFromAnyone) {
                        SettingRow(icon: "message.fill", title: "Messages from Anyone", color: .blue)
                    }
                }
                
                // Notifications Section
                Section("Notifications") {
                    NavigationLink {
                        NotificationSettingsView()
                    } label: {
                        SettingRow(icon: "bell.badge", title: "Notification Preferences", color: .red)
                    }
                    
                    Toggle(isOn: $viewModel.pushNotifications) {
                        SettingRow(icon: "bell.fill", title: "Push Notifications", color: .orange)
                    }
                    .onChange(of: viewModel.pushNotifications) { _, newValue in
                        viewModel.updateNotificationPermissions(enabled: newValue)
                    }
                    
                    Toggle(isOn: $viewModel.emailNotifications) {
                        SettingRow(icon: "envelope.fill", title: "Email Notifications", color: .blue)
                    }
                }
                
                // Discovery Section
                Section("Discovery") {
                    Toggle(isOn: $viewModel.appearsInDiscovery) {
                        SettingRow(icon: "magnifyingglass", title: "Appear in Discovery", color: .purple)
                    }
                    
                    NavigationLink {
                        DiscoveryPreferencesView()
                    } label: {
                        SettingRow(icon: "slider.horizontal.3", title: "Discovery Preferences", color: .pink)
                    }
                }
                
                // Content Section
                Section("Content") {
                    NavigationLink {
                        ContentPreferencesView()
                    } label: {
                        SettingRow(icon: "square.grid.3x3", title: "Content Preferences", color: .indigo)
                    }
                    
                    Toggle(isOn: $viewModel.autoplayVideos) {
                        SettingRow(icon: "play.circle", title: "Autoplay Videos", color: .blue)
                    }
                    
                    Toggle(isOn: $viewModel.highQualityUploads) {
                        SettingRow(icon: "photo", title: "High Quality Uploads", color: .green)
                    }
                }
                
                // App Settings Section
                Section("App") {
                    NavigationLink {
                        AppearanceSettingsView()
                    } label: {
                        SettingRow(icon: "paintbrush", title: "Appearance", color: .cyan)
                    }
                    
                    NavigationLink {
                        LanguageSettingsView()
                    } label: {
                        SettingRow(icon: "globe", title: "Language", color: .green)
                    }
                    
                    NavigationLink {
                        DataUsageView()
                    } label: {
                        SettingRow(icon: "chart.bar", title: "Data Usage", color: .orange)
                    }
                }
                
                // Support Section
                Section("Support") {
                    Button {
                        viewModel.openHelpCenter()
                    } label: {
                        SettingRow(icon: "questionmark.circle", title: "Help Center", color: .blue)
                    }
                    
                    Button {
                        viewModel.contactSupport()
                    } label: {
                        SettingRow(icon: "envelope", title: "Contact Support", color: .green)
                    }
                    
                    Button {
                        viewModel.reportProblem()
                    } label: {
                        SettingRow(icon: "exclamationmark.triangle", title: "Report a Problem", color: .orange)
                    }
                }
                
                // Legal Section
                Section("Legal") {
                    Button {
                        showPrivacyPolicy = true
                    } label: {
                        SettingRow(icon: "doc.text", title: "Privacy Policy", color: .gray)
                    }
                    
                    Button {
                        showTerms = true
                    } label: {
                        SettingRow(icon: "doc.text", title: "Terms of Service", color: .gray)
                    }
                    
                    Button {
                        Task {
                            await viewModel.requestDataExport()
                        }
                    } label: {
                        SettingRow(icon: "arrow.down.doc", title: "Download My Data", color: .blue)
                    }
                }
                
                // About Section
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(viewModel.appVersion)
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Build")
                        Spacer()
                        Text(viewModel.buildNumber)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("About")
                }
                
                // Danger Zone
                Section {
                    Button(role: .destructive) {
                        showLogoutConfirmation = true
                    } label: {
                        SettingRow(icon: "rectangle.portrait.and.arrow.right", title: "Sign Out", color: .red)
                    }
                    
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        SettingRow(icon: "trash", title: "Delete Account", color: .red)
                    }
                } header: {
                    Text("Danger Zone")
                } footer: {
                    Text("Deleting your account is permanent and cannot be undone.")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .confirmationDialog("Sign Out", isPresented: $showLogoutConfirmation) {
                Button("Sign Out", role: .destructive) {
                    Task {
                        await auth.signOut()
                        dismiss()
                    }
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .confirmationDialog("Delete Account", isPresented: $showDeleteConfirmation) {
                Button("Delete Account", role: .destructive) {
                    Task {
                        await viewModel.deleteAccount()
                        await auth.signOut()
                        dismiss()
                    }
                }
            } message: {
                Text("This action cannot be undone. All your data will be permanently deleted.")
            }
            .sheet(isPresented: $showPrivacyPolicy) {
                WebViewSheet(url: "https://featur.app/privacy", title: "Privacy Policy")
            }
            .sheet(isPresented: $showTerms) {
                WebViewSheet(url: "https://featur.app/terms", title: "Terms of Service")
            }
        }
    }
}

// MARK: - Setting Row
private struct SettingRow: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(color)
                .frame(width: 28, height: 28)
                .background(color.opacity(0.15), in: RoundedRectangle(cornerRadius: 6))
            
            Text(title)
        }
    }
}

// MARK: - Settings View Model
@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var profileVisible = true
    @Published var showOnlineStatus = true
    @Published var allowMessagesFromAnyone = true
    @Published var pushNotifications = true
    @Published var emailNotifications = true
    @Published var appearsInDiscovery = true
    @Published var autoplayVideos = true
    @Published var highQualityUploads = false
    
    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    func updateNotificationPermissions(enabled: Bool) {
        if enabled {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
                DispatchQueue.main.async {
                    self.pushNotifications = granted
                }
            }
        }
    }
    
    func deleteAccount() async {
        print("🗑️ Deleting account...")

        guard let currentUser = Auth.auth().currentUser else {
            print("⚠️ No user logged in")
            return
        }

        let userId = currentUser.uid

        do {
            // Step 1: Delete user data from Firestore
            let service = FirebaseService()
            let db = Firestore.firestore()

            // Get user profile to retrieve media URLs before deletion
            var mediaURLsToDelete: [String] = []
            if let userProfile = try? await service.fetchProfile(uid: userId) {
                // Collect profile photo URL
                if let profileImageURL = userProfile.profileImageURL {
                    mediaURLsToDelete.append(profileImageURL)
                }
                // Collect gallery media URLs
                if let mediaURLs = userProfile.mediaURLs {
                    mediaURLsToDelete.append(contentsOf: mediaURLs)
                }
            }

            // Delete user profile
            try await db.collection("users").document(userId).delete()
            print("✅ Deleted user profile")

            // Delete swipes
            let swipes = try await db.collection("swipes")
                .whereField("userId", isEqualTo: userId)
                .getDocuments()
            for doc in swipes.documents {
                try await doc.reference.delete()
            }
            print("✅ Deleted \(swipes.documents.count) swipes")

            // Delete matches
            let matches1 = try await db.collection("matches")
                .whereField("userId1", isEqualTo: userId)
                .getDocuments()
            let matches2 = try await db.collection("matches")
                .whereField("userId2", isEqualTo: userId)
                .getDocuments()
            for doc in matches1.documents + matches2.documents {
                try await doc.reference.delete()
            }
            print("✅ Deleted \(matches1.documents.count + matches2.documents.count) matches")

            // Delete conversations and messages
            let conversations = try await db.collection("conversations")
                .whereField("participantIds", arrayContains: userId)
                .getDocuments()
            for conv in conversations.documents {
                // Delete messages in this conversation
                if let convId = conv.documentID as String? {
                    let messages = try await db.collection("messages")
                        .whereField("conversationId", isEqualTo: convId)
                        .getDocuments()
                    for msg in messages.documents {
                        try await msg.reference.delete()
                    }
                }
                // Delete conversation
                try await conv.reference.delete()
            }
            print("✅ Deleted \(conversations.documents.count) conversations")

            // Step 2: Delete all media from Firebase Storage
            if !mediaURLsToDelete.isEmpty {
                for url in mediaURLsToDelete {
                    do {
                        try await service.deleteMedia(url: url)
                    } catch {
                        // Log error but don't fail the whole deletion
                        print("⚠️ Failed to delete media (non-critical): \(url)")
                    }
                }
                print("✅ Deleted \(mediaURLsToDelete.count) media files from Storage")
            }

            // Step 3: Delete Firebase Auth account
            try await currentUser.delete()
            print("✅ Deleted Firebase Auth account")

            // Track analytics before deletion completes
            AnalyticsManager.shared.trackAccountDeletion(reason: nil)

            print("✅ Account deletion completed successfully")

        } catch {
            print("❌ Error deleting account: \(error)")
            // Note: Error is logged but not thrown since this is called from UI
        }
    }
    
    func openHelpCenter() {
        if let url = URL(string: "https://featur.app/help") {
            UIApplication.shared.open(url)
        }
    }
    
    func contactSupport() {
        if let url = URL(string: "mailto:support@featur.app") {
            UIApplication.shared.open(url)
        }
    }
    
    func reportProblem() {
        if let url = URL(string: "https://featur.app/report") {
            UIApplication.shared.open(url)
        }
    }
    
    func requestDataExport() async {
        print("📦 Requesting data export...")

        guard let currentUser = Auth.auth().currentUser else {
            print("⚠️ No user logged in")
            return
        }

        let userId = currentUser.uid

        do {
            let service = FirebaseService()
            let db = Firestore.firestore()

            // Collect all user data
            var exportData: [String: Any] = [:]

            // User profile
            if let profile = try await service.fetchProfile(uid: userId) {
                // Break up complex expression for faster type-checking
                let locationData: [String: String] = [
                    "city": profile.location?.city ?? "",
                    "state": profile.location?.state ?? "",
                    "country": profile.location?.country ?? ""
                ]

                let contentStylesArray = profile.contentStyles.map { $0.rawValue }
                let formatter = ISO8601DateFormatter()
                let createdAtString = formatter.string(from: profile.createdAt)
                let updatedAtString = formatter.string(from: profile.updatedAt)

                var profileData: [String: Any] = [:]
                profileData["uid"] = profile.uid
                profileData["displayName"] = profile.displayName
                profileData["age"] = profile.age ?? "N/A"
                profileData["bio"] = profile.bio ?? ""
                profileData["location"] = locationData
                profileData["interests"] = profile.interests ?? []
                profileData["contentStyles"] = contentStylesArray
                profileData["isVerified"] = profile.isVerified ?? false
                profileData["followerCount"] = profile.followerCount ?? 0
                profileData["createdAt"] = createdAtString
                profileData["updatedAt"] = updatedAtString

                exportData["profile"] = profileData
            }

            // Swipe history
            let swipes = try await db.collection("swipes")
                .whereField("userId", isEqualTo: userId)
                .getDocuments()
            exportData["swipes"] = swipes.documents.map { doc in
                var data = doc.data()
                data["documentId"] = doc.documentID
                return data
            }

            // Matches
            let matches = try await service.fetchMatches(forUser: userId)
            exportData["matches"] = matches.map { match in
                [
                    "matchId": match.id ?? "",
                    "userId1": match.userId1,
                    "userId2": match.userId2,
                    "matchedAt": ISO8601DateFormatter().string(from: match.matchedAt),
                    "hasMessaged": match.hasMessaged
                ]
            }

            // Conversations
            let conversations = try await service.fetchConversations(forUser: userId)
            exportData["conversations"] = conversations.map { conv in
                [
                    "conversationId": conv.id ?? "",
                    "participants": conv.participantIds,
                    "lastMessage": conv.lastMessage ?? "",
                    "lastMessageAt": ISO8601DateFormatter().string(from: conv.lastMessageAt),
                    "createdAt": ISO8601DateFormatter().string(from: conv.createdAt)
                ]
            }

            // Convert to JSON
            let jsonData = try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)

            // Save to file
            let fileName = "featur_data_export_\(ISO8601DateFormatter().string(from: Date())).json"
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
            try jsonData.write(to: tempURL)

            // Present share sheet to export
            let activityVC = UIActivityViewController(
                activityItems: [tempURL],
                applicationActivities: nil
            )

            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootVC = window.rootViewController {

                var topVC = rootVC
                while let presented = topVC.presentedViewController {
                    topVC = presented
                }

                if let popover = activityVC.popoverPresentationController {
                    popover.sourceView = topVC.view
                    popover.sourceRect = CGRect(x: topVC.view.bounds.midX, y: topVC.view.bounds.midY, width: 0, height: 0)
                    popover.permittedArrowDirections = []
                }

                topVC.present(activityVC, animated: true)
            }

            // Track analytics
            AnalyticsManager.shared.trackDataExport()

            print("✅ Data export prepared successfully")

        } catch {
            print("❌ Error exporting data: \(error)")
        }
    }
}

// MARK: - Privacy Settings View
struct PrivacySettingsView: View {
    @StateObject private var viewModel = PrivacySettingsViewModel()
    
    var body: some View {
        List {
            Section {
                Picker("Who can see my profile", selection: $viewModel.profileVisibility) {
                    Text("Everyone").tag(0)
                    Text("Matches Only").tag(1)
                    Text("Nobody").tag(2)
                }
                
                Picker("Who can message me", selection: $viewModel.messagePrivacy) {
                    Text("Everyone").tag(0)
                    Text("Matches Only").tag(1)
                    Text("Nobody").tag(2)
                }
            } header: {
                Text("Privacy Controls")
            }
            
            Section {
                Toggle("Show my location", isOn: $viewModel.showLocation)
                Toggle("Show my last active", isOn: $viewModel.showLastActive)
                Toggle("Show my social links", isOn: $viewModel.showSocialLinks)
            } header: {
                Text("Profile Information")
            }
            
            Section {
                Toggle("Appears in search results", isOn: $viewModel.searchable)
                Toggle("Recommend my profile", isOn: $viewModel.recommendable)
            } header: {
                Text("Discovery")
            }
        }
        .navigationTitle("Privacy Settings")
    }
}

@MainActor
final class PrivacySettingsViewModel: ObservableObject {
    @Published var profileVisibility = 0
    @Published var messagePrivacy = 0
    @Published var showLocation = true
    @Published var showLastActive = true
    @Published var showSocialLinks = true
    @Published var searchable = true
    @Published var recommendable = true
}

// MARK: - Notification Settings View
struct NotificationSettingsView: View {
    @StateObject private var viewModel = NotificationSettingsViewModel()
    
    var body: some View {
        List {
            Section {
                Toggle("New matches", isOn: $viewModel.newMatches)
                Toggle("New messages", isOn: $viewModel.newMessages)
                Toggle("Message replies", isOn: $viewModel.messageReplies)
            } header: {
                Text("Messages & Matches")
            }
            
            Section {
                Toggle("New followers", isOn: $viewModel.newFollowers)
                Toggle("Profile views", isOn: $viewModel.profileViews)
                Toggle("Likes", isOn: $viewModel.likes)
            } header: {
                Text("Activity")
            }
            
            Section {
                Toggle("Collaboration requests", isOn: $viewModel.collabRequests)
                Toggle("Event invitations", isOn: $viewModel.eventInvites)
            } header: {
                Text("Opportunities")
            }
            
            Section {
                Toggle("Featured", isOn: $viewModel.featured)
                Toggle("Tips & tricks", isOn: $viewModel.tips)
                Toggle("Product updates", isOn: $viewModel.updates)
            } header: {
                Text("From FEATUR")
            }
        }
        .navigationTitle("Notifications")
    }
}

@MainActor
final class NotificationSettingsViewModel: ObservableObject {
    @Published var newMatches = true
    @Published var newMessages = true
    @Published var messageReplies = true
    @Published var newFollowers = true
    @Published var profileViews = false
    @Published var likes = true
    @Published var collabRequests = true
    @Published var eventInvites = true
    @Published var featured = true
    @Published var tips = false
    @Published var updates = true
}

// MARK: - Supporting Views
struct EditAccountView: View {
    @EnvironmentObject var auth: AuthViewModel
    @StateObject private var viewModel = EditAccountViewModel()

    var body: some View {
        Form {
            // Profile Photo Section
            Section {
                HStack {
                    Spacer()
                    VStack(spacing: 16) {
                        // Profile Image Display
                        ZStack(alignment: .bottomTrailing) {
                            if let selectedImage = viewModel.selectedImage {
                                selectedImage
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 120, height: 120)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.gray.opacity(0.2), lineWidth: 2))
                            } else if let photoURL = auth.userProfile?.profileImageURL,
                                      !photoURL.isEmpty {
                                AsyncImage(url: URL(string: photoURL)) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                } placeholder: {
                                    Image(systemName: "person.circle.fill")
                                        .resizable()
                                        .foregroundStyle(.gray)
                                }
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.gray.opacity(0.2), lineWidth: 2))
                            } else {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .foregroundStyle(.gray)
                                    .frame(width: 120, height: 120)
                            }

                            // Upload indicator
                            if viewModel.isUploading {
                                ProgressView()
                                    .tint(.white)
                                    .padding(8)
                                    .background(.blue, in: Circle())
                            } else {
                                Image(systemName: "camera.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundStyle(.white)
                                    .background(Circle().fill(.blue))
                                    .overlay(Circle().stroke(.white, lineWidth: 2))
                            }
                        }

                        PhotosPicker(selection: $viewModel.photoSelection,
                                   matching: .images,
                                   photoLibrary: .shared()) {
                            Text(viewModel.selectedImage == nil ? "Change Photo" : "Update Photo")
                                .font(.subheadline.bold())
                                .foregroundStyle(.blue)
                        }
                        .disabled(viewModel.isUploading)

                        if viewModel.selectedImage != nil {
                            HStack(spacing: 12) {
                                Button("Cancel") {
                                    viewModel.cancelSelection()
                                }
                                .buttonStyle(.bordered)

                                Button("Upload") {
                                    Task {
                                        await viewModel.uploadPhoto()
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                                .disabled(viewModel.isUploading)
                            }
                        }
                    }
                    Spacer()
                }
                .listRowBackground(Color.clear)
            } header: {
                Text("Profile Photo")
            } footer: {
                if let message = viewModel.statusMessage {
                    Text(message)
                        .foregroundStyle(viewModel.uploadSuccess ? .green : .red)
                        .font(.caption)
                }
            }

            // Account Info Section
            Section {
                HStack {
                    Text("Email")
                    Spacer()
                    Text(Auth.auth().currentUser?.email ?? "N/A")
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("User ID")
                    Spacer()
                    Text(auth.userProfile?.uid.prefix(8) ?? "N/A")
                        .foregroundStyle(.secondary)
                        .font(.caption.monospaced())
                }

                HStack {
                    Text("Account Created")
                    Spacer()
                    if let created = Auth.auth().currentUser?.metadata.creationDate {
                        Text(created.formatted(date: .abbreviated, time: .omitted))
                            .foregroundStyle(.secondary)
                    } else {
                        Text("N/A")
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Account Information")
            }

            // Display Name Section
            Section {
                TextField("Display Name", text: $viewModel.displayName)
                    .textInputAutocapitalization(.words)

                if viewModel.displayName != (auth.userProfile?.displayName ?? "") {
                    Button("Save Changes") {
                        Task {
                            await viewModel.updateDisplayName()
                        }
                    }
                    .disabled(viewModel.displayName.isEmpty || viewModel.isUpdating)
                }
            } header: {
                Text("Profile Information")
            }

            // Social Links Section
            Section {
                // Instagram
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: "camera")
                            .foregroundStyle(.pink)
                            .frame(width: 28)
                        Text("Instagram")
                            .font(.subheadline.weight(.semibold))
                    }

                    TextField("Username", text: $viewModel.instagramUsername)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    TextField("Follower count", text: $viewModel.instagramFollowers)
                        .keyboardType(.numberPad)

                    Toggle("Verified", isOn: $viewModel.instagramVerified)
                }
                .padding(.vertical, 4)

                Divider()

                // TikTok
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: "music.note")
                            .foregroundStyle(.black)
                            .frame(width: 28)
                        Text("TikTok")
                            .font(.subheadline.weight(.semibold))
                    }

                    TextField("Username", text: $viewModel.tiktokUsername)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    TextField("Follower count", text: $viewModel.tiktokFollowers)
                        .keyboardType(.numberPad)

                    Toggle("Verified", isOn: $viewModel.tiktokVerified)
                }
                .padding(.vertical, 4)

                Divider()

                // YouTube
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: "play.rectangle")
                            .foregroundStyle(.red)
                            .frame(width: 28)
                        Text("YouTube")
                            .font(.subheadline.weight(.semibold))
                    }

                    TextField("Username", text: $viewModel.youtubeUsername)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    TextField("Subscriber count", text: $viewModel.youtubeFollowers)
                        .keyboardType(.numberPad)

                    Toggle("Verified", isOn: $viewModel.youtubeVerified)
                }
                .padding(.vertical, 4)

                Divider()

                // Twitch
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: "gamecontroller")
                            .foregroundStyle(.purple)
                            .frame(width: 28)
                        Text("Twitch")
                            .font(.subheadline.weight(.semibold))
                    }

                    TextField("Username", text: $viewModel.twitchUsername)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    TextField("Follower count", text: $viewModel.twitchFollowers)
                        .keyboardType(.numberPad)

                    Toggle("Verified", isOn: $viewModel.twitchVerified)
                }
                .padding(.vertical, 4)

                // Save Social Links Button
                if viewModel.socialLinksChanged {
                    Button("Save Social Links") {
                        Task {
                            await viewModel.updateSocialLinks()
                        }
                    }
                    .disabled(viewModel.isUpdatingSocials)
                }
            } header: {
                Text("Social Links")
            } footer: {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your social links will be shown as non-clickable text for credibility. Users won't be redirected outside the app.")
                    if let message = viewModel.socialsStatusMessage {
                        Text(message)
                            .foregroundStyle(viewModel.socialsUpdateSuccess ? .green : .red)
                    }
                }
                .font(.caption)
            }

            // Media Gallery Section
            Section {
                // Gallery Grid
                if let mediaURLs = auth.userProfile?.mediaURLs, !mediaURLs.isEmpty {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(Array(mediaURLs.enumerated()), id: \.offset) { index, url in
                            ZStack(alignment: .topTrailing) {
                                AsyncImage(url: URL(string: url)) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                } placeholder: {
                                    Rectangle()
                                        .fill(.gray.opacity(0.2))
                                }
                                .frame(height: 100)
                                .clipped()
                                .cornerRadius(8)

                                // Delete button
                                Button {
                                    Task {
                                        await viewModel.deleteMedia(at: index)
                                    }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.title3)
                                        .foregroundStyle(.white)
                                        .background(Circle().fill(.red))
                                }
                                .padding(4)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }

                // Upload new media
                PhotosPicker(selection: $viewModel.mediaSelections,
                           maxSelectionCount: 6,
                           matching: .images,
                           photoLibrary: .shared()) {
                    HStack {
                        Image(systemName: "photo.on.rectangle.angled")
                            .foregroundStyle(.blue)
                        Text("Add Photos to Gallery")
                        Spacer()
                        if viewModel.isUploadingMedia {
                            ProgressView()
                        } else {
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .disabled(viewModel.isUploadingMedia || (auth.userProfile?.mediaURLs?.count ?? 0) >= 6)

                if viewModel.isUploadingMedia {
                    HStack {
                        Text("Uploading \(viewModel.uploadProgress.0) of \(viewModel.uploadProgress.1)...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        ProgressView(value: Double(viewModel.uploadProgress.0), total: Double(viewModel.uploadProgress.1))
                            .frame(width: 100)
                    }
                }
            } header: {
                Text("Media Gallery")
            } footer: {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Add up to 6 photos to showcase your content")
                    if let message = viewModel.mediaStatusMessage {
                        Text(message)
                            .foregroundStyle(viewModel.mediaUploadSuccess ? .green : .red)
                    }
                }
                .font(.caption)
            }
        }
        .navigationTitle("Edit Account")
        .onAppear {
            viewModel.auth = auth
            viewModel.displayName = auth.userProfile?.displayName ?? ""
            viewModel.loadSocialLinks()
        }
        .alert("Upload Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "Unknown error occurred")
        }
    }
}

@MainActor
final class EditAccountViewModel: ObservableObject {
    @Published var photoSelection: PhotosPickerItem?
    @Published var selectedImage: Image?
    @Published var isUploading = false
    @Published var uploadSuccess = false
    @Published var statusMessage: String?
    @Published var showError = false
    @Published var errorMessage: String?
    @Published var displayName = ""
    @Published var isUpdating = false

    // Media gallery properties
    @Published var mediaSelections: [PhotosPickerItem] = []
    @Published var isUploadingMedia = false
    @Published var mediaUploadSuccess = false
    @Published var mediaStatusMessage: String?
    @Published var uploadProgress: (Int, Int) = (0, 0)

    // Social links properties
    @Published var instagramUsername = ""
    @Published var instagramFollowers = ""
    @Published var instagramVerified = false
    @Published var tiktokUsername = ""
    @Published var tiktokFollowers = ""
    @Published var tiktokVerified = false
    @Published var youtubeUsername = ""
    @Published var youtubeFollowers = ""
    @Published var youtubeVerified = false
    @Published var twitchUsername = ""
    @Published var twitchFollowers = ""
    @Published var twitchVerified = false
    @Published var isUpdatingSocials = false
    @Published var socialsUpdateSuccess = false
    @Published var socialsStatusMessage: String?

    var socialLinksChanged: Bool {
        guard let profile = auth?.userProfile else { return false }

        let currentInstagram = profile.socialLinks?.instagram
        let currentTikTok = profile.socialLinks?.tiktok
        let currentYouTube = profile.socialLinks?.youtube
        let currentTwitch = profile.socialLinks?.twitch

        return instagramUsername != (currentInstagram?.username ?? "") ||
               instagramFollowers != (currentInstagram?.followerCount.map(String.init) ?? "") ||
               instagramVerified != (currentInstagram?.isVerified ?? false) ||
               tiktokUsername != (currentTikTok?.username ?? "") ||
               tiktokFollowers != (currentTikTok?.followerCount.map(String.init) ?? "") ||
               tiktokVerified != (currentTikTok?.isVerified ?? false) ||
               youtubeUsername != (currentYouTube?.username ?? "") ||
               youtubeFollowers != (currentYouTube?.followerCount.map(String.init) ?? "") ||
               youtubeVerified != (currentYouTube?.isVerified ?? false) ||
               twitchUsername != (currentTwitch?.username ?? "") ||
               twitchFollowers != (currentTwitch?.followerCount.map(String.init) ?? "") ||
               twitchVerified != (currentTwitch?.isVerified ?? false)
    }

    var auth: AuthViewModel?
    private var selectedImageData: Data?
    private let service = FirebaseService()

    init() {
        // Watch for photo selection changes
        Task {
            for await selection in $photoSelection.values {
                await handlePhotoSelection(selection)
            }
        }

        // Watch for media gallery selection changes
        Task {
            for await selections in $mediaSelections.values {
                await handleMediaSelections(selections)
            }
        }
    }

    private func handlePhotoSelection(_ selection: PhotosPickerItem?) async {
        guard let selection = selection else { return }

        do {
            // Load the image data
            guard let data = try await selection.loadTransferable(type: Data.self) else {
                statusMessage = "Failed to load image"
                return
            }

            // Validate image size (max 10MB)
            let maxSize = 10 * 1024 * 1024 // 10MB
            if data.count > maxSize {
                statusMessage = "Image too large. Please select an image under 10MB."
                return
            }

            selectedImageData = data

            // Create SwiftUI Image for preview
            if let uiImage = UIImage(data: data) {
                selectedImage = Image(uiImage: uiImage)
                statusMessage = "Ready to upload"
                uploadSuccess = false
            }
        } catch {
            print("❌ Error loading photo: \(error)")
            statusMessage = "Failed to load image"
        }
    }

    func cancelSelection() {
        photoSelection = nil
        selectedImage = nil
        selectedImageData = nil
        statusMessage = nil
        uploadSuccess = false
    }

    func uploadPhoto() async {
        guard let imageData = selectedImageData,
              let userId = Auth.auth().currentUser?.uid else {
            statusMessage = "No image selected or user not found"
            return
        }

        isUploading = true
        statusMessage = "Uploading..."
        uploadSuccess = false

        do {
            // Compress image if needed
            let compressedData = compressImageIfNeeded(imageData)

            // Upload to Firebase Storage
            let photoURL = try await service.uploadProfilePhoto(userId: userId, imageData: compressedData)

            // Update user profile in Firestore
            guard var profile = auth?.userProfile else {
                throw NSError(domain: "EditAccount", code: -1, userInfo: [NSLocalizedDescriptionKey: "User profile not found"])
            }

            profile.profileImageURL = photoURL
            try await service.updateProfile(profile)

            // Update local auth state
            auth?.userProfile?.profileImageURL = photoURL

            // Success
            isUploading = false
            uploadSuccess = true
            statusMessage = "Photo uploaded successfully!"

            // Track analytics
            AnalyticsManager.shared.trackMediaUpload(type: "profile_photo", count: 1)

            // Clear selection after successful upload
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.selectedImage = nil
                self.selectedImageData = nil
                self.photoSelection = nil
            }

            print("✅ Profile photo uploaded: \(photoURL)")

        } catch {
            isUploading = false
            uploadSuccess = false
            statusMessage = "Upload failed"
            errorMessage = error.localizedDescription
            showError = true
            print("❌ Error uploading photo: \(error)")
        }
    }

    private func compressImageIfNeeded(_ data: Data) -> Data {
        // If data is already small enough, return as is
        let targetSize = 2 * 1024 * 1024 // 2MB target
        if data.count <= targetSize {
            return data
        }

        // Compress the image
        guard let uiImage = UIImage(data: data) else { return data }

        var compression: CGFloat = 0.8
        var compressedData = data

        while compressedData.count > targetSize && compression > 0.1 {
            if let compressed = uiImage.jpegData(compressionQuality: compression) {
                compressedData = compressed
            }
            compression -= 0.1
        }

        print("📦 Compressed image from \(data.count / 1024)KB to \(compressedData.count / 1024)KB")
        return compressedData
    }

    func updateDisplayName() async {
        guard let userId = Auth.auth().currentUser?.uid,
              var profile = auth?.userProfile,
              !displayName.isEmpty else {
            return
        }

        isUpdating = true

        do {
            profile.displayName = displayName
            try await service.updateProfile(profile)

            // Update local auth state
            auth?.userProfile?.displayName = displayName

            isUpdating = false
            print("✅ Display name updated")

        } catch {
            isUpdating = false
            errorMessage = "Failed to update display name"
            showError = true
            print("❌ Error updating display name: \(error)")
        }
    }

    // MARK: - Media Gallery Methods

    private func handleMediaSelections(_ selections: [PhotosPickerItem]) async {
        guard !selections.isEmpty else { return }
        guard let userId = Auth.auth().currentUser?.uid else {
            mediaStatusMessage = "User not found"
            return
        }

        // Check if we're at limit
        let currentCount = auth?.userProfile?.mediaURLs?.count ?? 0
        let availableSlots = 6 - currentCount

        if availableSlots <= 0 {
            mediaStatusMessage = "Maximum 6 photos allowed"
            mediaSelections = []
            return
        }

        // Limit selections to available slots
        let selectionsToProcess = Array(selections.prefix(availableSlots))

        isUploadingMedia = true
        mediaStatusMessage = "Processing images..."
        uploadProgress = (0, selectionsToProcess.count)
        mediaUploadSuccess = false

        var uploadedURLs: [String] = []

        do {
            // Process each selection
            for (index, selection) in selectionsToProcess.enumerated() {
                uploadProgress = (index + 1, selectionsToProcess.count)

                // Load image data
                guard let data = try await selection.loadTransferable(type: Data.self) else {
                    print("⚠️ Failed to load image \(index + 1)")
                    continue
                }

                // Validate size
                let maxSize = 10 * 1024 * 1024 // 10MB
                if data.count > maxSize {
                    print("⚠️ Image \(index + 1) too large")
                    continue
                }

                // Compress
                let compressedData = compressImageIfNeeded(data)

                // Upload to Firebase Storage
                let path = "media/\(userId)/\(UUID().uuidString).jpg"
                let url = try await service.uploadMedia(data: compressedData, path: path)
                uploadedURLs.append(url)

                print("✅ Uploaded media \(index + 1) of \(selectionsToProcess.count)")
            }

            // Update profile with new URLs
            if !uploadedURLs.isEmpty {
                guard var profile = auth?.userProfile else {
                    throw NSError(domain: "EditAccount", code: -1, userInfo: [NSLocalizedDescriptionKey: "User profile not found"])
                }

                var currentMediaURLs = profile.mediaURLs ?? []
                currentMediaURLs.append(contentsOf: uploadedURLs)
                profile.mediaURLs = currentMediaURLs

                try await service.updateProfile(profile)

                // Update local auth state
                auth?.userProfile?.mediaURLs = currentMediaURLs

                // Track analytics
                AnalyticsManager.shared.trackMediaUpload(type: "gallery", count: uploadedURLs.count)

                mediaUploadSuccess = true
                mediaStatusMessage = "Uploaded \(uploadedURLs.count) photo\(uploadedURLs.count > 1 ? "s" : "") successfully!"
            }

            // Clear selections
            isUploadingMedia = false
            mediaSelections = []

            // Clear success message after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.mediaStatusMessage = nil
                self.mediaUploadSuccess = false
            }

        } catch {
            isUploadingMedia = false
            mediaUploadSuccess = false
            mediaStatusMessage = "Upload failed: \(error.localizedDescription)"
            mediaSelections = []
            print("❌ Error uploading media: \(error)")
        }
    }

    func deleteMedia(at index: Int) async {
        guard var profile = auth?.userProfile,
              var mediaURLs = profile.mediaURLs,
              index < mediaURLs.count else {
            return
        }

        let urlToDelete = mediaURLs[index]

        do {
            // Remove from array
            mediaURLs.remove(at: index)
            profile.mediaURLs = mediaURLs

            // Update Firestore
            try await service.updateProfile(profile)

            // Update local auth state
            auth?.userProfile?.mediaURLs = mediaURLs

            // Delete from Firebase Storage to save space
            do {
                try await service.deleteMedia(url: urlToDelete)
                print("✅ Deleted media from Storage and Firestore")
            } catch {
                // Don't fail the whole operation if Storage deletion fails
                // The URL is already removed from Firestore, which is the critical part
                print("⚠️ Failed to delete from Storage (non-critical): \(error.localizedDescription)")
            }

            print("✅ Deleted media at index \(index)")

        } catch {
            errorMessage = "Failed to delete photo"
            showError = true
            print("❌ Error deleting media: \(error)")
        }
    }

    // MARK: - Social Links Methods

    func loadSocialLinks() {
        guard let profile = auth?.userProfile else { return }

        // Load Instagram
        if let instagram = profile.socialLinks?.instagram {
            instagramUsername = instagram.username
            instagramFollowers = instagram.followerCount.map(String.init) ?? ""
            instagramVerified = instagram.isVerified
        }

        // Load TikTok
        if let tiktok = profile.socialLinks?.tiktok {
            tiktokUsername = tiktok.username
            tiktokFollowers = tiktok.followerCount.map(String.init) ?? ""
            tiktokVerified = tiktok.isVerified
        }

        // Load YouTube
        if let youtube = profile.socialLinks?.youtube {
            youtubeUsername = youtube.username
            youtubeFollowers = youtube.followerCount.map(String.init) ?? ""
            youtubeVerified = youtube.isVerified
        }

        // Load Twitch
        if let twitch = profile.socialLinks?.twitch {
            twitchUsername = twitch.username
            twitchFollowers = twitch.followerCount.map(String.init) ?? ""
            twitchVerified = twitch.isVerified
        }
    }

    func updateSocialLinks() async {
        guard var profile = auth?.userProfile else { return }

        isUpdatingSocials = true
        socialsStatusMessage = "Updating..."
        socialsUpdateSuccess = false

        // Build social links
        var socialLinks = UserProfile.SocialLinks()

        // Instagram
        if !instagramUsername.isEmpty {
            socialLinks.instagram = UserProfile.SocialLinks.SocialAccount(
                username: instagramUsername,
                followerCount: Int(instagramFollowers),
                isVerified: instagramVerified
            )
        }

        // TikTok
        if !tiktokUsername.isEmpty {
            socialLinks.tiktok = UserProfile.SocialLinks.SocialAccount(
                username: tiktokUsername,
                followerCount: Int(tiktokFollowers),
                isVerified: tiktokVerified
            )
        }

        // YouTube
        if !youtubeUsername.isEmpty {
            socialLinks.youtube = UserProfile.SocialLinks.SocialAccount(
                username: youtubeUsername,
                followerCount: Int(youtubeFollowers),
                isVerified: youtubeVerified
            )
        }

        // Twitch
        if !twitchUsername.isEmpty {
            socialLinks.twitch = UserProfile.SocialLinks.SocialAccount(
                username: twitchUsername,
                followerCount: Int(twitchFollowers),
                isVerified: twitchVerified
            )
        }

        profile.socialLinks = socialLinks

        do {
            // Update profile
            try await service.updateProfile(profile)

            // Update local auth state
            auth?.userProfile?.socialLinks = socialLinks

            isUpdatingSocials = false
            socialsUpdateSuccess = true
            socialsStatusMessage = "Social links updated successfully!"

            print("✅ Social links updated")

            // Clear success message after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.socialsStatusMessage = nil
                self.socialsUpdateSuccess = false
            }

        } catch {
            isUpdatingSocials = false
            socialsUpdateSuccess = false
            socialsStatusMessage = "Failed to update social links"
            print("❌ Error updating social links: \(error)")
        }
    }
}

struct ChangePasswordView: View {
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showSuccess = false
    @Environment(\.dismiss) var dismiss

    var body: some View {
        Form {
            Section {
                SecureField("Current Password", text: $currentPassword)
                SecureField("New Password", text: $newPassword)
                    .textContentType(.newPassword)
                SecureField("Confirm New Password", text: $confirmPassword)
                    .textContentType(.newPassword)
            } footer: {
                Text("Password must be at least 6 characters")
                    .font(.caption)
            }

            if let error = errorMessage {
                Section {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }

            Section {
                Button {
                    Task {
                        await changePassword()
                    }
                } label: {
                    if isLoading {
                        HStack {
                            ProgressView()
                            Text("Changing Password...")
                        }
                    } else {
                        Text("Change Password")
                    }
                }
                .disabled(isInvalid || isLoading)
            }
        }
        .navigationTitle("Change Password")
        .alert("Password Changed", isPresented: $showSuccess) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Your password has been successfully updated.")
        }
    }

    private var isInvalid: Bool {
        currentPassword.isEmpty ||
        newPassword.isEmpty ||
        newPassword != confirmPassword ||
        newPassword.count < 6
    }

    private func changePassword() async {
        guard let user = Auth.auth().currentUser,
              let email = user.email else {
            errorMessage = "User not found"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            // Step 1: Reauthenticate user for security
            let credential = EmailAuthProvider.credential(withEmail: email, password: currentPassword)
            try await user.reauthenticate(with: credential)

            // Step 2: Update password
            try await user.updatePassword(to: newPassword)

            // Step 3: Show success
            isLoading = false
            showSuccess = true

            // Clear fields
            currentPassword = ""
            newPassword = ""
            confirmPassword = ""

            print("✅ Password changed successfully")

        } catch let error as NSError {
            isLoading = false

            // Provide user-friendly error messages
            switch error.code {
            case AuthErrorCode.wrongPassword.rawValue:
                errorMessage = "Current password is incorrect"
            case AuthErrorCode.weakPassword.rawValue:
                errorMessage = "New password is too weak"
            case AuthErrorCode.requiresRecentLogin.rawValue:
                errorMessage = "Please sign out and sign in again to change password"
            case AuthErrorCode.networkError.rawValue:
                errorMessage = "Network error. Please check your connection"
            default:
                errorMessage = "Failed to change password: \(error.localizedDescription)"
            }

            print("❌ Error changing password: \(error)")
        }
    }
}

struct BlockedUsersView: View {
    @State private var blockedUsers: [String] = []
    
    var body: some View {
        List {
            if blockedUsers.isEmpty {
                ContentUnavailableView(
                    "No Blocked Users",
                    systemImage: "hand.raised.slash",
                    description: Text("Users you block will appear here")
                )
            } else {
                ForEach(blockedUsers, id: \.self) { user in
                    HStack {
                        Text(user)
                        Spacer()
                        Button("Unblock", role: .destructive) {
                            // Unblock user
                        }
                    }
                }
            }
        }
        .navigationTitle("Blocked Users")
    }
}

struct DiscoveryPreferencesView: View {
    var body: some View {
        Text("Discovery Preferences")
            .navigationTitle("Discovery")
    }
}

struct ContentPreferencesView: View {
    var body: some View {
        Text("Content Preferences")
            .navigationTitle("Content")
    }
}

struct AppearanceSettingsView: View {
    @State private var appearance = 0
    
    var body: some View {
        List {
            Picker("Theme", selection: $appearance) {
                Text("Automatic").tag(0)
                Text("Light").tag(1)
                Text("Dark").tag(2)
            }
        }
        .navigationTitle("Appearance")
    }
}

struct LanguageSettingsView: View {
    var body: some View {
        Text("Language Settings")
            .navigationTitle("Language")
    }
}

struct DataUsageView: View {
    var body: some View {
        List {
            Section {
                HStack {
                    Text("Data used this month")
                    Spacer()
                    Text("125 MB")
                        .foregroundStyle(.secondary)
                }
            }
            
            Section {
                Toggle("Download over cellular", isOn: .constant(false))
                Toggle("Auto-download media", isOn: .constant(true))
            }
        }
        .navigationTitle("Data Usage")
    }
}

struct WebViewSheet: View {
    let url: String
    let title: String
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            Text("WebView: \(url)")
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") { dismiss() }
                    }
                }
        }
    }
}
