import SwiftUI
import AuthenticationServices
import FirebaseAuth

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
            // Track screen view
            AnalyticsManager.shared.trackScreenView(screenName: "Profile", screenClass: "EnhancedProfileView")

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
        .onChange(of: showSettings) { _, isShowing in
            if !isShowing {
                // Refresh profile when returning from settings
                Task {
                    await profileViewModel.refreshProfile()
                }
            }
        }
    }
    
    // MARK: - Profile Header
    private var profileHeader: some View {
        VStack(spacing: 16) {
            // Profile Image/Avatar
            ZStack(alignment: .bottomTrailing) {
                if let profile = profileViewModel.profile,
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
                
                // Edit button
                Button {
                    showEditProfile = true
                } label: {
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(.white)
                        .background(
                            Circle()
                                .fill(AppTheme.accent)
                                .frame(width: 32, height: 32)
                        )
                }
                .offset(x: 4, y: 4)
            }
            .shadow(color: AppTheme.accent.opacity(0.3), radius: 20, x: 0, y: 10)
            
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
                value: formatFollowerCount(profile.followerCount ?? 0),
                label: "Followers",
                icon: "person.2.fill"
            )
            
            Divider()
                .frame(height: 40)
            
            statBox(
                value: "\((profile.mediaURLs ?? []).count)",
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

            // Photo Gallery Card
            if let mediaURLs = profile.mediaURLs, !mediaURLs.isEmpty {
                GlassCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("My Photos", systemImage: "photo.on.rectangle.angled")
                            .font(.headline)

                        LazyVGrid(columns: [GridItem(.fixed(100)), GridItem(.fixed(100)), GridItem(.fixed(100))], spacing: 8) {
                            ForEach(Array(mediaURLs.enumerated()), id: \.offset) { index, url in
                                AsyncImage(url: URL(string: url)) { phase in
                                    switch phase {
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .scaledToFill()
                                    case .failure(_):
                                        Rectangle()
                                            .fill(.red.opacity(0.2))
                                            .overlay(
                                                Image(systemName: "exclamationmark.triangle")
                                                    .foregroundStyle(.red)
                                            )
                                    case .empty:
                                        Rectangle()
                                            .fill(.gray.opacity(0.2))
                                            .overlay(
                                                ProgressView()
                                                    .tint(AppTheme.accent)
                                            )
                                    @unknown default:
                                        Rectangle()
                                            .fill(.gray.opacity(0.2))
                                    }
                                }
                                .frame(width: 100, height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                }
            }

            // Social Links Card
            if profile.socialLinks?.tiktok != nil ||
               profile.socialLinks?.instagram != nil ||
               profile.socialLinks?.youtube != nil ||
               profile.socialLinks?.twitch != nil {
                GlassCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Social Media", systemImage: "link")
                            .font(.headline)

                        VStack(spacing: 10) {
                            if let instagram = profile.socialLinks?.instagram {
                                socialLinkRow(
                                    platform: "Instagram",
                                    icon: "camera",
                                    username: instagram.username,
                                    followers: instagram.followerCount,
                                    isVerified: instagram.isVerified
                                )
                            }

                            if let tiktok = profile.socialLinks?.tiktok {
                                socialLinkRow(
                                    platform: "TikTok",
                                    icon: "music.note",
                                    username: tiktok.username,
                                    followers: tiktok.followerCount,
                                    isVerified: tiktok.isVerified
                                )
                            }

                            if let youtube = profile.socialLinks?.youtube {
                                socialLinkRow(
                                    platform: "YouTube",
                                    icon: "play.rectangle",
                                    username: youtube.username,
                                    followers: youtube.followerCount,
                                    isVerified: youtube.isVerified
                                )
                            }

                            if let twitch = profile.socialLinks?.twitch {
                                socialLinkRow(
                                    platform: "Twitch",
                                    icon: "gamecontroller",
                                    username: twitch.username,
                                    followers: twitch.followerCount,
                                    isVerified: twitch.isVerified
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
            if !(profile.collaborationPreferences?.lookingFor ?? []).isEmpty {

                GlassCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Looking to Collaborate", systemImage: "hand.wave.fill")
                            .font(.headline)
                        
                        FlowLayout(spacing: 8) {
                            ForEach(profile.collaborationPreferences?.lookingFor ?? [], id: \.self) { collab in

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
                            Text("Responds \(profile.collaborationPreferences?.responseTime.rawValue ?? "N/A")")


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
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(AppTheme.accent)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(platform)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

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
        }
        .padding(.vertical, 8)
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
