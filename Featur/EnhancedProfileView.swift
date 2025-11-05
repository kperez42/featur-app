// EnhancedProfileView.swift - PREMIUM PROFILE PAGE v2.0
import SwiftUI
import FirebaseAuth
import PhotosUI

struct EnhancedProfileView: View {
    @EnvironmentObject var auth: AuthViewModel
    @StateObject private var viewModel = ProfileViewModel()
    @State private var showEditSheet = false
    @State private var showSettingsSheet = false
    @State private var showQRSheet = false
    @State private var showShareSheet = false
    @State private var showStatsSheet = false
    @State private var scrollOffset: CGFloat = 0
    
    var body: some View {
        Group {
            if auth.user == nil {
                PremiumGuestView()
            } else if viewModel.needsSetup {
                ProfileCreationFlow(viewModel: viewModel)
            } else if let profile = viewModel.profile {
                MainProfileContent(
                    profile: profile,
                    viewModel: viewModel,
                    showEditSheet: $showEditSheet,
                    showSettingsSheet: $showSettingsSheet,
                    showQRSheet: $showQRSheet,
                    showShareSheet: $showShareSheet,
                    showStatsSheet: $showStatsSheet,
                    scrollOffset: $scrollOffset
                )
            } else {
                LoadingProfileScreen()
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
private struct MainProfileContent: View {
    let profile: UserProfile
    @ObservedObject var viewModel: ProfileViewModel
    @Binding var showEditSheet: Bool
    @Binding var showSettingsSheet: Bool
    @Binding var showQRSheet: Bool
    @Binding var showShareSheet: Bool
    @Binding var showStatsSheet: Bool
    @Binding var scrollOffset: CGFloat
    @EnvironmentObject var auth: AuthViewModel
    
    @State private var selectedTab = 0
    @State private var showSuccessBanner = false
    @State private var showProfilePreview = false
    
    var body: some View {
        ZStack(alignment: .top) {
            ScrollView {
                VStack(spacing: 0) {
                    // Enhanced Hero with 3D Effect
                    ProfileHeroSection(
                        profile: profile,
                        scrollOffset: scrollOffset,
                        onEdit: { showEditSheet = true },
                        onShare: { showShareSheet = true },
                        onQR: { showQRSheet = true },
                        onPreview: { showProfilePreview = true }
                    )
                    .background(
                        GeometryReader { geo in
                            Color.clear.preference(
                                key: ScrollOffsetKey.self,
                                value: geo.frame(in: .named("scroll")).minY
                            )
                        }
                    )
                    
                    // Quick Actions Bar
                    QuickActionsBar(
                        onEditProfile: { showEditSheet = true },
                        onViewStats: { showStatsSheet = true },
                        onShareProfile: { showShareSheet = true }
                    )
                    .padding(.horizontal)
                    .padding(.top, -20)
                    .zIndex(1)
                    
                    // Stats Cards with Animation
                    EnhancedStatsGrid(
                        profile: profile,
                        onTapStats: { showStatsSheet = true }
                    )
                    .padding(.horizontal)
                    .padding(.top, 20)
                    
                    // Profile Strength Indicator
                    ProfileStrengthCard(profile: profile)
                        .padding(.horizontal)
                        .padding(.top, 16)
                    
                    // Achievement Showcase
                    AchievementShowcase(profile: profile)
                        .padding(.horizontal)
                        .padding(.top, 16)
                    
                    // Content Preview Section
                    ContentPreviewSection(profile: profile)
                        .padding(.top, 20)
                    
                    // Bio & Info Section
                    BioInfoSection(profile: profile)
                        .padding(.horizontal)
                        .padding(.top, 20)
                    
                    // Social Links Grid
                    SocialLinksSection(profile: profile)
                        .padding(.horizontal)
                        .padding(.top, 20)
                    
                    // Collaboration Details
                    CollaborationDetailsCard(preferences: profile.collaborationPreferences)
                        .padding(.horizontal)
                        .padding(.top, 20)
                    
                    // Activity Timeline
                    ActivityTimelineSection()
                        .padding(.horizontal)
                        .padding(.top, 20)
                    
                    // Bottom Padding
                    Color.clear.frame(height: 100)
                }
            }
            .coordinateSpace(name: "scroll")
            .onPreferenceChange(ScrollOffsetKey.self) { value in
                scrollOffset = value
            }
            
            // Success Banner
            if showSuccessBanner {
                SuccessBanner(message: "Profile updated!")
                    .padding(.top, 60)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .background(AppTheme.bg)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(profile.displayName)
                    .font(.headline)
                    .opacity(scrollOffset < -100 ? 1 : 0)
                    .animation(.easeInOut, value: scrollOffset)
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { showEditSheet = true } label: {
                        Label("Edit Profile", systemImage: "pencil")
                    }
                    Button { showProfilePreview = true } label: {
                        Label("Preview Profile", systemImage: "eye")
                    }
                    Button { showQRSheet = true } label: {
                        Label("QR Code", systemImage: "qrcode")
                    }
                    Button { showShareSheet = true } label: {
                        Label("Share Profile", systemImage: "square.and.arrow.up")
                    }
                    Divider()
                    Button { showStatsSheet = true } label: {
                        Label("Analytics", systemImage: "chart.bar")
                    }
                    Button { showSettingsSheet = true } label: {
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
                        .symbolEffect(.bounce, value: showEditSheet)
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            EnhancedEditProfileSheet(profile: profile, viewModel: viewModel) {
                showSuccessBanner = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation { showSuccessBanner = false }
                }
            }
        }
        .sheet(isPresented: $showSettingsSheet) {
            SettingsSheet()
        }
        .sheet(isPresented: $showQRSheet) {
            EnhancedQRCodeSheet(profile: profile)
        }
        .sheet(isPresented: $showStatsSheet) {
            EnhancedStatsSheet(profile: profile)
        }
        .fullScreenCover(isPresented: $showProfilePreview) {
            ProfilePreviewView(profile: profile)
        }
    }
}

// MARK: - Enhanced Hero Section
private struct ProfileHeroSection: View {
    let profile: UserProfile
    let scrollOffset: CGFloat
    let onEdit: () -> Void
    let onShare: () -> Void
    let onQR: () -> Void
    let onPreview: () -> Void
    
    @State private var animateGradient = false
    @State private var showSparkles = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            backgroundLayer
            particlesLayer
            profileContentLayer
        }
    }
    
    private var backgroundLayer: some View {
        AnimatedGradientBackground(animate: animateGradient)
            .frame(height: 320 + max(0, scrollOffset * 0.5))
            .clipped()
            .onAppear {
                withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                    animateGradient = true
                }
            }
    }
    
    private var particlesLayer: some View {
        ParticleEffectView()
            .frame(height: 320)
            .opacity(0.3)
    }
    
    private var profileContentLayer: some View {
        VStack(spacing: 20) {
            profileImageSection
            nameAndStatusSection
        }
        .padding(.bottom, 30)
    }
    
    private var profileImageSection: some View {
        ZStack {
            glowRings
            profileImage
            if profile.isVerified {
                verifiedBadge
            }
        }
        .scaleEffect(scrollOffset < 0 ? 1 - (scrollOffset / -1000) : 1)
    }
    
    private var glowRings: some View {
        ForEach(0..<3) { i in
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.3 - Double(i) * 0.1), .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
                .frame(width: 160 + CGFloat(i * 8), height: 160 + CGFloat(i * 8))
                .blur(radius: 4)
                .opacity(animateGradient ? 0.8 : 0.4)
        }
    }
    
    private var profileImage: some View {
        Group {
            if let imageURL = profile.profileImageURL, let url = URL(string: imageURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .empty:
                        ProgressView()
                            .tint(.white)
                    case .failure:
                        InitialsAvatar(name: profile.displayName, size: 140)
                    @unknown default:
                        InitialsAvatar(name: profile.displayName, size: 140)
                    }
                }
            } else {
                InitialsAvatar(name: profile.displayName, size: 140)
            }
        }
        .frame(width: 140, height: 140)
        .clipShape(Circle())
        .overlay(Circle().stroke(.white, lineWidth: 4))
        .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
    }
    
    private var verifiedBadge: some View {
        ZStack {
            Circle()
                .fill(.white)
                .frame(width: 36, height: 36)
            
            Image(systemName: "checkmark.seal.fill")
                .font(.title2)
                .foregroundStyle(.blue)
                .symbolEffect(.bounce, value: showSparkles)
        }
        .offset(x: 50, y: 50)
        .shadow(radius: 5)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.spring()) { showSparkles = true }
            }
        }
    }
    
    private var nameAndStatusSection: some View {
        VStack(spacing: 8) {
            nameRow
            if let location = profile.location, let city = location.city {
                locationBadge(city: city, state: location.state)
            }
        }
        .shadow(radius: 10)
    }
    
    private var nameRow: some View {
        HStack(spacing: 8) {
            Text(profile.displayName)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            
            if let age = profile.age {
                Text("\(age)")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
    }
    
    private func locationBadge(city: String, state: String?) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "mappin.circle.fill")
            Text("\(city), \(state ?? "")")
        }
        .font(.subheadline)
        .foregroundStyle(.white.opacity(0.9))
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.white.opacity(0.2), in: Capsule())
    }
}

// MARK: - Quick Actions Bar
private struct QuickActionsBar: View {
    let onEditProfile: () -> Void
    let onViewStats: () -> Void
    let onShareProfile: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            QuickActionButton(
                icon: "pencil.circle.fill",
                label: "Edit",
                color: AppTheme.accent,
                action: onEditProfile
            )
            
            QuickActionButton(
                icon: "chart.bar.fill",
                label: "Stats",
                color: .blue,
                action: onViewStats
            )
            
            QuickActionButton(
                icon: "square.and.arrow.up.fill",
                label: "Share",
                color: .green,
                action: onShareProfile
            )
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
    }
}

private struct QuickActionButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            Haptics.impact(.medium)
            withAnimation(.spring(response: 0.3)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
            }
            action()
        }) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                
                Text(label)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .scaleEffect(isPressed ? 0.9 : 1.0)
    }
}

// MARK: - Enhanced Stats Grid
private struct EnhancedStatsGrid: View {
    let profile: UserProfile
    let onTapStats: () -> Void
    
    @State private var animateNumbers = false
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                AnimatedStatCard(
                    title: "Followers",
                    value: profile.followerCount,
                    icon: "person.3.fill",
                    color: .purple,
                    animate: animateNumbers
                )
                
                AnimatedStatCard(
                    title: "Matches",
                    value: Int.random(in: 20...100),
                    icon: "heart.fill",
                    color: .pink,
                    animate: animateNumbers
                )
            }
            
            HStack(spacing: 12) {
                AnimatedStatCard(
                    title: "Profile Views",
                    value: Int.random(in: 500...2000),
                    icon: "eye.fill",
                    color: .blue,
                    animate: animateNumbers
                )
                
                AnimatedStatCard(
                    title: "Collabs",
                    value: Int.random(in: 5...30),
                    icon: "star.fill",
                    color: .orange,
                    animate: animateNumbers
                )
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring()) {
                    animateNumbers = true
                }
            }
        }
        .onTapGesture(perform: onTapStats)
    }
}

private struct AnimatedStatCard: View {
    let title: String
    let value: Int
    let icon: String
    let color: Color
    let animate: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(color)
                
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Text(formatNumber(animate ? value : 0))
                .font(.title2.bold())
                .foregroundStyle(.primary)
                .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Profile Strength Card
private struct ProfileStrengthCard: View {
    let profile: UserProfile
    
    var completionPercentage: Double {
        var score = 0.0
        if profile.profileImageURL != nil { score += 20 }
        if profile.bio != nil && !profile.bio!.isEmpty { score += 15 }
        if !profile.contentStyles.isEmpty { score += 15 }
        if !profile.mediaURLs.isEmpty { score += 15 }
        if profile.location != nil { score += 10 }
        if !profile.interests.isEmpty { score += 10 }
        if profile.socialLinks.instagram != nil || profile.socialLinks.tiktok != nil { score += 15 }
        return score
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Profile Strength")
                        .font(.headline)
                    
                    Text(strengthLevel)
                        .font(.subheadline)
                        .foregroundStyle(strengthColor)
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                        .frame(width: 60, height: 60)
                    
                    Circle()
                        .trim(from: 0, to: completionPercentage / 100)
                        .stroke(strengthColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))
                    
                    Text("\(Int(completionPercentage))%")
                        .font(.caption.bold())
                }
            }
            
            // Suggestions
            if completionPercentage < 100 {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(suggestions, id: \.self) { suggestion in
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle")
                                .foregroundStyle(.green)
                            Text(suggestion)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
    }
    
    var strengthLevel: String {
        switch completionPercentage {
        case 90...100: return "Excellent!"
        case 70..<90: return "Very Good"
        case 50..<70: return "Good"
        default: return "Needs Improvement"
        }
    }
    
    var strengthColor: Color {
        switch completionPercentage {
        case 90...100: return .green
        case 70..<90: return .blue
        case 50..<70: return .orange
        default: return .red
        }
    }
    
    var suggestions: [String] {
        var tips: [String] = []
        if profile.bio == nil || profile.bio!.isEmpty { tips.append("Add a bio") }
        if profile.mediaURLs.isEmpty { tips.append("Upload content") }
        if profile.socialLinks.instagram == nil && profile.socialLinks.tiktok == nil {
            tips.append("Connect social accounts")
        }
        return Array(tips.prefix(3))
    }
}

// MARK: - Achievement Showcase
private struct AchievementShowcase: View {
    let profile: UserProfile
    
    @State private var selectedAchievement: Achievement?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Achievements")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(achievements) { achievement in
                        AchievementBadge(achievement: achievement, isUnlocked: achievement.isUnlocked(for: profile))
                            .onTapGesture {
                                selectedAchievement = achievement
                                Haptics.impact(.light)
                            }
                    }
                }
                .padding(.horizontal)
            }
        }
        .sheet(item: $selectedAchievement) { achievement in
            AchievementDetailSheet(achievement: achievement, profile: profile)
        }
    }
    
    var achievements: [Achievement] {
        [
            Achievement(
                id: "first_match",
                icon: "heart.fill",
                title: "First Match",
                description: "Got your first match!",
                color: .pink,
                requirement: { $0.followerCount > 0 }
            ),
            Achievement(
                id: "popular",
                icon: "star.fill",
                title: "Popular Creator",
                description: "Reached 1K followers",
                color: .orange,
                requirement: { $0.followerCount >= 1000 }
            ),
            Achievement(
                id: "verified",
                icon: "checkmark.seal.fill",
                title: "Verified",
                description: "Got verified status",
                color: .blue,
                requirement: { $0.isVerified }
            ),
            Achievement(
                id: "content_king",
                icon: "photo.stack.fill",
                title: "Content King",
                description: "Uploaded 10+ photos",
                color: .purple,
                requirement: { $0.mediaURLs.count >= 10 }
            )
        ]
    }
}

private struct AchievementBadge: View {
    let achievement: Achievement
    let isUnlocked: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(isUnlocked ? achievement.color.opacity(0.2) : Color.gray.opacity(0.2))
                    .frame(width: 60, height: 60)
                
                Image(systemName: achievement.icon)
                    .font(.title2)
                    .foregroundStyle(isUnlocked ? achievement.color : .gray)
            }
            
            Text(achievement.title)
                .font(.caption.bold())
                .multilineTextAlignment(.center)
                .frame(width: 80)
        }
        .opacity(isUnlocked ? 1.0 : 0.5)
        .scaleEffect(isUnlocked ? 1.0 : 0.95)
    }
}

struct Achievement: Identifiable {
    let id: String
    let icon: String
    let title: String
    let description: String
    let color: Color
    let requirement: (UserProfile) -> Bool
    
    func isUnlocked(for profile: UserProfile) -> Bool {
        requirement(profile)
    }
}

// MARK: - Content Preview Section
private struct ContentPreviewSection: View {
    let profile: UserProfile
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Content")
                .font(.headline)
                .padding(.horizontal)
            
            if !profile.mediaURLs.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(profile.mediaURLs.prefix(6), id: \.self) { url in
                            AsyncImage(url: URL(string: url)) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 120, height: 160)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                case .empty:
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(width: 120, height: 160)
                                        .overlay(ProgressView())
                                default:
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(width: 120, height: 160)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            } else {
                EmptyContentPlaceholder()
                    .padding(.horizontal)
            }
        }
    }
}

private struct EmptyContentPlaceholder: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 50))
                .foregroundStyle(.secondary)
            
            Text("No content yet")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Text("Upload photos to showcase your work")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 160)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Bio & Info Section
private struct BioInfoSection: View {
    let profile: UserProfile
    
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Bio
            if let bio = profile.bio, !bio.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("About")
                        .font(.headline)
                    
                    Text(bio)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(isExpanded ? nil : 3)
                    
                    if bio.count > 100 {
                        Button(isExpanded ? "Show Less" : "Show More") {
                            withAnimation { isExpanded.toggle() }
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.accent)
                    }
                }
            }
            
            // Content Styles
            if !profile.contentStyles.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Content Styles")
                        .font(.headline)
                    
                    FlowLayout(spacing: 8) {
                        ForEach(profile.contentStyles, id: \.self) { style in
                            HStack(spacing: 4) {
                                Image(systemName: style.icon)
                                Text(style.rawValue)
                            }
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(AppTheme.accent.opacity(0.15), in: Capsule())
                            .foregroundStyle(AppTheme.accent)
                        }
                    }
                }
            }
            
            // Interests
            if !profile.interests.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Interests")
                        .font(.headline)
                    
                    FlowLayout(spacing: 8) {
                        ForEach(profile.interests, id: \.self) { interest in
                            Text(interest)
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(AppTheme.card, in: Capsule())
                        }
                    }
                }
            }
        }
        .padding()
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Social Links Section
private struct SocialLinksSection: View {
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
                        isVerified: instagram.isVerified,
                        icon: "camera.fill",
                        color: Color(red: 0.8, green: 0.3, blue: 0.6)
                    )
                }
                
                if let tiktok = profile.socialLinks.tiktok {
                    SocialLinkRow(
                        platform: "TikTok",
                        username: tiktok.username,
                        followers: tiktok.followerCount,
                        isVerified: tiktok.isVerified,
                        icon: "music.note",
                        color: .black
                    )
                }
                
                if let youtube = profile.socialLinks.youtube {
                    SocialLinkRow(
                        platform: "YouTube",
                        username: youtube.username,
                        followers: youtube.followerCount,
                        isVerified: youtube.isVerified,
                        icon: "play.rectangle.fill",
                        color: .red
                    )
                }
                
                if let twitch = profile.socialLinks.twitch {
                    SocialLinkRow(
                        platform: "Twitch",
                        username: twitch.username,
                        followers: twitch.followerCount,
                        isVerified: twitch.isVerified,
                        icon: "videoprojector.fill",
                        color: Color(red: 0.6, green: 0.4, blue: 0.9)
                    )
                }
            }
        }
        .padding()
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct SocialLinkRow: View {
    let platform: String
    let username: String
    let followers: Int?
    let isVerified: Bool
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
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

// MARK: - Collaboration Details Card
private struct CollaborationDetailsCard: View {
    let preferences: UserProfile.CollaborationPreferences
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Collaboration Details")
                .font(.headline)
            
            // Looking For
            if !preferences.lookingFor.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Looking For", systemImage: "magnifyingglass")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    
                    FlowLayout(spacing: 8) {
                        ForEach(preferences.lookingFor, id: \.self) { type in
                            Text(type.rawValue)
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.15), in: Capsule())
                                .foregroundStyle(.blue)
                        }
                    }
                }
            }
            
            // Availability
            if !preferences.availability.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Availability", systemImage: "calendar")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 8) {
                        ForEach(preferences.availability, id: \.self) { avail in
                            Text(avail.rawValue.capitalized)
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.green.opacity(0.15), in: Capsule())
                                .foregroundStyle(.green)
                        }
                    }
                }
            }
            
            // Response Time
            HStack(spacing: 8) {
                Image(systemName: "clock.fill")
                    .foregroundStyle(.orange)
                Text(preferences.responseTime.rawValue)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.orange.opacity(0.15), in: Capsule())
        }
        .padding()
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Activity Timeline Section
private struct ActivityTimelineSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Activity")
                .font(.headline)
            
            VStack(spacing: 12) {
                ActivityTimelineItem(
                    icon: "heart.fill",
                    title: "New Match",
                    subtitle: "Matched with Sarah J.",
                    time: "2h ago",
                    color: .pink
                )
                
                ActivityTimelineItem(
                    icon: "photo.fill",
                    title: "Content Uploaded",
                    subtitle: "Added 3 new photos",
                    time: "5h ago",
                    color: .blue
                )
                
                ActivityTimelineItem(
                    icon: "message.fill",
                    title: "New Message",
                    subtitle: "From Marcus C.",
                    time: "1d ago",
                    color: .green
                )
            }
        }
        .padding()
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct ActivityTimelineItem: View {
    let icon: String
    let title: String
    let subtitle: String
    let time: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Text(time)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(Color.gray.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Enhanced Edit Profile Sheet
struct EnhancedEditProfileSheet: View {
    let profile: UserProfile
    @ObservedObject var viewModel: ProfileViewModel
    let onSave: () -> Void
    @Environment(\.dismiss) var dismiss
    
    @State private var displayName: String
    @State private var bio: String
    @State private var selectedInterests: Set<String>
    @State private var selectedContentStyles: Set<UserProfile.ContentStyle>
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var isUploading = false
    
    let availableInterests = ["Music", "Art", "Gaming", "Fitness", "Travel", "Food", "Tech", "Fashion", "Sports", "Photography"]
    
    init(profile: UserProfile, viewModel: ProfileViewModel, onSave: @escaping () -> Void) {
        self.profile = profile
        self.viewModel = viewModel
        self.onSave = onSave
        _displayName = State(initialValue: profile.displayName)
        _bio = State(initialValue: profile.bio ?? "")
        _selectedInterests = State(initialValue: Set(profile.interests))
        _selectedContentStyles = State(initialValue: Set(profile.contentStyles))
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
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                        } else {
                            InitialsAvatar(name: profile.displayName, size: 80)
                        }
                        
                        Spacer()
                        
                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            Text("Change Photo")
                                .font(.subheadline.weight(.semibold))
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
                
                Section("Content Styles") {
                    ForEach(UserProfile.ContentStyle.allCases, id: \.self) { style in
                        Toggle(isOn: Binding(
                            get: { selectedContentStyles.contains(style) },
                            set: { isOn in
                                if isOn {
                                    selectedContentStyles.insert(style)
                                } else {
                                    selectedContentStyles.remove(style)
                                }
                            }
                        )) {
                            HStack {
                                Image(systemName: style.icon)
                                Text(style.rawValue)
                            }
                        }
                        .tint(AppTheme.accent)
                    }
                }
                
                Section("Interests") {
                    ForEach(availableInterests, id: \.self) { interest in
                        Toggle(interest, isOn: Binding(
                            get: { selectedInterests.contains(interest) },
                            set: { isOn in
                                if isOn {
                                    selectedInterests.insert(interest)
                                } else {
                                    selectedInterests.remove(interest)
                                }
                            }
                        ))
                        .tint(AppTheme.accent)
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
                            updated.interests = Array(selectedInterests)
                            updated.contentStyles = Array(selectedContentStyles)
                            await viewModel.updateProfile(updated)
                            Haptics.notify(.success)
                            onSave()
                            dismiss()
                        }
                    }
                    .fontWeight(.bold)
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

// MARK: - Enhanced QR Code Sheet
struct EnhancedQRCodeSheet: View {
    let profile: UserProfile
    @Environment(\.dismiss) var dismiss
    
    @State private var showShareSheet = false
    @State private var qrImage: UIImage?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()
                
                Text("Scan to Connect")
                    .font(.title.bold())
                
                // QR Code
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.4, green: 0.3, blue: 0.8), Color(red: 0.6, green: 0.4, blue: 0.9)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 280, height: 280)
                        .shadow(color: AppTheme.accent.opacity(0.3), radius: 20, y: 10)
                    
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.white)
                        .frame(width: 240, height: 240)
                    
                    Image(systemName: "qrcode")
                        .font(.system(size: 120))
                        .foregroundStyle(.black)
                }
                
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
                    
                    Text("@\(profile.uid)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 16) {
                    Button {
                        // Download QR
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
                        showShareSheet = true
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

// MARK: - Enhanced Stats Sheet
struct EnhancedStatsSheet: View {
    let profile: UserProfile
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedPeriod: StatsPeriod = .week
    
    enum StatsPeriod: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
        case allTime = "All Time"
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Period Selector
                    Picker("Period", selection: $selectedPeriod) {
                        ForEach(StatsPeriod.allCases, id: \.self) { period in
                            Text(period.rawValue).tag(period)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    // Engagement Stats
                    StatsSection(title: "Engagement", icon: "chart.line.uptrend.xyaxis") {
                        VStack(spacing: 12) {
                            DetailedStatRow(
                                label: "Profile Views",
                                value: "\(Int.random(in: 500...5000))",
                                change: "+12%",
                                isPositive: true
                            )
                            DetailedStatRow(
                                label: "New Followers",
                                value: "+\(Int.random(in: 50...500))",
                                change: "+8%",
                                isPositive: true
                            )
                            DetailedStatRow(
                                label: "Likes Received",
                                value: "\(Int.random(in: 100...1000))",
                                change: "+15%",
                                isPositive: true
                            )
                        }
                    }
                    
                    // Match Stats
                    StatsSection(title: "Matches", icon: "heart.fill") {
                        VStack(spacing: 12) {
                            DetailedStatRow(
                                label: "Total Matches",
                                value: "\(Int.random(in: 10...100))",
                                change: "+5%",
                                isPositive: true
                            )
                            DetailedStatRow(
                                label: "Match Rate",
                                value: "24%",
                                change: "+3%",
                                isPositive: true
                            )
                            DetailedStatRow(
                                label: "Messages Sent",
                                value: "\(Int.random(in: 50...500))",
                                change: "+10%",
                                isPositive: true
                            )
                        }
                    }
                    
                    // Content Stats
                    StatsSection(title: "Content", icon: "photo.stack.fill") {
                        VStack(spacing: 12) {
                            DetailedStatRow(
                                label: "Total Photos",
                                value: "\(profile.mediaURLs.count)",
                                change: "+2",
                                isPositive: true
                            )
                            DetailedStatRow(
                                label: "Avg. Likes per Photo",
                                value: "\(Int.random(in: 50...200))",
                                change: "+18%",
                                isPositive: true
                            )
                        }
                    }
                    
                    // Growth Chart Placeholder
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Growth Overview")
                            .font(.headline)
                        
                        RoundedRectangle(cornerRadius: 16)
                            .fill(AppTheme.gradient.opacity(0.3))
                            .frame(height: 200)
                            .overlay(
                                VStack {
                                    Image(systemName: "chart.bar.fill")
                                        .font(.system(size: 50))
                                        .foregroundStyle(.white)
                                    Text("Chart Coming Soon")
                                        .font(.caption)
                                        .foregroundStyle(.white)
                                }
                            )
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(AppTheme.bg)
            .navigationTitle("Analytics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

private struct StatsSection<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundStyle(AppTheme.accent)
            
            content
        }
        .padding()
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }
}

private struct DetailedStatRow: View {
    let label: String
    let value: String
    let change: String
    let isPositive: Bool
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(value)
                    .font(.headline)
                
                HStack(spacing: 2) {
                    Image(systemName: isPositive ? "arrow.up.right" : "arrow.down.right")
                        .font(.caption2)
                    Text(change)
                        .font(.caption2)
                }
                .foregroundStyle(isPositive ? .green : .red)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Profile Preview View
struct ProfilePreviewView: View {
    let profile: UserProfile
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ProfileDetailView(profile: profile)
                .navigationTitle("Preview")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
        }
    }
}

// MARK: - Achievement Detail Sheet
struct AchievementDetailSheet: View {
    let achievement: Achievement
    let profile: UserProfile
    @Environment(\.dismiss) var dismiss
    
    var isUnlocked: Bool {
        achievement.isUnlocked(for: profile)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(isUnlocked ? achievement.color.opacity(0.2) : Color.gray.opacity(0.2))
                        .frame(width: 150, height: 150)
                    
                    Image(systemName: achievement.icon)
                        .font(.system(size: 60))
                        .foregroundStyle(isUnlocked ? achievement.color : .gray)
                        .symbolEffect(.bounce, value: isUnlocked)
                }
                
                VStack(spacing: 12) {
                    Text(achievement.title)
                        .font(.title.bold())
                    
                    Text(achievement.description)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                if isUnlocked {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("Unlocked!")
                            .font(.headline)
                            .foregroundStyle(.green)
                    }
                    .padding()
                    .background(Color.green.opacity(0.15), in: Capsule())
                } else {
                    HStack(spacing: 8) {
                        Image(systemName: "lock.fill")
                            .foregroundStyle(.gray)
                        Text("Not Yet Unlocked")
                            .font(.headline)
                            .foregroundStyle(.gray)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.15), in: Capsule())
                }
                
                Spacer()
                
                Button("Close") {
                    dismiss()
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(AppTheme.accent, in: RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 32)
                .padding(.bottom, 20)
            }
            .navigationTitle("Achievement")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Success Banner
struct SuccessBanner: View {
    let message: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
            
            Text(message)
                .font(.subheadline.weight(.semibold))
            
            Spacer()
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 10)
        .padding(.horizontal)
    }
}

// MARK: - Guest View
private struct PremiumGuestView: View {
    var body: some View {
        ZStack {
            AppTheme.gradient.ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                VStack(spacing: 20) {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 100))
                        .foregroundStyle(.white)
                        .shadow(radius: 20)
                    
                    Text("Welcome to FEATUR")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    
                    Text("Connect with creators and grow your network")
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                Spacer()
                
                VStack(spacing: 16) {
                    FeatureRow(icon: "heart.fill", text: "Match with creators like you")
                    FeatureRow(icon: "bubble.left.and.bubble.right.fill", text: "Collaborate on projects")
                    FeatureRow(icon: "star.fill", text: "Grow your following")
                    FeatureRow(icon: "chart.line.uptrend.xyaxis", text: "Track your progress")
                }
                .padding(.horizontal, 40)
                
                Spacer()
                
                NavigationLink {
                    LoginView(navigationPath: .constant(NavigationPath()))
                } label: {
                    Text("Get Started")
                        .font(.headline)
                        .foregroundStyle(AppTheme.accent)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.white, in: RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
        }
    }
}

private struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .frame(width: 32)
            Text(text)
                .font(.subheadline)
            Spacer()
        }
        .foregroundStyle(.white)
    }
}

// MARK: - Loading Screen
private struct LoadingProfileScreen: View {
    var body: some View {
        ZStack {
            AppTheme.bg.ignoresSafeArea()
            
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

// MARK: - Helper Views
private struct InitialsAvatar: View {
    let name: String
    let size: CGFloat
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [AppTheme.accent, .purple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(width: size, height: size)
            .clipShape(Circle())
            
            Text(String(name.prefix(1)).uppercased())
                .font(.system(size: size * 0.4, weight: .bold))
                .foregroundStyle(.white)
        }
        .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
    }
}

private struct AnimatedGradientBackground: View {
    let animate: Bool
    
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: animate ? 0.4 : 0.5, green: 0.3, blue: animate ? 0.8 : 0.7),
                Color(red: animate ? 0.6 : 0.5, green: 0.4, blue: animate ? 0.9 : 1.0)
            ],
            startPoint: animate ? .topLeading : .bottomLeading,
            endPoint: animate ? .bottomTrailing : .topTrailing
        )
    }
}

private struct ParticleEffectView: View {
    @State private var particles: [Particle] = []
    
    struct Particle: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var size: CGFloat
        var opacity: Double
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(.white.opacity(particle.opacity))
                        .frame(width: particle.size, height: particle.size)
                        .position(x: particle.x, y: particle.y)
                        .blur(radius: 2)
                }
            }
            .onAppear {
                generateParticles(in: geo.size)
            }
        }
    }
    
    func generateParticles(in size: CGSize) {
        particles = (0..<20).map { _ in
            Particle(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: 0...size.height),
                size: CGFloat.random(in: 2...6),
                opacity: Double.random(in: 0.1...0.3)
            )
        }
    }
}

private struct BlurView: UIViewRepresentable {
    let style: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

// MARK: - Scroll Offset Key
struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
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
