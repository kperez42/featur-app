// EnhancedProfileView.swift - PREMIUM PROFILE PAGE
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
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Hero Header with Parallax
                ProfileHeroSection(
                    profile: profile,
                    scrollOffset: scrollOffset,
                    onEdit: { showEditSheet = true },
                    onShare: { showShareSheet = true },
                    onQR: { showQRSheet = true }
                )
                .background(
                    GeometryReader { geo in
                        Color.clear.preference(
                            key: ScrollOffsetKey.self,
                            value: geo.frame(in: .named("scroll")).minY
                        )
                    }
                )
                
                // Stats Cards
                ProfileStatsGrid(profile: profile, onTapStats: { showStatsSheet = true })
                    .padding(.horizontal)
                    .padding(.top, -30)
                
                // Achievement Badges
                AchievementBadgeRow(profile: profile)
                    .padding(.horizontal)
                    .padding(.top, 16)
                
                // Profile Completion
                ProfileCompletionCard(profile: profile)
                    .padding(.horizontal)
                    .padding(.top, 16)
                
                // Tab Selector
                CustomTabBar(selectedTab: $selectedTab)
                    .padding(.top, 24)
                
                // Tab Content
                TabContent(selectedTab: selectedTab, profile: profile)
                    .padding(.horizontal)
                    .padding(.top, 20)
                    .padding(.bottom, 100)
            }
        }
        .coordinateSpace(name: "scroll")
        .onPreferenceChange(ScrollOffsetKey.self) { value in
            scrollOffset = value
        }
        .background(AppTheme.bg)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(profile.displayName)
                    .font(.headline)
                    .opacity(scrollOffset < -100 ? 1 : 0)
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { showEditSheet = true } label: {
                        Label("Edit Profile", systemImage: "pencil")
                    }
                    Button { showQRSheet = true } label: {
                        Label("QR Code", systemImage: "qrcode")
                    }
                    Button { showShareSheet = true } label: {
                        Label("Share Profile", systemImage: "square.and.arrow.up")
                    }
                    Divider()
                    Button { showSettingsSheet = true } label: {
                        Label("Settings", systemImage: "gear")
                    }
                    Button(role: .destructive) {
                        Task { await auth.signOut() }
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle.fill")
                        .foregroundStyle(AppTheme.accent)
                        .font(.title3)
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            EditProfileSheet(profile: profile, viewModel: viewModel)
        }
        .sheet(isPresented: $showSettingsSheet) {
            SettingsSheet()
        }
        .sheet(isPresented: $showQRSheet) {
            QRCodeSheet(profile: profile)
        }
        .sheet(isPresented: $showStatsSheet) {
            DetailedStatsSheet(profile: profile)
        }
    }
}

// MARK: - Hero Section
private struct ProfileHeroSection: View {
    let profile: UserProfile
    let scrollOffset: CGFloat
    let onEdit: () -> Void
    let onShare: () -> Void
    let onQR: () -> Void
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Gradient Background with Parallax
            AppTheme.gradient
                .frame(height: 300 + max(0, scrollOffset))
                .clipped()
            
            // Content
            VStack(spacing: 16) {
                // Profile Image with Ring
                ZStack(alignment: .bottomTrailing) {
                    if let imageURL = profile.profileImageURL, let url = URL(string: imageURL) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 140, height: 140)
                                    .clipShape(Circle())
                            default:
                                InitialsAvatar(name: profile.displayName, size: 140)
                            }
                        }
                    } else {
                        InitialsAvatar(name: profile.displayName, size: 140)
                    }
                    
                    // Verification Badge
                    if profile.isVerified {
                        ZStack {
                            Circle()
                                .fill(.white)
                                .frame(width: 36, height: 36)
                            Image(systemName: "checkmark.seal.fill")
                                .font(.title2)
                                .foregroundStyle(.blue)
                        }
                        .offset(x: -4, y: -4)
                    }
                    
                    // Online Indicator
                    if profile.isOnline {
                        Circle()
                            .fill(.green)
                            .frame(width: 24, height: 24)
                            .overlay(Circle().stroke(.white, lineWidth: 3))
                    }
                }
                .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
                
                // Name & Info
                VStack(spacing: 6) {
                    Text(profile.displayName)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.white)
                    
                    if let age = profile.age {
                        HStack(spacing: 12) {
                            HStack(spacing: 4) {
                                Image(systemName: "calendar")
                                Text("\(age) years old")
                            }
                            
                            if let location = profile.location, let city = location.city {
                                Text("•")
                                HStack(spacing: 4) {
                                    Image(systemName: "mappin.circle")
                                    Text(city)
                                }
                            }
                        }
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.9))
                    }
                }
                
                // Bio
                if let bio = profile.bio, !bio.isEmpty {
                    Text(bio)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.95))
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .padding(.horizontal, 40)
                }
                
                // Quick Actions
                HStack(spacing: 16) {
                    QuickActionBtn(icon: "pencil", label: "Edit", action: onEdit)
                    QuickActionBtn(icon: "qrcode", label: "QR", action: onQR)
                    QuickActionBtn(icon: "square.and.arrow.up", label: "Share", action: onShare)
                }
                .padding(.top, 12)
            }
            .padding(.bottom, 40)
        }
    }
}

private struct QuickActionBtn: View {
    let icon: String
    let label: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                Text(label)
                    .font(.caption)
            }
            .frame(width: 80)
            .padding(.vertical, 10)
            .background(.white.opacity(0.25), in: RoundedRectangle(cornerRadius: 14))
            .foregroundStyle(.white)
        }
    }
}

// MARK: - Stats Grid
private struct ProfileStatsGrid: View {
    let profile: UserProfile
    let onTapStats: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                StatCard(
                    icon: "person.3.fill",
                    value: formatNumber(profile.followerCount),
                    label: "Followers",
                    gradient: [.blue, .cyan]
                )
                
                StatCard(
                    icon: "heart.fill",
                    value: "\(Int.random(in: 1000...10000))",
                    label: "Likes",
                    gradient: [.pink, .red]
                )
            }
            
            HStack(spacing: 12) {
                StatCard(
                    icon: "eye.fill",
                    value: formatNumber(Int.random(in: 10000...500000)),
                    label: "Views",
                    gradient: [.purple, .indigo]
                )
                
                StatCard(
                    icon: "arrow.up.right",
                    value: "+\(Int.random(in: 10...50))%",
                    label: "Growth",
                    gradient: [.green, .mint]
                )
            }
            
            Button(action: onTapStats) {
                HStack {
                    Text("View Detailed Analytics")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .foregroundStyle(AppTheme.accent)
                .padding()
                .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 14))
            }
        }
    }
}

private struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let gradient: [Color]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(
                    LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                )
            
            Text(value)
                .font(.title2.bold())
            
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: gradient[0].opacity(0.2), radius: 8, y: 4)
    }
}

// MARK: - Achievement Badges
private struct AchievementBadgeRow: View {
    let profile: UserProfile
    
    var achievements: [Achievement] {
        var list: [Achievement] = []
        if profile.isVerified {
            list.append(.init(icon: "checkmark.seal.fill", title: "Verified", color: .blue))
        }
        if profile.followerCount >= 100000 {
            list.append(.init(icon: "crown.fill", title: "Top Creator", color: .yellow))
        }
        if profile.followerCount >= 10000 {
            list.append(.init(icon: "star.fill", title: "Rising Star", color: .orange))
        }
        if profile.followerCount >= 1000 {
            list.append(.init(icon: "flame.fill", title: "Popular", color: .red))
        }
        return list
    }
    
    var body: some View {
        if !achievements.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Achievements")
                    .font(.headline)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(achievements) { achievement in
                            AchievementBadge(achievement: achievement)
                        }
                    }
                }
            }
        }
    }
}

private struct Achievement: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let color: Color
}

private struct AchievementBadge: View {
    let achievement: Achievement
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: achievement.icon)
                .foregroundStyle(achievement.color)
            Text(achievement.title)
                .font(.subheadline.weight(.semibold))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(achievement.color.opacity(0.15), in: Capsule())
        .overlay(Capsule().stroke(achievement.color.opacity(0.3), lineWidth: 1))
    }
}

// MARK: - Profile Completion
private struct ProfileCompletionCard: View {
    let profile: UserProfile
    
    var completion: Double {
        var score: Double = 0
        let total: Double = 7
        
        if profile.profileImageURL != nil { score += 1 }
        if profile.bio != nil && !profile.bio!.isEmpty { score += 1 }
        if !profile.mediaURLs.isEmpty { score += 1 }
        if profile.location != nil { score += 1 }
        if !profile.contentStyles.isEmpty { score += 1 }
        if profile.socialLinks.instagram != nil || profile.socialLinks.tiktok != nil { score += 1 }
        if !profile.interests.isEmpty { score += 1 }
        
        return score / total
    }
    
    var body: some View {
        if completion < 1.0 {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Profile Strength")
                        .font(.headline)
                    Spacer()
                    Text("\(Int(completion * 100))%")
                        .font(.headline)
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
                                    colors: [AppTheme.accent, .green],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * completion, height: 8)
                    }
                }
                .frame(height: 8)
                
                Text("Complete your profile to get more matches!")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
        }
    }
}

// MARK: - Custom Tab Bar
private struct CustomTabBar: View {
    @Binding var selectedTab: Int
    let tabs = ["Overview", "Content", "Stats", "Activity"]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach(0..<tabs.count, id: \.self) { index in
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            selectedTab = index
                        }
                    } label: {
                        VStack(spacing: 8) {
                            Text(tabs[index])
                                .font(.subheadline.weight(selectedTab == index ? .bold : .regular))
                                .foregroundStyle(selectedTab == index ? AppTheme.accent : .secondary)
                            
                            if selectedTab == index {
                                Capsule()
                                    .fill(AppTheme.accent)
                                    .frame(height: 3)
                                    .transition(.scale)
                            } else {
                                Capsule()
                                    .fill(Color.clear)
                                    .frame(height: 3)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Tab Content
private struct TabContent: View {
    let selectedTab: Int
    let profile: UserProfile
    
    var body: some View {
        Group {
            switch selectedTab {
            case 0: OverviewTab(profile: profile)
            case 1: ContentTab(profile: profile)
            case 2: StatsTab(profile: profile)
            case 3: ActivityTab(profile: profile)
            default: OverviewTab(profile: profile)
            }
        }
    }
}

// MARK: - Overview Tab
private struct OverviewTab: View {
    let profile: UserProfile
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Content Styles
            if !profile.contentStyles.isEmpty {
                SectionCard(title: "Content Styles", icon: "square.grid.3x3") {
                    FlowLayout(spacing: 8) {
                        ForEach(profile.contentStyles, id: \.self) { style in
                            TagChip(title: style.rawValue, active: false)
                        }
                    }
                }
            }
            
            // Interests
            if !profile.interests.isEmpty {
                SectionCard(title: "Interests", icon: "heart.fill") {
                    FlowLayout(spacing: 8) {
                        ForEach(profile.interests, id: \.self) { interest in
                            Text(interest)
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(AppTheme.card, in: Capsule())
                        }
                    }
                }
            }
            
            // Social Links
            SocialLinksSection(profile: profile)
            
            // Collaboration Preferences
            CollabPreferencesSection(profile: profile)
        }
    }
}

// MARK: - Content Tab
private struct ContentTab: View {
    let profile: UserProfile
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if profile.mediaURLs.isEmpty {
                EmptyContentState()
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(profile.mediaURLs, id: \.self) { url in
                        AsyncImage(url: URL(string: url)) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 120)
                                    .clipped()
                                    .cornerRadius(12)
                            default:
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(AppTheme.card)
                                    .frame(height: 120)
                            }
                        }
                    }
                }
            }
        }
    }
}

private struct EmptyContentState: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.stack")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            
            Text("No content yet")
                .font(.headline)
            
            Text("Add photos and videos to showcase your work")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

// MARK: - Stats Tab
private struct StatsTab: View {
    let profile: UserProfile
    
    var body: some View {
        VStack(spacing: 16) {
            // Engagement Stats
            SectionCard(title: "Engagement", icon: "chart.line.uptrend.xyaxis") {
                VStack(spacing: 12) {
                    StatRow(label: "Avg. Likes", value: "\(Int.random(in: 100...1000))")
                    StatRow(label: "Avg. Comments", value: "\(Int.random(in: 20...200))")
                    StatRow(label: "Avg. Shares", value: "\(Int.random(in: 10...100))")
                    StatRow(label: "Engagement Rate", value: "\(Int.random(in: 5...15))%")
                }
            }
            
            // Growth Stats
            SectionCard(title: "Growth", icon: "arrow.up.right") {
                VStack(spacing: 12) {
                    StatRow(label: "This Week", value: "+\(Int.random(in: 50...500))")
                    StatRow(label: "This Month", value: "+\(Int.random(in: 500...5000))")
                    StatRow(label: "All Time", value: formatNumber(profile.followerCount))
                }
            }
        }
    }
}

private struct StatRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
        .font(.subheadline)
    }
}

// MARK: - Activity Tab
private struct ActivityTab: View {
    let profile: UserProfile
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionCard(title: "Recent Activity", icon: "clock.fill") {
                VStack(spacing: 16) {
                    ActivityItem(icon: "person.badge.plus", text: "Gained 25 new followers", time: "2h ago")
                    ActivityItem(icon: "heart.fill", text: "Post received 150 likes", time: "5h ago")
                    ActivityItem(icon: "message.fill", text: "New collaboration request", time: "1d ago")
                    ActivityItem(icon: "star.fill", text: "Profile was featured", time: "3d ago")
                }
            }
        }
    }
}

private struct ActivityItem: View {
    let icon: String
    let text: String
    let time: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(AppTheme.accent)
                .frame(width: 40, height: 40)
                .background(AppTheme.accent.opacity(0.15), in: Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(text)
                    .font(.subheadline)
                Text(time)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Section Components
private struct SectionCard<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(AppTheme.accent)
                Text(title)
                    .font(.headline)
            }
            
            content
        }
        .padding()
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct SocialLinksSection: View {
    let profile: UserProfile
    
    var body: some View {
        SectionCard(title: "Social Links", icon: "link") {
            VStack(spacing: 12) {
                if let ig = profile.socialLinks.instagram {
                    SocialLinkRow(platform: "Instagram", username: ig.username, icon: "camera", verified: ig.isVerified)
                }
                if let tt = profile.socialLinks.tiktok {
                    SocialLinkRow(platform: "TikTok", username: tt.username, icon: "music.note", verified: tt.isVerified)
                }
                if let yt = profile.socialLinks.youtube {
                    SocialLinkRow(platform: "YouTube", username: yt.username, icon: "play.rectangle", verified: yt.isVerified)
                }
                if let tw = profile.socialLinks.twitch {
                    SocialLinkRow(platform: "Twitch", username: tw.username, icon: "gamecontroller", verified: tw.isVerified)
                }
            }
        }
    }
}

private struct SocialLinkRow: View {
    let platform: String
    let username: String
    let icon: String
    let verified: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(AppTheme.accent)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(platform)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack(spacing: 4) {
                    Text("@\(username)")
                        .font(.subheadline)
                    if verified {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                }
            }
            
            Spacer()
            
            Button {
                // Open social link
            } label: {
                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct CollabPreferencesSection: View {
    let profile: UserProfile
    
    var body: some View {
        SectionCard(title: "Collaboration", icon: "person.2.fill") {
            VStack(alignment: .leading, spacing: 12) {
                if !profile.collaborationPreferences.lookingFor.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Looking For")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        FlowLayout(spacing: 8) {
                            ForEach(profile.collaborationPreferences.lookingFor, id: \.self) { type in
                                Text(type.rawValue)
                                    .font(.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(AppTheme.accent.opacity(0.15), in: Capsule())
                                    .foregroundStyle(AppTheme.accent)
                            }
                        }
                    }
                }
                
                HStack {
                    Image(systemName: "clock")
                        .foregroundStyle(.secondary)
                    Text(profile.collaborationPreferences.responseTime.rawValue)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

// MARK: - Loading & Guest Views
private struct LoadingProfileScreen: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(AppTheme.accent)
            Text("Loading profile...")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.bg)
    }
}

private struct PremiumGuestView: View {
    @EnvironmentObject var auth: AuthViewModel
    
    var body: some View {
        ZStack {
            AppTheme.gradient.ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                VStack(spacing: 16) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 100))
                        .foregroundStyle(.white)
                        .shadow(radius: 20)
                    
                    VStack(spacing: 8) {
                        Text("Join FEATUR")
                            .font(.largeTitle.bold())
                            .foregroundStyle(.white)
                        
                        Text("Connect with creators, collaborate, and grow")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                    }
                }
                
                VStack(spacing: 16) {
                    FeatureRow(icon: "person.3.fill", text: "Match with creators")
                    FeatureRow(icon: "message.fill", text: "Direct messaging")
                    FeatureRow(icon: "star.fill", text: "Get featured")
                    FeatureRow(icon: "chart.line.uptrend.xyaxis", text: "Track your growth")
                }
                .padding(.horizontal, 40)
                
                Spacer()
                
                NavigationLink {
                    LoginView(navigationPath: .constant(NavigationPath()))
                } label: {
                    Text("Sign In")
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

// MARK: - Helper Views
private struct InitialsAvatar: View {
    let name: String
    let size: CGFloat
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.purple, .pink],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(width: size, height: size)
            .clipShape(Circle())
            
            Text(String(name.prefix(1)).uppercased())
                .font(.system(size: size * 0.4, weight: .bold))
                .foregroundStyle(.white)
        }
        .overlay(Circle().stroke(.white, lineWidth: 4))
        .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
    }
}

// MARK: - Sheets
struct EditProfileSheet: View {
    let profile: UserProfile
    @ObservedObject var viewModel: ProfileViewModel
    @Environment(\.dismiss) var dismiss
    @State private var displayName: String
    @State private var bio: String
    @State private var selectedPhoto: PhotosPickerItem?
    
    init(profile: UserProfile, viewModel: ProfileViewModel) {
        self.profile = profile
        self.viewModel = viewModel
        _displayName = State(initialValue: profile.displayName)
        _bio = State(initialValue: profile.bio ?? "")
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Info") {
                    TextField("Display Name", text: $displayName)
                    TextField("Bio", text: $bio, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Profile Photo") {
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        HStack {
                            if let imageURL = profile.profileImageURL, let url = URL(string: imageURL) {
                                AsyncImage(url: url) { image in
                                    image.resizable().scaledToFill()
                                } placeholder: {
                                    Color.gray
                                }
                                .frame(width: 60, height: 60)
                                .clipShape(Circle())
                            }
                            Text("Change Photo")
                        }
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
                            updated.bio = bio
                            await viewModel.updateProfile(updated)
                            dismiss()
                        }
                    }
                }
            }
        }
    }
}

struct QRCodeSheet: View {
    let profile: UserProfile
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Text("Scan to connect")
                    .font(.title2.bold())
                
                // Placeholder QR Code
                RoundedRectangle(cornerRadius: 20)
                    .fill(AppTheme.gradient)
                    .frame(width: 250, height: 250)
                    .overlay(
                        Image(systemName: "qrcode")
                            .font(.system(size: 100))
                            .foregroundStyle(.white)
                    )
                
                Text(profile.displayName)
                    .font(.headline)
                
                Button("Share QR Code") {
                    // Share functionality
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.accent)
            }
            .padding()
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

struct DetailedStatsSheet: View {
    let profile: UserProfile
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Monthly Stats
                    SectionCard(title: "This Month", icon: "calendar") {
                        VStack(spacing: 12) {
                            StatRow(label: "New Followers", value: "+\(Int.random(in: 100...1000))")
                            StatRow(label: "Total Likes", value: "\(Int.random(in: 1000...10000))")
                            StatRow(label: "Profile Views", value: "\(Int.random(in: 500...5000))")
                            StatRow(label: "Matches", value: "\(Int.random(in: 5...50))")
                        }
                    }
                    
                    // All Time Stats
                    SectionCard(title: "All Time", icon: "infinity") {
                        VStack(spacing: 12) {
                            StatRow(label: "Total Followers", value: formatNumber(profile.followerCount))
                            StatRow(label: "Total Matches", value: "\(Int.random(in: 50...500))")
                            StatRow(label: "Messages Sent", value: "\(Int.random(in: 100...1000))")
                            StatRow(label: "Collaborations", value: "\(Int.random(in: 5...50))")
                        }
                    }
                }
                .padding()
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
