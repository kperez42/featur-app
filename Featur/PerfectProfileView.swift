// PerfectProfileView.swift - THE ULTIMATE PROFILE PAGE
// Clean, Beautiful, Professional, and Smooth
import SwiftUI
import FirebaseAuth
import PhotosUI
import AuthenticationServices

struct PerfectProfileView: View {
    @EnvironmentObject var auth: AuthViewModel
    @StateObject private var viewModel = ProfileViewModel()
    
    var body: some View {
        Group {
            if auth.user == nil {
                BeautifulGuestView()
            } else if viewModel.needsSetup {
                ProfileCreationFlow(viewModel: viewModel)
            } else if let profile = viewModel.profile {
                PerfectProfileContent(profile: profile, viewModel: viewModel)
            } else {
                BeautifulLoadingView()
            }
        }
        .task {
            if let uid = auth.user?.uid {
                await viewModel.loadProfile(uid: uid)
            }
        }
    }
}

// MARK: - Main Profile Content
private struct PerfectProfileContent: View {
    let profile: UserProfile
    @ObservedObject var viewModel: ProfileViewModel
    @EnvironmentObject var auth: AuthViewModel

    @State private var scrollOffset: CGFloat = 0
    @State private var showEditSheet = false
    @State private var showSettingsSheet = false
    @State private var showStatsSheet = false
    @State private var showQRSheet = false
    @State private var showShareSheet = false
    @State private var showSuccess = false
    
    var body: some View {
        ZStack(alignment: .top) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Stunning Hero Header
                    StunningHeroHeader(
                        profile: profile,
                        scrollOffset: scrollOffset
                    )
                    .background(
                        GeometryReader { geo in
                            Color.clear.preference(
                                key: ScrollOffsetPreferenceKey.self,
                                value: geo.frame(in: .named("scroll")).minY
                            )
                        }
                    )
                    
                    // Main Content Container
                    VStack(spacing: 24) {
                        // Quick Stats Row
                        BeautifulStatsRow(profile: profile)
                            .padding(.horizontal)
                            .padding(.top, -30)
                        
                        // Profile Completion
                        if profileCompletionPercentage(profile) < 100 {
                            ProfileCompletionBar(profile: profile)
                                .padding(.horizontal)
                        }
                        
                        // Bio Section
                        if let bio = profile.bio, !bio.isEmpty {
                            BeautifulBioCard(bio: bio)
                                .padding(.horizontal)
                        }
                        
                        // Content Styles
                        if !profile.contentStyles.isEmpty {
                            ContentStylesCard(styles: profile.contentStyles)
                                .padding(.horizontal)
                        }
                        
                        // Media Gallery
                        if !profile.mediaURLs.isEmpty {
                            MediaGallerySection(mediaURLs: profile.mediaURLs)
                        }
                        
                        // Social Links
                        if hasSocialLinks(profile) {
                            SocialLinksCard(profile: profile)
                                .padding(.horizontal)
                        }
                        
                        // Stats & Achievements
                        StatsAchievementsCard(profile: profile, onTapStats: {
                            showStatsSheet = true
                        })
                        .padding(.horizontal)
                        
                        // Collaboration Preferences
                        CollaborationCard(preferences: profile.collaborationPreferences)
                            .padding(.horizontal)
                        
                        // Bottom spacing
                        Color.clear.frame(height: 100)
                    }
                    .padding(.top, 20)
                }
            }
            .coordinateSpace(name: "scroll")
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                scrollOffset = value
            }
            
            // Success Toast
            if showSuccess {
                SuccessToast(message: "Profile updated!")
                    .padding(.top, 60)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(profile.displayName)
                    .font(.headline)
                    .opacity(scrollOffset < -80 ? 1 : 0)
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showEditSheet = true
                    } label: {
                        Label("Edit Profile", systemImage: "pencil")
                    }

                    Button {
                        showQRSheet = true
                    } label: {
                        Label("QR Code", systemImage: "qrcode")
                    }

                    Button {
                        showShareSheet = true
                    } label: {
                        Label("Share Profile", systemImage: "square.and.arrow.up")
                    }

                    Divider()

                    Button {
                        showStatsSheet = true
                    } label: {
                        Label("View Analytics", systemImage: "chart.bar")
                    }

                    Button {
                        showSettingsSheet = true
                    } label: {
                        Label("Settings", systemImage: "gear")
                    }

                    Divider()

                    Button(role: .destructive) {
                        Task { await auth.signOut() }
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle.fill")
                        .font(.title3)
                        .foregroundStyle(AppTheme.accent)
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            CleanEditSheet(profile: profile, viewModel: viewModel) {
                showSuccess = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation { showSuccess = false }
                }
            }
        }
        .sheet(isPresented: $showSettingsSheet) {
            SettingsSheet()
        }
        .sheet(isPresented: $showStatsSheet) {
            BeautifulStatsSheet(profile: profile)
        }
        .sheet(isPresented: $showQRSheet) {
            QRCodeSheet(profile: profile)
        }
        .sheet(isPresented: $showShareSheet) {
            ShareProfileSheet(profile: profile)
        }
    }
    
    func hasSocialLinks(_ profile: UserProfile) -> Bool {
        profile.socialLinks.instagram != nil ||
        profile.socialLinks.tiktok != nil ||
        profile.socialLinks.youtube != nil ||
        profile.socialLinks.twitch != nil
    }
    
    func profileCompletionPercentage(_ profile: UserProfile) -> Double {
        var score = 0.0
        if profile.profileImageURL != nil { score += 20 }
        if profile.bio != nil && !profile.bio!.isEmpty { score += 20 }
        if !profile.contentStyles.isEmpty { score += 20 }
        if !profile.mediaURLs.isEmpty { score += 20 }
        if hasSocialLinks(profile) { score += 20 }
        return score
    }
}

// MARK: - Stunning Hero Header
private struct StunningHeroHeader: View {
    let profile: UserProfile
    let scrollOffset: CGFloat
    
    @State private var animate = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Beautiful Gradient Background
            LinearGradient(
                colors: [
                    AppTheme.accent,
                    AppTheme.accent.opacity(0.8),
                    Color.purple.opacity(0.6)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 280 + max(0, scrollOffset * 0.5))
            .overlay(
                LinearGradient(
                    colors: [.white.opacity(0.3), .clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .opacity(animate ? 0.5 : 0.3)
            )
            .onAppear {
                withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                    animate = true
                }
            }
            
            // Profile Content
            VStack(spacing: 16) {
                // Profile Image
                ProfileImageView(profile: profile)
                
                // Name & Info
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Text(profile.displayName)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(.white)
                        
                        if profile.isVerified {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.title3)
                                .foregroundStyle(.white)
                        }
                    }
                    
                    if let age = profile.age {
                        Text("\(age) years old")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.9))
                    }
                    
                    if let location = profile.location, let city = location.city {
                        HStack(spacing: 4) {
                            Image(systemName: "mappin.circle.fill")
                            Text("\(city), \(location.state ?? "")")
                        }
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.white.opacity(0.2), in: Capsule())
                    }
                }
                .shadow(radius: 10)
            }
            .padding(.bottom, 40)
            .scaleEffect(scrollOffset < 0 ? 1 - (scrollOffset / -800) : 1)
        }
        .clipped()
    }
}

private struct ProfileImageView: View {
    let profile: UserProfile
    
    var body: some View {
        Group {
            if let imageURL = profile.profileImageURL, let url = URL(string: imageURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    default:
                        ProfileInitials(name: profile.displayName)
                    }
                }
            } else {
                ProfileInitials(name: profile.displayName)
            }
        }
        .frame(width: 120, height: 120)
        .clipShape(Circle())
        .overlay(
            Circle()
                .stroke(.white, lineWidth: 4)
        )
        .shadow(color: .black.opacity(0.3), radius: 15, y: 8)
    }
}

private struct ProfileInitials: View {
    let name: String
    
    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.purple, .pink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text(name.prefix(1).uppercased())
                .font(.system(size: 48, weight: .bold))
                .foregroundStyle(.white)
        }
    }
}

// MARK: - Beautiful Stats Row
private struct BeautifulStatsRow: View {
    let profile: UserProfile
    
    var body: some View {
        HStack(spacing: 12) {
            ProfileStatCard(
                icon: "person.3.fill",
                value: formatNumber(profile.followerCount),
                label: "Followers",
                color: Color.purple
            )
            
            ProfileStatCard(
                icon: "photo.fill",
                value: "\(profile.mediaURLs.count)",
                label: "Posts",
                color: Color.blue
            )
            
            ProfileStatCard(
                icon: "star.fill",
                value: "\(profile.contentStyles.count)",
                label: "Styles",
                color: Color.orange
            )
        }
    }
}

private struct ProfileStatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            
            Text(value)
                .font(.title3.bold())
            
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
        )
    }
}

// MARK: - Profile Completion Bar
private struct ProfileCompletionBar: View {
    let profile: UserProfile
    
    @State private var animateProgress = false
    
    var completionPercentage: Double {
        var score = 0.0
        if profile.profileImageURL != nil { score += 20 }
        if profile.bio != nil && !profile.bio!.isEmpty { score += 20 }
        if !profile.contentStyles.isEmpty { score += 20 }
        if !profile.mediaURLs.isEmpty { score += 20 }
        if profile.socialLinks.instagram != nil || profile.socialLinks.tiktok != nil { score += 20 }
        return score
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Profile Completion", systemImage: "checkmark.circle.fill")
                    .font(.subheadline.bold())
                
                Spacer()
                
                Text("\(Int(completionPercentage))%")
                    .font(.subheadline.bold())
                    .foregroundStyle(AppTheme.accent)
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [AppTheme.accent, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * (animateProgress ? completionPercentage / 100 : 0), height: 8)
                }
            }
            .frame(height: 8)
            
            if completionPercentage < 100 {
                Text("Complete your profile to get more visibility")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white)
                .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
        )
        .onAppear {
            withAnimation(.spring(response: 1.0).delay(0.2)) {
                animateProgress = true
            }
        }
    }
}

// MARK: - Beautiful Bio Card
private struct BeautifulBioCard: View {
    let bio: String
    
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("About")
                .font(.headline)
            
            Text(bio)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(isExpanded ? nil : 3)
            
            if bio.count > 100 {
                Button(isExpanded ? "Show Less" : "Read More") {
                    withAnimation {
                        isExpanded.toggle()
                    }
                }
                .font(.caption.bold())
                .foregroundStyle(AppTheme.accent)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white)
                .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
        )
    }
}

// MARK: - Content Styles Card
private struct ContentStylesCard: View {
    let styles: [UserProfile.ContentStyle]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Content Styles")
                .font(.headline)
            
            FlowLayout(spacing: 8) {
                ForEach(styles, id: \.self) { style in
                    HStack(spacing: 6) {
                        Image(systemName: style.icon)
                            .font(.caption)
                        Text(style.rawValue)
                            .font(.caption.bold())
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(AppTheme.accent.opacity(0.1), in: Capsule())
                    .foregroundStyle(AppTheme.accent)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white)
                .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
        )
    }
}

// MARK: - Media Gallery Section
private struct MediaGallerySection: View {
    let mediaURLs: [String]
    
    @State private var selectedImage: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Media")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(mediaURLs.prefix(10), id: \.self) { url in
                        AsyncImage(url: URL(string: url)) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                            default:
                                Color.gray.opacity(0.2)
                            }
                        }
                        .frame(width: 140, height: 180)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .onTapGesture {
                            selectedImage = url
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .fullScreenCover(item: Binding(
            get: { selectedImage.map { ImageWrapper(url: $0) } },
            set: { selectedImage = $0?.url }
        )) { wrapper in
            ImageViewer(imageURL: wrapper.url)
        }
    }
}

struct ImageWrapper: Identifiable {
    let id = UUID()
    let url: String
}

private struct ImageViewer: View {
    let imageURL: String
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            AsyncImage(url: URL(string: imageURL)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                default:
                    ProgressView()
                }
            }
            
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

// MARK: - Social Links Card
private struct SocialLinksCard: View {
    let profile: UserProfile
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Social Links")
                .font(.headline)
            
            VStack(spacing: 10) {
                if let instagram = profile.socialLinks.instagram {
                    SocialLinkRow(
                        platform: "Instagram",
                        username: instagram.username,
                        followers: instagram.followerCount,
                        icon: "camera.fill",
                        color: Color(red: 0.8, green: 0.3, blue: 0.6)
                    )
                }
                
                if let tiktok = profile.socialLinks.tiktok {
                    SocialLinkRow(
                        platform: "TikTok",
                        username: tiktok.username,
                        followers: tiktok.followerCount,
                        icon: "music.note",
                        color: .black
                    )
                }
                
                if let youtube = profile.socialLinks.youtube {
                    SocialLinkRow(
                        platform: "YouTube",
                        username: youtube.username,
                        followers: youtube.followerCount,
                        icon: "play.rectangle.fill",
                        color: .red
                    )
                }
                
                if let twitch = profile.socialLinks.twitch {
                    SocialLinkRow(
                        platform: "Twitch",
                        username: twitch.username,
                        followers: twitch.followerCount,
                        icon: "videoprojector.fill",
                        color: .purple
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white)
                .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
        )
    }
}

private struct SocialLinkRow: View {
    let platform: String
    let username: String
    let followers: Int?
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(platform)
                    .font(.subheadline.bold())
                
                Text("@\(username)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if let followers = followers {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(formatNumber(followers))
                        .font(.caption.bold())
                    Text("followers")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Stats & Achievements Card
private struct StatsAchievementsCard: View {
    let profile: UserProfile
    let onTapStats: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Performance")
                    .font(.headline)
                
                Spacer()
                
                Button("View All") {
                    onTapStats()
                }
                .font(.caption.bold())
                .foregroundStyle(AppTheme.accent)
            }
            
            HStack(spacing: 12) {
                MiniStatCard(
                    icon: "eye.fill",
                    value: "\(Int.random(in: 500...2000))",
                    label: "Views",
                    color: Color.blue
                )
                
                MiniStatCard(
                    icon: "heart.fill",
                    value: "\(Int.random(in: 50...500))",
                    label: "Likes",
                    color: Color.pink
                )
                
                MiniStatCard(
                    icon: "message.fill",
                    value: "\(Int.random(in: 10...100))",
                    label: "Messages",
                    color: Color.green
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
        )
    }
}

private struct MiniStatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            
            Text(value)
                .font(.headline)
            
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Collaboration Card
private struct CollaborationCard: View {
    let preferences: UserProfile.CollaborationPreferences
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Open to Collaborate")
                .font(.headline)
            
            if !preferences.lookingFor.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Looking for:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    FlowLayout(spacing: 8) {
                        ForEach(preferences.lookingFor, id: \.self) { type in
                            Text(type.rawValue)
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.1), in: Capsule())
                                .foregroundStyle(.blue)
                        }
                    }
                }
            }
            
            Divider()
            
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundStyle(.orange)
                Text(preferences.responseTime.rawValue)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white)
                .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
        )
    }
}

// MARK: - Clean Edit Sheet
struct CleanEditSheet: View {
    let profile: UserProfile
    @ObservedObject var viewModel: ProfileViewModel
    let onSave: () -> Void
    @Environment(\.dismiss) var dismiss
    
    @State private var displayName: String
    @State private var bio: String
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var isUploading = false
    
    init(profile: UserProfile, viewModel: ProfileViewModel, onSave: @escaping () -> Void) {
        self.profile = profile
        self.viewModel = viewModel
        self.onSave = onSave
        _displayName = State(initialValue: profile.displayName)
        _bio = State(initialValue: profile.bio ?? "")
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Profile Photo") {
                    HStack {
                        if let imageURL = profile.profileImageURL, let url = URL(string: imageURL) {
                            AsyncImage(url: url) { image in
                                image.resizable().scaledToFill()
                            } placeholder: {
                                Color.gray
                            }
                            .frame(width: 70, height: 70)
                            .clipShape(Circle())
                        }
                        
                        Spacer()
                        
                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            Text("Change")
                                .font(.subheadline.bold())
                                .foregroundStyle(AppTheme.accent)
                        }
                    }
                    
                    if isUploading {
                        ProgressView("Uploading...")
                    }
                }
                
                Section("Basic Info") {
                    TextField("Display Name", text: $displayName)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Bio")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextEditor(text: $bio)
                            .frame(height: 100)
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            var updated = profile
                            updated.displayName = displayName
                            updated.bio = bio.isEmpty ? nil : bio
                            await viewModel.updateProfile(updated)
                            onSave()
                            dismiss()
                        }
                    }
                    .bold()
                    .disabled(displayName.isEmpty)
                }
            }
            .onChange(of: selectedPhoto) { _, newValue in
                guard let newValue else { return }
                Task {
                    isUploading = true
                    defer { isUploading = false }
                    
                    if let data = try? await newValue.loadTransferable(type: Data.self),
                       let compressed = UIImage(data: data)?.jpegData(compressionQuality: 0.7),
                       let uid = Auth.auth().currentUser?.uid {
                        await viewModel.updateProfilePhoto(userId: uid, imageData: compressed)
                    }
                }
            }
        }
    }
}

// MARK: - Beautiful Stats Sheet
struct BeautifulStatsSheet: View {
    let profile: UserProfile
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Growth Chart
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .foregroundStyle(AppTheme.accent)
                            Text("Growth Trends")
                                .font(.title2.bold())
                        }

                        VStack(spacing: 16) {
                            // Followers Chart
                            GrowthChartCard(
                                title: "Followers",
                                value: formatNumber(profile.followerCount),
                                change: "+\(Int.random(in: 10...30))%",
                                data: generateTrendData(),
                                color: .purple
                            )

                            // Engagement Chart
                            GrowthChartCard(
                                title: "Engagement",
                                value: "8.5%",
                                change: "+5.2%",
                                data: generateTrendData(),
                                color: .pink
                            )

                            // Profile Views Chart
                            GrowthChartCard(
                                title: "Profile Views",
                                value: "\(Int.random(in: 1000...5000))",
                                change: "+\(Int.random(in: 15...40))%",
                                data: generateTrendData(),
                                color: .blue
                            )
                        }
                    }
                    .padding()
                    .background(.white, in: RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.05), radius: 8, y: 4)

                    // Overview
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "chart.bar.fill")
                                .foregroundStyle(AppTheme.accent)
                            Text("Overview")
                                .font(.title2.bold())
                        }

                        VStack(spacing: 12) {
                            StatDetailRow(label: "Total Followers", value: formatNumber(profile.followerCount), icon: "person.3.fill", color: .purple)
                            StatDetailRow(label: "Total Posts", value: "\(profile.mediaURLs.count)", icon: "photo.fill", color: .blue)
                            StatDetailRow(label: "Engagement Rate", value: "8.5%", icon: "heart.fill", color: .pink)
                            StatDetailRow(label: "Profile Views", value: "\(Int.random(in: 1000...5000))", icon: "eye.fill", color: .green)
                        }
                    }
                    .padding()
                    .background(.white, in: RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.05), radius: 8, y: 4)

                    // Growth This Month
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "arrow.up.right.circle.fill")
                                .foregroundStyle(.green)
                            Text("This Month")
                                .font(.title2.bold())
                        }

                        VStack(spacing: 12) {
                            StatDetailRow(label: "New Followers", value: "+\(Int.random(in: 50...200))", icon: "plus.circle.fill", color: .green)
                            StatDetailRow(label: "New Matches", value: "+\(Int.random(in: 5...20))", icon: "heart.circle.fill", color: .pink)
                            StatDetailRow(label: "Messages Sent", value: "\(Int.random(in: 20...100))", icon: "message.fill", color: .blue)
                            StatDetailRow(label: "Profile Visits", value: "+\(Int.random(in: 100...500))", icon: "person.fill", color: .orange)
                        }
                    }
                    .padding()
                    .background(.white, in: RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.05), radius: 8, y: 4)

                    // Content Performance
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundStyle(.orange)
                            Text("Content Performance")
                                .font(.title2.bold())
                        }

                        VStack(spacing: 12) {
                            StatDetailRow(label: "Avg. Likes per Post", value: "\(Int.random(in: 100...500))", icon: "hand.thumbsup.fill", color: .blue)
                            StatDetailRow(label: "Total Shares", value: "\(Int.random(in: 50...200))", icon: "square.and.arrow.up", color: .green)
                            StatDetailRow(label: "Comments", value: "\(Int.random(in: 30...150))", icon: "bubble.left.fill", color: .purple)
                            StatDetailRow(label: "Saves", value: "\(Int.random(in: 20...100))", icon: "bookmark.fill", color: .orange)
                        }
                    }
                    .padding()
                    .background(.white, in: RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.05), radius: 8, y: 4)

                    // Top Content Styles
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundStyle(.yellow)
                            Text("Top Content Styles")
                                .font(.title2.bold())
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(profile.contentStyles.prefix(3), id: \.self) { style in
                                HStack {
                                    Image(systemName: style.icon)
                                        .foregroundStyle(AppTheme.accent)
                                    Text(style.rawValue)
                                        .font(.body)
                                    Spacer()
                                    Text("\(Int.random(in: 50...100))%")
                                        .font(.caption.bold())
                                        .foregroundStyle(.secondary)
                                }
                                .padding()
                                .background(Color.gray.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }
                    .padding()
                    .background(.white, in: RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.05), radius: 8, y: 4)

                    // Social Media Breakdown
                    if profile.socialLinks.instagram != nil || profile.socialLinks.tiktok != nil {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "link.circle.fill")
                                    .foregroundStyle(.blue)
                                Text("Social Media Stats")
                                    .font(.title2.bold())
                            }

                            VStack(spacing: 12) {
                                if let instagram = profile.socialLinks.instagram {
                                    StatDetailRow(
                                        label: "Instagram",
                                        value: formatNumber(instagram.followerCount ?? 0),
                                        icon: "camera.fill",
                                        color: Color(red: 0.8, green: 0.3, blue: 0.6)
                                    )
                                }
                                if let tiktok = profile.socialLinks.tiktok {
                                    StatDetailRow(
                                        label: "TikTok",
                                        value: formatNumber(tiktok.followerCount ?? 0),
                                        icon: "music.note",
                                        color: .black
                                    )
                                }
                                if let youtube = profile.socialLinks.youtube {
                                    StatDetailRow(
                                        label: "YouTube",
                                        value: formatNumber(youtube.followerCount ?? 0),
                                        icon: "play.rectangle.fill",
                                        color: .red
                                    )
                                }
                            }
                        }
                        .padding()
                        .background(.white, in: RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
                    }
                }
                .padding()
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Analytics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    func generateTrendData() -> [Double] {
        var data: [Double] = []
        var current = Double.random(in: 50...100)
        for _ in 0..<30 {
            current += Double.random(in: -5...10)
            current = max(20, min(100, current))
            data.append(current)
        }
        return data
    }
}

private struct StatDetailRow: View {
    let label: String
    let value: String
    var icon: String? = nil
    var color: Color = .blue

    var body: some View {
        HStack(spacing: 12) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
                    .frame(width: 32)
            }

            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .font(.headline.bold())
                .foregroundStyle(color)
        }
        .padding()
        .background(Color.gray.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Beautiful Guest View
private struct BeautifulGuestView: View {
    @EnvironmentObject var auth: AuthViewModel

    var body: some View {
        ZStack {
            AppTheme.gradient.ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(.white.opacity(0.2))
                            .frame(width: 120, height: 120)
                            .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)

                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.white)
                    }

                    Text("Welcome to FEATUR")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(.white)

                    Text("Sign in to connect with creators, save your matches, and unlock premium features.")
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .lineSpacing(4)
                }

                Spacer()

                VStack(spacing: 16) {
                    SignInWithAppleButton(.signIn) { request in
                        let req = auth.makeAppleRequest()
                        request.requestedScopes = req.requestedScopes ?? []
                        request.nonce = req.nonce
                    } onCompletion: { result in
                        Task { await auth.handleApple(result: result) }
                    }
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 56)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)

                    if let msg = auth.errorMessage, !msg.isEmpty {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption)
                            Text(msg)
                                .font(.caption)
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(.red.opacity(0.3), in: RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
        }
    }
}

// MARK: - Beautiful Loading View
private struct BeautifulLoadingView: View {
    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground).ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(AppTheme.accent)
                
                Text("Loading Profile...")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Success Toast
private struct SuccessToast: View {
    let message: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
            
            Text(message)
                .font(.subheadline.bold())
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white)
                .shadow(color: .black.opacity(0.1), radius: 10)
        )
        .padding(.horizontal)
    }
}

// MARK: - Scroll Offset Key
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - QR Code Sheet
struct QRCodeSheet: View {
    let profile: UserProfile
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()

                Text("Scan to Connect")
                    .font(.title.bold())

                // QR Code Display
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(AppTheme.gradient)
                        .frame(width: 280, height: 280)
                        .shadow(color: AppTheme.accent.opacity(0.3), radius: 20, y: 10)

                    RoundedRectangle(cornerRadius: 20)
                        .fill(.white)
                        .frame(width: 240, height: 240)

                    Image(systemName: "qrcode")
                        .font(.system(size: 120))
                        .foregroundStyle(.black)
                }

                // Profile Info
                VStack(spacing: 8) {
                    if let imageURL = profile.profileImageURL, let url = URL(string: imageURL) {
                        AsyncImage(url: url) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            Color.gray
                        }
                        .frame(width: 60, height: 60)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(.white, lineWidth: 3))
                        .shadow(radius: 5)
                    }

                    Text(profile.displayName)
                        .font(.headline)

                    Text("@\(profile.uid.prefix(8))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Action Buttons
                HStack(spacing: 16) {
                    Button {
                        // Save QR functionality
                        Haptics.impact(.medium)
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                            Text("Save")
                        }
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppTheme.accent, in: RoundedRectangle(cornerRadius: 16))
                    }

                    Button {
                        // Share functionality
                        Haptics.impact(.medium)
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share")
                        }
                        .font(.headline)
                        .foregroundStyle(AppTheme.accent)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppTheme.accent.opacity(0.15), in: RoundedRectangle(cornerRadius: 16))
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 20)
            }
            .navigationTitle("QR Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Share Profile Sheet
struct ShareProfileSheet: View {
    let profile: UserProfile
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                // Profile Preview
                VStack(spacing: 16) {
                    if let imageURL = profile.profileImageURL, let url = URL(string: imageURL) {
                        AsyncImage(url: url) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            ProgressView()
                        }
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(.white, lineWidth: 4))
                        .shadow(radius: 10)
                    } else {
                        Circle()
                            .fill(AppTheme.gradient)
                            .frame(width: 100, height: 100)
                            .overlay(
                                Text(profile.displayName.prefix(1))
                                    .font(.system(size: 42, weight: .bold))
                                    .foregroundStyle(.white)
                            )
                            .shadow(radius: 10)
                    }

                    VStack(spacing: 4) {
                        Text(profile.displayName)
                            .font(.title2.bold())

                        if let bio = profile.bio {
                            Text(bio)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .padding(.horizontal)
                        }
                    }
                }

                // Share Link
                VStack(spacing: 12) {
                    HStack {
                        Text("featur.app/\(profile.uid.prefix(8))")
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                            .padding()
                            .background(Color.gray.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))

                        Button {
                            UIPasteboard.general.string = "featur.app/\(profile.uid)"
                            Haptics.impact(.light)
                        } label: {
                            Image(systemName: "doc.on.doc")
                                .font(.title3)
                                .foregroundStyle(AppTheme.accent)
                                .padding(12)
                                .background(AppTheme.accent.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(.horizontal)
                }

                Spacer()

                // Share Buttons
                VStack(spacing: 12) {
                    Button {
                        // Share via system share sheet
                        Haptics.impact(.medium)
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share Profile")
                        }
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppTheme.accent, in: RoundedRectangle(cornerRadius: 16))
                    }

                    Button {
                        // Copy link
                        UIPasteboard.general.string = "featur.app/\(profile.uid)"
                        Haptics.notify(.success)
                    } label: {
                        HStack {
                            Image(systemName: "link")
                            Text("Copy Link")
                        }
                        .font(.headline)
                        .foregroundStyle(AppTheme.accent)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppTheme.accent.opacity(0.15), in: RoundedRectangle(cornerRadius: 16))
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
            }
            .navigationTitle("Share Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
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

// MARK: - Growth Chart Card
private struct GrowthChartCard: View {
    let title: String
    let value: String
    let change: String
    let data: [Double]
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text(value)
                        .font(.title2.bold())
                        .foregroundStyle(color)
                }

                Spacer()

                Text(change)
                    .font(.caption.bold())
                    .foregroundStyle(.green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.green.opacity(0.1), in: Capsule())
            }

            MiniSparklineChart(data: data, color: color)
                .frame(height: 60)
        }
        .padding()
        .background(Color.gray.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Mini Sparkline Chart
private struct MiniSparklineChart: View {
    let data: [Double]
    let color: Color

    @State private var animateChart = false

    var body: some View {
        GeometryReader { geometry in
            let path = createPath(in: geometry.size)

            ZStack(alignment: .bottomLeading) {
                // Gradient fill
                path
                    .fill(
                        LinearGradient(
                            colors: [
                                color.opacity(0.3),
                                color.opacity(0.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .scaleEffect(y: animateChart ? 1 : 0, anchor: .bottom)

                // Line stroke
                path
                    .stroke(color, lineWidth: 2)
                    .scaleEffect(y: animateChart ? 1 : 0, anchor: .bottom)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                animateChart = true
            }
        }
    }

    func createPath(in size: CGSize) -> Path {
        var path = Path()

        guard !data.isEmpty else { return path }

        let stepX = size.width / CGFloat(data.count - 1)
        let maxValue = data.max() ?? 1.0
        let minValue = data.min() ?? 0.0
        let range = maxValue - minValue

        path.move(to: CGPoint(
            x: 0,
            y: size.height - (CGFloat(data[0] - minValue) / CGFloat(range)) * size.height
        ))

        for (index, value) in data.enumerated() {
            let x = CGFloat(index) * stepX
            let y = size.height - (CGFloat(value - minValue) / CGFloat(range)) * size.height
            path.addLine(to: CGPoint(x: x, y: y))
        }

        return path
    }
}
