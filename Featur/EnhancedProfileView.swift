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
                Text("Guest Mode")
               // PremiumGuestView()
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
struct LoadingProfileScreen: View {
    var body: some View {
        ProgressView("Loading Profile...")
            .padding()
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

                    if let prefs = profile.collaborationPreferences {
                        // Collaboration Details Card
                        CollaborationDetailsCard(preferences: prefs)
                            .padding(.horizontal)
                            .padding(.top, 20)

                        // 3D Interactive Profile Card
                        Interactive3DProfileCard(profile: profile)
                            .padding(.horizontal)
                            .padding(.top, 20)

                        // Profile Insights Card
                        ProfileInsightsCard(profile: profile)
                            .padding(.horizontal)
                            .padding(.top, 20)

                        // Testimonials Section
                        TestimonialsSection()
                            .padding(.horizontal)
                            .padding(.top, 20)

                        // Collaboration History
                        CollaborationHistorySection(profile: profile)
                            .padding(.horizontal)
                            .padding(.top, 20)
                    }

                    // Bottom Padding
                    Color.clear.frame(height: 100)
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
                
                // Floating Action Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        FloatingActionMenu(
                            onNewPost: {
                                Haptics.impact(.medium)
                            },
                            onMessage: {
                                Haptics.impact(.medium)
                            },
                            onShare: {
                                showShareSheet = true
                                Haptics.impact(.medium)
                            }
                        )
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                    }
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
                if let currentProfile = viewModel.profile {
                    ProfilePreviewView(profile: currentProfile)
                }
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
            ZStack {
                // Animated gradient base
                AnimatedGradientBackground(animate: animateGradient)
                    .frame(height: 320 + max(0, scrollOffset * 0.5))
                    .clipped()
                    .onAppear {
                        withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                            animateGradient = true
                        }
                    }
                
                // Animated mesh gradient overlay
                MeshGradientOverlay()
                    .frame(height: 320 + max(0, scrollOffset * 0.5))
                    .opacity(0.6)
                    .blendMode(.overlay)
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
                if profile.isVerified ?? false {
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
            HStack(spacing: 8) {
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
                
                QuickActionButton(
                    icon: "bookmark.fill",
                    label: "Saved",
                    color: .orange,
                    action: {
                        Haptics.impact(.medium)
                    }
                )
            }
            .padding()
            .background(
                .ultraThinMaterial,
                in: RoundedRectangle(cornerRadius: 20)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.15), radius: 15, y: 5)
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
                        value: profile.followerCount ?? 0,
                        icon: "person.3.fill",
                        color: .purple,
                        animate: animateNumbers,
                        trendData: generateTrendData()
                    )
                    
                    AnimatedStatCard(
                        title: "Matches",
                        value: Int.random(in: 20...100),
                        icon: "heart.fill",
                        color: .pink,
                        animate: animateNumbers,
                        trendData: generateTrendData()
                    )
                }
                
                HStack(spacing: 12) {
                    AnimatedStatCard(
                        title: "Profile Views",
                        value: Int.random(in: 500...2000),
                        icon: "eye.fill",
                        color: .blue,
                        animate: animateNumbers,
                        trendData: generateTrendData()
                    )
                    
                    AnimatedStatCard(
                        title: "Collabs",
                        value: Int.random(in: 5...30),
                        icon: "star.fill",
                        color: .orange,
                        animate: animateNumbers,
                        trendData: generateTrendData()
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
        
        func generateTrendData() -> [Double] {
            (0..<7).map { _ in Double.random(in: 0.3...1.0) }
        }
    }
    
    private struct AnimatedStatCard: View {
        let title: String
        let value: Int
        let icon: String
        let color: Color
        let animate: Bool
        let trendData: [Double]
        func formatNumber(_ value: Int) -> String {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
        }
        
        var body: some View {
            VStack(spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.caption)
                        .foregroundStyle(color)
                    
                    Text(title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                }
                
                Text(formatNumber(animate ? value : 0))
                    .font(.title2.bold())
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText())
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Mini sparkline chart
                MiniSparklineChart(data: trendData, color: color)
                    .frame(height: 30)
            }
            .padding()
            .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(color.opacity(0.2), lineWidth: 1)
            )
        }
    }
    
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
            
            path.move(to: CGPoint(
                x: 0,
                y: size.height - (CGFloat(data[0]) / CGFloat(maxValue)) * size.height
            ))
            
            for (index, value) in data.enumerated() {
                let x = CGFloat(index) * stepX
                let y = size.height - (CGFloat(value) / CGFloat(maxValue)) * size.height
                path.addLine(to: CGPoint(x: x, y: y))
            }
            
            return path
        }
    }
    
    // MARK: - Profile Strength Card
    private struct ProfileStrengthCard: View {
        let profile: UserProfile
        
        var completionPercentage: Double {
            var score = 0.0
            if profile.profileImageURL != nil { score += 20 }
            if let bio = profile.bio, !bio.isEmpty { score += 15 }
            if !profile.contentStyles.isEmpty { score += 15 }
            if !(profile.mediaURLs ?? []).isEmpty {
                score += 15
            }
            if profile.location != nil { score += 10 }
            if !(profile.interests ?? []).isEmpty {
                score += 10
            }
            if profile.socialLinks?.instagram != nil || profile.socialLinks?.tiktok != nil {
                score += 15
            }
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
            if profile.bio?.isEmpty ?? true { tips.append("Add a bio") }
            if (profile.mediaURLs ?? []).isEmpty { tips.append("Upload content") }
            if profile.socialLinks?.instagram == nil && profile.socialLinks?.tiktok  == nil {
                tips.append("Connect social accounts")
            }
            return Array(tips.prefix(3))
        }
    }
    
    // MARK: - Achievement Showcase
    private struct AchievementShowcase: View {
        let profile: UserProfile
        
        @State private var selectedAchievement: Achievement?
        @State private var animateProgress = false
        
        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Achievements")
                        .font(.headline)
                    
                    Spacer()
                    
                    // Achievement Progress Ring
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 3)
                            .frame(width: 40, height: 40)
                        
                        Circle()
                            .trim(from: 0, to: animateProgress ? achievementProgress : 0)
                            .stroke(
                                LinearGradient(
                                    colors: [AppTheme.accent, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                style: StrokeStyle(lineWidth: 3, lineCap: .round)
                            )
                            .frame(width: 40, height: 40)
                            .rotationEffect(.degrees(-90))
                        
                        Text("\(unlockedCount)/\(achievements.count)")
                            .font(.caption2.bold())
                    }
                    .onAppear {
                        withAnimation(.spring(response: 1.0).delay(0.3)) {
                            animateProgress = true
                        }
                    }
                }
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
                    requirement: { ($0.followerCount ?? 0) > 0 }
                ),
                Achievement(
                    id: "popular",
                    icon: "star.fill",
                    title: "Popular Creator",
                    description: "Reached 1K followers",
                    color: .orange,
                    requirement: { ($0.followerCount ?? 1000) >= 1000 }
                ),
                Achievement(
                    id: "verified",
                    icon: "checkmark.seal.fill",
                    title: "Verified",
                    description: "Got verified status",
                    color: .blue,
                    requirement: { $0.isVerified ?? false}
                ),
                Achievement(
                    id: "content_king",
                    icon: "photo.stack.fill",
                    title: "Content King",
                    description: "Uploaded 10+ photos",
                    color: .purple,
                    requirement: { ($0.mediaURLs?.count ?? 0) >= 10 }
                    
                ),
                Achievement(
                    id: "social_butterfly",
                    icon: "person.3.fill",
                    title: "Social Butterfly",
                    description: "Connected 3+ social accounts",
                    color: .cyan,
                    requirement: { profile in
                        let linkedAccounts = [
                            profile.socialLinks?.instagram,
                            profile.socialLinks?.tiktok,
                            profile.socialLinks?.youtube,
                            profile.socialLinks?.twitch
                        ].compactMap { $0 }.count
                        return linkedAccounts >= 3
                    }
                ),
                Achievement(
                    id: "complete_profile",
                    icon: "checkmark.circle.fill",
                    title: "Profile Master",
                    description: "100% profile completion",
                    color: .green,
                    requirement: { profile in
                        profile.profileImageURL != nil &&
                        profile.bio != nil &&
                        !profile.contentStyles.isEmpty &&
                        (profile.mediaURLs?.isEmpty == false)
                    }
                )
            ]
        }
        
        var unlockedCount: Int {
            achievements.filter { $0.isUnlocked(for: profile) }.count
        }
        
        var achievementProgress: Double {
            Double(unlockedCount) / Double(achievements.count)
        }
    }
    
    private struct AchievementBadge: View {
        let achievement: Achievement
        let isUnlocked: Bool
        
        @State private var shimmerOffset: CGFloat = -200
        
        var body: some View {
            VStack(spacing: 8) {
                ZStack {
                    // Background circle
                    Circle()
                        .fill(isUnlocked ? achievement.color.opacity(0.2) : Color.gray.opacity(0.2))
                        .frame(width: 70, height: 70)
                    
                    // Shimmer effect for unlocked
                    if isUnlocked {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        .clear,
                                        .white.opacity(0.3),
                                        .clear
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: 70, height: 70)
                            .offset(x: shimmerOffset)
                            .mask(Circle())
                            .onAppear {
                                withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                                    shimmerOffset = 200
                                }
                            }
                    }
                    
                    Image(systemName: achievement.icon)
                        .font(.title2)
                        .foregroundStyle(isUnlocked ? achievement.color : .gray)
                        .symbolEffect(.bounce, value: isUnlocked)
                    
                    // Lock icon overlay
                    if !isUnlocked {
                        Image(systemName: "lock.fill")
                            .font(.caption2)
                            .foregroundStyle(.gray)
                            .offset(x: 20, y: 20)
                            .background(
                                Circle()
                                    .fill(.white)
                                    .frame(width: 20, height: 20)
                            )
                    }
                }
                
                Text(achievement.title)
                    .font(.caption.bold())
                    .multilineTextAlignment(.center)
                    .frame(width: 90)
                    .foregroundStyle(isUnlocked ? .primary : .secondary)
            }
            .opacity(isUnlocked ? 1.0 : 0.6)
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
                
                if (profile.mediaURLs?.isEmpty == false) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach((profile.mediaURLs ?? []).prefix(6), id: \.self) { url in
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
                if !(profile.interests ?? []).isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Interests")
                            .font(.headline)
                        
                        FlowLayout(spacing: 8) {
                            ForEach(profile.interests ?? [], id: \.self) { interest in
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
                    if let instagram = profile.socialLinks?.instagram {
                        SocialLinkRow(
                            platform: "Instagram",
                            username: instagram.username,
                            followers: instagram.followerCount,
                            isVerified: instagram.isVerified,
                            icon: "camera.fill",
                            color: Color(red: 0.8, green: 0.3, blue: 0.6)
                        )
                    }
                    
                    if let tiktok = profile.socialLinks?.tiktok {
                        SocialLinkRow(
                            platform: "TikTok",
                            username: tiktok.username,
                            followers: tiktok.followerCount,
                            isVerified: tiktok.isVerified,
                            icon: "music.note",
                            color: .black
                        )
                    }
                    
                    if let youtube = profile.socialLinks?.youtube {
                        SocialLinkRow(
                            platform: "YouTube",
                            username: youtube.username,
                            followers: youtube.followerCount,
                            isVerified: youtube.isVerified,
                            icon: "play.rectangle.fill",
                            color: .red
                        )
                    }
                    
                    if let twitch = profile.socialLinks?.twitch {
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
    
    // MARK: - Interactive 3D Profile Card
    private struct Interactive3DProfileCard: View {
        let profile: UserProfile
        
        @State private var dragAmount = CGSize.zero
        @State private var isPressed = false
        
        var body: some View {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Profile Card")
                            .font(.headline)
                        
                        Text("Swipe to see 3D effect")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "hand.draw")
                        .foregroundStyle(AppTheme.accent)
                        .font(.title3)
                }
                
                ZStack {
                    // Card background with gradient
                    RoundedRectangle(cornerRadius: 24)
                        .fill(
                            LinearGradient(
                                colors: [
                                    AppTheme.accent,
                                    AppTheme.accent.opacity(0.7),
                                    Color.purple
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 200)
                        .shadow(color: AppTheme.accent.opacity(0.4), radius: 20, x: 0, y: 10)
                    
                    // Glossy overlay
                    RoundedRectangle(cornerRadius: 24)
                        .fill(
                            LinearGradient(
                                colors: [
                                    .white.opacity(0.3),
                                    .clear,
                                    .white.opacity(0.1)
                                ],
                                startPoint: UnitPoint(
                                    x: 0.5 + dragAmount.width / 500,
                                    y: 0 + dragAmount.height / 500
                                ),
                                endPoint: UnitPoint(
                                    x: 0.5 - dragAmount.width / 500,
                                    y: 1 - dragAmount.height / 500
                                )
                            )
                        )
                        .frame(height: 200)
                    
                    // Card content
                    HStack(spacing: 16) {
                        // Profile image
                        if let imageURL = profile.profileImageURL, let url = URL(string: imageURL) {
                            AsyncImage(url: url) { image in
                                image.resizable().scaledToFill()
                            } placeholder: {
                                Color.white.opacity(0.3)
                            }
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(.white, lineWidth: 2)
                            )
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 6) {
                                Text(profile.displayName)
                                    .font(.title3.bold())
                                    .foregroundStyle(.white)
                                
                                if profile.isVerified ?? false {
                                    Image(systemName: "checkmark.seal.fill")
                                        .foregroundStyle(.white)
                                }
                            }
                            
                            Text("@\(profile.uid.prefix(8))")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.8))
                            
                            HStack(spacing: 12) {
                                CardStat(icon: "heart.fill", value: "\(formatNumber(profile.followerCount ?? 0))")
                                CardStat(icon: "star.fill", value: "\(profile.contentStyles.count)")
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(20)
                }
                .rotation3DEffect(
                    .degrees(Double(dragAmount.width) / 20),
                    axis: (x: 0, y: 1, z: 0)
                )
                .rotation3DEffect(
                    .degrees(Double(-dragAmount.height) / 20),
                    axis: (x: 1, y: 0, z: 0)
                )
                .scaleEffect(isPressed ? 0.98 : 1.0)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            dragAmount = value.translation
                            isPressed = true
                        }
                        .onEnded { _ in
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                                dragAmount = .zero
                                isPressed = false
                            }
                        }
                )
            }
            .padding()
            .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
        }
    }
    
    private struct CardStat: View {
        let icon: String
        let value: String
        
        var body: some View {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                Text(value)
                    .font(.caption.bold())
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.white.opacity(0.2), in: Capsule())
        }
    }
    
    // MARK: - Profile Insights Card
    private struct ProfileInsightsCard: View {
        let profile: UserProfile
        
        @State private var showInsights = false
        
        var body: some View {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Label("Profile Insights", systemImage: "chart.xyaxis.line")
                        .font(.headline)
                    
                    Spacer()
                    
                    Button {
                        withAnimation(.spring()) {
                            showInsights.toggle()
                        }
                        Haptics.impact(.light)
                    } label: {
                        Image(systemName: showInsights ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                            .foregroundStyle(AppTheme.accent)
                    }
                }
                
                if showInsights {
                    VStack(spacing: 16) {
                        // Engagement Rate
                        InsightRow(
                            title: "Engagement Rate",
                            value: "8.5%",
                            trend: "+2.3%",
                            isPositive: true,
                            icon: "chart.line.uptrend.xyaxis",
                            color: .green
                        )
                        
                        // Response Rate
                        InsightRow(
                            title: "Response Rate",
                            value: "92%",
                            trend: "+5%",
                            isPositive: true,
                            icon: "message.badge.filled.fill",
                            color: .blue
                        )
                        
                        // Profile Completion
                        InsightRow(
                            title: "Profile Quality",
                            value: "Excellent",
                            trend: "Top 10%",
                            isPositive: true,
                            icon: "star.fill",
                            color: .orange
                        )
                        
                        // Weekly Growth
                        InsightRow(
                            title: "Weekly Growth",
                            value: "+\(Int.random(in: 50...200))",
                            trend: "Above average",
                            isPositive: true,
                            icon: "arrow.up.right.circle.fill",
                            color: .purple
                        )
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding()
            .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
        }
    }
    
    private struct InsightRow: View {
        let title: String
        let value: String
        let trend: String
        let isPositive: Bool
        let icon: String
        let color: Color
        
        var body: some View {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: icon)
                        .foregroundStyle(color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Text(value)
                        .font(.headline)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(trend)
                        .font(.caption)
                        .foregroundStyle(isPositive ? .green : .red)
                    
                    Image(systemName: isPositive ? "arrow.up.right" : "arrow.down.right")
                        .font(.caption2)
                        .foregroundStyle(isPositive ? .green : .red)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
        }
    }
    
    // MARK: - Featured Content Carousel
    private struct FeaturedContentCarousel: View {
        let profile: UserProfile
        
        @State private var currentIndex = 0
        
        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Featured Content")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    Spacer()
                    
                    Button("See All") {
                        Haptics.impact(.light)
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.accent)
                    .padding(.horizontal)
                }
                
                if (profile.mediaURLs ?? []).isEmpty {
                    TabView(selection: $currentIndex) {
                        ForEach(Array((profile.mediaURLs ?? []).prefix(5).enumerated()), id: \.offset) { index, url in
                            FeaturedContentCard(imageURL: url, index: index)
                                .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .automatic))
                    .frame(height: 280)
                } else {
                    EmptyFeaturedContentCard()
                        .padding(.horizontal)
                }
            }
        }
    }
    
    private struct FeaturedContentCard: View {
        let imageURL: String
        let index: Int

        @State private var isLiked = false
        
        var body: some View {
            ZStack(alignment: .bottomLeading) {
                AsyncImage(url: URL(string: imageURL)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .empty:
                        Color.gray.opacity(0.2)
                            .overlay(ProgressView())
                    default:
                        Color.gray.opacity(0.2)
                    }
                }
                .frame(height: 280)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                
                // Gradient Overlay
                LinearGradient(
                    colors: [.clear, .black.opacity(0.7)],
                    startPoint: .center,
                    endPoint: .bottom
                )
                .frame(height: 280)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                
                // Content Info
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Image(systemName: "eye.fill")
                            Text("\(Int.random(in: 500...5000))")
                        }
                        .font(.caption.bold())
                        
                        HStack(spacing: 6) {
                            Image(systemName: "heart.fill")
                            Text("\(Int.random(in: 50...500))")
                        }
                        .font(.caption.bold())
                    }
                    .foregroundStyle(.white)
                    
                    Spacer()
                    
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            isLiked.toggle()
                        }
                        Haptics.impact(.medium)
                    } label: {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .font(.title2)
                            .foregroundStyle(isLiked ? .red : .white)
                            .symbolEffect(.bounce, value: isLiked)
                    }
                }
                .padding()
            }
            .padding(.horizontal)
        }
    }
    
    private struct EmptyFeaturedContentCard: View {
        var body: some View {
            VStack(spacing: 16) {
                Image(systemName: "star.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(AppTheme.accent.opacity(0.5))
                
                Text("No Featured Content")
                    .font(.headline)
                
                Text("Upload your best work to feature here")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 200)
            .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 20))
        }
    }
    
    // MARK: - Skills & Expertise Section
    private struct SkillsExpertiseSection: View {
        let profile: UserProfile
        
        let skills = [
            ("Video Editing", 0.9),
            ("Content Creation", 0.85),
            ("Photography", 0.75),
            ("Social Media", 0.95),
            ("Collaboration", 0.88)
        ]
        
        var body: some View {
            VStack(alignment: .leading, spacing: 16) {
                Text("Skills & Expertise")
                    .font(.headline)
                
                VStack(spacing: 12) {
                    ForEach(skills, id: \.0) { skill in
                        SkillBar(name: skill.0, proficiency: skill.1)
                    }
                }
            }
            .padding()
            .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
        }
    }
    
    private struct SkillBar: View {
        let name: String
        let proficiency: Double
        
        @State private var animatedProficiency: Double = 0
        
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(name)
                        .font(.subheadline)
                    
                    Spacer()
                    
                    Text("\(Int(proficiency * 100))%")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                }
                
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [AppTheme.accent, AppTheme.accent.opacity(0.7)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * animatedProficiency, height: 8)
                    }
                }
                .frame(height: 8)
            }
            .onAppear {
                withAnimation(.spring(response: 0.8).delay(0.1)) {
                    animatedProficiency = proficiency
                }
            }
        }
    }
    
    // MARK: - Testimonials Section
    private struct TestimonialsSection: View {
        var body: some View {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Testimonials")
                        .font(.headline)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        ForEach(0..<5) { _ in
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundStyle(.yellow)
                        }
                        Text("4.9")
                            .font(.caption.bold())
                    }
                }
                
                VStack(spacing: 12) {
                    TestimonialCard(
                        name: "Sarah Johnson",
                        role: "Content Creator",
                        rating: 5,
                        text: "Amazing collaborator! Professional and creative. Highly recommend!",
                        imageURL: nil
                    )
                    
                    TestimonialCard(
                        name: "Marcus Chen",
                        role: "Video Editor",
                        rating: 5,
                        text: "Great to work with! Delivered high-quality content on time.",
                        imageURL: nil
                    )
                    
                    TestimonialCard(
                        name: "Alex Rivera",
                        role: "Photographer",
                        rating: 4,
                        text: "Talented creator with excellent communication skills.",
                        imageURL: nil
                    )
                }
            }
            .padding()
            .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
        }
    }
    
    private struct TestimonialCard: View {
        let name: String
        let role: String
        let rating: Int
        let text: String
        let imageURL: String?
        
        var body: some View {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 12) {
                    if let imageURL = imageURL, let url = URL(string: imageURL) {
                        AsyncImage(url: url) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            Circle().fill(AppTheme.accent.opacity(0.3))
                        }
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                    } else {
                        ZStack {
                            Circle()
                                .fill(AppTheme.accent.opacity(0.3))
                                .frame(width: 40, height: 40)
                            
                            Text(name.prefix(1))
                                .font(.headline)
                                .foregroundStyle(AppTheme.accent)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(name)
                            .font(.subheadline.bold())
                        
                        Text(role)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 2) {
                        ForEach(0..<rating, id: \.self) { _ in
                            Image(systemName: "star.fill")
                                .font(.caption2)
                                .foregroundStyle(.yellow)
                        }
                    }
                }
                
                Text(text)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }
            .padding()
            .background(Color.gray.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
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
            _selectedInterests = State(initialValue: Set(profile.interests ?? []))
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

                        if let qrImage = qrImage {
                            Image(uiImage: qrImage)
                                .resizable()
                                .interpolation(.none)
                                .frame(width: 220, height: 220)
                        } else {
                            ProgressView()
                        }
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
                            if let qrImage = qrImage {
                                UIImageWriteToSavedPhotosAlbum(qrImage, nil, nil, nil)
                                Haptics.notify(.success)
                            }
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
                .task {
                    // Generate QR code with real HTTPS URL
                    let profileURL = "https://featur.app/profile/\(profile.uid)"

                    // Try to load profile image for center
                    var centerImage: UIImage?
                    if let imageURL = profile.profileImageURL,
                       let url = URL(string: imageURL),
                       let imageData = try? Data(contentsOf: url) {
                        centerImage = UIImage(data: imageData)
                    }

                    // Generate QR code
                    qrImage = QRCodeGenerator.generateStylized(
                        from: profileURL,
                        centerImage: centerImage,
                        size: CGSize(width: 512, height: 512)
                    )
                }
                .sheet(isPresented: $showShareSheet) {
                    if let qrImage = qrImage {
                        ShareSheet(items: [qrImage])
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
                                    value: "\((profile.mediaURLs ?? []).count)",
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
    
    // MARK: - Preview Profile Image Helper
    struct PreviewProfileImage: View {
        let imageURL: String?

        var body: some View {
            Group {
                if let imageURL = imageURL, let url = URL(string: imageURL) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        placeholderView
                    }
                    .frame(width: UIScreen.main.bounds.width, height: 300)
                    .clipped()
                } else {
                    placeholderView
                }
            }
        }

        private var placeholderView: some View {
            Rectangle()
                .fill(AppTheme.accent.opacity(0.2))
                .frame(height: 300)
                .overlay(ProgressView().tint(.white))
        }
    }

    // MARK: - Profile Preview Content Sections
    struct PreviewContentSection: View {
        let profile: UserProfile

        var body: some View {
            VStack(spacing: 20) {
                PreviewNameSection(profile: profile)
                PreviewActionButtons()
                PreviewBioSection(bio: profile.bio)
                PreviewContentStylesSection(styles: profile.contentStyles)
                PreviewSocialLinksSection(profile: profile)
            }
            .padding()
            .padding(.bottom, 100)
        }
    }

    struct PreviewActionButtons: View {
        var body: some View {
            HStack(spacing: 12) {
                // Like Button (preview only - non-functional)
                HStack {
                    Image(systemName: "heart")
                    Text("Like")
                }
                .font(.headline)
                .foregroundStyle(AppTheme.accent)
                .frame(maxWidth: .infinity)
                .padding()
                .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))

                // Message Button (preview only - non-functional)
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
        }
    }

    struct PreviewNameSection: View {
        let profile: UserProfile

        var body: some View {
            HStack {
                Text(profile.displayName)
                    .font(.system(size: 28, weight: .bold))
                if profile.isVerified ?? false {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(.blue)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    struct PreviewBioSection: View {
        let bio: String?

        var body: some View {
            Group {
                if let bio = bio, !bio.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("About")
                            .font(.headline)
                        Text(bio)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    struct PreviewContentStylesSection: View {
        let styles: [UserProfile.ContentStyle]

        var body: some View {
            Group {
                if !styles.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Content Styles")
                            .font(.headline)
                        FlowLayout(spacing: 8) {
                            ForEach(styles, id: \.self) { style in
                                styleTag(style)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }

        private func styleTag(_ style: UserProfile.ContentStyle) -> some View {
            Text(style.rawValue)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(AppTheme.accent.opacity(0.15), in: Capsule())
                .foregroundStyle(AppTheme.accent)
        }
    }

    struct PreviewSocialLinksSection: View {
        let profile: UserProfile

        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                if hasAnySocialLinks {
                    Text("Social Links")
                        .font(.headline)

                    VStack(spacing: 8) {
                        if let handle = profile.socialLinks?.instagram?.username {
                            socialLinkRow(icon: "camera.fill", color: .purple, handle: handle)
                        }
                        if let handle = profile.socialLinks?.tiktok?.username {
                            socialLinkRow(icon: "music.note", color: .black, handle: handle)
                        }
                        if let handle = profile.socialLinks?.youtube?.username {
                            socialLinkRow(icon: "play.rectangle.fill", color: .red, handle: handle)
                        }
                        if let handle = profile.socialLinks?.twitch?.username {
                            socialLinkRow(icon: "tv.fill", color: .purple, handle: handle)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }

        private var hasAnySocialLinks: Bool {
            profile.socialLinks?.instagram?.username != nil || profile.socialLinks?.tiktok?.username != nil ||
            profile.socialLinks?.youtube?.username != nil || profile.socialLinks?.twitch?.username != nil
        }

        private func socialLinkRow(icon: String, color: Color, handle: String) -> some View {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text("@\(handle)")
                Spacer()
            }
            .padding(12)
            .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Profile Preview View
    struct ProfilePreviewView: View {
        let profile: UserProfile
        @Environment(\.dismiss) var dismiss

        var body: some View {
            NavigationStack {
                ScrollView {
                    VStack(spacing: 20) {
                        PreviewProfileImage(imageURL: profile.profileImageURL)
                        PreviewContentSection(profile: profile)
                    }
                }
                .background(AppTheme.bg)
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
    
    private struct MeshGradientOverlay: View {
        @State private var phase: CGFloat = 0
        
        var body: some View {
            GeometryReader { geometry in
                ZStack {
                    ForEach(0..<5) { i in
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color.white.opacity(0.15),
                                        Color.white.opacity(0.05),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 150
                                )
                            )
                            .frame(width: 300, height: 300)
                            .offset(
                                x: cos(phase + Double(i) * 0.5) * 100,
                                y: sin(phase + Double(i) * 0.7) * 80
                            )
                            .blur(radius: 30)
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
            .onAppear {
                withAnimation(.linear(duration: 10).repeatForever(autoreverses: false)) {
                    phase = .pi * 2
                }
            }
        }
    }
    
    // MARK: - Collaboration History Section
    private struct CollaborationHistorySection: View {
        let profile: UserProfile
        
        let collaborations = [
            CollabItem(name: "Sarah J.", project: "Beauty Campaign", date: "2 weeks ago", image: nil, status: .completed),
            CollabItem(name: "Marcus C.", project: "Gaming Stream", date: "1 month ago", image: nil, status: .completed),
            CollabItem(name: "Alex R.", project: "Photography Series", date: "Ongoing", image: nil, status: .active)
        ]
        
        var body: some View {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Label("Collaboration History", systemImage: "person.2.fill")
                        .font(.headline)
                    
                    Spacer()
                    
                    Text("\(collaborations.count)")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(AppTheme.accent, in: Capsule())
                }
                
                VStack(spacing: 12) {
                    ForEach(collaborations) { collab in
                        CollabHistoryCard(collab: collab)
                    }
                }
            }
            .padding()
            .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
        }
    }
    
    struct CollabItem: Identifiable {
        let id = UUID()
        let name: String
        let project: String
        let date: String
        let image: String?
        let status: CollabStatus
        
        enum CollabStatus {
            case active, completed, pending
            
            var color: Color {
                switch self {
                case .active: return .green
                case .completed: return .blue
                case .pending: return .orange
                }
            }
            
            var icon: String {
                switch self {
                case .active: return "checkmark.circle.fill"
                case .completed: return "checkmark.seal.fill"
                case .pending: return "clock.fill"
                }
            }
        }
    }
    
    private struct CollabHistoryCard: View {
        let collab: CollabItem
        
        var body: some View {
            HStack(spacing: 12) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(AppTheme.accent.opacity(0.3))
                        .frame(width: 50, height: 50)
                    
                    Text(collab.name.prefix(1))
                        .font(.title3.bold())
                        .foregroundStyle(AppTheme.accent)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(collab.project)
                        .font(.subheadline.bold())
                    
                    HStack(spacing: 6) {
                        Text(collab.name)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Circle()
                            .fill(Color.secondary)
                            .frame(width: 2, height: 2)
                        
                        Text(collab.date)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: collab.status.icon)
                        .font(.caption)
                    Text(collab.status == .active ? "Active" : collab.status == .completed ? "Done" : "Pending")
                        .font(.caption2.bold())
                }
                .foregroundStyle(collab.status.color)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(collab.status.color.opacity(0.15), in: Capsule())
            }
            .padding()
            .background(Color.gray.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
        }
    }
    
    // MARK: - Creator Stats Dashboard
    private struct CreatorStatsDashboard: View {
        let profile: UserProfile
        
        @State private var selectedMetric: StatMetric = .engagement
        
        enum StatMetric: String, CaseIterable {
            case engagement = "Engagement"
            case reach = "Reach"
            case growth = "Growth"
            
            var icon: String {
                switch self {
                case .engagement: return "chart.bar.fill"
                case .reach: return "arrow.up.forward"
                case .growth: return "chart.line.uptrend.xyaxis"
                }
            }
            
            var color: Color {
                switch self {
                case .engagement: return .blue
                case .reach: return .purple
                case .growth: return .green
                }
            }
        }
        
        var body: some View {
            VStack(alignment: .leading, spacing: 16) {
                Text("Creator Dashboard")
                    .font(.headline)
                
                // Metric Selector
                HStack(spacing: 8) {
                    ForEach(StatMetric.allCases, id: \.self) { metric in
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                selectedMetric = metric
                            }
                            Haptics.impact(.light)
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: metric.icon)
                                    .font(.caption)
                                Text(metric.rawValue)
                                    .font(.caption.bold())
                            }
                            .foregroundStyle(selectedMetric == metric ? .white : .primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                selectedMetric == metric ? metric.color : Color.gray.opacity(0.1),
                                in: Capsule()
                            )
                        }
                    }
                }
                
                // Metric Display
                VStack(spacing: 16) {
                    HStack(alignment: .bottom, spacing: 8) {
                        Text(metricValue)
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundStyle(selectedMetric.color)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.up.right")
                                Text("+12.5%")
                            }
                            .font(.caption.bold())
                            .foregroundStyle(.green)
                            
                            Text("vs last week")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .offset(y: -8)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Bar Chart
                    HStack(alignment: .bottom, spacing: 8) {
                        ForEach(0..<7, id: \.self) { index in
                            VStack(spacing: 4) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(
                                        LinearGradient(
                                            colors: [selectedMetric.color, selectedMetric.color.opacity(0.6)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .frame(width: 32, height: CGFloat.random(in: 40...120))
                                
                                Text(dayLabel(for: index))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(selectedMetric.color.opacity(0.05))
                )
            }
            .padding()
            .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
        }
        
        var metricValue: String {
            switch selectedMetric {
            case .engagement: return "8.5%"
            case .reach: return "12.3K"
            case .growth: return "+847"
            }
        }
        
        func dayLabel(for index: Int) -> String {
            let days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
            return days[index]
        }
    }
    
    // MARK: - Content Calendar Preview
    private struct ContentCalendarPreview: View {
        @State private var selectedDate = Date()
        
        let scheduledPosts = [
            ScheduledPost(date: Date(), title: "New Tutorial Video", type: .video),
            ScheduledPost(date: Date().addingTimeInterval(86400), title: "Behind the Scenes", type: .photo),
            ScheduledPost(date: Date().addingTimeInterval(86400 * 2), title: "Q&A Session", type: .live)
        ]
        
        var body: some View {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Label("Content Calendar", systemImage: "calendar")
                        .font(.headline)
                    
                    Spacer()
                    
                    Button("View All") {
                        Haptics.impact(.light)
                    }
                    .font(.caption.bold())
                    .foregroundStyle(AppTheme.accent)
                }
                
                // Week View
                HStack(spacing: 8) {
                    ForEach(0..<7, id: \.self) { day in
                        CalendarDayCell(
                            day: day + 1,
                            hasContent: [1, 3, 5].contains(day + 1),
                            isSelected: day == 0
                        )
                    }
                }
                
                // Scheduled Posts
                VStack(spacing: 10) {
                    ForEach(scheduledPosts.prefix(3)) { post in
                        ScheduledPostRow(post: post)
                    }
                }
            }
            .padding()
            .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
        }
    }
    
    struct ScheduledPost: Identifiable {
        let id = UUID()
        let date: Date
        let title: String
        let type: PostType
        
        enum PostType {
            case video, photo, live
            
            var icon: String {
                switch self {
                case .video: return "video.fill"
                case .photo: return "photo.fill"
                case .live: return "waveform"
                }
            }
            
            var color: Color {
                switch self {
                case .video: return .red
                case .photo: return .blue
                case .live: return .purple
                }
            }
        }
    }
    
    private struct CalendarDayCell: View {
        let day: Int
        let hasContent: Bool
        let isSelected: Bool
        
        var body: some View {
            VStack(spacing: 4) {
                Text("\(day)")
                    .font(.caption.bold())
                    .foregroundStyle(isSelected ? .white : .primary)
                
                if hasContent {
                    Circle()
                        .fill(isSelected ? .white : AppTheme.accent)
                        .frame(width: 4, height: 4)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                isSelected ? AppTheme.accent : Color.gray.opacity(0.1),
                in: RoundedRectangle(cornerRadius: 8)
            )
        }
    }
    
    private struct ScheduledPostRow: View {
        let post: ScheduledPost
        
        var body: some View {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(post.type.color.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: post.type.icon)
                        .foregroundStyle(post.type.color)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(post.title)
                        .font(.subheadline.bold())
                    
                    Text(post.date, style: .time)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color.gray.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
        }
    }
    
    // MARK: - Networking Score Card
    private struct NetworkingScoreCard: View {
        let profile: UserProfile
        
        @State private var animateScore = false
        
        var networkingScore: Int {
            var score = 50
            if profile.isVerified ?? false { score += 20 }
            if (profile.followerCount ?? 0) > 1000 { score += 15 }
            if !profile.contentStyles.isEmpty { score += 10 }
            if profile.socialLinks?.instagram != nil { score += 5 }
            return min(score, 100)
        }
        
        var body: some View {
            VStack(spacing: 20) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Networking Score")
                            .font(.headline)
                        
                        Text("Based on profile activity and engagement")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                }
                
                HStack(spacing: 32) {
                    // Score Ring
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                            .frame(width: 120, height: 120)
                        
                        Circle()
                            .trim(from: 0, to: animateScore ? Double(networkingScore) / 100 : 0)
                            .stroke(
                                AngularGradient(
                                    colors: [.green, .yellow, .orange, .red, .purple],
                                    center: .center
                                ),
                                style: StrokeStyle(lineWidth: 12, lineCap: .round)
                            )
                            .frame(width: 120, height: 120)
                            .rotationEffect(.degrees(-90))
                        
                        VStack(spacing: 4) {
                            Text("\(networkingScore)")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                            Text("Score")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    // Score Breakdown
                    VStack(alignment: .leading, spacing: 12) {
                        ScoreFactorRow(icon: "checkmark.seal.fill", label: "Verified", value: (profile.isVerified ?? false) ? 20 : 0, maxValue: 20)
                        ScoreFactorRow(icon: "person.3.fill", label: "Followers", value: (profile.followerCount ?? 0) > 1000 ? 15 : 5, maxValue: 15)
                        ScoreFactorRow(icon: "photo.fill", label: "Content", value: 10, maxValue: 10)
                        ScoreFactorRow(icon: "link", label: "Socials", value: 5, maxValue: 5)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppTheme.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [AppTheme.accent.opacity(0.3), .purple.opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
            )
            .onAppear {
                withAnimation(.spring(response: 1.5).delay(0.3)) {
                    animateScore = true
                }
            }
        }
    }
    
    private struct ScoreFactorRow: View {
        let icon: String
        let label: String
        let value: Int
        let maxValue: Int
        
        var body: some View {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(value > 0 ? .green : .secondary)
                    .frame(width: 20)
                
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text("+\(value)")
                    .font(.caption.bold())
                    .foregroundStyle(value > 0 ? .green : .secondary)
            }
        }
    }
    
    // MARK: - Profile Milestones Section
    private struct ProfileMilestonesSection: View {
        let profile: UserProfile
        
        let milestones = [
            Milestone(icon: "star.fill", title: "Reached 1K Followers", date: "2 weeks ago", color: .yellow, isAchieved: true),
            Milestone(icon: "heart.fill", title: "100 Matches", date: "1 month ago", color: .pink, isAchieved: true),
            Milestone(icon: "photo.fill", title: "Upload 50 Photos", date: "Next milestone", color: .blue, isAchieved: false),
            Milestone(icon: "flame.fill", title: "30 Day Streak", date: "Coming soon", color: .orange, isAchieved: false)
        ]
        
        var body: some View {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Label("Milestones", systemImage: "flag.fill")
                        .font(.headline)
                    
                    Spacer()
                    
                    Text("\(milestones.filter { $0.isAchieved }.count)/\(milestones.count)")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(AppTheme.accent, in: Capsule())
                }
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(milestones) { milestone in
                        MilestoneCard(milestone: milestone)
                    }
                }
            }
            .padding()
            .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
        }
    }
    
    struct Milestone: Identifiable {
        let id = UUID()
        let icon: String
        let title: String
        let date: String
        let color: Color
        let isAchieved: Bool
    }
    
    private struct MilestoneCard: View {
        let milestone: Milestone
        
        @State private var bounce = false
        
        var body: some View {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(milestone.isAchieved ? milestone.color.opacity(0.2) : Color.gray.opacity(0.1))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: milestone.icon)
                        .font(.title2)
                        .foregroundStyle(milestone.isAchieved ? milestone.color : .gray)
                        .scaleEffect(bounce ? 1.1 : 1.0)
                    
                    if !milestone.isAchieved {
                        Image(systemName: "lock.fill")
                            .font(.caption2)
                            .foregroundStyle(.gray)
                            .offset(x: 20, y: 20)
                            .background(
                                Circle()
                                    .fill(.white)
                                    .frame(width: 18, height: 18)
                            )
                    }
                }
                .onAppear {
                    if milestone.isAchieved {
                        withAnimation(.spring(response: 0.5).repeatForever(autoreverses: true)) {
                            bounce = true
                        }
                    }
                }
                
                VStack(spacing: 4) {
                    Text(milestone.title)
                        .font(.caption.bold())
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                    
                    Text(milestone.date)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.05))
            )
            .opacity(milestone.isAchieved ? 1.0 : 0.6)
        }
    }
    
    // MARK: - Recent Visitors Section
    private struct RecentVisitorsSection: View {
        @State private var visitors = generateVisitors()
        @State private var showAll = false
        
        var body: some View {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Label("Recent Visitors", systemImage: "eye.fill")
                        .font(.headline)
                    
                    Spacer()
                    
                    Button(showAll ? "Show Less" : "Show All") {
                        withAnimation(.spring()) {
                            showAll.toggle()
                        }
                        Haptics.impact(.light)
                    }
                    .font(.caption.bold())
                    .foregroundStyle(AppTheme.accent)
                }
                
                VStack(spacing: 10) {
                    ForEach(Array(visitors.prefix(showAll ? 10 : 3).enumerated()), id: \.offset) { index, visitor in
                        VisitorRow(visitor: visitor)
                            .transition(.asymmetric(
                                insertion: .move(edge: .leading).combined(with: .opacity),
                                removal: .move(edge: .trailing).combined(with: .opacity)
                            ))
                    }
                }
            }
            .padding()
            .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
        }
        
        static func generateVisitors() -> [Visitor] {
            let names = ["Emma Wilson", "James Lee", "Sofia Garcia", "Noah Kim", "Olivia Brown", "Liam Chen", "Ava Martinez", "Mason Taylor"]
            let times = ["2 min ago", "15 min ago", "1 hour ago", "3 hours ago", "5 hours ago", "1 day ago", "2 days ago", "3 days ago"]
            let verifiedStatus = [true, false, true, false, false, true, false, true]

            return zip(zip(names, times), verifiedStatus).map { nameTime, verified in
                Visitor(name: nameTime.0, time: nameTime.1, isVerified: verified)
            }
        }
    }
    
    struct Visitor: Identifiable {
        let id = UUID()
        let name: String
        let time: String
        let isVerified: Bool
    }
    
    private struct VisitorRow: View {
        let visitor: Visitor
        
        var body: some View {
            HStack(spacing: 12) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [AppTheme.accent, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                    
                    Text(visitor.name.prefix(1))
                        .font(.headline)
                        .foregroundStyle(.white)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(visitor.name)
                            .font(.subheadline.bold())
                        
                        if visitor.isVerified {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.caption2)
                                .foregroundStyle(.blue)
                        }
                    }
                    
                    Text(visitor.time)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Button {
                    Haptics.impact(.light)
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
        }
    }
    
    // MARK: - Creator Badges Section
    private struct CreatorBadgesSection: View {
        let profile: UserProfile
        
        let badges = [
            CreatorBadge(icon: "star.fill", title: "Top Creator", description: "Top 5% this month", color: .yellow),
            CreatorBadge(icon: "flame.fill", title: "Hot Streak", description: "30 days active", color: .orange),
            CreatorBadge(icon: "bolt.fill", title: "Quick Responder", description: "Fast reply time", color: .blue),
            CreatorBadge(icon: "heart.fill", title: "Community Favorite", description: "Highly rated", color: .pink),
            CreatorBadge(icon: "trophy.fill", title: "Rising Star", description: "Fastest growing", color: .purple),
            CreatorBadge(icon: "sparkles", title: "Quality Content", description: "High engagement", color: .cyan)
        ]
        
        var body: some View {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Label("Creator Badges", systemImage: "rosette")
                        .font(.headline)
                    
                    Spacer()
                    
                    Text("\(badges.count)")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(AppTheme.accent, in: Capsule())
                }
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(badges) { badge in
                        CreatorBadgeCard(badge: badge)
                    }
                }
            }
            .padding()
            .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
        }
    }
    
    struct CreatorBadge: Identifiable {
        let id = UUID()
        let icon: String
        let title: String
        let description: String
        let color: Color
    }
    
    private struct CreatorBadgeCard: View {
        let badge: CreatorBadge
        
        @State private var shimmer = false
        
        var body: some View {
            VStack(spacing: 10) {
                ZStack {
                    // Background with shimmer
                    Circle()
                        .fill(badge.color.opacity(0.2))
                        .frame(width: 60, height: 60)
                    
                    // Shimmer overlay
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.clear, .white.opacity(0.5), .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 60, height: 60)
                        .offset(x: shimmer ? 100 : -100)
                        .mask(Circle())
                    
                    Image(systemName: badge.icon)
                        .font(.title3)
                        .foregroundStyle(badge.color)
                }
                .onAppear {
                    withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                        shimmer = true
                    }
                }
                
                VStack(spacing: 2) {
                    Text(badge.title)
                        .font(.caption.bold())
                        .multilineTextAlignment(.center)
                    
                    Text(badge.description)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [badge.color.opacity(0.05), badge.color.opacity(0.02)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(badge.color.opacity(0.2), lineWidth: 1)
            )
        }
    }
    
    // MARK: - Floating Action Menu
    private struct FloatingActionMenu: View {
        let onNewPost: () -> Void
        let onMessage: () -> Void
        let onShare: () -> Void
        
        @State private var isExpanded = false
        
        var body: some View {
            VStack(spacing: 16) {
                if isExpanded {
                    FloatingActionButton(
                        icon: "square.and.pencil.fill",
                        color: .blue,
                        size: 50
                    ) {
                        onNewPost()
                        withAnimation(.spring()) { isExpanded = false }
                    }
                    .transition(.scale.combined(with: .opacity))
                    
                    FloatingActionButton(
                        icon: "paperplane.fill",
                        color: .green,
                        size: 50
                    ) {
                        onMessage()
                        withAnimation(.spring()) { isExpanded = false }
                    }
                    .transition(.scale.combined(with: .opacity))
                    
                    FloatingActionButton(
                        icon: "square.and.arrow.up.fill",
                        color: .orange,
                        size: 50
                    ) {
                        onShare()
                        withAnimation(.spring()) { isExpanded = false }
                    }
                    .transition(.scale.combined(with: .opacity))
                }
                
                // Main FAB
                FloatingActionButton(
                    icon: isExpanded ? "xmark" : "plus",
                    color: AppTheme.accent,
                    size: 60
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isExpanded.toggle()
                    }
                    Haptics.impact(.medium)
                }
            }
        }
    }
    
    private struct FloatingActionButton: View {
        let icon: String
        let color: Color
        let size: CGFloat
        let action: () -> Void
        
        @State private var isPressed = false
        
        var body: some View {
            Button(action: action) {
                ZStack {
                    Circle()
                        .fill(color)
                        .frame(width: size, height: size)
                        .shadow(color: color.opacity(0.4), radius: 10, y: 5)
                    
                    Image(systemName: icon)
                        .font(.system(size: size * 0.4, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .scaleEffect(isPressed ? 0.9 : 1.0)
            .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity, pressing: { pressing in
                withAnimation(.spring(response: 0.3)) {
                    isPressed = pressing
                }
            }, perform: {})
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

