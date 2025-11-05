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
    
    @State private var animateGradient = false
    @State private var showingBadgeAnimation = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Animated Gradient Background with Parallax
            AnimatedGradientBackground(animate: animateGradient)
                .frame(height: 300 + max(0, scrollOffset))
                .clipped()
                .onAppear {
                    withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                        animateGradient = true
                    }
                }
            
            // Decorative Elements
            GeometryReader { geo in
                ZStack {
                    // Floating circles
                    Circle()
                        .fill(.white.opacity(0.1))
                        .frame(width: 100, height: 100)
                        .offset(x: -20, y: 40)
                        .blur(radius: 20)
                    
                    Circle()
                        .fill(.white.opacity(0.08))
                        .frame(width: 150, height: 150)
                        .offset(x: geo.size.width - 80, y: 100)
                        .blur(radius: 25)
                }
            }
            
            // Content
            VStack(spacing: 16) {
                // Profile Image with Premium Ring
                ZStack(alignment: .bottomTrailing) {
                    // Outer glow ring
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.white.opacity(0.3), .white.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 152, height: 152)
                        .blur(radius: 8)
                    
                    // Profile Image
                    Group {
                        if let imageURL = profile.profileImageURL, let url = URL(string: imageURL) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 140, height: 140)
                                        .clipShape(Circle())
                                case .failure(_):
                                    InitialsAvatar(name: profile.displayName, size: 140)
                                default:
                                    ZStack {
                                        Circle()
                                            .fill(.white.opacity(0.2))
                                            .frame(width: 140, height: 140)
                                        ProgressView()
                                            .tint(.white)
                                    }
                                }
                            }
                        } else {
                            InitialsAvatar(name: profile.displayName, size: 140)
                        }
                    }
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.8), .white.opacity(0.4)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 4
                            )
                    )
                    
                    // Verification Badge with Animation
                    if profile.isVerified {
                        ZStack {
                            Circle()
                                .fill(.white)
                                .frame(width: 40, height: 40)
                                .shadow(color: .blue.opacity(0.3), radius: 8, y: 2)
                            
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(.blue)
                                .scaleEffect(showingBadgeAnimation ? 1.1 : 1.0)
                                .onAppear {
                                    withAnimation(.spring(response: 0.6, dampingFraction: 0.5).repeatForever()) {
                                        showingBadgeAnimation = true
                                    }
                                }
                        }
                        .offset(x: -4, y: -4)
                    }
                    
                    // Animated Online Indicator
                    if profile.isOnline {
                        OnlinePulseIndicator()
                            .offset(x: 4, y: 4)
                    }
                }
                .shadow(color: .black.opacity(0.4), radius: 25, y: 15)
                
                // Name & Info with Social Proof
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Text(profile.displayName)
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
                        
                        if profile.isVerified {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(.blue)
                                .font(.title2)
                                .shadow(color: .blue.opacity(0.5), radius: 4)
                        }
                    }
                    
                    // Enhanced Info Row
                    HStack(spacing: 16) {
                        if let age = profile.age {
                            InfoPill(icon: "calendar", text: "\(age) years")
                        }
                        
                        if let location = profile.location, let city = location.city {
                            InfoPill(icon: "mappin.circle", text: city)
                        }
                        
                        // Follower Badge
                        if profile.followerCount >= 1000 {
                            InfoPill(
                                icon: "person.3.fill",
                                text: formatNumber(profile.followerCount),
                                color: .yellow
                            )
                        }
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.95))
                }
                
                // Enhanced Bio with Read More
                if let bio = profile.bio, !bio.isEmpty {
                    Text(bio)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.95))
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .padding(.horizontal, 32)
                        .shadow(color: .black.opacity(0.2), radius: 2)
                }
                
                // Premium Quick Actions with Icons
                HStack(spacing: 12) {
                    PremiumActionButton(
                        icon: "pencil.circle.fill",
                        label: "Edit",
                        gradient: [.blue, .cyan],
                        action: onEdit
                    )
                    PremiumActionButton(
                        icon: "qrcode",
                        label: "QR",
                        gradient: [.purple, .pink],
                        action: onQR
                    )
                    PremiumActionButton(
                        icon: "square.and.arrow.up.circle.fill",
                        label: "Share",
                        gradient: [.green, .mint],
                        action: onShare
                    )
                }
                .padding(.top, 8)
            }
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Animated Gradient Background
private struct AnimatedGradientBackground: View {
    let animate: Bool
    
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.4, green: 0.3, blue: 0.9),
                Color(red: 0.6, green: 0.4, blue: 1.0),
                Color(red: 0.5, green: 0.35, blue: 0.95)
            ],
            startPoint: animate ? .topLeading : .bottomLeading,
            endPoint: animate ? .bottomTrailing : .topTrailing
        )
    }
}

// MARK: - Online Pulse Indicator
private struct OnlinePulseIndicator: View {
    @State private var isPulsing = false
    
    var body: some View {
        ZStack {
            // Pulse ring
            Circle()
                .fill(.green.opacity(0.3))
                .frame(width: 32, height: 32)
                .scaleEffect(isPulsing ? 1.3 : 1.0)
                .opacity(isPulsing ? 0 : 1)
            
            // Solid indicator
            Circle()
                .fill(.green)
                .frame(width: 24, height: 24)
                .overlay(Circle().stroke(.white, lineWidth: 3))
                .shadow(color: .green.opacity(0.5), radius: 4)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.5).repeatForever(autoreverses: false)) {
                isPulsing = true
            }
        }
    }
}

// MARK: - Info Pill
private struct InfoPill: View {
    let icon: String
    let text: String
    var color: Color = .white
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
            Text(text)
                .font(.caption.weight(.medium))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.white.opacity(0.25), in: Capsule())
        .foregroundStyle(color)
        .shadow(color: .black.opacity(0.2), radius: 4)
    }
}

// MARK: - Premium Action Button
private struct PremiumActionButton: View {
    let icon: String
    let label: String
    let gradient: [Color]
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            Haptics.impact(.medium)
            action()
        }) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                Text(label)
                    .font(.caption.weight(.semibold))
            }
            .frame(width: 85)
            .padding(.vertical, 12)
            .background(
                LinearGradient(
                    colors: gradient.map { $0.opacity(0.9) },
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 16)
            )
            .foregroundStyle(.white)
            .shadow(color: gradient[0].opacity(0.4), radius: 8, y: 4)
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PressableButtonStyle(isPressed: $isPressed))
    }
}

// MARK: - Pressable Button Style
private struct PressableButtonStyle: ButtonStyle {
    @Binding var isPressed: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { _, newValue in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPressed = newValue
                }
            }
    }
}

// MARK: - Stats Grid
private struct ProfileStatsGrid: View {
    let profile: UserProfile
    let onTapStats: () -> Void
    
    @State private var showStats = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Primary Stats Row
            HStack(spacing: 12) {
                PremiumStatCard(
                    icon: "person.3.fill",
                    value: formatNumber(profile.followerCount),
                    label: "Followers",
                    gradient: [Color(red: 0.2, green: 0.5, blue: 1.0), Color(red: 0.4, green: 0.7, blue: 1.0)],
                    delay: 0.0
                )
                .opacity(showStats ? 1 : 0)
                .offset(y: showStats ? 0 : 20)
                
                PremiumStatCard(
                    icon: "heart.fill",
                    value: "\(Int.random(in: 1000...10000))",
                    label: "Likes",
                    gradient: [Color(red: 1.0, green: 0.3, blue: 0.5), Color(red: 1.0, green: 0.5, blue: 0.7)],
                    delay: 0.1
                )
                .opacity(showStats ? 1 : 0)
                .offset(y: showStats ? 0 : 20)
            }
            
            // Secondary Stats Row
            HStack(spacing: 12) {
                PremiumStatCard(
                    icon: "eye.fill",
                    value: formatNumber(Int.random(in: 10000...500000)),
                    label: "Views",
                    gradient: [Color(red: 0.6, green: 0.3, blue: 1.0), Color(red: 0.8, green: 0.5, blue: 1.0)],
                    delay: 0.2
                )
                .opacity(showStats ? 1 : 0)
                .offset(y: showStats ? 0 : 20)
                
                PremiumStatCard(
                    icon: "arrow.up.right",
                    value: "+\(Int.random(in: 10...50))%",
                    label: "Growth",
                    gradient: [Color(red: 0.2, green: 0.8, blue: 0.5), Color(red: 0.4, green: 1.0, blue: 0.7)],
                    delay: 0.3
                )
                .opacity(showStats ? 1 : 0)
                .offset(y: showStats ? 0 : 20)
            }
            
            // View Analytics Button
            Button(action: {
                Haptics.impact(.medium)
                onTapStats()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.subheadline.weight(.semibold))
                    Text("View Detailed Analytics")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                }
                .foregroundStyle(
                    LinearGradient(
                        colors: [AppTheme.accent, AppTheme.accent.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .padding()
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(AppTheme.card)
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [AppTheme.accent.opacity(0.1), .clear],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [AppTheme.accent.opacity(0.3), .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: 1
                        )
                )
            }
            .opacity(showStats ? 1 : 0)
            .offset(y: showStats ? 0 : 20)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                showStats = true
            }
        }
    }
}

// MARK: - Premium Stat Card
private struct PremiumStatCard: View {
    let icon: String
    let value: String
    let label: String
    let gradient: [Color]
    let delay: Double
    
    @State private var isAnimating = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Icon with gradient background
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: gradient.map { $0.opacity(0.2) },
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                
                Text(label)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(AppTheme.card)
                    .shadow(color: gradient[0].opacity(0.15), radius: 12, y: 6)
                
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [gradient[0].opacity(0.05), .clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        colors: [gradient[0].opacity(0.2), .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .scaleEffect(isAnimating ? 1.0 : 0.9)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(delay)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Achievement Badges
private struct AchievementBadgeRow: View {
    let profile: UserProfile
    
    @State private var showBadges = false
    
    var achievements: [Achievement] {
        var list: [Achievement] = []
        if profile.isVerified {
            list.append(.init(
                icon: "checkmark.seal.fill",
                title: "Verified Creator",
                color: .blue,
                gradient: [Color(red: 0.2, green: 0.5, blue: 1.0), Color(red: 0.4, green: 0.7, blue: 1.0)]
            ))
        }
        if profile.followerCount >= 100000 {
            list.append(.init(
                icon: "crown.fill",
                title: "Top Creator",
                color: .yellow,
                gradient: [Color(red: 1.0, green: 0.8, blue: 0.0), Color(red: 1.0, green: 0.9, blue: 0.2)]
            ))
        }
        if profile.followerCount >= 10000 {
            list.append(.init(
                icon: "star.fill",
                title: "Rising Star",
                color: .orange,
                gradient: [Color(red: 1.0, green: 0.5, blue: 0.0), Color(red: 1.0, green: 0.7, blue: 0.2)]
            ))
        }
        if profile.followerCount >= 1000 {
            list.append(.init(
                icon: "flame.fill",
                title: "Popular",
                color: .red,
                gradient: [Color(red: 1.0, green: 0.2, blue: 0.3), Color(red: 1.0, green: 0.4, blue: 0.5)]
            ))
        }
        // New achievements
        if !profile.contentStyles.isEmpty && profile.contentStyles.count >= 3 {
            list.append(.init(
                icon: "sparkles",
                title: "Multi-Talented",
                color: .purple,
                gradient: [Color(red: 0.6, green: 0.3, blue: 1.0), Color(red: 0.8, green: 0.5, blue: 1.0)]
            ))
        }
        if profile.socialLinks.instagram != nil && profile.socialLinks.tiktok != nil {
            list.append(.init(
                icon: "link.circle.fill",
                title: "Connected",
                color: .cyan,
                gradient: [Color(red: 0.2, green: 0.8, blue: 1.0), Color(red: 0.4, green: 0.9, blue: 1.0)]
            ))
        }
        return list
    }
    
    var body: some View {
        if !achievements.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "trophy.fill")
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.yellow, .orange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Text("Achievements")
                        .font(.headline)
                    
                    Spacer()
                    
                    Text("\(achievements.count)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(AppTheme.accent, in: Capsule())
                }
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(achievements.enumerated()), id: \.offset) { index, achievement in
                            PremiumAchievementBadge(achievement: achievement)
                                .opacity(showBadges ? 1 : 0)
                                .scaleEffect(showBadges ? 1 : 0.8)
                                .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(Double(index) * 0.1), value: showBadges)
                        }
                    }
                }
            }
            .onAppear {
                withAnimation {
                    showBadges = true
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
    let gradient: [Color]
}

// MARK: - Premium Achievement Badge
private struct PremiumAchievementBadge: View {
    let achievement: Achievement
    
    @State private var isGlowing = false
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Glow effect
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [achievement.color.opacity(0.3), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 30
                        )
                    )
                    .frame(width: 60, height: 60)
                    .scaleEffect(isGlowing ? 1.2 : 1.0)
                    .opacity(isGlowing ? 0.5 : 0.8)
                
                // Badge background
                Circle()
                    .fill(
                        LinearGradient(
                            colors: achievement.gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 52, height: 52)
                    .shadow(color: achievement.color.opacity(0.4), radius: 8, y: 4)
                
                // Icon
                Image(systemName: achievement.icon)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.3), radius: 2)
            }
            
            Text(achievement.title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .frame(width: 90)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.card)
                .shadow(color: achievement.color.opacity(0.15), radius: 8, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [achievement.color.opacity(0.3), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                isGlowing = true
            }
        }
    }
}

// MARK: - Profile Completion
private struct ProfileCompletionCard: View {
    let profile: UserProfile
    
    @State private var animatedProgress: CGFloat = 0
    
    var completionData: (score: Double, total: Double, missing: [String]) {
        var score: Double = 0
        let total: Double = 7
        var missing: [String] = []
        
        if profile.profileImageURL != nil {
            score += 1
        } else {
            missing.append("Profile photo")
        }
        
        if profile.bio != nil && !profile.bio!.isEmpty {
            score += 1
        } else {
            missing.append("Bio")
        }
        
        if !profile.mediaURLs.isEmpty {
            score += 1
        } else {
            missing.append("Content media")
        }
        
        if profile.location != nil {
            score += 1
        } else {
            missing.append("Location")
        }
        
        if !profile.contentStyles.isEmpty {
            score += 1
        } else {
            missing.append("Content styles")
        }
        
        if profile.socialLinks.instagram != nil || profile.socialLinks.tiktok != nil {
            score += 1
        } else {
            missing.append("Social links")
        }
        
        if !profile.interests.isEmpty {
            score += 1
        } else {
            missing.append("Interests")
        }
        
        return (score, total, missing)
    }
    
    var completion: Double {
        completionData.score / completionData.total
    }
    
    var completionColor: Color {
        switch completion {
        case 0..<0.4: return .red
        case 0.4..<0.7: return .orange
        case 0.7..<0.9: return .blue
        default: return .green
        }
    }
    
    var body: some View {
        if completion < 1.0 {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Profile Strength")
                            .font(.headline)
                        
                        Text(completionMessage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    // Circular Progress Indicator
                    ZStack {
                        Circle()
                            .stroke(completionColor.opacity(0.2), lineWidth: 6)
                            .frame(width: 60, height: 60)
                        
                        Circle()
                            .trim(from: 0, to: animatedProgress)
                            .stroke(
                                LinearGradient(
                                    colors: [completionColor, completionColor.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                style: StrokeStyle(lineWidth: 6, lineCap: .round)
                            )
                            .frame(width: 60, height: 60)
                            .rotationEffect(.degrees(-90))
                            .animation(.spring(response: 1, dampingFraction: 0.7), value: animatedProgress)
                        
                        VStack(spacing: 0) {
                            Text("\(Int(completion * 100))")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                            Text("%")
                                .font(.caption2.weight(.semibold))
                        }
                        .foregroundStyle(completionColor)
                    }
                }
                
                // Progress Bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.15))
                            .frame(height: 10)
                        
                        // Progress with gradient
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: [completionColor, completionColor.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * animatedProgress, height: 10)
                            .shadow(color: completionColor.opacity(0.4), radius: 4, y: 2)
                        
                        // Milestone markers
                        HStack(spacing: 0) {
                            ForEach([0.25, 0.5, 0.75, 1.0], id: \.self) { milestone in
                                Circle()
                                    .fill(animatedProgress >= CGFloat(milestone) ? completionColor : Color.gray.opacity(0.3))
                                    .frame(width: 12, height: 12)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: 2)
                                    )
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .padding(.horizontal, -6)
                    }
                }
                .frame(height: 10)
                
                // Missing Items
                if !completionData.missing.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Complete your profile:")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        
                        FlowLayout(spacing: 8) {
                            ForEach(completionData.missing.prefix(3), id: \.self) { item in
                                HStack(spacing: 4) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.caption2)
                                    Text(item)
                                        .font(.caption)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(completionColor.opacity(0.1), in: Capsule())
                                .foregroundStyle(completionColor)
                            }
                        }
                    }
                }
            }
            .padding()
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(AppTheme.card)
                    
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [completionColor.opacity(0.05), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            colors: [completionColor.opacity(0.2), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            )
            .onAppear {
                withAnimation(.easeOut(duration: 1.2).delay(0.3)) {
                    animatedProgress = CGFloat(completion)
                }
            }
        }
    }
    
    private var completionMessage: String {
        switch completion {
        case 0..<0.4: return "Let's get started!"
        case 0.4..<0.7: return "You're making progress!"
        case 0.7..<0.9: return "Almost there!"
        default: return "Looking good!"
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
