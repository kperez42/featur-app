import SwiftUI
import PhotosUI
import FirebaseAuth
import AuthenticationServices  // âœ… ADD THIS IMPORT

struct EnhancedProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @EnvironmentObject var auth: AuthViewModel
    @State private var showEditSheet = false
    
    var body: some View {
        Group {
            if auth.user == nil {
                GuestProfileView()
            } else {
                authenticatedProfile
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .background(AppTheme.bg)
        .task {
            if let uid = auth.user?.uid {
                await viewModel.loadProfile(uid: uid)
            }
        }
    }
    
    private var authenticatedProfile: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header with Edit Button
                HStack {
                    Spacer()
                    Button("Edit Profile") {
                        showEditSheet = true
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.accent)
                }
                .padding(.horizontal)
                
                if let profile = viewModel.profile {
                    // Profile Header
                    profileHeader(profile)
                    
                    // Media Grid
                    mediaGrid(profile)
                    
                    // About Section
                    aboutSection(profile)
                    
                    // Content Styles
                    contentStylesSection(profile)
                    
                    // Social Links
                    socialLinksSection(profile)
                    
                    // Settings
                    settingsSection
                } else if viewModel.isLoading {
                    ProgressView()
                        .frame(height: 300)
                } else {
                    createProfilePrompt
                }
            }
            .padding(.bottom, 32)
        }
        .sheet(isPresented: $showEditSheet) {
            if let profile = viewModel.profile {
                EditProfileView(profile: profile) { updated in
                    Task {
                        await viewModel.updateProfile(updated)
                    }
                }
            }
        }
    }
    
    private func profileHeader(_ profile: UserProfile) -> some View {
        VStack(spacing: 16) {
            // Profile Photo
            AsyncImage(url: URL(string: profile.mediaURLs.first ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(AppTheme.accent.opacity(0.2))
                    .overlay {
                        Image(systemName: "person.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(AppTheme.accent)
                    }
            }
            .frame(width: 120, height: 120)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(AppTheme.accent, lineWidth: 3)
            )
            
            // Name & Verification
            HStack(spacing: 8) {
                Text(profile.displayName)
                    .font(.title2.bold())
                
                if let age = profile.age {
                    Text("\(age)")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                
                if profile.isVerified {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(AppTheme.accent)
                }
            }
            
            // Location
            if let location = profile.location, let city = location.city {
                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(.caption)
                    Text(city)
                        .font(.subheadline)
                }
                .foregroundStyle(.secondary)
            }
            
            // Stats
            HStack(spacing: 32) {
                StatView(value: profile.followerCount, label: "Followers")
                StatView(value: 0, label: "Following")
                StatView(value: 0, label: "Collabs")
            }
        }
    }
    
    private func mediaGrid(_ profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Media")
                .font(.headline)
                .padding(.horizontal)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 4) {
                ForEach(profile.mediaURLs.prefix(6), id: \.self) { url in
                    AsyncImage(url: URL(string: url)) { image in
                        image
                            .resizable()
                            .aspectRatio(1, contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(AppTheme.card)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                // Add more button
                if profile.mediaURLs.count < 6 {
                    Button {
                        showEditSheet = true
                    } label: {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(AppTheme.card)
                            .overlay {
                                Image(systemName: "plus")
                                    .font(.title2)
                                    .foregroundStyle(.secondary)
                            }
                            .aspectRatio(1, contentMode: .fit)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    private func aboutSection(_ profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("About Me")
                .font(.headline)
            
            Text(profile.bio ?? "No bio yet")
                .foregroundStyle(profile.bio == nil ? .secondary : .primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }
    
    private func contentStylesSection(_ profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Content Style")
                .font(.headline)
                .padding(.horizontal)
            
            FlowLayout(spacing: 8) {
                ForEach(profile.contentStyles, id: \.self) { style in
                    TagChip(title: style.rawValue, active: true)
                }
            }
            .padding(.horizontal)
        }
    }
    
    private func socialLinksSection(_ profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Social Media")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 8) {
                if let tiktok = profile.socialLinks.tiktok {
                    SocialLinkRow(
                        platform: "TikTok",
                        username: tiktok.username,
                        followers: tiktok.followerCount,
                        icon: "music.note"
                    )
                }
                
                if let instagram = profile.socialLinks.instagram {
                    SocialLinkRow(
                        platform: "Instagram",
                        username: instagram.username,
                        followers: instagram.followerCount,
                        icon: "camera"
                    )
                }
                
                if let youtube = profile.socialLinks.youtube {
                    SocialLinkRow(
                        platform: "YouTube",
                        username: youtube.username,
                        followers: youtube.followerCount,
                        icon: "play.rectangle"
                    )
                }
                
                if let twitch = profile.socialLinks.twitch {
                    SocialLinkRow(
                        platform: "Twitch",
                        username: twitch.username,
                        followers: twitch.followerCount,
                        icon: "gamecontroller"
                    )
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var settingsSection: some View {
        VStack(spacing: 12) {
            Button {
                Task { await auth.signOut() }
            } label: {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text("Sign Out")
                    Spacer()
                }
                .padding()
                .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 12))
            }
            .foregroundStyle(.red)
        }
        .padding(.horizontal)
    }
    
    private var createProfilePrompt: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 64))
                .foregroundStyle(AppTheme.accent)
            
            Text("Complete Your Profile")
                .font(.title2.bold())
            
            Text("Add your details to start connecting with other creators")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Create Profile") {
                showEditSheet = true
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.accent)
        }
        .padding()
        .frame(height: 400)
    }
}

// MARK: - Supporting Views

struct StatView: View {
    let value: Int
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.title3.bold())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

struct SocialLinkRow: View {
    let platform: String
    let username: String
    let followers: Int?
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(AppTheme.accent)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(platform)
                    .font(.subheadline.weight(.semibold))
                Text("@\(username)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if let followers = followers {
                Text(formatCount(followers))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 12))
    }
    
    private func formatCount(_ num: Int) -> String {
        if num >= 1_000_000 {
            return String(format: "%.1fM", Double(num) / 1_000_000)
        } else if num >= 1_000 {
            return String(format: "%.1fK", Double(num) / 1_000)
        }
        return "\(num)"
    }
}

// MARK: - Edit Profile View

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var profile: UserProfile
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var isSaving = false
    let onSave: (UserProfile) -> Void
    
    init(profile: UserProfile, onSave: @escaping (UserProfile) -> Void) {
        _profile = State(initialValue: profile)
        self.onSave = onSave
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Photo Picker
                    PhotosPicker(selection: $selectedPhotos, maxSelectionCount: 6, matching: .images) {
                        VStack(spacing: 12) {
                            if !profile.mediaURLs.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(profile.mediaURLs, id: \.self) { url in
                                            AsyncImage(url: URL(string: url)) { image in
                                                image.resizable()
                                            } placeholder: {
                                                Rectangle().fill(AppTheme.card)
                                            }
                                            .frame(width: 100, height: 120)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                        }
                                    }
                                }
                            }
                            
                            Button {
                                // Trigger photo picker
                            } label: {
                                Label("Add Photos", systemImage: "plus.circle")
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding()
                        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
                    }
                    
                    // Basic Info
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Basic Info")
                            .font(.headline)
                        
                        TextField("Display Name", text: $profile.displayName)
                            .textFieldStyle(CustomTextFieldStyle())
                        
                        HStack {
                            Text("Age:")
                            TextField("Age", value: $profile.age, format: .number)
                                .keyboardType(.numberPad)
                                .textFieldStyle(CustomTextFieldStyle())
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Bio")
                                .font(.subheadline)
                            TextEditor(text: Binding(
                                get: { profile.bio ?? "" },
                                set: { profile.bio = $0.isEmpty ? nil : $0 }
                            ))
                            .frame(height: 100)
                            .padding(8)
                            .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    
                    // Content Styles
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Content Styles")
                            .font(.headline)
                        
                        FlowLayout(spacing: 8) {
                            ForEach(UserProfile.ContentStyle.allCases, id: \.self) { style in
                                let isSelected = profile.contentStyles.contains(style)
                                Button {
                                    if isSelected {
                                        profile.contentStyles.removeAll { $0 == style }
                                    } else {
                                        profile.contentStyles.append(style)
                                    }
                                } label: {
                                    TagChip(title: style.rawValue, active: isSelected)
                                }
                            }
                        }
                    }
                    
                    // Social Links
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Social Media")
                            .font(.headline)
                        
                        SocialInputField(
                            platform: "TikTok",
                            icon: "music.note",
                            username: Binding(
                                get: { profile.socialLinks.tiktok?.username ?? "" },
                                set: { newValue in
                                    if newValue.isEmpty {
                                        profile.socialLinks.tiktok = nil
                                    } else {
                                        profile.socialLinks.tiktok = .init(username: newValue, followerCount: profile.socialLinks.tiktok?.followerCount, isVerified: false)
                                    }
                                }
                            )
                        )
                        
                        SocialInputField(
                            platform: "Instagram",
                            icon: "camera",
                            username: Binding(
                                get: { profile.socialLinks.instagram?.username ?? "" },
                                set: { newValue in
                                    if newValue.isEmpty {
                                        profile.socialLinks.instagram = nil
                                    } else {
                                        profile.socialLinks.instagram = .init(username: newValue, followerCount: profile.socialLinks.instagram?.followerCount, isVerified: false)
                                    }
                                }
                            )
                        )
                        
                        SocialInputField(
                            platform: "YouTube",
                            icon: "play.rectangle",
                            username: Binding(
                                get: { profile.socialLinks.youtube?.username ?? "" },
                                set: { newValue in
                                    if newValue.isEmpty {
                                        profile.socialLinks.youtube = nil
                                    } else {
                                        profile.socialLinks.youtube = .init(username: newValue, followerCount: profile.socialLinks.youtube?.followerCount, isVerified: false)
                                    }
                                }
                            )
                        )
                        
                        SocialInputField(
                            platform: "Twitch",
                            icon: "gamecontroller",
                            username: Binding(
                                get: { profile.socialLinks.twitch?.username ?? "" },
                                set: { newValue in
                                    if newValue.isEmpty {
                                        profile.socialLinks.twitch = nil
                                    } else {
                                        profile.socialLinks.twitch = .init(username: newValue, followerCount: profile.socialLinks.twitch?.followerCount, isVerified: false)
                                    }
                                }
                            )
                        )
                    }
                }
                .padding()
            }
            .background(AppTheme.bg)
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        isSaving = true
                        onSave(profile)
                        dismiss()
                    }
                    .disabled(profile.displayName.isEmpty || isSaving)
                }
            }
        }
    }
}

struct SocialInputField: View {
    let platform: String
    let icon: String
    @Binding var username: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(AppTheme.accent)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(platform)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("@username", text: $username)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
        }
        .padding()
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Guest Profile View

struct GuestProfileView: View {
    @EnvironmentObject var auth: AuthViewModel
    
    var body: some View {
        VStack(spacing: 24) {
            Circle()
                .fill(AppTheme.accent.opacity(0.2))
                .frame(width: 100, height: 100)
                .overlay {
                    Image(systemName: "person.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(AppTheme.accent)
                }
            
            Text("Welcome to FEATUR")
                .font(.title.bold())
            
            Text("Sign in to create your profile and start connecting with creators")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            SignInWithAppleButton(.signIn) { request in
                let req = auth.makeAppleRequest()
                request.requestedScopes = req.requestedScopes ?? []
                request.nonce = req.nonce
            } onCompletion: { result in
                Task { await auth.handleApple(result: result) }
            }
            .signInWithAppleButtonStyle(.black)
            .frame(height: 52)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 32)
            
            if let msg = auth.errorMessage, !msg.isEmpty {
                Text(msg)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
        .padding()
        .background(AppTheme.bg)
    }
}

// MARK: - Profile View Model

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var profile: UserProfile?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let service = FirebaseService()
    
    func loadProfile(uid: String) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            profile = try await service.fetchProfile(uid: uid)
            
            // If no profile exists, create a default one
            if profile == nil {
                let defaultProfile = UserProfile(
                    uid: uid,
                    displayName: "New Creator",
                    interests: [],
                    contentStyles: [],
                    socialLinks: .init(),
                    mediaURLs: [],
                    isVerified: false,
                    followerCount: 0,
                    collaborationPreferences: .init(
                        lookingFor: [],
                        availability: [],
                        responseTime: .moderate
                    ),
                    createdAt: Date(),
                    updatedAt: Date()
                )
                try await service.createProfile(defaultProfile)
                profile = defaultProfile
            }
        } catch {
            errorMessage = error.localizedDescription
            print("Error loading profile: \(error)")
        }
    }
    
    func updateProfile(_ updated: UserProfile) async {
        do {
            try await service.updateProfile(updated)
            profile = updated
            Haptics.notify(.success)
        } catch {
            errorMessage = error.localizedDescription
            Haptics.notify(.error)
            print("Error updating profile: \(error)")
        }
    }
    
    func uploadPhotos(_ items: [PhotosPickerItem]) async {
        guard let uid = profile?.uid else { return }
        
        var urls: [String] = profile?.mediaURLs ?? []
        
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self) {
                if let url = try? await service.uploadProfilePhoto(userId: uid, imageData: data) {
                    urls.append(url)
                }
            }
        }
        
        if var updatedProfile = profile {
            updatedProfile.mediaURLs = urls
            await updateProfile(updatedProfile)
        }
    }
}
