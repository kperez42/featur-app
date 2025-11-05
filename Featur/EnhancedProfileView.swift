import SwiftUI
import FirebaseAuth
import PhotosUI
import AuthenticationServices

// MARK: - Enhanced Profile View (Drop-in Replacement)
struct EnhancedProfileView: View {
    @EnvironmentObject var auth: AuthViewModel
    @StateObject private var viewModel = ProfileViewModel()
    @State private var selectedTab: ProfileTab = .overview
    @State private var showingEditSheet = false
    @State private var showingSettingsSheet = false
    @State private var showingQRCode = false
    @State private var showingShareSheet = false
    @State private var scrollOffset: CGFloat = 0
    @State private var showSuccessToast = false
    @State private var toastMessage = ""
    @State private var showStatsDetail = false
    @State private var showAchievements = false
    @State private var profileCompletion: Double = 0.75
    
    var body: some View {
        Group {
            if auth.user == nil {
                ImprovedGuestProfileView()
            } else if viewModel.needsSetup {
                ProfileCreationFlow(viewModel: viewModel)
            } else if let profile = viewModel.profile {
                MainProfileView(
                    profile: profile,
                    viewModel: viewModel,
                    selectedTab: $selectedTab,
                    showingEditSheet: $showingEditSheet,
                    showingSettingsSheet: $showingSettingsSheet,
                    showingQRCode: $showingQRCode,
                    showingShareSheet: $showingShareSheet,
                    scrollOffset: $scrollOffset,
                    showSuccessToast: $showSuccessToast,
                    toastMessage: $toastMessage,
                    showStatsDetail: $showStatsDetail,
                    showAchievements: $showAchievements,
                    profileCompletion: $profileCompletion
                )
            } else {
                LoadingProfileView()
            }
        }
        .task {
            if let uid = auth.user?.uid {
                await viewModel.loadProfile(uid: uid)
            }
        }
        .overlay(alignment: .top) {
            if showSuccessToast {
                SuccessToast(message: toastMessage)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                            withAnimation {
                                showSuccessToast = false
                            }
                        }
                    }
            }
        }
    }
}

// MARK: - Profile Tab Enum
private enum ProfileTab: String, CaseIterable, Identifiable {
    case overview = "Overview"
    case content = "Content"
    case stats = "Stats"
    case activity = "Activity"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .overview: return "person.circle.fill"
        case .content: return "square.grid.3x3.fill"
        case .stats: return "chart.bar.fill"
        case .activity: return "clock.fill"
        }
    }
}

// MARK: - Main Profile View
private struct MainProfileView: View {
    let profile: UserProfile
    @ObservedObject var viewModel: ProfileViewModel
    @Binding var selectedTab: ProfileTab
    @Binding var showingEditSheet: Bool
    @Binding var showingSettingsSheet: Bool
    @Binding var showingQRCode: Bool
    @Binding var showingShareSheet: Bool
    @Binding var scrollOffset: CGFloat
    @Binding var showSuccessToast: Bool
    @Binding var toastMessage: String
    @Binding var showStatsDetail: Bool
    @Binding var showAchievements: Bool
    @Binding var profileCompletion: Double
    
    @EnvironmentObject var auth: AuthViewModel
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Hero Header
                    ProfileHeroHeader(
                        profile: profile,
                        scrollOffset: $scrollOffset,
                        onEdit: { showingEditSheet = true },
                        onShare: { showingShareSheet = true },
                        onQR: { showingQRCode = true }
                    )
                    
                    // Quick Stats Dashboard
                    QuickStatsDashboard(
                        profile: profile,
                        onTapStats: { showStatsDetail = true }
                    )
                    .padding(.horizontal)
                    .padding(.top, 20)
                    
                    // Achievement Badges
                    if hasAchievements(profile) {
                        AchievementBadgesRow(
                            profile: profile,
                            onTapAll: { showAchievements = true }
                        )
                        .padding(.horizontal)
                        .padding(.top, 16)
                    }
                    
                    // Tab Selector
                    ProfileTabSelector(selectedTab: $selectedTab)
                        .padding(.top, 20)
                    
                    // Tab Content
                    Group {
                        switch selectedTab {
                        case .overview:
                            OverviewTabContent(profile: profile)
                        case .content:
                            ContentTabView(profile: profile)
                        case .stats:
                            StatsTabView(profile: profile)
                        case .activity:
                            ActivityTabView(profile: profile)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                    .padding(.bottom, 100)
                }
            }
            .background(AppTheme.bg)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(profile.displayName)
                        .font(.headline)
                        .opacity(scrollOffset > 200 ? 1 : 0)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            showingEditSheet = true
                        } label: {
                            Label("Edit Profile", systemImage: "pencil")
                        }
                        
                        Button {
                            showingQRCode = true
                        } label: {
                            Label("QR Code", systemImage: "qrcode")
                        }
                        
                        Button {
                            showingShareSheet = true
                        } label: {
                            Label("Share Profile", systemImage: "square.and.arrow.up")
                        }
                        
                        Divider()
                        
                        Button {
                            showingSettingsSheet = true
                        } label: {
                            Label("Settings", systemImage: "gear")
                        }
                        
                        Button(role: .destructive) {
                            Task { await auth.signOut() }
                        } label: {
                            Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundStyle(AppTheme.accent)
                    }
                }
            }
            .sheet(isPresented: $showingEditSheet) {
                ProfileEditSheet(profile: profile, viewModel: viewModel)
            }
            .sheet(isPresented: $showingSettingsSheet) {
                SettingsSheet()
            }
            .sheet(isPresented: $showingQRCode) {
                QRCodeSheet(profile: profile)
            }
            .sheet(isPresented: $showStatsDetail) {
                DetailedStatsSheet(profile: profile)
            }
            .sheet(isPresented: $showAchievements) {
                AchievementsSheet(profile: profile)
            }
        }
    }
    
    private func hasAchievements(_ profile: UserProfile) -> Bool {
        return profile.followerCount >= 1000 || profile.isVerified
    }
}

// MARK: - Profile Hero Header
private struct ProfileHeroHeader: View {
    let profile: UserProfile
    @Binding var scrollOffset: CGFloat
    let onEdit: () -> Void
    let onShare: () -> Void
    let onQR: () -> Void
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Background gradient
            AppTheme.gradient
                .frame(height: 280)
                .offset(y: -scrollOffset * 0.5)
            
            VStack(spacing: 16) {
                // Profile Image
                ZStack(alignment: .bottomTrailing) {
                    if let imageURL = profile.profileImageURL,
                       let url = URL(string: imageURL) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 120, height: 120)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: 4)
                                    )
                                    .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
                            default:
                                Circle()
                                    .fill(LinearGradient(
                                        colors: [.purple, .pink],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ))
                                    .frame(width: 120, height: 120)
                                    .overlay(
                                        Text(profile.displayName.prefix(1).uppercased())
                                            .font(.system(size: 48, weight: .bold))
                                            .foregroundStyle(.white)
                                    )
                            }
                        }
                    }
                    
                    // Online status indicator
                    if profile.isOnline {
                        Circle()
                            .fill(.green)
                            .frame(width: 20, height: 20)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 3)
                            )
                    }
                }
                
                // Name and verification
                VStack(spacing: 4) {
                    HStack(spacing: 8) {
                        Text(profile.displayName)
                            .font(.title.bold())
                            .foregroundStyle(.white)
                        
                        if profile.isVerified {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(.blue)
                                .font(.title3)
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
                            Text(city)
                        }
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                    }
                }
                
                // Quick action buttons
                HStack(spacing: 12) {
                    QuickActionButton(icon: "pencil", label: "Edit", action: onEdit)
                    QuickActionButton(icon: "qrcode", label: "QR", action: onQR)
                    QuickActionButton(icon: "square.and.arrow.up", label: "Share", action: onShare)
                }
                .padding(.top, 8)
            }
            .padding(.bottom, 20)
        }
    }
}

// MARK: - Quick Action Button
private struct QuickActionButton: View {
    let icon: String
    let label: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                Text(label)
                    .font(.caption2)
            }
            .frame(width: 70)
            .padding(.vertical, 8)
            .background(.white.opacity(0.2), in: RoundedRectangle(cornerRadius: 12))
            .foregroundStyle(.white)
        }
    }
}

// MARK: - Quick Stats Dashboard
private struct QuickStatsDashboard: View {
    let profile: UserProfile
    let onTapStats: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Your Stats")
                    .font(.headline)
                Spacer()
                Button(action: onTapStats) {
                    Text("See All")
                        .font(.caption)
                        .foregroundStyle(AppTheme.accent)
                }
            }
            
            HStack(spacing: 12) {
                StatCard(
                    icon: "person.3.fill",
                    value: formatNumber(profile.followerCount),
                    label: "Followers",
                    color: .blue
                )
                
                StatCard(
                    icon: "heart.fill",
                    value: "\(Int.random(in: 500...5000))",
                    label: "Likes",
                    color: .pink
                )
                
                StatCard(
                    icon: "eye.fill",
                    value: formatNumber(Int.random(in: 10000...100000)),
                    label: "Views",
                    color: .purple
                )
            }
        }
        .padding()
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
    }
    
    private func formatNumber(_ num: Int) -> String {
        if num >= 1_000_000 {
            return String(format: "%.1fM", Double(num) / 1_000_000)
        } else if num >= 1_000 {
            return String(format: "%.1fK", Double(num) / 1_000)
        }
        return "\(num)"
    }
}

// MARK: - Stat Card
private struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .font(.title3)
            }
            
            Text(value)
                .font(.title3.bold())
            
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(AppTheme.bg, in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Achievement Badges Row
private struct AchievementBadgesRow: View {
    let profile: UserProfile
    let onTapAll: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Achievements")
                    .font(.headline)
                Spacer()
                Button(action: onTapAll) {
                    Text("View All")
                        .font(.caption)
                        .foregroundStyle(AppTheme.accent)
                }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    if profile.isVerified {
                        AchievementBadge(
                            icon: "checkmark.seal.fill",
                            title: "Verified Creator",
                            color: .blue
                        )
                    }
                    
                    if profile.followerCount >= 10000 {
                        AchievementBadge(
                            icon: "star.fill",
                            title: "10K Followers",
                            color: .yellow
                        )
                    }
                    
                    if profile.followerCount >= 1000 {
                        AchievementBadge(
                            icon: "trophy.fill",
                            title: "1K Followers",
                            color: .orange
                        )
                    }
                    
                    // Mock achievements
                    AchievementBadge(
                        icon: "flame.fill",
                        title: "7 Day Streak",
                        color: .red
                    )
                    
                    AchievementBadge(
                        icon: "heart.fill",
                        title: "First Match",
                        color: .pink
                    )
                }
            }
        }
    }
}

// MARK: - Achievement Badge
private struct AchievementBadge: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 60, height: 60)
                
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .font(.title2)
            }
            
            Text(title)
                .font(.caption2)
                .multilineTextAlignment(.center)
                .frame(width: 80)
        }
    }
}

// MARK: - Profile Tab Selector
private struct ProfileTabSelector: View {
    @Binding var selectedTab: ProfileTab
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(ProfileTab.allCases) { tab in
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            selectedTab = tab
                        }
                        Haptics.impact(.light)
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: tab.icon)
                                .font(.title3)
                            Text(tab.rawValue)
                                .font(.caption)
                        }
                        .frame(width: 80)
                        .padding(.vertical, 12)
                        .background(
                            selectedTab == tab ? AppTheme.accent : AppTheme.card,
                            in: RoundedRectangle(cornerRadius: 12)
                        )
                        .foregroundStyle(selectedTab == tab ? .white : .primary)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Overview Tab Content
private struct OverviewTabContent: View {
    let profile: UserProfile
    
    var body: some View {
        VStack(spacing: 20) {
            // Bio Section
            if let bio = profile.bio, !bio.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("About")
                        .font(.headline)
                    
                    Text(bio)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
            }
            
            // Content Styles
            if !profile.contentStyles.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Content Styles")
                        .font(.headline)
                    
                    FlowLayout(spacing: 8) {
                        ForEach(profile.contentStyles, id: \.self) { style in
                            HStack(spacing: 6) {
                                Image(systemName: style.icon)
                                Text(style.rawValue)
                            }
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(AppTheme.accent.opacity(0.15), in: Capsule())
                            .foregroundStyle(AppTheme.accent)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
            }
            
            // Social Links
            if hasSocialLinks(profile.socialLinks) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Social Links")
                        .font(.headline)
                    
                    VStack(spacing: 10) {
                        if let instagram = profile.socialLinks.instagram {
                            SocialLinkRow(
                                platform: "Instagram",
                                username: instagram.username,
                                followers: instagram.followerCount,
                                verified: instagram.isVerified,
                                icon: "camera.fill",
                                color: .pink
                            )
                        }
                        
                        if let tiktok = profile.socialLinks.tiktok {
                            SocialLinkRow(
                                platform: "TikTok",
                                username: tiktok.username,
                                followers: tiktok.followerCount,
                                verified: tiktok.isVerified,
                                icon: "music.note",
                                color: .black
                            )
                        }
                        
                        if let youtube = profile.socialLinks.youtube {
                            SocialLinkRow(
                                platform: "YouTube",
                                username: youtube.username,
                                followers: youtube.followerCount,
                                verified: youtube.isVerified,
                                icon: "play.rectangle.fill",
                                color: .red
                            )
                        }
                        
                        if let twitch = profile.socialLinks.twitch {
                            SocialLinkRow(
                                platform: "Twitch",
                                username: twitch.username,
                                followers: twitch.followerCount,
                                verified: twitch.isVerified,
                                icon: "tv.fill",
                                color: .purple
                            )
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
            }
            
            // Collaboration Preferences
            if !profile.collaborationPreferences.lookingFor.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Looking to Collaborate On")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(profile.collaborationPreferences.lookingFor, id: \.self) { type in
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                Text(type.rawValue)
                                    .font(.subheadline)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
            }
        }
    }
    
    private func hasSocialLinks(_ links: UserProfile.SocialLinks) -> Bool {
        links.instagram != nil || links.tiktok != nil ||
        links.youtube != nil || links.twitch != nil
    }
}

// MARK: - Social Link Row
private struct SocialLinkRow: View {
    let platform: String
    let username: String
    let followers: Int?
    let verified: Bool
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .foregroundStyle(color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(platform)
                        .font(.subheadline.weight(.medium))
                    
                    if verified {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                }
                
                Text("@\(username)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                if let followers = followers {
                    Text("\(formatFollowerCount(followers)) followers")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
                .font(.caption)
        }
        .padding()
        .background(AppTheme.bg, in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Content Tab View
private struct ContentTabView: View {
    let profile: UserProfile
    
    private let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]
    
    var body: some View {
        VStack(spacing: 16) {
            if profile.mediaURLs.isEmpty {
                EmptyContentState()
            } else {
                LazyVGrid(columns: columns, spacing: 2) {
                    ForEach(Array(profile.mediaURLs.enumerated()), id: \.offset) { index, urlString in
                        if let url = URL(string: urlString) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(height: 120)
                                        .clipped()
                                default:
                                    Rectangle()
                                        .fill(AppTheme.card)
                                        .frame(height: 120)
                                }
                            }
                            .clipShape(Rectangle())
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Empty Content State
private struct EmptyContentState: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            
            Text("No Content Yet")
                .font(.title3.bold())
            
            Text("Start uploading your best work to showcase your creativity!")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

// MARK: - Stats Tab View
private struct StatsTabView: View {
    let profile: UserProfile
    
    var body: some View {
        VStack(spacing: 16) {
            // Growth Chart Placeholder
            VStack(alignment: .leading, spacing: 12) {
                Text("Growth Over Time")
                    .font(.headline)
                
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(AppTheme.card)
                        .frame(height: 200)
                    
                    VStack(spacing: 8) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)
                        Text("Analytics coming soon")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            // Engagement Stats
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    EngagementStatCard(
                        title: "Avg. Views",
                        value: "\(Int.random(in: 1000...10000))",
                        change: "+12%",
                        isPositive: true
                    )
                    
                    EngagementStatCard(
                        title: "Engagement",
                        value: "4.2%",
                        change: "+0.5%",
                        isPositive: true
                    )
                }
                
                HStack(spacing: 12) {
                    EngagementStatCard(
                        title: "Profile Views",
                        value: "\(Int.random(in: 500...5000))",
                        change: "+8%",
                        isPositive: true
                    )
                    
                    EngagementStatCard(
                        title: "Match Rate",
                        value: "67%",
                        change: "-3%",
                        isPositive: false
                    )
                }
            }
        }
    }
}

// MARK: - Engagement Stat Card
private struct EngagementStatCard: View {
    let title: String
    let value: String
    let change: String
    let isPositive: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text(value)
                .font(.title2.bold())
            
            HStack(spacing: 4) {
                Image(systemName: isPositive ? "arrow.up.right" : "arrow.down.right")
                Text(change)
            }
            .font(.caption)
            .foregroundStyle(isPositive ? .green : .red)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Activity Tab View
private struct ActivityTabView: View {
    let profile: UserProfile
    
    var body: some View {
        VStack(spacing: 16) {
            // Recent Activity
            ForEach(0..<5) { index in
                ActivityItemRow(
                    icon: ["heart.fill", "person.fill.badge.plus", "message.fill", "star.fill", "hand.thumbsup.fill"][index],
                    title: ["New match with Sarah J.", "Alex started following you", "New message from Marcus", "Featured on discover page", "Someone liked your profile"][index],
                    time: "\(index + 1)h ago",
                    color: [.pink, .blue, .purple, .yellow, .green][index]
                )
            }
        }
    }
}

// MARK: - Activity Item Row
private struct ActivityItemRow: View {
    let icon: String
    let title: String
    let time: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .foregroundStyle(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                
                Text(time)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Improved Guest Profile View
private struct ImprovedGuestProfileView: View {
    @EnvironmentObject var auth: AuthViewModel
    @State private var animateGradient = false
    @State private var showFeatures = false
    
    var body: some View {
        ZStack {
            AppTheme.gradient.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 40) {
                    Spacer(minLength: 60)
                    
                    // Logo and Title
                    VStack(spacing: 20) {
                        Image(systemName: "person.crop.circle.badge.checkmark")
                            .font(.system(size: 80))
                            .foregroundStyle(.white)
                            .shadow(radius: 10)
                        
                        Text("Welcome to FEATUR")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundStyle(.white)
                        
                        Text("Connect with creators worldwide")
                            .font(.title3)
                            .foregroundStyle(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                    }
                    .opacity(showFeatures ? 1 : 0)
                    .offset(y: showFeatures ? 0 : 20)
                    
                    // Features
                    VStack(spacing: 20) {
                        FeatureRow(
                            icon: "person.2.fill",
                            title: "Find Collaborators",
                            description: "Match with creators who share your vision"
                        )
                        
                        FeatureRow(
                            icon: "chart.line.uptrend.xyaxis",
                            title: "Track Your Growth",
                            description: "See your stats and analytics in one place"
                        )
                        
                        FeatureRow(
                            icon: "sparkles",
                            title: "Get Featured",
                            description: "Showcase your work to millions"
                        )
                    }
                    .padding(.horizontal)
                    .opacity(showFeatures ? 1 : 0)
                    .offset(y: showFeatures ? 0 : 30)
                    
                    // Sign In Button
                    VStack(spacing: 16) {
                        SignInWithAppleButton(.signIn) { request in
                            let req = auth.makeAppleRequest()
                            request.requestedScopes = req.requestedScopes ?? []
                            request.nonce = req.nonce
                        } onCompletion: { result in
                            Task { await auth.handleApple(result: result) }
                        }
                        .signInWithAppleButtonStyle(.white)
                        .frame(height: 50)
                        .cornerRadius(12)
                        
                        if let error = auth.errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                                .padding()
                                .background(.white.opacity(0.2), in: RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    .padding(.horizontal, 32)
                    .padding(.top, 20)
                    
                    Spacer(minLength: 40)
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                showFeatures = true
            }
        }
    }
}

// MARK: - Feature Row
private struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(.white.opacity(0.2))
                    .frame(width: 60, height: 60)
                
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
            }
            
            Spacer()
        }
        .padding()
        .background(.white.opacity(0.15), in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Loading Profile View
private struct LoadingProfileView: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            AppTheme.bg.ignoresSafeArea()
            
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .stroke(AppTheme.accent.opacity(0.3), lineWidth: 4)
                        .frame(width: 60, height: 60)
                    
                    Circle()
                        .trim(from: 0, to: 0.7)
                        .stroke(AppTheme.accent, lineWidth: 4)
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(isAnimating ? 360 : 0))
                }
                
                Text("Loading profile...")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                isAnimating = true
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
                .font(.title3)
                .foregroundStyle(.green)
            
            Text(message)
                .font(.subheadline.bold())
                .foregroundStyle(.primary)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
        .padding(.top, 60)
        .padding(.horizontal)
    }
}

// MARK: - Profile Edit Sheet (Placeholder)
private struct ProfileEditSheet: View {
    let profile: UserProfile
    @ObservedObject var viewModel: ProfileViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Info") {
                    Text("Edit functionality coming soon")
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Settings Sheet (Placeholder)
private struct SettingsSheet: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section("Account") {
                    NavigationLink("Privacy") { Text("Privacy Settings") }
                    NavigationLink("Notifications") { Text("Notification Settings") }
                }
                
                Section("Support") {
                    NavigationLink("Help Center") { Text("Help") }
                    NavigationLink("Report a Problem") { Text("Report") }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - QR Code Sheet (Placeholder)
private struct QRCodeSheet: View {
    let profile: UserProfile
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Spacer()
                
                // QR Code placeholder
                RoundedRectangle(cornerRadius: 20)
                    .fill(AppTheme.card)
                    .frame(width: 250, height: 250)
                    .overlay(
                        VStack(spacing: 12) {
                            Image(systemName: "qrcode")
                                .font(.system(size: 80))
                                .foregroundStyle(AppTheme.accent)
                            Text("@\(profile.displayName)")
                                .font(.headline)
                        }
                    )
                
                Text("Scan to connect with me!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Spacer()
            }
            .padding()
            .background(AppTheme.bg)
            .navigationTitle("My QR Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Detailed Stats Sheet (Placeholder)
private struct DetailedStatsSheet: View {
    let profile: UserProfile
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Detailed analytics coming soon!")
                        .font(.headline)
                        .padding()
                }
                .padding()
            }
            .background(AppTheme.bg)
            .navigationTitle("Detailed Stats")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Achievements Sheet (Placeholder)
private struct AchievementsSheet: View {
    let profile: UserProfile
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Text("All achievements coming soon!")
                        .font(.headline)
                        .padding()
                }
                .padding()
            }
            .background(AppTheme.bg)
            .navigationTitle("Achievements")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
