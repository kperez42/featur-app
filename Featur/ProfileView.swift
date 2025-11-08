import SwiftUI
import AuthenticationServices
import FirebaseAuth
import PhotosUI

struct ProfileView: View {
    @EnvironmentObject var auth: AuthViewModel
    @StateObject private var profileViewModel = ProfileViewModel()
    @State private var showSettings = false
    @State private var showEditProfile = false

    var body: some View {
        Group {
            if auth.user == nil {
                GuestProfileSignIn()
            } else {
                SignedInProfile(
                    profileViewModel: profileViewModel,
                    showSettings: $showSettings,
                    showEditProfile: $showEditProfile
                )
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if let uid = auth.user?.uid {
                await profileViewModel.loadProfile(uid: uid)
            }
        }
    }
}

// MARK: - Guest Profile Sign In
private struct GuestProfileSignIn: View {
    @EnvironmentObject var auth: AuthViewModel

    var body: some View {
        ZStack {
            // Background gradient
            AppTheme.gradient
                .ignoresSafeArea()
                .opacity(0.1)
            
            VStack(spacing: 32) {
                Spacer()
                
                // Icon
                ZStack {
                    Circle()
                        .fill(AppTheme.gradient)
                        .frame(width: 120, height: 120)
                        .shadow(color: AppTheme.accent.opacity(0.3), radius: 20, x: 0, y: 10)
                    
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.white)
                }
                
                VStack(spacing: 12) {
                    Text("Welcome to FEATUR")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                    
                    Text("Sign in to connect with creators, save your matches, and unlock premium features.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 32)
                        .lineSpacing(4)
                }
                
                Spacer()
                
                // Sign in button
                VStack(spacing: 16) {
                    SignInWithAppleButton(.signIn) { request in
                        let req = auth.makeAppleRequest()
                        request.requestedScopes = req.requestedScopes ?? []
                        request.nonce = req.nonce
                    } onCompletion: { result in
                        Task { await auth.handleApple(result: result) }
                    }
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 56)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    
                    if let msg = auth.errorMessage, !msg.isEmpty {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption)
                            Text(msg)
                                .font(.caption)
                        }
                        .foregroundStyle(.red)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
    }
}

// MARK: - Signed In Profile
private struct SignedInProfile: View {
    @EnvironmentObject var auth: AuthViewModel
    @ObservedObject var profileViewModel: ProfileViewModel
    @Binding var showSettings: Bool
    @Binding var showEditProfile: Bool

    @State private var displayName: String = ""
    @State private var email: String = ""
    @State private var appleAnon: Bool = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var isUploadingPhoto = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header Section
                profileHeader
                
                // Stats Section
                if let profile = profileViewModel.profile {
                    statsSection(profile: profile)
                }
                
                // Action Buttons
                actionButtons
                
                // Profile Info Cards
                if let profile = profileViewModel.profile {
                    profileInfoCards(profile: profile)
                } else {
                    setupProfileCard
                }
                
                // Account Section
                accountSection
                
                Spacer(minLength: 32)
            }
        }
        .background(AppTheme.bg.ignoresSafeArea())
        .refreshable {
            await profileViewModel.refreshProfile()
        }
        .onAppear {
            loadUser()
        }
        .sheet(isPresented: $showSettings) {
            SettingsSheet()
                .environmentObject(auth)
        }
        .sheet(isPresented: $showEditProfile) {
            if let profile = profileViewModel.profile {
                ProfileCreationFlow(viewModel: profileViewModel)
            } else {
                ProfileCreationFlow(viewModel: profileViewModel)
            }
        }
    }
    
    // MARK: - Profile Header
    private var profileHeader: some View {
        VStack(spacing: 16) {
            // Profile Image/Avatar
            ZStack(alignment: .bottomTrailing) {
                Group {
                    if isUploadingPhoto {
                        ZStack {
                            avatarPlaceholder
                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(.white)
                        }
                    } else if let profile = profileViewModel.profile,
                       let imageURL = profile.profileImageURL,
                       let url = URL(string: imageURL) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 120, height: 120)
                                    .clipShape(Circle())
                            default:
                                avatarPlaceholder
                            }
                        }
                    } else {
                        avatarPlaceholder
                    }
                }

                // Photo picker button
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    Image(systemName: isUploadingPhoto ? "arrow.up.circle.fill" : "pencil.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(.white)
                        .background(
                            Circle()
                                .fill(AppTheme.accent)
                                .frame(width: 32, height: 32)
                        )
                }
                .offset(x: 4, y: 4)
                .disabled(isUploadingPhoto)
            }
            .shadow(color: AppTheme.accent.opacity(0.3), radius: 20, x: 0, y: 10)
            .onChange(of: selectedPhoto) { oldValue, newValue in
                guard let newValue else { return }
                Task {
                    await uploadProfilePhoto(newValue)
                }
            }
            
            // Name and verification
            VStack(spacing: 6) {
                HStack(spacing: 8) {
                    Text(profileViewModel.profile?.displayName ?? displayName)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                    
                    if profileViewModel.profile?.isVerified == true {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.title3)
                            .foregroundStyle(AppTheme.accent)
                    }
                }
                
                if let profile = profileViewModel.profile, let age = profile.age {
                    Text("\(age) years old")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                if appleAnon {
                    HStack(spacing: 4) {
                        Image(systemName: "applelogo")
                            .font(.caption2)
                        Text("Private Relay")
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.1), in: Capsule())
                }
            }
            
            // Bio
            if let profile = profileViewModel.profile, let bio = profile.bio, !bio.isEmpty {
                Text(bio)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .padding(.horizontal, 32)
            }
        }
        .padding(.top, 24)
        .padding(.bottom, 20)
    }
    
    // MARK: - Avatar Placeholder
    private var avatarPlaceholder: some View {
        ZStack {
            Circle()
                .fill(AppTheme.gradient)
                .frame(width: 120, height: 120)
            
            Text(initials(from: displayName.isEmpty ? email : displayName))
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
    }
    
    // MARK: - Stats Section
    private func statsSection(profile: UserProfile) -> some View {
        HStack(spacing: 0) {
            statBox(
                value: formatFollowerCount(profile.followerCount),
                label: "Followers",
                icon: "person.2.fill"
            )
            
            Divider()
                .frame(height: 40)
            
            statBox(
                value: "\(profile.mediaURLs.count)",
                label: "Posts",
                icon: "photo.stack.fill"
            )
            
            Divider()
                .frame(height: 40)
            
            statBox(
                value: "\(profile.contentStyles.count)",
                label: "Styles",
                icon: "star.fill"
            )
        }
        .padding(.vertical, 20)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal, 16)
        .padding(.bottom, 20)
    }
    
    private func statBox(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(AppTheme.accent)
            
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
            
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Action Buttons
    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button {
                Haptics.impact(.medium)
                showEditProfile = true
            } label: {
                Label("Edit Profile", systemImage: "pencil")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppTheme.accent, in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(.white)
            }

            Button {
                Haptics.impact(.light)
                showSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.headline)
                    .frame(width: 50, height: 50)
                    .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(AppTheme.accent)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 20)
    }
    
    // MARK: - Profile Info Cards
    private func profileInfoCards(profile: UserProfile) -> some View {
        VStack(spacing: 16) {
            // Content Styles Card
            if !profile.contentStyles.isEmpty {
                GlassCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Content Styles", systemImage: "sparkles")
                            .font(.headline)
                        
                        FlowLayout(spacing: 8) {
                            ForEach(profile.contentStyles, id: \.self) { style in
                                HStack(spacing: 6) {
                                    Image(systemName: style.icon)
                                        .font(.caption)
                                    Text(style.rawValue)
                                        .font(.caption.weight(.medium))
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(AppTheme.accent.opacity(0.15), in: Capsule())
                                .foregroundStyle(AppTheme.accent)
                            }
                        }
                    }
                }
            }
            
            // Social Links Card
            if profile.socialLinks.tiktok != nil || 
               profile.socialLinks.instagram != nil || 
               profile.socialLinks.youtube != nil {
                GlassCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Social Media", systemImage: "link")
                            .font(.headline)
                        
                        VStack(spacing: 10) {
                            if let tiktok = profile.socialLinks.tiktok {
                                socialLinkRow(
                                    platform: "TikTok",
                                    icon: "music.note",
                                    username: tiktok.username,
                                    followers: tiktok.followerCount,
                                    isVerified: tiktok.isVerified
                                )
                            }
                            
                            if let instagram = profile.socialLinks.instagram {
                                socialLinkRow(
                                    platform: "Instagram",
                                    icon: "camera",
                                    username: instagram.username,
                                    followers: instagram.followerCount,
                                    isVerified: instagram.isVerified
                                )
                            }
                            
                            if let youtube = profile.socialLinks.youtube {
                                socialLinkRow(
                                    platform: "YouTube",
                                    icon: "play.rectangle",
                                    username: youtube.username,
                                    followers: youtube.followerCount,
                                    isVerified: youtube.isVerified
                                )
                            }
                        }
                    }
                }
            }
            
            // Location Card
            if let location = profile.location, location.city != nil {
                GlassCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Location", systemImage: "mappin.circle.fill")
                            .font(.headline)
                        
                        HStack(spacing: 8) {
                            Image(systemName: "location.fill")
                                .foregroundStyle(AppTheme.accent)
                            
                            if let city = location.city, let state = location.state {
                                Text("\(city), \(state)")
                                    .font(.body)
                            }
                        }
                    }
                }
            }
            
            // Collaboration Preferences Card
            if !profile.collaborationPreferences.lookingFor.isEmpty {
                GlassCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Looking to Collaborate", systemImage: "hand.wave.fill")
                            .font(.headline)
                        
                        FlowLayout(spacing: 8) {
                            ForEach(profile.collaborationPreferences.lookingFor, id: \.self) { collab in
                                Text(collab.rawValue)
                                    .font(.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(AppTheme.card, in: Capsule())
                            }
                        }
                        
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.caption)
                            Text("Responds \(profile.collaborationPreferences.responseTime.displayText)")
                                .font(.caption)
                        }
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
    }
    
    private func socialLinkRow(platform: String, icon: String, username: String, followers: Int?, isVerified: Bool) -> some View {
        Button {
            Haptics.impact(.light)
            openSocialMediaLink(platform: platform, username: username)
        } label: {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(AppTheme.accent)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text("@\(username)")
                            .font(.body.weight(.medium))

                        if isVerified {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.caption)
                                .foregroundStyle(.blue)
                        }
                    }

                    if let followers = followers {
                        Text("\(formatFollowerCount(followers)) followers")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func openSocialMediaLink(platform: String, username: String) {
        var urlString = ""

        switch platform.lowercased() {
        case "tiktok":
            urlString = "https://www.tiktok.com/@\(username)"
        case "instagram":
            urlString = "https://www.instagram.com/\(username)"
        case "youtube":
            urlString = "https://www.youtube.com/@\(username)"
        case "twitch":
            urlString = "https://www.twitch.tv/\(username)"
        default:
            return
        }

        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
    
    // MARK: - Setup Profile Card
    private var setupProfileCard: some View {
        GlassCard {
            VStack(spacing: 16) {
                Image(systemName: "person.crop.circle.badge.plus")
                    .font(.system(size: 60))
                    .foregroundStyle(AppTheme.accent)
                
                Text("Complete Your Profile")
                    .font(.title3.bold())
                
                Text("Add your content styles, social links, and photos to start connecting with other creators.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                
                Button {
                    Haptics.impact(.medium)
                    showEditProfile = true
                } label: {
                    Text("Set Up Profile")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppTheme.accent, in: RoundedRectangle(cornerRadius: 14))
                        .foregroundStyle(.white)
                }
            }
            .padding(.vertical, 8)
        }
        .padding(.horizontal, 16)
    }
    
    // MARK: - Account Section
    private var accountSection: some View {
        VStack(spacing: 12) {
            Divider()
                .padding(.vertical, 8)
            
            VStack(spacing: 8) {
                accountInfoRow(label: "Email", value: email, icon: "envelope.fill")
                
                if let uid = Auth.auth().currentUser?.uid {
                    accountInfoRow(label: "User ID", value: uid, icon: "key.fill", monospaced: true)
                }
            }
            
            // Sign Out Button
            Button {
                Haptics.impact(.medium)
                Task { await auth.signOut() }
            } label: {
                Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(.red)
            }
            .padding(.top, 8)
        }
        .padding(.horizontal, 16)
        .padding(.top, 20)
    }
    
    private func accountInfoRow(label: String, value: String, icon: String, monospaced: Bool = false) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(AppTheme.accent)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text(value)
                    .font(monospaced ? .caption.monospaced() : .caption)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Button {
                UIPasteboard.general.string = value
                Haptics.impact(.light)
            } label: {
                Image(systemName: "doc.on.doc")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 10))
    }
    
    // MARK: - Helper Functions
    private func loadUser() {
        let u = Auth.auth().currentUser
        displayName = u?.displayName ?? ""
        email = u?.email ?? ""

        if let provider = u?.providerData.first(where: { $0.providerID == "apple.com" }),
           let mail = provider.email, mail.contains("privaterelay.appleid.com") {
            appleAnon = true
        } else {
            appleAnon = false
        }
    }

    private func initials(from text: String) -> String {
        let parts = text.split(separator: " ")
        let letters = parts.prefix(2).compactMap { $0.first }
        if letters.isEmpty, let first = text.first {
            return String(first).uppercased()
        }
        return letters.map { String($0).uppercased() }.joined()
    }

    private func uploadProfilePhoto(_ item: PhotosPickerItem) async {
        guard let uid = auth.user?.uid else { return }

        isUploadingPhoto = true
        Haptics.impact(.medium)

        do {
            if let data = try await item.loadTransferable(type: Data.self) {
                await profileViewModel.updateProfilePhoto(userId: uid, imageData: data)
                Haptics.notify(.success)
            }
        } catch {
            print("Error loading photo: \(error)")
            Haptics.notify(.error)
        }

        isUploadingPhoto = false
        selectedPhoto = nil
    }
}

// MARK: - Preview
#if DEBUG
struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ProfileView()
                .environmentObject(AuthViewModel())
        }
    }
}
#endif
