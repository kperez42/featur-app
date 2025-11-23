// EnhancedProfileView.swift - PREMIUM PROFILE PAGE v2.0
import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseFunctions
import PhotosUI

// MARK: - Stats Period Enum
enum StatsPeriod: String, CaseIterable {
    case week = "Week"
    case month = "Month"
    case year = "Year"
    case allTime = "All Time"

    var days: Int? {
        switch self {
        case .week: return 7
        case .month: return 30
        case .year: return 365
        case .allTime: return nil
        }
    }
}

struct EnhancedProfileView: View {
    @EnvironmentObject var auth: AuthViewModel
    @StateObject private var viewModel = ProfileViewModel()
    @State private var showEditSheet = false
    @State private var showSettingsSheet = false
    @State private var showQRSheet = false
    @State private var showShareSheet = false
    @State private var showStatsSheet = false
    @State private var showFeaturedSheet = false
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
                    showFeaturedSheet: $showFeaturedSheet,
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
    @Binding var showFeaturedSheet: Bool
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

                    // Verification Section
                    VerificationSection(profile: profile)
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
                        TestimonialsSection(profile: profile)
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
                        Button { showFeaturedSheet = true } label: {
                            Label("Get FEATUREd", systemImage: "star.circle")
                        }
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
                    .menuOrder(.fixed)
                    .menuStyle(.button)
                }
            }
            .sheet(isPresented: $showEditSheet) {
                if let currentProfile = viewModel.profile {
                    EnhancedEditProfileSheet(profile: currentProfile, viewModel: viewModel) {
                        showSuccessBanner = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation { showSuccessBanner = false }
                        }
                    }
                }
            }
            .onChange(of: showEditSheet) { _, isShowing in
                if isShowing {
                    // Force refresh profile from Firestore when opening edit sheet
                    Task {
                        await viewModel.refreshProfile()
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
            .sheet(isPresented: $showFeaturedSheet) {
                GetFeaturedSheet()
            }
            .sheet(isPresented: $showShareSheet) {
                let profileURL = "https://featur.app/profile/\(profile.uid)"
                let shareText = "Check out \(profile.displayName)'s profile on Featur!"
                ShareSheet(items: [shareText, URL(string: profileURL)!])
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
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
        @StateObject private var analytics = ProfileAnalyticsViewModel()

        var body: some View {
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    AnimatedStatCard(
                        title: "Followers",
                        value: profile.followerCount ?? 0,
                        icon: "person.3.fill",
                        color: .purple,
                        animate: animateNumbers,
                        trendData: generateRealisticTrendData(currentValue: profile.followerCount ?? 0)
                    )

                    AnimatedStatCard(
                        title: "Matches",
                        value: analytics.matchCount,
                        icon: "heart.fill",
                        color: .pink,
                        animate: animateNumbers,
                        trendData: generateRealisticTrendData(currentValue: analytics.matchCount)
                    )
                }

                HStack(spacing: 12) {
                    AnimatedStatCard(
                        title: "Profile Views",
                        value: analytics.profileViewCount,
                        icon: "eye.fill",
                        color: .blue,
                        animate: animateNumbers,
                        trendData: generateRealisticTrendData(currentValue: analytics.profileViewCount)
                    )

                    AnimatedStatCard(
                        title: "Collabs",
                        value: analytics.collabCount,
                        icon: "star.fill",
                        color: .orange,
                        animate: animateNumbers,
                        trendData: generateRealisticTrendData(currentValue: analytics.collabCount)
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
            .task {
                await analytics.loadAnalytics(userId: profile.uid)
            }
        }

        // Generate realistic trend data that shows growth, never negative
        func generateRealisticTrendData(currentValue: Int) -> [Double] {
            guard currentValue > 0 else {
                return Array(repeating: 0.0, count: 7)
            }

            let doubleValue = Double(currentValue)

            // Generate realistic data with natural fluctuations
            // Use consistent seed based on current value for reproducibility
            var generator = SeededRandomGenerator(seed: UInt64(currentValue))

            // Start from a lower base value
            let startValue = doubleValue * Double.random(in: 0.5...0.7, using: &generator)
            var data: [Double] = [startValue]

            // Generate 6 more days with realistic ups and downs
            for i in 1..<7 {
                let previousValue = data[i - 1]
                let targetValue = doubleValue // We want to trend toward current value

                // Calculate how far we still need to grow
                let remainingGrowth = targetValue - previousValue
                let daysRemaining = Double(7 - i)

                // Base growth per day (to reach target)
                let baseGrowth = remainingGrowth / daysRemaining

                // Add realistic variation (+/- 30% of base growth)
                let variation = baseGrowth * Double.random(in: -0.3...0.5, using: &generator)
                let dailyChange = baseGrowth + variation

                // Calculate next value, ensuring we don't go negative or overshoot too much
                var nextValue = previousValue + dailyChange
                nextValue = max(0, min(nextValue, targetValue * 1.1))

                data.append(nextValue)
            }

            // Ensure last value is exactly the current value
            data[6] = doubleValue

            return data
        }
    }

    // Custom random generator with seed for reproducible "random" data
    struct SeededRandomGenerator: RandomNumberGenerator {
        private var state: UInt64

        init(seed: UInt64) {
            self.state = seed
        }

        mutating func next() -> UInt64 {
            state = state &* 6364136223846793005 &+ 1442695040888963407
            return state
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

        // Calculate trend from data (simple: compare last value to first)
        var trendPercentage: Int {
            guard trendData.count >= 2,
                  let first = trendData.first,
                  let last = trendData.last,
                  first > 0 else { return 0 }
            let change = ((last - first) / first) * 100
            return Int(change)
        }

        var body: some View {
            VStack(spacing: 12) {
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundStyle(color)

                    Spacer()

                    // Trend indicator
                    if trendPercentage != 0 {
                        HStack(spacing: 4) {
                            Image(systemName: trendPercentage > 0 ? "arrow.up.right" : "arrow.down.right")
                                .font(.caption)
                            Text("\(abs(trendPercentage))%")
                                .font(.caption.bold())
                        }
                        .foregroundStyle(trendPercentage > 0 ? .green : .red)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background((trendPercentage > 0 ? Color.green : Color.red).opacity(0.1), in: Capsule())
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(formatNumber(animate ? value : 0))
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(.primary)
                        .contentTransition(.numericText())

                    Text(title)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(20)
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
        @State private var selectedImageIndex: Int = 0
        @State private var showFullScreenImage = false

        private var contentImages: [String] {
            profile.mediaURLs ?? []
        }

        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                Text("Content")
                    .font(.headline)
                    .padding(.horizontal)

                if !contentImages.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(Array(contentImages.enumerated()), id: \.element) { index, url in
                                AsyncImage(url: URL(string: url)) { phase in
                                    switch phase {
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 120, height: 160)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                            .onTapGesture {
                                                selectedImageIndex = index
                                                showFullScreenImage = true
                                            }
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
            .fullScreenCover(isPresented: $showFullScreenImage) {
                FullScreenImageViewer(images: contentImages, startingIndex: selectedImageIndex)
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
                    let genderValues = ["Male", "Female", "Non-binary", "Prefer not to say"]
                    let filteredInterests = (profile.interests ?? []).filter { !genderValues.contains($0) }

                    if !filteredInterests.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Interests")
                                .font(.headline)

                            FlowLayout(spacing: 8) {
                                ForEach(filteredInterests, id: \.self) { interest in
                                    HStack(spacing: 4) {
                                        Image(systemName: iconForInterest(interest))
                                        Text(interest)
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
                }
            }
            .padding()
            .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
        }

        // Map interests to SF Symbols icons (same as ProfileDetailView)
        private func iconForInterest(_ interest: String) -> String {
            let lowercased = interest.lowercased()

            // Sports & Fitness
            if lowercased.contains("fitness") || lowercased.contains("gym") || lowercased.contains("workout") {
                return "figure.run"
            } else if lowercased.contains("yoga") || lowercased.contains("meditation") {
                return "figure.yoga"
            } else if lowercased.contains("basketball") {
                return "basketball.fill"
            } else if lowercased.contains("football") || lowercased.contains("soccer") {
                return "soccerball"
            } else if lowercased.contains("tennis") {
                return "tennisball.fill"
            } else if lowercased.contains("sports") {
                return "sportscourt.fill"
            } else if lowercased.contains("running") || lowercased.contains("jogging") {
                return "figure.run"
            } else if lowercased.contains("swimming") {
                return "figure.pool.swim"
            } else if lowercased.contains("cycling") || lowercased.contains("biking") {
                return "bicycle"
            }
            // Creative Arts
            else if lowercased.contains("music") || lowercased.contains("singing") {
                return "music.note"
            } else if lowercased.contains("art") || lowercased.contains("drawing") || lowercased.contains("painting") {
                return "paintpalette.fill"
            } else if lowercased.contains("photography") || lowercased.contains("camera") {
                return "camera.fill"
            } else if lowercased.contains("dance") || lowercased.contains("dancing") {
                return "figure.dance"
            } else if lowercased.contains("film") || lowercased.contains("movie") || lowercased.contains("cinema") {
                return "film.fill"
            } else if lowercased.contains("theater") || lowercased.contains("acting") {
                return "theatermasks.fill"
            } else if lowercased.contains("writing") || lowercased.contains("poetry") {
                return "pencil.and.outline"
            }
            // Food & Drink
            else if lowercased.contains("cooking") || lowercased.contains("baking") {
                return "frying.pan.fill"
            } else if lowercased.contains("food") || lowercased.contains("cuisine") {
                return "fork.knife"
            } else if lowercased.contains("coffee") {
                return "cup.and.saucer.fill"
            } else if lowercased.contains("wine") || lowercased.contains("cocktail") {
                return "wineglass.fill"
            }
            // Technology
            else if lowercased.contains("gaming") || lowercased.contains("video game") {
                return "gamecontroller.fill"
            } else if lowercased.contains("tech") || lowercased.contains("coding") || lowercased.contains("programming") {
                return "laptopcomputer"
            } else if lowercased.contains("ai") || lowercased.contains("robot") {
                return "cpu"
            }
            // Nature & Outdoors
            else if lowercased.contains("travel") || lowercased.contains("adventure") {
                return "airplane"
            } else if lowercased.contains("hiking") || lowercased.contains("camping") {
                return "mountain.2.fill"
            } else if lowercased.contains("nature") || lowercased.contains("outdoor") {
                return "leaf.fill"
            } else if lowercased.contains("beach") || lowercased.contains("ocean") {
                return "beach.umbrella.fill"
            } else if lowercased.contains("garden") {
                return "leaf.arrow.triangle.circlepath"
            }
            // Animals
            else if lowercased.contains("pet") || lowercased.contains("dog") || lowercased.contains("cat") {
                return "pawprint.fill"
            } else if lowercased.contains("animal") {
                return "hare.fill"
            }
            // Fashion & Beauty
            else if lowercased.contains("fashion") || lowercased.contains("style") {
                return "tshirt.fill"
            } else if lowercased.contains("beauty") || lowercased.contains("makeup") {
                return "sparkles"
            } else if lowercased.contains("shopping") {
                return "bag.fill"
            }
            // Reading & Learning
            else if lowercased.contains("reading") || lowercased.contains("book") {
                return "book.fill"
            } else if lowercased.contains("podcast") {
                return "mic.fill"
            } else if lowercased.contains("learning") || lowercased.contains("education") {
                return "graduationcap.fill"
            }
            // Entertainment
            else if lowercased.contains("tv") || lowercased.contains("series") {
                return "tv.fill"
            } else if lowercased.contains("anime") || lowercased.contains("manga") {
                return "book.closed.fill"
            }
            // Health & Wellness
            else if lowercased.contains("health") || lowercased.contains("wellness") {
                return "heart.fill"
            } else if lowercased.contains("mental health") || lowercased.contains("mindfulness") {
                return "brain.head.profile"
            }
            // Social
            else if lowercased.contains("social") || lowercased.contains("networking") {
                return "person.2.fill"
            } else if lowercased.contains("volunteer") || lowercased.contains("charity") {
                return "hands.sparkles.fill"
            }
            // Default
            else {
                return "star.fill"
            }
        }
    }

    // MARK: - Verification Section
    private struct VerificationSection: View {
        let profile: UserProfile
        @State private var showEmailVerification = false
        @State private var showPhoneVerification = false

        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                Text("Verification")
                    .font(.headline)

                VStack(spacing: 12) {
                    // Email Verification
                    VerificationRow(
                        title: "Email",
                        subtitle: profile.email ?? "Not provided",
                        isVerified: profile.isEmailVerified ?? false,
                        icon: "envelope.fill",
                        color: .blue,
                        showButton: profile.isEmailVerified != true
                    ) {
                        showEmailVerification = true
                    }

                    // Phone Verification
                    VerificationRow(
                        title: "Phone Number",
                        subtitle: profile.phoneNumber ?? "Not provided",
                        isVerified: profile.isPhoneVerified ?? false,
                        icon: "phone.fill",
                        color: .green,
                        showButton: profile.isPhoneVerified != true
                    ) {
                        showPhoneVerification = true
                    }
                }
            }
            .padding()
            .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
            .sheet(isPresented: $showEmailVerification) {
                EmailVerificationView(profile: profile)
            }
            .sheet(isPresented: $showPhoneVerification) {
                PhoneVerificationView(profile: profile)
            }
        }
    }

    private struct VerificationRow: View {
        let title: String
        let subtitle: String
        let isVerified: Bool
        let icon: String
        let color: Color
        let showButton: Bool
        let onVerifyTap: () -> Void

        var body: some View {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
                    .frame(width: 32)

                // Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))

                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Status or button
                if isVerified {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(.green)
                        Text("Verified")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.green)
                    }
                } else if showButton {
                    Button {
                        onVerifyTap()
                    } label: {
                        Text("Verify")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(AppTheme.accent, in: Capsule())
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isVerified ? Color.green.opacity(0.1) : AppTheme.bg)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isVerified ? Color.green.opacity(0.3) : Color.clear, lineWidth: 1)
            )
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
        @StateObject private var insightsVM = ProfileInsightsViewModel()
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
                    if insightsVM.isLoading {
                        ProgressView("Loading insights...")
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        VStack(spacing: 16) {
                            // Engagement Rate
                            InsightRow(
                                title: "Engagement Rate",
                                value: String(format: "%.1f%%", insightsVM.engagementRate),
                                trend: insightsVM.engagementTrend,
                                isPositive: insightsVM.engagementTrendPositive,
                                icon: "chart.line.uptrend.xyaxis",
                                color: .green
                            )

                            // Response Rate
                            InsightRow(
                                title: "Response Rate",
                                value: String(format: "%.0f%%", insightsVM.responseRate),
                                trend: insightsVM.responseTrend,
                                isPositive: insightsVM.responseTrendPositive,
                                icon: "message.badge.filled.fill",
                                color: .blue
                            )

                            // Profile Completion
                            InsightRow(
                                title: "Profile Quality",
                                value: insightsVM.profileQuality,
                                trend: insightsVM.profileCompletionText,
                                isPositive: true,
                                icon: "star.fill",
                                color: .orange
                            )

                            // Weekly Growth
                            InsightRow(
                                title: "Weekly Growth",
                                value: "+\(insightsVM.weeklyGrowth)",
                                trend: insightsVM.growthTrend,
                                isPositive: insightsVM.weeklyGrowth > 0,
                                icon: "arrow.up.right.circle.fill",
                                color: .purple
                            )
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
            }
            .padding()
            .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
            .task {
                await insightsVM.loadInsights(userId: profile.uid)
            }
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
                
                if !(profile.mediaURLs ?? []).isEmpty {
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
                            .frame(maxWidth: .infinity, maxHeight: 280)
                    case .empty:
                        Color.gray.opacity(0.2)
                            .overlay(ProgressView())
                            .frame(maxWidth: .infinity, maxHeight: 280)
                    default:
                        Color.gray.opacity(0.2)
                            .frame(maxWidth: .infinity, maxHeight: 280)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 20))
                
                // Gradient Overlay
                LinearGradient(
                    colors: [.clear, .black.opacity(0.7)],
                    startPoint: .center,
                    endPoint: .bottom
                )
                .frame(maxWidth: .infinity, maxHeight: 280)
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
        let profile: UserProfile
        @StateObject private var testimonialsVM = TestimonialsViewModel()
        @State private var showAddTestimonial = false

        var body: some View {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Testimonials")
                        .font(.headline)

                    Spacer()

                    if !testimonialsVM.testimonials.isEmpty {
                        HStack(spacing: 4) {
                            ForEach(0..<5) { index in
                                Image(systemName: index < Int(testimonialsVM.averageRating) ? "star.fill" : "star")
                                    .font(.caption)
                                    .foregroundStyle(.yellow)
                            }
                            Text(String(format: "%.1f", testimonialsVM.averageRating))
                                .font(.caption.bold())
                        }
                    }
                }

                if testimonialsVM.isLoading {
                    ProgressView("Loading testimonials...")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else if testimonialsVM.testimonials.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "quote.bubble")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("No testimonials yet")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                } else {
                    VStack(spacing: 12) {
                        ForEach(testimonialsVM.testimonials.prefix(3)) { testimonial in
                            TestimonialCard(testimonial: testimonial)
                        }

                        if testimonialsVM.testimonials.count > 3 {
                            Button("View All \(testimonialsVM.testimonials.count) Testimonials") {
                                showAddTestimonial = true
                            }
                            .font(.caption)
                            .foregroundStyle(AppTheme.accent)
                        }
                    }
                }
            }
            .padding()
            .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
            .task {
                await testimonialsVM.loadTestimonials(profileUserId: profile.uid)
            }
            .sheet(isPresented: $showAddTestimonial) {
                AllTestimonialsSheet(
                    profile: profile,
                    viewModel: testimonialsVM
                )
            }
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
        @State private var selectedGalleryPhotos: [PhotosPickerItem] = []
        @State private var galleryImageURLs: [String]
        @State private var isUploading = false
        @State private var isUploadingGallery = false
        @State private var showNetworkAlert = false
        @State private var networkAlertMessage = ""
        @State private var hasInitializedGallery = false

        let availableInterests = ["Music", "Art", "Gaming", "Fitness", "Travel", "Food", "Tech", "Fashion", "Sports", "Photography"]
        
        init(profile: UserProfile, viewModel: ProfileViewModel, onSave: @escaping () -> Void) {
            self.profile = profile
            self.viewModel = viewModel
            self.onSave = onSave
            _displayName = State(initialValue: profile.displayName)
            _bio = State(initialValue: profile.bio ?? "")
            _selectedInterests = State(initialValue: Set(profile.interests ?? []))
            _selectedContentStyles = State(initialValue: Set(profile.contentStyles))
            _galleryImageURLs = State(initialValue: profile.mediaURLs ?? [])
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
                    
                    Section {
                        TextField("Display Name", text: $displayName)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Bio")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            TextEditor(text: $bio)
                                .frame(height: 100)
                        }
                    } header: {
                        Text("Basic Info")
                    }

                    Section {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Add up to 6 photos")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("\(galleryImageURLs.count)/6")
                                    .font(.caption)
                                    .foregroundStyle(galleryImageURLs.count >= 6 ? .red : .secondary)
                            }

                            // Photo grid - use fixed size to prevent NaN errors
                            LazyVGrid(columns: [GridItem(.fixed(100)), GridItem(.fixed(100)), GridItem(.fixed(100))], spacing: 12) {
                                ForEach(galleryImageURLs, id: \.self) { url in
                                    ZStack(alignment: .topTrailing) {
                                        AsyncImage(url: URL(string: url)) { phase in
                                            switch phase {
                                            case .success(let image):
                                                image
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: 100, height: 100)
                                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                            case .failure(_):
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(.red.opacity(0.2))
                                                    .frame(width: 100, height: 100)
                                                    .overlay(
                                                        Image(systemName: "exclamationmark.triangle")
                                                            .foregroundStyle(.red)
                                                    )
                                            case .empty:
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(.gray.opacity(0.2))
                                                    .frame(width: 100, height: 100)
                                                    .overlay(
                                                        ProgressView()
                                                            .tint(AppTheme.accent)
                                                    )
                                            @unknown default:
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(.gray.opacity(0.2))
                                                    .frame(width: 100, height: 100)
                                            }
                                        }

                                        Button {
                                            let urlToDelete = url
                                            print("🗑️ User clicked delete for photo")
                                            // Remove from local array
                                            withAnimation {
                                                galleryImageURLs.removeAll { $0 == urlToDelete }
                                            }
                                            // Save removal to Firestore immediately
                                            if let uid = Auth.auth().currentUser?.uid {
                                                Task {
                                                    await viewModel.removeMediaURL(userId: uid, url: urlToDelete)
                                                    print("✅ Photo deleted from Firestore")
                                                }
                                            }
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundStyle(.white)
                                                .background(Circle().fill(.black.opacity(0.6)))
                                        }
                                        .buttonStyle(.plain)
                                        .padding(4)
                                    }
                                }

                                // Add photo button
                                if galleryImageURLs.count < 6 {
                                    PhotosPicker(selection: $selectedGalleryPhotos, maxSelectionCount: 6 - galleryImageURLs.count, matching: .images) {
                                        VStack(spacing: 8) {
                                            Image(systemName: "plus")
                                                .font(.title2)
                                            Text("Add")
                                                .font(.caption)
                                        }
                                        .foregroundStyle(AppTheme.accent)
                                        .frame(width: 100, height: 100)
                                        .background(AppTheme.accent.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                                    }
                                }
                            }

                            if isUploadingGallery {
                                ProgressView("Uploading photos...")
                                    .frame(maxWidth: .infinity)
                            }
                        }
                    } header: {
                        Text("Photo Gallery")
                    } footer: {
                        Text("These photos will be visible to others on your profile")
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
                                // Get latest profile to avoid overwriting photos
                                guard var updated = viewModel.profile else { return }
                                updated.displayName = displayName
                                updated.bio = bio.isEmpty ? nil : bio
                                updated.interests = Array(selectedInterests)
                                updated.contentStyles = Array(selectedContentStyles)
                                // DON'T set mediaURLs here - photos are saved immediately via addMediaURL/removeMediaURL
                                await viewModel.updateProfile(updated)
                                Haptics.notify(.success)
                                onSave()
                                dismiss()
                            }
                        }
                        .fontWeight(.bold)
                        .disabled(displayName.isEmpty || isUploadingGallery)
                    }
                }
                .onChange(of: selectedPhoto) { _, newValue in
                    guard let newValue else { return }
                    Task {
                        isUploading = true
                        defer { isUploading = false }

                        if let data = try? await newValue.loadTransferable(type: Data.self),
                           let image = UIImage(data: data),
                           let uid = Auth.auth().currentUser?.uid {
                            // Resize to max 1200px for faster upload
                            let resized = resizeImage(image, maxWidth: 1200)
                            if let compressed = resized.jpegData(compressionQuality: 0.5) {
                                print("📦 Compressed profile photo: \(data.count / 1024)KB → \(compressed.count / 1024)KB")
                                await viewModel.updateProfilePhoto(userId: uid, imageData: compressed)
                            }
                        }
                    }
                }
                .onChange(of: selectedGalleryPhotos) { _, newPhotos in
                    guard !newPhotos.isEmpty else { return }
                    Task {
                        isUploadingGallery = true
                        defer {
                            isUploadingGallery = false
                            selectedGalleryPhotos = []
                        }

                        for photo in newPhotos {
                            // Stop if we've reached the 6 photo limit
                            guard galleryImageURLs.count < 6 else {
                                print("⚠️ Reached 6 photo limit, stopping uploads")
                                break
                            }

                            if let data = try? await photo.loadTransferable(type: Data.self),
                               let image = UIImage(data: data),
                               let uid = Auth.auth().currentUser?.uid {
                                // Resize to 800px max width and compress aggressively
                                let resized = resizeImage(image, maxWidth: 800)
                                // Use 0.3 quality for much faster uploads (smaller file size)
                                if let compressed = resized.jpegData(compressionQuality: 0.3) {
                                    print("📦 Compressed image: \(data.count / 1024)KB → \(compressed.count / 1024)KB")
                                    if let url = await viewModel.uploadGalleryPhoto(userId: uid, imageData: compressed) {
                                        await MainActor.run {
                                            galleryImageURLs.append(url)
                                        }
                                        // CRITICAL FIX: Save to Firestore immediately so photos don't get lost
                                        await viewModel.addMediaURL(userId: uid, url: url)
                                        print("✅ Photo saved to profile: \(galleryImageURLs.count)/6")
                                    } else if let errorMsg = await viewModel.errorMessage {
                                        // Show alert if upload failed (e.g., WiFi blocking)
                                        await MainActor.run {
                                            networkAlertMessage = errorMsg
                                            showNetworkAlert = true
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .alert("Upload Failed", isPresented: $showNetworkAlert) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text(networkAlertMessage)
                }
                .task {
                    // Only sync once when sheet first appears
                    guard !hasInitializedGallery else {
                        print("⏭️ Gallery already initialized, skipping sync")
                        return
                    }

                    // Wait a tiny bit for profile refresh to complete, then sync
                    try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds

                    // Sync galleryImageURLs with latest profile data when sheet opens
                    if let latestProfile = viewModel.profile {
                        let newURLs = latestProfile.mediaURLs ?? []
                        print("🔄 Syncing gallery photos on sheet open")
                        print("   Current: \(galleryImageURLs.count) photos")
                        print("   From Firestore: \(newURLs.count) photos")

                        // Only update if we haven't already initialized
                        if !hasInitializedGallery {
                            galleryImageURLs = newURLs
                            hasInitializedGallery = true
                            print("✅ Gallery initialized with \(galleryImageURLs.count) photos")
                        }
                    }
                }
            }
        }

        // MARK: - Image Helper

        private func resizeImage(_ image: UIImage, maxWidth: CGFloat) -> UIImage {
            let size = image.size

            // If image is already smaller, return as-is
            if size.width <= maxWidth {
                return image
            }

            // Calculate new size maintaining aspect ratio
            let ratio = maxWidth / size.width
            let newHeight = size.height * ratio
            let newSize = CGSize(width: maxWidth, height: newHeight)

            // Resize the image
            let renderer = UIGraphicsImageRenderer(size: newSize)
            return renderer.image { _ in
                image.draw(in: CGRect(origin: .zero, size: newSize))
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
                    
                    // Save/Share button - uses system Share sheet (no permissions needed)
                    Button {
                        showShareSheet = true
                        Haptics.impact(.medium)
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                            Text("Save or Share")
                        }
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppTheme.accent, in: RoundedRectangle(cornerRadius: 16))
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
                    // Generate QR code with unique profile URL
                    // Each profile has a unique UID, so the QR code is unique to each user
                    let profileURL = "https://featur.app/profile/\(profile.uid)"

                    // Generate QR code without center image (avoid blocking network call that freezes UI)
                    qrImage = QRCodeGenerator.generateStylized(
                        from: profileURL,
                        centerImage: nil,
                        size: CGSize(width: 512, height: 512)
                    )
                }
                .sheet(isPresented: $showShareSheet) {
                    if let qrImage = qrImage {
                        ShareSheet(items: [qrImage])
                            .presentationDetents([.medium, .large])
                            .presentationDragIndicator(.visible)
                    }
                }
            }
        }
    }
    
    // MARK: - Enhanced Stats Sheet
    struct EnhancedStatsSheet: View {
        let profile: UserProfile
        @Environment(\.dismiss) var dismiss
        @StateObject private var analyticsVM = DetailedAnalyticsViewModel()

        @State private var selectedPeriod: StatsPeriod = .week

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
                        .onChange(of: selectedPeriod) { _, newPeriod in
                            Task {
                                await analyticsVM.loadAnalytics(userId: profile.uid, period: newPeriod)
                            }
                        }

                        if analyticsVM.isLoading {
                            ProgressView("Loading analytics...")
                                .padding()
                        } else {
                            // Engagement Stats
                            StatsSection(title: "Engagement", icon: "chart.line.uptrend.xyaxis") {
                                VStack(spacing: 12) {
                                    DetailedStatRow(
                                        label: "Profile Views",
                                        value: "\(analyticsVM.profileViews)",
                                        change: analyticsVM.profileViewsChange,
                                        isPositive: analyticsVM.profileViewsChangePositive
                                    )
                                    DetailedStatRow(
                                        label: "New Followers",
                                        value: "+\(analyticsVM.newFollowers)",
                                        change: analyticsVM.followersChange,
                                        isPositive: analyticsVM.followersChangePositive
                                    )
                                    DetailedStatRow(
                                        label: "Likes Received",
                                        value: "\(analyticsVM.likesReceived)",
                                        change: analyticsVM.likesChange,
                                        isPositive: analyticsVM.likesChangePositive
                                    )
                                }
                            }

                            // Match Stats
                            StatsSection(title: "Matches", icon: "heart.fill") {
                                VStack(spacing: 12) {
                                    DetailedStatRow(
                                        label: "Total Matches",
                                        value: "\(analyticsVM.totalMatches)",
                                        change: analyticsVM.matchesChange,
                                        isPositive: analyticsVM.matchesChangePositive
                                    )
                                    DetailedStatRow(
                                        label: "Match Rate",
                                        value: analyticsVM.matchRate,
                                        change: analyticsVM.matchRateChange,
                                        isPositive: analyticsVM.matchRateChangePositive
                                    )
                                    DetailedStatRow(
                                        label: "Messages Sent",
                                        value: "\(analyticsVM.messagesSent)",
                                        change: analyticsVM.messagesChange,
                                        isPositive: analyticsVM.messagesChangePositive
                                    )
                                }
                            }

                            // Content Stats
                            StatsSection(title: "Content", icon: "photo.stack.fill") {
                                VStack(spacing: 12) {
                                    DetailedStatRow(
                                        label: "Total Photos",
                                        value: "\((profile.mediaURLs ?? []).count)",
                                        change: "—",
                                        isPositive: true
                                    )
                                    DetailedStatRow(
                                        label: "Active Collabs",
                                        value: "\(analyticsVM.activeCollabs)",
                                        change: analyticsVM.collabsChange,
                                        isPositive: analyticsVM.collabsChangePositive
                                    )
                                }
                            }

                            // Summary Card
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Period Summary")
                                    .font(.headline)

                                RoundedRectangle(cornerRadius: 16)
                                    .fill(AppTheme.gradient.opacity(0.3))
                                    .frame(height: 120)
                                    .overlay(
                                        VStack(spacing: 8) {
                                            Image(systemName: "chart.bar.fill")
                                                .font(.system(size: 40))
                                                .foregroundStyle(.white)
                                            Text("Total Activity: \(analyticsVM.totalActivity)")
                                                .font(.headline)
                                                .foregroundStyle(.white)
                                            Text("in \(selectedPeriod.rawValue)")
                                                .font(.caption)
                                                .foregroundStyle(.white.opacity(0.8))
                                        }
                                    )
                            }
                            .padding(.horizontal)
                        }
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
                .task {
                    await analyticsVM.loadAnalytics(userId: profile.uid, period: selectedPeriod)
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
                PreviewLocationAgeSection(profile: profile)
                PreviewActionButtons()
                PreviewBioSection(bio: profile.bio)
                PreviewInterestsSection(interests: profile.interests)
                PreviewContentStylesSection(styles: profile.contentStyles)
                PreviewCollabPreferencesSection(preferences: profile.collaborationPreferences)
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
            VStack(alignment: .leading, spacing: 8) {
                // Name and verified badge
                HStack {
                    Text(profile.displayName)
                        .font(.system(size: 28, weight: .bold))
                    if profile.isVerified ?? false {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(.blue)
                    }

                    // Online Status Badge - uses real Firebase presence data
                    if PresenceManager.shared.isOnline(userId: profile.uid) {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(.green)
                                .frame(width: 8, height: 8)
                            Text("Online")
                                .font(.caption.bold())
                                .foregroundStyle(.green)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.green.opacity(0.15), in: Capsule())
                    }
                }

                // Verification Status Badges
                HStack(spacing: 8) {
                    // Email Verified Badge
                    if profile.isEmailVerified ?? false {
                        HStack(spacing: 4) {
                            Image(systemName: "envelope.fill")
                                .font(.caption2)
                            Text("Email Verified")
                                .font(.caption2.weight(.medium))
                        }
                        .foregroundStyle(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.blue.opacity(0.1), in: Capsule())
                        .overlay(Capsule().stroke(.blue.opacity(0.3), lineWidth: 1))
                    }

                    // Phone Verified Badge
                    if profile.isPhoneVerified ?? false {
                        HStack(spacing: 4) {
                            Image(systemName: "phone.fill")
                                .font(.caption2)
                            Text("Phone Verified")
                                .font(.caption2.weight(.medium))
                        }
                        .foregroundStyle(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.green.opacity(0.1), in: Capsule())
                        .overlay(Capsule().stroke(.green.opacity(0.3), lineWidth: 1))
                    }
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

    struct PreviewLocationAgeSection: View {
        let profile: UserProfile

        var body: some View {
            Group {
                if hasLocationOrAge {
                    HStack(spacing: 12) {
                        if let location = profile.location {
                            HStack(spacing: 4) {
                                Image(systemName: "location.fill")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(locationText(location))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        if let location = profile.location, profile.age != nil {
                            Text("•")
                                .foregroundStyle(.secondary)
                        }

                        if let age = profile.age {
                            HStack(spacing: 4) {
                                Image(systemName: "person.fill")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("\(age)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }

        private var hasLocationOrAge: Bool {
            (profile.location != nil && !locationText(profile.location!).isEmpty) || profile.age != nil
        }

        private func locationText(_ location: UserProfile.Location) -> String {
            var parts: [String] = []
            if let city = location.city, !city.isEmpty {
                parts.append(city)
            }
            if let state = location.state, !state.isEmpty {
                parts.append(state)
            }
            return parts.joined(separator: ", ")
        }
    }

    struct PreviewInterestsSection: View {
        let interests: [String]?

        // Filter out gender-related values that shouldn't be in interests
        private var filteredInterests: [String] {
            let genderValues = ["Male", "Female", "Non-binary", "Prefer not to say"]
            return (interests ?? []).filter { !genderValues.contains($0) }
        }

        var body: some View {
            Group {
                if !filteredInterests.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Interests")
                            .font(.headline)
                        FlowLayout(spacing: 8) {
                            ForEach(filteredInterests, id: \.self) { interest in
                                Text(interest)
                                    .font(.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(AppTheme.accent.opacity(0.15), in: Capsule())
                                    .foregroundStyle(AppTheme.accent)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    struct PreviewCollabPreferencesSection: View {
        let preferences: UserProfile.CollaborationPreferences?

        var body: some View {
            Group {
                if let preferences = preferences, !preferences.lookingFor.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Looking For")
                            .font(.headline)
                        FlowLayout(spacing: 8) {
                            ForEach(preferences.lookingFor, id: \.self) { collabType in
                                HStack(spacing: 4) {
                                    Image(systemName: "sparkles")
                                        .font(.caption2)
                                    Text(collabType.rawValue)
                                        .font(.caption)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.orange.opacity(0.15), in: Capsule())
                                .foregroundStyle(.orange)
                            }
                        }

                        // Response Time
                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(preferences.responseTime.rawValue)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
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
        @State private var selectedImageIndex = 0
        @State private var showFullScreenImage = false
        @StateObject private var presenceManager = PresenceManager.shared

        // Combine profile photo + gallery photos for carousel
        private var allPhotos: [String] {
            var photos: [String] = []
            // Add gallery photos first
            if let mediaURLs = profile.mediaURLs, !mediaURLs.isEmpty {
                photos.append(contentsOf: mediaURLs)
            }
            // Add profile photo at the end if not already in gallery
            if let profileImage = profile.profileImageURL,
               !photos.contains(profileImage) {
                photos.append(profileImage)
            }
            return photos
        }

        var body: some View {
            NavigationStack {
                ScrollView {
                    VStack(spacing: 20) {
                        // Photo Gallery Carousel (like ProfileDetailView)
                        if !allPhotos.isEmpty {
                            TabView(selection: $selectedImageIndex) {
                                ForEach(Array(allPhotos.enumerated()), id: \.offset) { index, url in
                                    AsyncImage(url: URL(string: url)) { phase in
                                        switch phase {
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: UIScreen.main.bounds.width, height: 400)
                                                .clipped()
                                                .onTapGesture {
                                                    showFullScreenImage = true
                                                }
                                        case .empty:
                                            Rectangle()
                                                .fill(AppTheme.accent.opacity(0.2))
                                                .frame(width: UIScreen.main.bounds.width, height: 400)
                                                .overlay(ProgressView().tint(.white))
                                        case .failure(_):
                                            Rectangle()
                                                .fill(.red.opacity(0.2))
                                                .frame(width: UIScreen.main.bounds.width, height: 400)
                                                .overlay(
                                                    Image(systemName: "exclamationmark.triangle")
                                                        .foregroundStyle(.red)
                                                )
                                        @unknown default:
                                            Rectangle()
                                                .fill(AppTheme.accent.opacity(0.2))
                                                .frame(width: UIScreen.main.bounds.width, height: 400)
                                        }
                                    }
                                    .tag(index)
                                }
                            }
                            .tabViewStyle(.page(indexDisplayMode: .always))
                            .frame(height: 400)

                            // Photo counter
                            if allPhotos.count > 1 {
                                Text("\(selectedImageIndex + 1) / \(allPhotos.count)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .padding(.top, -10)
                            }
                        } else {
                            // Fallback if no photos
                            Rectangle()
                                .fill(AppTheme.accent.opacity(0.2))
                                .frame(height: 300)
                                .overlay(
                                    Image(systemName: "person.circle.fill")
                                        .font(.system(size: 80))
                                        .foregroundStyle(AppTheme.accent)
                                )
                        }

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
                .task {
                    // Fetch current user's real online status from Firebase
                    await presenceManager.fetchOnlineStatus(userId: profile.uid)
                }
                .fullScreenCover(isPresented: $showFullScreenImage) {
                    FullScreenImageViewer(images: allPhotos, startingIndex: selectedImageIndex)
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
        @StateObject private var collabVM = CollaborationHistoryViewModel()
        @State private var showAllCollabs = false

        var body: some View {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Label("Collaboration History", systemImage: "person.2.fill")
                        .font(.headline)

                    Spacer()

                    if !collabVM.collaborations.isEmpty {
                        Text("\(collabVM.collaborations.count)")
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(AppTheme.accent, in: Capsule())
                    }
                }

                if collabVM.isLoading {
                    ProgressView("Loading collaborations...")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else if collabVM.collaborations.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "person.2")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("No collaborations yet")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                } else {
                    VStack(spacing: 12) {
                        ForEach(collabVM.collaborations.prefix(3)) { collabWithPartner in
                            CollabHistoryCard(
                                collaboration: collabWithPartner.collaboration,
                                partnerProfile: collabWithPartner.partnerProfile
                            )
                        }

                        if collabVM.collaborations.count > 3 {
                            Button("View All \(collabVM.collaborations.count) Collaborations") {
                                showAllCollabs = true
                            }
                            .font(.caption)
                            .foregroundStyle(AppTheme.accent)
                        }
                    }
                }
            }
            .padding()
            .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
            .task {
                await collabVM.loadCollaborations(userId: profile.uid)
            }
            .sheet(isPresented: $showAllCollabs) {
                AllCollaborationsSheet(
                    profile: profile,
                    viewModel: collabVM
                )
            }
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

    // MARK: - Full Screen Image Viewer
    private struct FullScreenImageViewer: View {
        let images: [String]
        let startingIndex: Int
        @Environment(\.dismiss) var dismiss
        @State private var currentIndex: Int
        @State private var scale: CGFloat = 1.0
        @State private var lastScale: CGFloat = 1.0
        @State private var offset: CGSize = .zero
        @State private var lastOffset: CGSize = .zero

        init(images: [String], startingIndex: Int) {
            self.images = images
            self.startingIndex = startingIndex
            _currentIndex = State(initialValue: startingIndex)
        }

        // Convenience init for single image
        init(imageURL: String) {
            self.init(images: [imageURL], startingIndex: 0)
        }

        var body: some View {
            ZStack {
                Color.black.ignoresSafeArea()

                TabView(selection: $currentIndex) {
                    ForEach(Array(images.enumerated()), id: \.element) { index, url in
                        ZoomableImageView(
                            imageURL: url,
                            scale: index == currentIndex ? $scale : .constant(1.0),
                            lastScale: index == currentIndex ? $lastScale : .constant(1.0),
                            offset: index == currentIndex ? $offset : .constant(.zero),
                            lastOffset: index == currentIndex ? $lastOffset : .constant(.zero)
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .onChange(of: currentIndex) { _ in
                    // Reset zoom when swiping to another image
                    withAnimation {
                        scale = 1.0
                        lastScale = 1.0
                        offset = .zero
                        lastOffset = .zero
                    }
                }

                // Top overlay with close button and counter
                VStack {
                    HStack {
                        if images.count > 1 {
                            Text("\(currentIndex + 1) / \(images.count)")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(.ultraThinMaterial, in: Capsule())
                                .padding(.leading)
                        }

                        Spacer()

                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(.white)
                                .shadow(radius: 4)
                        }
                        .padding()
                    }
                    Spacer()
                }
            }
        }
    }

    // MARK: - Zoomable Image View
    private struct ZoomableImageView: View {
        let imageURL: String
        @Binding var scale: CGFloat
        @Binding var lastScale: CGFloat
        @Binding var offset: CGSize
        @Binding var lastOffset: CGSize

        var body: some View {
            AsyncImage(url: URL(string: imageURL)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .scaleEffect(scale)
                        .offset(offset)
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    scale = lastScale * value
                                }
                                .onEnded { _ in
                                    lastScale = scale
                                    // Reset if zoomed out too much
                                    if scale < 1.0 {
                                        withAnimation {
                                            scale = 1.0
                                            lastScale = 1.0
                                            offset = .zero
                                            lastOffset = .zero
                                        }
                                    }
                                }
                        )
                        .simultaneousGesture(
                            // Only enable drag when zoomed in to avoid conflicting with TabView swipe
                            scale > 1.0 ?
                            DragGesture()
                                .onChanged { value in
                                    offset = CGSize(
                                        width: lastOffset.width + value.translation.width,
                                        height: lastOffset.height + value.translation.height
                                    )
                                }
                                .onEnded { _ in
                                    lastOffset = offset
                                }
                            : nil
                        )
                        .onTapGesture(count: 2) {
                            // Double tap to zoom
                            withAnimation {
                                if scale > 1.0 {
                                    scale = 1.0
                                    lastScale = 1.0
                                    offset = .zero
                                    lastOffset = .zero
                                } else {
                                    scale = 2.0
                                    lastScale = 2.0
                                }
                            }
                        }
                case .empty:
                    ProgressView()
                        .tint(.white)
                case .failure:
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundStyle(.white)
                        Text("Failed to load image")
                            .foregroundStyle(.white)
                    }
                @unknown default:
                    ProgressView()
                        .tint(.white)
                }
            }
        }
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

// MARK: - Email Verification View
struct EmailVerificationView: View {
    let profile: UserProfile
    @Environment(\.dismiss) var dismiss
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @State private var verificationSent = false
    @State private var checkingStatus = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Icon
                Image(systemName: "envelope.badge.shield.half.filled")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue)
                    .padding(.top, 40)

                // Title
                VStack(spacing: 8) {
                    Text("Verify Email")
                        .font(.title.bold())
                    Text(verificationSent ? "Check your email inbox" : "We'll send a verification email to your address")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal)

                if !verificationSent {
                    // Email display (read-only - uses Firebase Auth email)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email Address")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)

                        if let authEmail = Auth.auth().currentUser?.email {
                            Text(authEmail)
                                .font(.body)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
                        } else {
                            Text("No email linked to account")
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(.horizontal)

                    Text("This is your Firebase Auth email")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    // Send verification button
                    Button {
                        sendVerificationEmail()
                    } label: {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Send Verification Email")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Auth.auth().currentUser?.email == nil ? Color.gray : AppTheme.accent)
                        .foregroundStyle(.white)
                        .cornerRadius(12)
                    }
                    .disabled(Auth.auth().currentUser?.email == nil || isLoading)
                    .padding(.horizontal)
                } else {
                    // Verification sent success
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.green)

                        Text("Verification email sent!")
                            .font(.headline)

                        if let email = Auth.auth().currentUser?.email {
                            Text("We sent a verification link to \(email). Click the link in your email to verify your address.")
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }

                        Button {
                            checkVerificationStatus()
                        } label: {
                            HStack {
                                if checkingStatus {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("I've Verified - Check Status")
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundStyle(.white)
                            .cornerRadius(12)
                        }
                        .disabled(checkingStatus)
                        .padding(.horizontal)

                        Button {
                            sendVerificationEmail()
                        } label: {
                            Text("Resend Email")
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.accent)
                        }
                    }
                }

                // Error/Success message
                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.horizontal)
                        .multilineTextAlignment(.center)
                }

                if let success = successMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text(success)
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                    .padding(.horizontal)
                }

                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func sendVerificationEmail() {
        guard let user = Auth.auth().currentUser else {
            errorMessage = "No user signed in"
            return
        }

        isLoading = true
        errorMessage = nil
        successMessage = nil

        user.sendEmailVerification { error in
            isLoading = false

            if let error = error {
                errorMessage = "Failed to send email: \(error.localizedDescription)"
                return
            }

            verificationSent = true
            successMessage = "Verification email sent!"

            // Also update the email in the user profile
            if let email = user.email {
                Task {
                    let db = Firestore.firestore()
                    try? await db.collection("users").document(profile.uid).updateData([
                        "email": email
                    ])
                }
            }
        }
    }

    private func checkVerificationStatus() {
        guard let user = Auth.auth().currentUser else {
            errorMessage = "No user signed in"
            return
        }

        checkingStatus = true
        errorMessage = nil

        // Reload user to get fresh email verification status
        user.reload { error in
            checkingStatus = false

            if let error = error {
                errorMessage = "Failed to check status: \(error.localizedDescription)"
                return
            }

            if user.isEmailVerified {
                // Update Firestore
                Task {
                    let db = Firestore.firestore()
                    try await db.collection("users").document(profile.uid).updateData([
                        "isEmailVerified": true
                    ])

                    await MainActor.run {
                        successMessage = "Email verified successfully!"

                        // Dismiss after short delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            dismiss()
                        }
                    }
                }
            } else {
                errorMessage = "Email not verified yet. Please check your inbox and click the verification link."
            }
        }
    }
}

// MARK: - Phone Verification View
struct PhoneVerificationView: View {
    let profile: UserProfile
    @Environment(\.dismiss) var dismiss
    @State private var phoneNumber: String = ""
    @State private var verificationCode: String = ""
    @State private var codeSent = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @State private var verificationID: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Icon
                Image(systemName: "phone.badge.checkmark")
                    .font(.system(size: 60))
                    .foregroundStyle(.green)
                    .padding(.top, 40)

                // Title
                VStack(spacing: 8) {
                    Text("Verify Phone Number")
                        .font(.title.bold())
                    Text("Enter your phone number to receive a verification code via SMS")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal)

                if !codeSent {
                    // Phone input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Phone Number")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)

                        TextField("+1 (555) 123-4567", text: $phoneNumber)
                            .textContentType(.telephoneNumber)
                            .keyboardType(.phonePad)
                            .padding()
                            .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal)

                    Text("Include country code (e.g., +1 for US)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)

                    // Send SMS button
                    Button {
                        sendSMSCode()
                    } label: {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Send SMS Code")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(phoneNumber.isEmpty ? Color.gray : Color.green)
                        .foregroundStyle(.white)
                        .cornerRadius(12)
                    }
                    .disabled(phoneNumber.isEmpty || isLoading)
                    .padding(.horizontal)
                } else {
                    // Verification code input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Verification Code")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)

                        TextField("Enter 6-digit code", text: $verificationCode)
                            .textContentType(.oneTimeCode)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.center)
                            .font(.title2.bold())
                            .padding()
                            .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
                            .onChange(of: verificationCode) { newValue in
                                // Auto-verify when 6 digits entered
                                if newValue.count == 6 {
                                    verifyCode()
                                }
                            }
                    }
                    .padding(.horizontal)

                    Text("Code sent to \(phoneNumber)")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    // Verify button
                    Button {
                        verifyCode()
                    } label: {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Verify Phone Number")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(verificationCode.isEmpty ? Color.gray : Color.green)
                        .foregroundStyle(.white)
                        .cornerRadius(12)
                    }
                    .disabled(verificationCode.isEmpty || isLoading)
                    .padding(.horizontal)

                    // Resend code
                    Button {
                        sendSMSCode()
                    } label: {
                        Text("Resend Code")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.accent)
                    }
                }

                // Error/Success message
                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.horizontal)
                }

                if let success = successMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text(success)
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                    .padding(.horizontal)
                }

                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            // Pre-fill phone if already in profile
            if let profilePhone = profile.phoneNumber {
                phoneNumber = profilePhone
            }
        }
    }

    private func sendSMSCode() {
        isLoading = true
        errorMessage = nil
        successMessage = nil

        // Use Firebase PhoneAuthProvider to send SMS
        PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumber, uiDelegate: nil) { verificationID, error in
            isLoading = false

            if let error = error {
                errorMessage = "Failed to send SMS: \(error.localizedDescription)"
                return
            }

            guard let verificationID = verificationID else {
                errorMessage = "Failed to get verification ID"
                return
            }

            self.verificationID = verificationID
            codeSent = true
            successMessage = "SMS code sent!"

            // Update phone number in profile
            Task {
                let db = Firestore.firestore()
                try? await db.collection("users").document(profile.uid).updateData([
                    "phoneNumber": phoneNumber
                ])
            }
        }
    }

    private func verifyCode() {
        guard let verificationID = verificationID else {
            errorMessage = "Please request a code first"
            return
        }

        isLoading = true
        errorMessage = nil

        // Create phone credential
        let credential = PhoneAuthProvider.provider().credential(
            withVerificationID: verificationID,
            verificationCode: verificationCode
        )

        // Link phone credential to current user
        Auth.auth().currentUser?.link(with: credential) { authResult, error in
            isLoading = false

            if let error = error {
                // If already linked, just mark as verified
                if (error as NSError).code == AuthErrorCode.credentialAlreadyInUse.rawValue {
                    Task {
                        let db = Firestore.firestore()
                        try await db.collection("users").document(profile.uid).updateData([
                            "isPhoneVerified": true
                        ])

                        await MainActor.run {
                            successMessage = "Phone verified successfully!"

                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                dismiss()
                            }
                        }
                    }
                } else {
                    errorMessage = "Verification failed: \(error.localizedDescription)"
                }
                return
            }

            // Successfully linked - mark as verified
            Task {
                let db = Firestore.firestore()
                try await db.collection("users").document(profile.uid).updateData([
                    "isPhoneVerified": true
                ])

                await MainActor.run {
                    successMessage = "Phone verified successfully!"

                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Profile Analytics ViewModel
@MainActor
final class ProfileAnalyticsViewModel: ObservableObject {
    @Published var matchCount: Int = 0
    @Published var profileViewCount: Int = 0
    @Published var collabCount: Int = 0
    @Published var isLoading: Bool = false

    private let service = FirebaseService()

    func loadAnalytics(userId: String) async {
        isLoading = true

        async let matchesTask = fetchMatchCount(userId: userId)
        async let viewsTask = fetchProfileViewCount(userId: userId)
        async let collabsTask = fetchCollabCount(userId: userId)

        let (matches, views, collabs) = await (matchesTask, viewsTask, collabsTask)

        matchCount = matches
        profileViewCount = views
        collabCount = collabs
        isLoading = false

        print("✅ Analytics loaded - Matches: \(matches), Views: \(views), Collabs: \(collabs)")
    }

    private func fetchMatchCount(userId: String) async -> Int {
        do {
            let matches = try await service.fetchMatches(forUser: userId)
            return matches.count
        } catch {
            print("❌ Error fetching match count: \(error)")
            return 0
        }
    }

    private func fetchProfileViewCount(userId: String) async -> Int {
        do {
            // Count profile views from swipes collection (likes received)
            let db = FirebaseFirestore.Firestore.firestore()
            let snapshot = try await db.collection("swipes")
                .whereField("targetUserId", isEqualTo: userId)
                .getDocuments()
            return snapshot.documents.count
        } catch {
            print("❌ Error fetching profile view count: \(error)")
            return 0
        }
    }

    private func fetchCollabCount(userId: String) async -> Int {
        do {
            // Count completed conversations as collabs
            // (Users who have exchanged messages indicate active collaboration interest)
            let db = FirebaseFirestore.Firestore.firestore()
            let snapshot = try await db.collection("conversations")
                .whereField("participantIds", arrayContains: userId)
                .getDocuments()

            // Count conversations with more than 5 messages as active collabs
            var activeCollabs = 0
            for doc in snapshot.documents {
                let messageSnapshot = try await db.collection("conversations")
                    .document(doc.documentID)
                    .collection("messages")
                    .getDocuments()

                if messageSnapshot.documents.count >= 5 {
                    activeCollabs += 1
                }
            }

            return activeCollabs
        } catch {
            print("❌ Error fetching collab count: \(error)")
            return 0
        }
    }
}

// MARK: - Detailed Analytics ViewModel (for Analytics Sheet)
@MainActor
final class DetailedAnalyticsViewModel: ObservableObject {
    @Published var isLoading: Bool = false

    // Engagement metrics
    @Published var profileViews: Int = 0
    @Published var profileViewsChange: String = "—"
    @Published var profileViewsChangePositive: Bool = true

    @Published var newFollowers: Int = 0
    @Published var followersChange: String = "—"
    @Published var followersChangePositive: Bool = true

    @Published var likesReceived: Int = 0
    @Published var likesChange: String = "—"
    @Published var likesChangePositive: Bool = true

    // Match metrics
    @Published var totalMatches: Int = 0
    @Published var matchesChange: String = "—"
    @Published var matchesChangePositive: Bool = true

    @Published var matchRate: String = "0%"
    @Published var matchRateChange: String = "—"
    @Published var matchRateChangePositive: Bool = true

    @Published var messagesSent: Int = 0
    @Published var messagesChange: String = "—"
    @Published var messagesChangePositive: Bool = true

    // Content metrics
    @Published var activeCollabs: Int = 0
    @Published var collabsChange: String = "—"
    @Published var collabsChangePositive: Bool = true

    @Published var totalActivity: Int = 0

    private let service = FirebaseService()

    func loadAnalytics(userId: String, period: StatsPeriod) async {
        isLoading = true

        let startDate = getStartDate(for: period)
        let previousStartDate = getPreviousStartDate(for: period)

        async let currentStats = fetchPeriodStats(userId: userId, startDate: startDate, endDate: Date())
        async let previousStats = fetchPeriodStats(userId: userId, startDate: previousStartDate, endDate: startDate)

        let (current, previous) = await (currentStats, previousStats)

        // Update current values
        profileViews = current.profileViews
        newFollowers = current.newFollowers
        likesReceived = current.likesReceived
        totalMatches = current.totalMatches
        messagesSent = current.messagesSent
        activeCollabs = current.activeCollabs

        // Calculate match rate
        let totalSwipes = current.totalSwipes
        if totalSwipes > 0 {
            let rate = Double(current.totalMatches) / Double(totalSwipes) * 100
            matchRate = String(format: "%.1f%%", rate)
        } else {
            matchRate = "0%"
        }

        // Calculate changes
        profileViewsChange = calculateChange(current: current.profileViews, previous: previous.profileViews)
        profileViewsChangePositive = current.profileViews >= previous.profileViews

        followersChange = calculateChange(current: current.newFollowers, previous: previous.newFollowers)
        followersChangePositive = current.newFollowers >= previous.newFollowers

        likesChange = calculateChange(current: current.likesReceived, previous: previous.likesReceived)
        likesChangePositive = current.likesReceived >= previous.likesReceived

        matchesChange = calculateChange(current: current.totalMatches, previous: previous.totalMatches)
        matchesChangePositive = current.totalMatches >= previous.totalMatches

        messagesChange = calculateChange(current: current.messagesSent, previous: previous.messagesSent)
        messagesChangePositive = current.messagesSent >= previous.messagesSent

        collabsChange = calculateChange(current: current.activeCollabs, previous: previous.activeCollabs)
        collabsChangePositive = current.activeCollabs >= previous.activeCollabs

        // Calculate match rate change
        if totalSwipes > 0 && previous.totalSwipes > 0 {
            let currentRate = Double(current.totalMatches) / Double(totalSwipes) * 100
            let previousRate = Double(previous.totalMatches) / Double(previous.totalSwipes) * 100
            let diff = currentRate - previousRate
            matchRateChange = diff >= 0 ? "+\(String(format: "%.1f", diff))%" : "\(String(format: "%.1f", diff))%"
            matchRateChangePositive = diff >= 0
        }

        // Calculate total activity
        totalActivity = profileViews + totalMatches + messagesSent + activeCollabs

        isLoading = false
        print("✅ Detailed analytics loaded for \(period.rawValue)")
    }

    private func fetchPeriodStats(userId: String, startDate: Date, endDate: Date) async -> PeriodStats {
        let db = FirebaseFirestore.Firestore.firestore()

        async let viewsTask = fetchCount(
            db: db,
            collection: "swipes",
            field: "targetUserId",
            userId: userId,
            startDate: startDate,
            endDate: endDate
        )

        async let likesTask = fetchCount(
            db: db,
            collection: "swipes",
            field: "targetUserId",
            userId: userId,
            startDate: startDate,
            endDate: endDate,
            additionalFilter: ("action", "like")
        )

        async let matchesTask = fetchMatchesInPeriod(userId: userId, startDate: startDate, endDate: endDate)

        async let messagesTask = fetchMessagesInPeriod(userId: userId, startDate: startDate, endDate: endDate)

        async let collabsTask = fetchCollabsInPeriod(userId: userId, startDate: startDate, endDate: endDate)

        async let swipesTask = fetchCount(
            db: db,
            collection: "swipes",
            field: "userId",
            userId: userId,
            startDate: startDate,
            endDate: endDate
        )

        let (views, likes, matches, messages, collabs, swipes) = await (viewsTask, likesTask, matchesTask, messagesTask, collabsTask, swipesTask)

        return PeriodStats(
            profileViews: views,
            newFollowers: 0, // Would need follower tracking system
            likesReceived: likes,
            totalMatches: matches,
            messagesSent: messages,
            activeCollabs: collabs,
            totalSwipes: swipes
        )
    }

    private func fetchCount(
        db: Firestore,
        collection: String,
        field: String,
        userId: String,
        startDate: Date,
        endDate: Date,
        additionalFilter: (String, String)? = nil
    ) async -> Int {
        do {
            var query = db.collection(collection)
                .whereField(field, isEqualTo: userId)
                .whereField("timestamp", isGreaterThanOrEqualTo: startDate)
                .whereField("timestamp", isLessThan: endDate)

            if let (filterField, filterValue) = additionalFilter {
                query = query.whereField(filterField, isEqualTo: filterValue)
            }

            let snapshot = try await query.getDocuments()
            return snapshot.documents.count
        } catch {
            print("❌ Error fetching count from \(collection): \(error)")
            return 0
        }
    }

    private func fetchMatchesInPeriod(userId: String, startDate: Date, endDate: Date) async -> Int {
        do {
            let matches = try await service.fetchMatches(forUser: userId)
            return matches.filter { $0.matchedAt >= startDate && $0.matchedAt < endDate }.count
        } catch {
            print("❌ Error fetching matches: \(error)")
            return 0
        }
    }

    private func fetchMessagesInPeriod(userId: String, startDate: Date, endDate: Date) async -> Int {
        do {
            let db = FirebaseFirestore.Firestore.firestore()
            let conversations = try await db.collection("conversations")
                .whereField("participantIds", arrayContains: userId)
                .getDocuments()

            var messageCount = 0
            for doc in conversations.documents {
                let messages = try await db.collection("conversations")
                    .document(doc.documentID)
                    .collection("messages")
                    .whereField("senderId", isEqualTo: userId)
                    .whereField("sentAt", isGreaterThanOrEqualTo: startDate)
                    .whereField("sentAt", isLessThan: endDate)
                    .getDocuments()

                messageCount += messages.documents.count
            }

            return messageCount
        } catch {
            print("❌ Error fetching messages: \(error)")
            return 0
        }
    }

    private func fetchCollabsInPeriod(userId: String, startDate: Date, endDate: Date) async -> Int {
        do {
            let db = FirebaseFirestore.Firestore.firestore()
            let conversations = try await db.collection("conversations")
                .whereField("participantIds", arrayContains: userId)
                .whereField("createdAt", isGreaterThanOrEqualTo: startDate)
                .whereField("createdAt", isLessThan: endDate)
                .getDocuments()

            var activeCollabs = 0
            for doc in conversations.documents {
                let messageSnapshot = try await db.collection("conversations")
                    .document(doc.documentID)
                    .collection("messages")
                    .getDocuments()

                if messageSnapshot.documents.count >= 5 {
                    activeCollabs += 1
                }
            }

            return activeCollabs
        } catch {
            print("❌ Error fetching collabs: \(error)")
            return 0
        }
    }

    private func getStartDate(for period: StatsPeriod) -> Date {
        let calendar = Calendar.current
        let now = Date()

        switch period {
        case .week:
            return calendar.date(byAdding: .day, value: -7, to: now) ?? now
        case .month:
            return calendar.date(byAdding: .day, value: -30, to: now) ?? now
        case .year:
            return calendar.date(byAdding: .day, value: -365, to: now) ?? now
        case .allTime:
            return Date(timeIntervalSince1970: 0) // Beginning of time
        }
    }

    private func getPreviousStartDate(for period: StatsPeriod) -> Date {
        let calendar = Calendar.current
        let currentStart = getStartDate(for: period)

        switch period {
        case .week:
            return calendar.date(byAdding: .day, value: -7, to: currentStart) ?? currentStart
        case .month:
            return calendar.date(byAdding: .day, value: -30, to: currentStart) ?? currentStart
        case .year:
            return calendar.date(byAdding: .day, value: -365, to: currentStart) ?? currentStart
        case .allTime:
            return Date(timeIntervalSince1970: 0)
        }
    }

    private func calculateChange(current: Int, previous: Int) -> String {
        guard previous > 0 else {
            return current > 0 ? "+100%" : "—"
        }

        let percentChange = Double(current - previous) / Double(previous) * 100

        if percentChange > 0 {
            return "+\(String(format: "%.1f", percentChange))%"
        } else if percentChange < 0 {
            return "\(String(format: "%.1f", percentChange))%"
        } else {
            return "0%"
        }
    }

    struct PeriodStats {
        let profileViews: Int
        let newFollowers: Int
        let likesReceived: Int
        let totalMatches: Int
        let messagesSent: Int
        let activeCollabs: Int
        let totalSwipes: Int
    }
}

// MARK: - Testimonial Card
struct TestimonialCard: View {
    let testimonial: Testimonial

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                if let imageURL = testimonial.authorImageURL, let url = URL(string: imageURL) {
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

                        Text(testimonial.authorName.prefix(1))
                            .font(.headline)
                            .foregroundStyle(AppTheme.accent)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(testimonial.authorName)
                            .font(.subheadline.bold())
                        if testimonial.isVerified {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.caption2)
                                .foregroundStyle(.blue)
                        }
                    }

                    if let role = testimonial.authorRole {
                        Text(role)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                HStack(spacing: 2) {
                    ForEach(0..<testimonial.rating, id: \.self) { _ in
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundStyle(.yellow)
                    }
                }
            }

            Text(testimonial.text)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(3)
        }
        .padding()
        .background(Color.gray.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Testimonials ViewModel
@MainActor
final class TestimonialsViewModel: ObservableObject {
    @Published var testimonials: [Testimonial] = []
    @Published var isLoading: Bool = false
    @Published var averageRating: Double = 0.0

    func loadTestimonials(profileUserId: String) async {
        isLoading = true

        do {
            let db = FirebaseFirestore.Firestore.firestore()
            let snapshot = try await db.collection("testimonials")
                .whereField("profileUserId", isEqualTo: profileUserId)
                .order(by: "createdAt", descending: true)
                .getDocuments()

            testimonials = snapshot.documents.compactMap { doc in
                try? doc.data(as: Testimonial.self)
            }

            // Calculate average rating
            if !testimonials.isEmpty {
                let totalRating = testimonials.reduce(0) { $0 + $1.rating }
                averageRating = Double(totalRating) / Double(testimonials.count)
            } else {
                averageRating = 0.0
            }

            print("✅ Loaded \(testimonials.count) testimonials with average rating \(averageRating)")
        } catch {
            print("❌ Error loading testimonials: \(error)")
        }

        isLoading = false
    }

    func addTestimonial(
        profileUserId: String,
        authorUserId: String,
        authorName: String,
        authorImageURL: String?,
        authorRole: String?,
        rating: Int,
        text: String,
        isVerified: Bool
    ) async throws {
        let db = FirebaseFirestore.Firestore.firestore()

        let testimonial = Testimonial(
            profileUserId: profileUserId,
            authorUserId: authorUserId,
            authorName: authorName,
            authorImageURL: authorImageURL,
            authorRole: authorRole,
            rating: rating,
            text: text,
            createdAt: Date(),
            isVerified: isVerified
        )

        try db.collection("testimonials").addDocument(from: testimonial)

        // Reload testimonials
        await loadTestimonials(profileUserId: profileUserId)

        print("✅ Testimonial added successfully")
    }
}

// MARK: - All Testimonials Sheet
struct AllTestimonialsSheet: View {
    let profile: UserProfile
    @ObservedObject var viewModel: TestimonialsViewModel
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var auth: AuthViewModel

    @State private var showAddTestimonial = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if !viewModel.testimonials.isEmpty {
                        // Summary Card
                        VStack(spacing: 12) {
                            HStack(spacing: 4) {
                                ForEach(0..<5) { index in
                                    Image(systemName: index < Int(viewModel.averageRating.rounded()) ? "star.fill" : "star")
                                        .font(.title2)
                                        .foregroundStyle(.yellow)
                                }
                            }

                            Text(String(format: "%.1f out of 5", viewModel.averageRating))
                                .font(.headline)

                            Text("\(viewModel.testimonials.count) testimonials")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal)

                        // All testimonials
                        VStack(spacing: 12) {
                            ForEach(viewModel.testimonials) { testimonial in
                                TestimonialCard(testimonial: testimonial)
                            }
                        }
                        .padding(.horizontal)
                    } else {
                        VStack(spacing: 16) {
                            Image(systemName: "quote.bubble")
                                .font(.system(size: 60))
                                .foregroundStyle(.secondary)
                            Text("No testimonials yet")
                                .font(.headline)
                            Text("Be the first to leave a testimonial!")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                    }
                }
                .padding(.vertical)
            }
            .background(AppTheme.bg)
            .navigationTitle("Testimonials")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    if let currentUserId = auth.user?.uid, currentUserId != profile.uid {
                        Button {
                            showAddTestimonial = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(AppTheme.accent)
                        }
                    }
                }
            }
            .sheet(isPresented: $showAddTestimonial) {
                AddTestimonialSheet(
                    profile: profile,
                    viewModel: viewModel
                )
            }
        }
        }
}

// MARK: - Add Testimonial Sheet
struct AddTestimonialSheet: View {
    let profile: UserProfile
    @ObservedObject var viewModel: TestimonialsViewModel
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var auth: AuthViewModel

    @State private var rating: Int = 5
    @State private var testimonialText: String = ""
    @State private var isSubmitting: Bool = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Rating") {
                    HStack {
                        ForEach(1...5, id: \.self) { star in
                            Button {
                                rating = star
                            } label: {
                                Image(systemName: star <= rating ? "star.fill" : "star")
                                    .font(.title2)
                                    .foregroundStyle(star <= rating ? .yellow : .gray)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }

                Section {
                    TextEditor(text: $testimonialText)
                        .frame(minHeight: 120)
                } header: {
                    Text("Your Testimonial")
                } footer: {
                    Text("Share your experience working with \(profile.displayName)")
                }
            }
            .navigationTitle("Add Testimonial")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Submit") {
                        Task { await submitTestimonial() }
                    }
                    .disabled(testimonialText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting)
                }
            }
            .disabled(isSubmitting)
        }
    }

    private func submitTestimonial() async {
        guard let currentUser = auth.userProfile,
              let currentUserId = auth.user?.uid else {
            return
        }

        isSubmitting = true

        do {
            // Check if there's an active conversation (for verified badge)
            let hasCollab = await checkHasCollaboration(userId: currentUserId, profileUserId: profile.uid)

            try await viewModel.addTestimonial(
                profileUserId: profile.uid,
                authorUserId: currentUserId,
                authorName: currentUser.displayName,
                authorImageURL: currentUser.profileImageURL,
                authorRole: currentUser.contentStyles.first?.rawValue,
                rating: rating,
                text: testimonialText.trimmingCharacters(in: .whitespacesAndNewlines),
                isVerified: hasCollab
            )

            dismiss()
        } catch {
            print("❌ Error submitting testimonial: \(error)")
        }

        isSubmitting = false
    }

    private func checkHasCollaboration(userId: String, profileUserId: String) async -> Bool {
        do {
            let db = FirebaseFirestore.Firestore.firestore()
            let conversations = try await db.collection("conversations")
                .whereField("participantIds", arrayContains: userId)
                .getDocuments()

            // Check if any conversation includes both users
            for doc in conversations.documents {
                if let participantIds = doc.data()["participantIds"] as? [String],
                   participantIds.contains(profileUserId) {
                    // Check if they've exchanged messages
                    let messages = try await db.collection("conversations")
                        .document(doc.documentID)
                        .collection("messages")
                        .getDocuments()

                    if messages.documents.count >= 3 {
                        return true
                    }
                }
            }
            return false
        } catch {
            return false
        }
    }
}

// MARK: - Collaboration History ViewModel
@MainActor
final class CollaborationHistoryViewModel: ObservableObject {
    @Published var collaborations: [CollaborationWithPartner] = []
    @Published var isLoading: Bool = false

    struct CollaborationWithPartner: Identifiable {
        var id: String { collaboration.id ?? UUID().uuidString }
        let collaboration: Collaboration
        let partnerProfile: UserProfile?
    }

    func loadCollaborations(userId: String) async {
        isLoading = true

        do {
            let db = FirebaseFirestore.Firestore.firestore()

            // Fetch collaborations where user is either user1 or user2
            let query1 = db.collection("collaborations")
                .whereField("user1Id", isEqualTo: userId)
            let query2 = db.collection("collaborations")
                .whereField("user2Id", isEqualTo: userId)

            let snapshot1 = try await query1.getDocuments()
            let snapshot2 = try await query2.getDocuments()

            var allCollabs: [Collaboration] = []

            allCollabs += snapshot1.documents.compactMap { doc in
                try? doc.data(as: Collaboration.self)
            }
            allCollabs += snapshot2.documents.compactMap { doc in
                try? doc.data(as: Collaboration.self)
            }

            // Sort by date
            allCollabs.sort { $0.startedAt > $1.startedAt }

            // Fetch partner profiles for each collaboration
            var collabsWithPartners: [CollaborationWithPartner] = []

            for collab in allCollabs {
                if let partnerId = collab.getPartnerUserId(currentUserId: userId) {
                    let partnerProfile = try? await fetchProfile(userId: partnerId)
                    collabsWithPartners.append(
                        CollaborationWithPartner(
                            collaboration: collab,
                            partnerProfile: partnerProfile
                        )
                    )
                }
            }

            collaborations = collabsWithPartners

            print("✅ Loaded \(collaborations.count) collaborations")
        } catch {
            print("❌ Error loading collaborations: \(error)")
        }

        isLoading = false
    }

    private func fetchProfile(userId: String) async throws -> UserProfile? {
        let db = FirebaseFirestore.Firestore.firestore()
        let doc = try await db.collection("users").document(userId).getDocument()
        return try? doc.data(as: UserProfile.self)
    }
}

// MARK: - All Collaborations Sheet
struct AllCollaborationsSheet: View {
    let profile: UserProfile
    @ObservedObject var viewModel: CollaborationHistoryViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if !viewModel.collaborations.isEmpty {
                        // Stats Summary
                        HStack(spacing: 16) {
                            StatBox(
                                title: "Total",
                                value: "\(viewModel.collaborations.count)",
                                color: .blue
                            )
                            StatBox(
                                title: "Active",
                                value: "\(viewModel.collaborations.filter { $0.collaboration.status == .active }.count)",
                                color: .green
                            )
                            StatBox(
                                title: "Completed",
                                value: "\(viewModel.collaborations.filter { $0.collaboration.status == .completed }.count)",
                                color: .purple
                            )
                        }
                        .padding(.horizontal)

                        // All collaborations
                        VStack(spacing: 12) {
                            ForEach(viewModel.collaborations) { collabWithPartner in
                                CollabHistoryCard(
                                    collaboration: collabWithPartner.collaboration,
                                    partnerProfile: collabWithPartner.partnerProfile
                                )
                            }
                        }
                        .padding(.horizontal)
                    } else {
                        VStack(spacing: 16) {
                            Image(systemName: "person.2")
                                .font(.system(size: 60))
                                .foregroundStyle(.secondary)
                            Text("No collaborations yet")
                                .font(.headline)
                            Text("Start collaborating with other creators!")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                    }
                }
                .padding(.vertical)
            }
            .background(AppTheme.bg)
            .navigationTitle("Collaboration History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    struct StatBox: View {
        let title: String
        let value: String
        let color: Color

        var body: some View {
            VStack(spacing: 4) {
                Text(value)
                    .font(.title2.bold())
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 12))
        }
    }
}

// MARK: - Profile Insights ViewModel
@MainActor
final class ProfileInsightsViewModel: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var engagementRate: Double = 0.0
    @Published var engagementTrend: String = "—"
    @Published var engagementTrendPositive: Bool = true
    @Published var responseRate: Double = 0.0
    @Published var responseTrend: String = "—"
    @Published var responseTrendPositive: Bool = true
    @Published var profileQuality: String = "Good"
    @Published var profileCompletionText: String = "—"
    @Published var weeklyGrowth: Int = 0
    @Published var growthTrend: String = "—"

    func loadInsights(userId: String) async {
        isLoading = true

        do {
            let db = FirebaseFirestore.Firestore.firestore()
            let now = Date()
            let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: now) ?? now
            let twoWeeksAgo = Calendar.current.date(byAdding: .day, value: -14, to: now) ?? now

            // Fetch profile views (from swipes collection)
            let profileViewsSnapshot = try await db.collection("swipes")
                .whereField("targetUserId", isEqualTo: userId)
                .getDocuments()
            let totalViews = profileViewsSnapshot.documents.count

            // Fetch likes received (swipes with action="like")
            let likesSnapshot = try await db.collection("swipes")
                .whereField("targetUserId", isEqualTo: userId)
                .whereField("action", isEqualTo: "like")
                .getDocuments()
            let totalLikes = likesSnapshot.documents.count

            // Calculate engagement rate
            if totalViews > 0 {
                engagementRate = (Double(totalLikes) / Double(totalViews)) * 100
            } else {
                engagementRate = 0.0
            }

            // Engagement trend (compare to previous week)
            let lastWeekViews = profileViewsSnapshot.documents.filter { doc in
                if let timestamp = doc.data()["timestamp"] as? Timestamp {
                    return timestamp.dateValue() >= weekAgo
                }
                return false
            }.count

            let lastWeekLikes = likesSnapshot.documents.filter { doc in
                if let timestamp = doc.data()["timestamp"] as? Timestamp {
                    return timestamp.dateValue() >= weekAgo
                }
                return false
            }.count

            let previousWeekViews = profileViewsSnapshot.documents.filter { doc in
                if let timestamp = doc.data()["timestamp"] as? Timestamp {
                    let date = timestamp.dateValue()
                    return date >= twoWeeksAgo && date < weekAgo
                }
                return false
            }.count

            if previousWeekViews > 0 {
                let previousWeekLikes = likesSnapshot.documents.filter { doc in
                    if let timestamp = doc.data()["timestamp"] as? Timestamp {
                        let date = timestamp.dateValue()
                        return date >= twoWeeksAgo && date < weekAgo
                    }
                    return false
                }.count

                let previousRate = (Double(previousWeekLikes) / Double(previousWeekViews)) * 100
                let currentRate = lastWeekViews > 0 ? (Double(lastWeekLikes) / Double(lastWeekViews)) * 100 : 0
                let diff = currentRate - previousRate
                engagementTrend = diff >= 0 ? "+\(String(format: "%.1f", diff))%" : "\(String(format: "%.1f", diff))%"
                engagementTrendPositive = diff >= 0
            } else {
                engagementTrend = "New"
                engagementTrendPositive = true
            }

            // Fetch messages sent and received
            let conversationsSnapshot = try await db.collection("conversations")
                .whereField("participantIds", arrayContains: userId)
                .getDocuments()

            var messagesSent = 0
            var messagesReceived = 0

            for convDoc in conversationsSnapshot.documents {
                let messagesSnapshot = try await db.collection("conversations")
                    .document(convDoc.documentID)
                    .collection("messages")
                    .getDocuments()

                for msgDoc in messagesSnapshot.documents {
                    if let senderId = msgDoc.data()["senderId"] as? String {
                        if senderId == userId {
                            messagesSent += 1
                        } else {
                            messagesReceived += 1
                        }
                    }
                }
            }

            // Calculate response rate
            if messagesReceived > 0 {
                responseRate = (Double(messagesSent) / Double(messagesReceived)) * 100
                responseRate = min(responseRate, 100) // Cap at 100%
            } else {
                responseRate = messagesSent > 0 ? 100 : 0
            }

            // Response trend
            if responseRate >= 80 {
                responseTrend = "Excellent"
                responseTrendPositive = true
            } else if responseRate >= 50 {
                responseTrend = "Good"
                responseTrendPositive = true
            } else {
                responseTrend = "Could improve"
                responseTrendPositive = false
            }

            // Calculate profile quality based on completion
            let completion = calculateProfileCompletion(userId: userId)
            if completion >= 90 {
                profileQuality = "Excellent"
                profileCompletionText = "Top 10%"
            } else if completion >= 70 {
                profileQuality = "Good"
                profileCompletionText = "\(completion)% complete"
            } else if completion >= 50 {
                profileQuality = "Fair"
                profileCompletionText = "\(completion)% complete"
            } else {
                profileQuality = "Needs work"
                profileCompletionText = "\(completion)% complete"
            }

            // Calculate weekly growth (new matches/likes in last 7 days)
            let weeklyMatches = try await db.collection("matches")
                .whereField("userId1", isEqualTo: userId)
                .whereField("matchedAt", isGreaterThanOrEqualTo: weekAgo)
                .getDocuments()

            let weeklyMatches2 = try await db.collection("matches")
                .whereField("userId2", isEqualTo: userId)
                .whereField("matchedAt", isGreaterThanOrEqualTo: weekAgo)
                .getDocuments()

            weeklyGrowth = weeklyMatches.documents.count + weeklyMatches2.documents.count + lastWeekLikes

            if weeklyGrowth >= 20 {
                growthTrend = "Excellent"
            } else if weeklyGrowth >= 10 {
                growthTrend = "Above average"
            } else if weeklyGrowth >= 5 {
                growthTrend = "Average"
            } else if weeklyGrowth > 0 {
                growthTrend = "Steady"
            } else {
                growthTrend = "Inactive"
            }

            print("✅ Profile insights loaded - Engagement: \(engagementRate)%, Response: \(responseRate)%, Growth: \(weeklyGrowth)")
        } catch {
            print("❌ Error loading profile insights: \(error)")
        }

        isLoading = false
    }

    private func calculateProfileCompletion(userId: String) -> Int {
        // This is a simplified calculation based on typical profile fields
        // In a real app, you'd fetch the profile and check each field
        var score = 0
        score += 10 // Base for having an account
        score += 20 // Profile image (assume they have one if viewing insights)
        score += 15 // Display name (required)
        score += 10 // Bio
        score += 10 // Location
        score += 10 // Content styles
        score += 10 // Social links
        score += 10 // Collaboration preferences
        score += 5  // Age
        return min(score, 100)
    }
}

// MARK: - Collaboration History Card
struct CollabHistoryCard: View {
    let collaboration: Collaboration
    let partnerProfile: UserProfile?

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            if let imageURL = partnerProfile?.profileImageURL, let url = URL(string: imageURL) {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Circle().fill(AppTheme.accent.opacity(0.3))
                }
                .frame(width: 50, height: 50)
                .clipShape(Circle())
            } else {
                ZStack {
                    Circle()
                        .fill(AppTheme.accent.opacity(0.3))
                        .frame(width: 50, height: 50)

                    if let name = partnerProfile?.displayName {
                        Text(name.prefix(1))
                            .font(.title3.bold())
                            .foregroundStyle(AppTheme.accent)
                    } else {
                        Image(systemName: "person.fill")
                            .foregroundStyle(AppTheme.accent)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(collaboration.projectName)
                    .font(.subheadline.bold())

                HStack(spacing: 6) {
                    Text(partnerProfile?.displayName ?? "Unknown")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Circle()
                        .fill(Color.secondary)
                        .frame(width: 2, height: 2)

                    Text(formatDate(collaboration.startedAt))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Status Badge
            HStack(spacing: 4) {
                Image(systemName: collaboration.status.icon)
                    .font(.caption2)
                Text(collaboration.status.rawValue)
                    .font(.caption2.bold())
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(getStatusColor(collaboration.status), in: Capsule())
        }
        .padding()
        .background(Color.gray.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private func getStatusColor(_ status: Collaboration.CollabStatus) -> Color {
        switch status {
        case .active: return .green
        case .completed: return .blue
        case .pending: return .orange
        }
    }
}

