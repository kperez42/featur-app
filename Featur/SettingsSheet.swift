// SettingsSheet.swift - Premium Settings Page
import SwiftUI
import FirebaseAuth
import UserNotifications

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

            // Step 2: Delete Firebase Auth account
            try await currentUser.delete()
            print("✅ Deleted Firebase Auth account")

            print("✅ Account deletion completed successfully")

        } catch {
            print("❌ Error deleting account: \(error)")
            throw error
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
                exportData["profile"] = [
                    "uid": profile.uid,
                    "displayName": profile.displayName,
                    "age": profile.age ?? "N/A",
                    "bio": profile.bio ?? "",
                    "location": [
                        "city": profile.location?.city ?? "",
                        "state": profile.location?.state ?? "",
                        "country": profile.location?.country ?? ""
                    ],
                    "interests": profile.interests ?? [],
                    "contentStyles": profile.contentStyles.map { $0.rawValue },
                    "isVerified": profile.isVerified ?? false,
                    "followerCount": profile.followerCount ?? 0,
                    "createdAt": ISO8601DateFormatter().string(from: profile.createdAt),
                    "updatedAt": ISO8601DateFormatter().string(from: profile.updatedAt)
                ]
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
    var body: some View {
        Text("Edit Account View")
            .navigationTitle("Edit Account")
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
