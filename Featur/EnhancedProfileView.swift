import SwiftUI
import FirebaseAuth
import PhotosUI
import AuthenticationServices

struct EnhancedProfileView: View {
    @EnvironmentObject var auth: AuthViewModel
    @StateObject private var viewModel = ProfileViewModel()
    @State private var selectedTab: ProfileTab = .grid
    @State private var showingEditSheet = false
    @State private var showingSettingsSheet = false
    @State private var showingQRCode = false
    @State private var showingShareSheet = false
    @State private var scrollOffset: CGFloat = 0
    
    enum ProfileTab: String, CaseIterable {
        case grid = "Grid"
        case reels = "Reels"
        case tagged = "Tagged"
        case collections = "Saved"
        
        var icon: String {
            switch self {
            case .grid: return "square.grid.3x3.fill"
            case .reels: return "play.rectangle.fill"
            case .tagged: return "person.crop.rectangle.fill"
            case .collections: return "bookmark.fill"
            }
        }
    }
    
    var body: some View {
        Group {
            if auth.user == nil {
                GuestProfileView()
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
                    scrollOffset: $scrollOffset
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
    }
}

// MARK: - Guest Profile View (Enhanced)
private struct GuestProfileView: View {
    @EnvironmentObject var auth: AuthViewModel
    @State private var animateGradient = false
    @State private var showFeatures = false
    
    var body: some View {
        ZStack {
            // Animated gradient background
            AnimatedGradientBackground(animate: animateGradient)
            
            ScrollView {
                VStack(spacing: 40) {
                    Spacer(minLength: 60)
                    
                    // Hero section
                    VStack(spacing: 24) {
                        // Animated logo/icon
                        ZStack {
                            Circle()
                                .fill(.white.opacity(0.15))
                                .frame(width: 140, height: 140)
                                .blur(radius: 20)
                            
                            Circle()
                                .fill(.white.opacity(0.1))
                                .frame(width: 120, height: 120)
                            
                            Image(systemName: "person.crop.circle.badge.plus")
                                .font(.system(size: 60))
                                .foregroundStyle(.white)
                                .shadow(color: .black.opacity(0.2), radius: 10)
                        }
                        .scaleEffect(showFeatures ? 1 : 0.8)
                        .opacity(showFeatures ? 1 : 0)
                        
                        VStack(spacing: 16) {
                            Text("Join FEATUR")
                                .font(.system(size: 40, weight: .heavy, design: .rounded))
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.center)
                                .shadow(color: .black.opacity(0.3), radius: 5)
                            
                            Text("The Ultimate Creator Network")
                                .font(.title3.weight(.medium))
                                .foregroundStyle(.white.opacity(0.9))
                                .multilineTextAlignment(.center)
                        }
                        .opacity(showFeatures ? 1 : 0)
                        .offset(y: showFeatures ? 0 : 20)
                    }
                    
                    // Feature cards
                    VStack(spacing: 20) {
                        ForEach(Array(features.enumerated()), id: \.offset) { index, feature in
                            FeatureCard(
                                icon: feature.icon,
                                title: feature.title,
                                description: feature.description,
                                color: feature.color
                            )
                            .opacity(showFeatures ? 1 : 0)
                            .offset(x: showFeatures ? 0 : -50)
                            .animation(
                                .spring(response: 0.6, dampingFraction: 0.8)
                                    .delay(Double(index) * 0.1),
                                value: showFeatures
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    // Stats preview
                    StatsPreviewCard()
                        .padding(.horizontal)
                        .opacity(showFeatures ? 1 : 0)
                        .offset(y: showFeatures ? 0 : 30)
                    
                    Spacer(minLength: 20)
                    
                    // Sign in section
                    VStack(spacing: 20) {
                        SignInWithAppleButton(.signIn) { request in
                            let req = auth.makeAppleRequest()
                            request.requestedScopes = req.requestedScopes ?? []
                            request.nonce = req.nonce
                        } onCompletion: { result in
                            Task { await auth.handleApple(result: result) }
                        }
                        .signInWithAppleButtonStyle(.white)
                        .frame(height: 56)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.3), radius: 15, y: 8)
                        
                        Text("By signing in, you agree to our Terms & Privacy Policy")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                        
                        if let errorMsg = auth.errorMessage, !errorMsg.isEmpty {
                            Text(errorMsg)
                                .font(.caption)
                                .foregroundStyle(.red)
                                .padding()
                                .background(.white.opacity(0.2), in: RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                animateGradient = true
            }
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.2)) {
                showFeatures = true
            }
        }
    }
    
    private let features = [
        (icon: "sparkles", title: "Get Discovered", description: "Be featured to millions of creators", color: Color.yellow),
        (icon: "person.2.fill", title: "Perfect Matches", description: "AI-powered collaboration matching", color: Color.blue),
        (icon: "chart.line.uptrend.xyaxis", title: "Track Growth", description: "Analytics and insights dashboard", color: Color.green),
        (icon: "bolt.fill", title: "Instant Connect", description: "Real-time messaging and networking", color: Color.orange)
    ]
}

// MARK: - Animated Gradient Background
private struct AnimatedGradientBackground: View {
    let animate: Bool
    
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.4, green: 0.3, blue: 0.9),
                Color(red: 0.6, green: 0.4, blue: 0.95),
                Color(red: 0.5, green: 0.35, blue: 0.85)
            ],
            startPoint: animate ? .topLeading : .bottomTrailing,
            endPoint: animate ? .bottomTrailing : .topLeading
        )
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: animate)
    }
}

// MARK: - Feature Card
private struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 56, height: 56)
                
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
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
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.white.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Stats Preview Card
private struct StatsPreviewCard: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("Join 100K+ Creators")
                .font(.title3.bold())
                .foregroundStyle(.white)
            
            HStack(spacing: 20) {
                StatItem(value: "10M+", label: "Connections")
                StatItem(value: "500K+", label: "Collabs")
                StatItem(value: "50K+", label: "Featured")
            }
        }
        .padding(24)
        .background(.white.opacity(0.15), in: RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(.white.opacity(0.2), lineWidth: 1)
        )
    }
}

private struct StatItem: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(.white)
            Text(label)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Loading Profile View
private struct LoadingProfileView: View {
    @State private var isRotating = false
    
    var body: some View {
        ZStack {
            AppTheme.bg.ignoresSafeArea()
            
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .stroke(AppTheme.accent.opacity(0.3), lineWidth: 4)
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .trim(from: 0, to: 0.7)
                        .stroke(AppTheme.accent, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(isRotating ? 360 : 0))
                        .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isRotating)
                }
                
                VStack(spacing: 8) {
                    Text("Loading Profile")
                        .font(.headline)
                    Text("Getting everything ready...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .onAppear {
            isRotating = true
        }
    }
}

// MARK: - Main Profile View
private struct MainProfileView: View {
    let profile: UserProfile
    @ObservedObject var viewModel: ProfileViewModel
    @Binding var selectedTab: EnhancedProfileView.ProfileTab
    @Binding var showingEditSheet: Bool
    @Binding var showingSettingsSheet: Bool
    @Binding var showingQRCode: Bool
    @Binding var showingShareSheet: Bool
    @Binding var scrollOffset: CGFloat
    @EnvironmentObject var auth: AuthViewModel
    
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showingImagePicker = false
    @State private var headerHeight: CGFloat = 0
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Premium animated header
                PremiumProfileHeader(
                    profile: profile,
                    scrollOffset: scrollOffset,
                    onEditPhoto: { showingImagePicker = true },
                    onQRCode: { showingQRCode = true },
                    onShare: { showingShareSheet = true },
                    onSettings: { showingSettingsSheet = true }
                )
                .background(
                    GeometryReader { geo in
                        Color.clear.preference(
                            key: ScrollOffsetPreferenceKey.self,
                            value: geo.frame(in: .named("scroll")).minY
                        )
                    }
                )
                
                VStack(spacing: 24) {
                    // Identity section
                    ProfileIdentitySection(profile: profile)
                        .padding(.top, 60)
                    
                    // Enhanced stats with animations
                    EnhancedStatsGrid(profile: profile)
                    
                    // Action buttons
                    ProfileActionButtons(
                        onEdit: { showingEditSheet = true },
                        onShare: { showingShareSheet = true },
                        onInsights: { /* Analytics */ }
                    )
                    
                    // Highlights carousel
                    HighlightsCarousel()
                    
                    // Achievement badges
                    AchievementBadgesGrid(profile: profile)
                    
                    // About section
                    ExpandableAboutSection(profile: profile)
                    
                    // Content styles with icons
                    ContentStylesGrid(styles: profile.contentStyles)
                    
                    // Social proof
                    SocialProofSection(profile: profile)
                    
                    // Collaboration preferences
                    CollaborationCard(preferences: profile.collaborationPreferences)
                    
                    // Recent activity
                    RecentActivityFeed()
                    
                    Divider()
                        .padding(.vertical, 8)
                    
                    // Tab selector
                    ModernTabSelector(selectedTab: $selectedTab)
                    
                    // Content grid
                    ContentTabView(selectedTab: selectedTab, profile: profile)
                }
                .padding(.horizontal)
            }
        }
        .coordinateSpace(name: "scroll")
        .background(AppTheme.bg)
        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
            scrollOffset = value
        }
        .sheet(isPresented: $showingEditSheet) {
            EnhancedEditProfileSheet(profile: profile, viewModel: viewModel)
        }
        .sheet(isPresented: $showingSettingsSheet) {
            EnhancedSettingsSheet(viewModel: viewModel, profile: profile)
        }
        .sheet(isPresented: $showingQRCode) {
            QRCodeSheet(profile: profile)
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareProfileSheet(profile: profile)
        }
        .photosPicker(
            isPresented: $showingImagePicker,
            selection: $selectedPhotoItem,
            matching: .images
        )
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let uid = profile.uid as String? {
                    await viewModel.updateProfilePhoto(userId: uid, imageData: data)
                }
            }
        }
    }
}

// MARK: - Scroll Offset Preference Key
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Premium Profile Header
private struct PremiumProfileHeader: View {
    let profile: UserProfile
    let scrollOffset: CGFloat
    let onEditPhoto: () -> Void
    let onQRCode: () -> Void
    let onShare: () -> Void
    let onSettings: () -> Void
    
    @State private var animateBackground = false
    
    private var parallaxOffset: CGFloat {
        let offset = max(scrollOffset, 0)
        return -offset * 0.5
    }
    
    private var opacity: Double {
        let progress = min(max(scrollOffset / 100, 0), 1)
        return Double(1 - progress)
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            // Parallax cover image
            GeometryReader { geo in
                if let coverURL = profile.mediaURLs.first, let url = URL(string: coverURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: geo.size.width, height: geo.size.height + max(scrollOffset, 0))
                                .clipped()
                                .offset(y: parallaxOffset)
                        default:
                            AppTheme.gradient
                                .offset(y: parallaxOffset)
                        }
                    }
                } else {
                    AppTheme.gradient
                        .offset(y: parallaxOffset)
                }
            }
            .frame(height: 220)
            .overlay(
                LinearGradient(
                    colors: [.clear, .black.opacity(0.6)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            
            VStack(spacing: 0) {
                // Top toolbar
                HStack {
                    Spacer()
                    
                    HStack(spacing: 12) {
                        ToolbarButton(icon: "qrcode", action: onQRCode)
                        ToolbarButton(icon: "square.and.arrow.up", action: onShare)
                        ToolbarButton(icon: "gearshape.fill", action: onSettings)
                    }
                }
                .padding()
                .opacity(opacity)
                
                Spacer()
                
                // Profile image with glow effect
                ZStack(alignment: .bottomTrailing) {
                    // Glow effect
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [AppTheme.accent.opacity(0.6), .clear],
                                center: .center,
                                startRadius: 50,
                                endRadius: 80
                            )
                        )
                        .frame(width: 140, height: 140)
                        .blur(radius: 20)
                    
                    // Profile image
                    if let profileImageURL = profile.profileImageURL,
                       let url = URL(string: profileImageURL) {
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
                                            .stroke(
                                                LinearGradient(
                                                    colors: [.white, .white.opacity(0.5)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 4
                                            )
                                    )
                                    .shadow(color: .black.opacity(0.3), radius: 15, y: 5)
                            default:
                                ProfilePlaceholderImage(name: profile.displayName)
                            }
                        }
                    } else {
                        ProfilePlaceholderImage(name: profile.displayName)
                    }
                    
                    // Edit button with pulse animation
                    Button(action: onEditPhoto) {
                        ZStack {
                            Circle()
                                .fill(AppTheme.accent)
                                .frame(width: 36, height: 36)
                            
                            Image(systemName: "camera.fill")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                        }
                        .shadow(color: AppTheme.accent.opacity(0.4), radius: 8, y: 4)
                    }
                    .offset(x: 4, y: 4)
                }
                .padding(.bottom, -60)
            }
            .frame(height: 220)
        }
        .frame(height: 220)
        .padding(.bottom, 60)
    }
}

// MARK: - Toolbar Button
private struct ToolbarButton: View {
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(.ultraThinMaterial, in: Circle())
                .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
        }
    }
}

// MARK: - Profile Placeholder Image
private struct ProfilePlaceholderImage: View {
    let name: String
    
    var body: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [AppTheme.accent, AppTheme.accent.opacity(0.7)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 120, height: 120)
            .overlay(
                Text(name.prefix(2).uppercased())
                    .font(.system(size: 42, weight: .bold))
                    .foregroundStyle(.white)
            )
            .overlay(
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [.white, .white.opacity(0.5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 4
                    )
            )
            .shadow(color: .black.opacity(0.3), radius: 15, y: 5)
    }
}

// MARK: - Profile Identity Section
private struct ProfileIdentitySection: View {
    let profile: UserProfile
    @State private var showAnimation = false
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Text(profile.displayName)
                    .font(.system(size: 28, weight: .bold))
                
                if profile.isVerified {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.title2)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(showAnimation ? 1 : 0.8)
                        .animation(.spring(response: 0.3).delay(0.2), value: showAnimation)
                }
                
                // Pro badge
                Text("PRO")
                    .font(.caption.weight(.black))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        LinearGradient(
                            colors: [.orange, .pink, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: Capsule()
                    )
                    .shadow(color: .pink.opacity(0.4), radius: 8, y: 4)
                    .scaleEffect(showAnimation ? 1 : 0.8)
                    .animation(.spring(response: 0.3).delay(0.3), value: showAnimation)
            }
            
            if let age = profile.age {
                HStack(spacing: 6) {
                    Image(systemName: "birthday.cake.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(age) • Content Creator")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
            if let bio = profile.bio {
                Text(bio)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.top, 4)
            }
            
            // Location
            if let location = profile.location {
                HStack(spacing: 6) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.caption)
                        .foregroundStyle(AppTheme.accent)
                    if let city = location.city, let state = location.state {
                        Text("\(city), \(state)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .onAppear {
            showAnimation = true
        }
    }
}

// MARK: - Enhanced Stats Grid
private struct EnhancedStatsGrid: View {
    let profile: UserProfile
    @State private var animateStats = false
    
    var body: some View {
        HStack(spacing: 0) {
            StatCard(
                value: formatFollowerCount(profile.followerCount),
                label: "Followers",
                icon: "person.2.fill",
                color: .blue
            )
            .opacity(animateStats ? 1 : 0)
            .offset(y: animateStats ? 0 : 20)
            .animation(.spring(response: 0.6).delay(0.1), value: animateStats)
            
            Divider()
                .frame(height: 60)
            
            StatCard(
                value: "\(Int.random(in: 50...150))",
                label: "Collabs",
                icon: "hands.sparkles.fill",
                color: .purple
            )
            .opacity(animateStats ? 1 : 0)
            .offset(y: animateStats ? 0 : 20)
            .animation(.spring(response: 0.6).delay(0.2), value: animateStats)
            
            Divider()
                .frame(height: 60)
            
            StatCard(
                value: "\(Int.random(in: 80...99))%",
                label: "Match Rate",
                icon: "chart.line.uptrend.xyaxis.circle.fill",
                color: .green
            )
            .opacity(animateStats ? 1 : 0)
            .offset(y: animateStats ? 0 : 20)
            .animation(.spring(response: 0.6).delay(0.3), value: animateStats)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppTheme.card)
                .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
        )
        .onAppear {
            animateStats = true
        }
    }
}

private struct StatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(.primary)
            
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Profile Action Buttons
private struct ProfileActionButtons: View {
    let onEdit: () -> Void
    let onShare: () -> Void
    let onInsights: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: onEdit) {
                HStack(spacing: 8) {
                    Image(systemName: "pencil")
                    Text("Edit Profile")
                        .fontWeight(.semibold)
                }
                .font(.subheadline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(AppTheme.accent, in: RoundedRectangle(cornerRadius: 12))
                .shadow(color: AppTheme.accent.opacity(0.3), radius: 8, y: 4)
            }
            
            Button(action: onShare) {
                Image(systemName: "square.and.arrow.up")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 50, height: 50)
                    .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 12))
            }
            
            Button(action: onInsights) {
                Image(systemName: "chart.bar.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 50, height: 50)
                    .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}

// MARK: - Highlights Carousel
private struct HighlightsCarousel: View {
    let highlights = [
        ("Travel", "airplane.circle.fill", Color.blue),
        ("Food", "fork.knife.circle.fill", Color.orange),
        ("Fitness", "figure.run.circle.fill", Color.green),
        ("Tech", "laptopcomputer.circle.fill", Color.purple),
        ("Music", "music.note.circle.fill", Color.pink)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Highlights")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(highlights, id: \.0) { highlight in
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [highlight.2, highlight.2.opacity(0.6)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 72, height: 72)
                                
                                Image(systemName: highlight.1)
                                    .font(.title2)
                                    .foregroundStyle(.white)
                            }
                            .overlay(
                                Circle()
                                    .stroke(.white, lineWidth: 3)
                            )
                            .shadow(color: highlight.2.opacity(0.3), radius: 8, y: 4)
                            
                            Text(highlight.0)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.primary)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Achievement Badges Grid
private struct AchievementBadgesGrid: View {
    let profile: UserProfile
    
    let achievements = [
        ("🏆", "Top Creator", "10K+ followers"),
        ("⚡", "Fast Responder", "< 1 hour"),
        ("🎯", "Perfect Match", "95% rate"),
        ("🔥", "Hot Streak", "30 days active")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Achievements")
                .font(.headline)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(achievements, id: \.0) { achievement in
                    AchievementBadge(
                        emoji: achievement.0,
                        title: achievement.1,
                        subtitle: achievement.2
                    )
                }
            }
        }
        .padding()
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct AchievementBadge: View {
    let emoji: String
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(emoji)
                .font(.title)
            
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
            
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(AppTheme.bg, in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Expandable About Section
private struct ExpandableAboutSection: View {
    let profile: UserProfile
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: { withAnimation { isExpanded.toggle() } }) {
                HStack {
                    Text("About")
                        .font(.headline)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 16) {
                    if !profile.interests.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Interests")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                            
                            FlowLayout(spacing: 8) {
                                ForEach(profile.interests, id: \.self) { interest in
                                    TagChip(title: interest, active: false)
                                }
                            }
                        }
                    }
                    
                    if let location = profile.location {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Location")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                            
                            if let city = location.city, let state = location.state {
                                Text("\(city), \(state)")
                                    .font(.body)
                            }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Member Since")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                        
                        Text(profile.createdAt, style: .date)
                            .font(.body)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding()
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Content Styles Grid
private struct ContentStylesGrid: View {
    let styles: [UserProfile.ContentStyle]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Content Styles")
                .font(.headline)
            
            FlowLayout(spacing: 10) {
                ForEach(styles, id: \.self) { style in
                    HStack(spacing: 6) {
                        Image(systemName: style.icon)
                            .font(.caption)
                        Text(style.rawValue)
                            .font(.subheadline.weight(.medium))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        LinearGradient(
                            colors: [AppTheme.accent.opacity(0.15), AppTheme.accent.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: Capsule()
                    )
                    .overlay(Capsule().stroke(AppTheme.accent.opacity(0.3), lineWidth: 1))
                }
            }
        }
        .padding()
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Social Proof Section
private struct SocialProofSection: View {
    let profile: UserProfile
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Social Presence")
                .font(.headline)
            
            VStack(spacing: 12) {
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
                
                if let instagram = profile.socialLinks.instagram {
                    SocialLinkRow(
                        platform: "Instagram",
                        username: instagram.username,
                        followers: instagram.followerCount,
                        isVerified: instagram.isVerified,
                        icon: "camera",
                        color: Color(red: 0.8, green: 0.3, blue: 0.6)
                    )
                }
                
                if let youtube = profile.socialLinks.youtube {
                    SocialLinkRow(
                        platform: "YouTube",
                        username: youtube.username,
                        followers: youtube.followerCount,
                        isVerified: youtube.isVerified,
                        icon: "play.rectangle",
                        color: .red
                    )
                }
                
                if let twitch = profile.socialLinks.twitch {
                    SocialLinkRow(
                        platform: "Twitch",
                        username: twitch.username,
                        followers: twitch.followerCount,
                        isVerified: twitch.isVerified,
                        icon: "tv",
                        color: Color(red: 0.58, green: 0.27, blue: 0.76)
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
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
            }
            
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
                    Text(formatFollowerCount(followers))
                        .font(.subheadline.weight(.semibold))
                    Text("followers")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(AppTheme.bg, in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Collaboration Card
private struct CollaborationCard: View {
    let preferences: UserProfile.CollaborationPreferences
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: { withAnimation { isExpanded.toggle() } }) {
                HStack {
                    Image(systemName: "person.2.badge.gearshape")
                        .font(.title3)
                        .foregroundStyle(AppTheme.accent)
                    
                    Text("Collaboration")
                        .font(.headline)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 16) {
                    if !preferences.lookingFor.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Looking For")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                            
                            FlowLayout(spacing: 8) {
                                ForEach(preferences.lookingFor, id: \.self) { type in
                                    TagChip(title: type.rawValue, active: true)
                                }
                            }
                        }
                    }
                    
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Availability")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(preferences.availability.map { $0.rawValue }.joined(separator: ", "))
                                .font(.subheadline)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Response")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(preferences.responseTime.displayText)
                                .font(.subheadline)
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [AppTheme.accent.opacity(0.1), AppTheme.card],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 16)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppTheme.accent.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Recent Activity Feed
private struct RecentActivityFeed: View {
    let activities = [
        ("Joined FEATUR community", "person.badge.plus", "2 days ago"),
        ("Earned Top Creator badge", "trophy.fill", "1 week ago"),
        ("Featured in Beauty category", "star.fill", "2 weeks ago")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Activity")
                .font(.headline)
            
            VStack(spacing: 10) {
                ForEach(activities, id: \.0) { activity in
                    HStack(spacing: 12) {
                        Image(systemName: activity.1)
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.accent)
                            .frame(width: 32, height: 32)
                            .background(AppTheme.accent.opacity(0.1), in: Circle())
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(activity.0)
                                .font(.subheadline)
                            Text(activity.2)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .padding()
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Modern Tab Selector
private struct ModernTabSelector: View {
    @Binding var selectedTab: EnhancedProfileView.ProfileTab
    @Namespace private var animation
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(EnhancedProfileView.ProfileTab.allCases, id: \.self) { tab in
                Button(action: { withAnimation(.spring(response: 0.3)) { selectedTab = tab } }) {
                    VStack(spacing: 8) {
                        Image(systemName: tab.icon)
                            .font(.title3)
                            .foregroundStyle(selectedTab == tab ? AppTheme.accent : .secondary)
                        
                        if selectedTab == tab {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(AppTheme.accent)
                                .frame(height: 3)
                                .matchedGeometryEffect(id: "tab", in: animation)
                        } else {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.clear)
                                .frame(height: 3)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Content Tab View
private struct ContentTabView: View {
    let selectedTab: EnhancedProfileView.ProfileTab
    let profile: UserProfile
    
    let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]
    
    var body: some View {
        Group {
            switch selectedTab {
            case .grid:
                if profile.mediaURLs.isEmpty {
                    EmptyContentView(
                        icon: "photo.on.rectangle.angled",
                        title: "No posts yet",
                        message: "Share your first content"
                    )
                } else {
                    LazyVGrid(columns: columns, spacing: 2) {
                        ForEach(profile.mediaURLs, id: \.self) { url in
                            AsyncImage(url: URL(string: url)) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(1, contentMode: .fill)
                                        .clipped()
                                default:
                                    Rectangle()
                                        .fill(AppTheme.card)
                                        .aspectRatio(1, contentMode: .fill)
                                }
                            }
                        }
                    }
                }
                
            case .reels:
                EmptyContentView(
                    icon: "play.rectangle.fill",
                    title: "No reels yet",
                    message: "Coming soon!"
                )
                
            case .tagged:
                EmptyContentView(
                    icon: "person.crop.rectangle",
                    title: "No tagged posts",
                    message: "Posts you're tagged in will appear here"
                )
                
            case .collections:
                EmptyContentView(
                    icon: "bookmark.fill",
                    title: "No saved posts",
                    message: "Save posts to view them later"
                )
            }
        }
    }
}

private struct EmptyContentView: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundStyle(.secondary.opacity(0.5))
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.title3.bold())
                    .foregroundStyle(.primary)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 80)
    }
}

// MARK: - Placeholder Sheets (Implement these based on your needs)
struct EnhancedEditProfileSheet: View {
    let profile: UserProfile
    @ObservedObject var viewModel: ProfileViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            Text("Edit Profile Sheet")
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

struct EnhancedSettingsSheet: View {
    @ObservedObject var viewModel: ProfileViewModel
    let profile: UserProfile
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var auth: AuthViewModel
    
    var body: some View {
        NavigationStack {
            List {
                Section("Account") {
                    Button("Sign Out") {
                        Task { await auth.signOut() }
                        dismiss()
                    }
                    .foregroundStyle(.red)
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

struct QRCodeSheet: View {
    let profile: UserProfile
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("QR Code")
                    .font(.title.bold())
                
                RoundedRectangle(cornerRadius: 20)
                    .fill(AppTheme.card)
                    .frame(width: 250, height: 250)
                    .overlay(
                        Image(systemName: "qrcode")
                            .font(.system(size: 100))
                            .foregroundStyle(.secondary)
                    )
                
                Text("Scan to view profile")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct ShareProfileSheet: View {
    let profile: UserProfile
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Share Profile")
                    .font(.title.bold())
                
                Text("Share your FEATUR profile with others")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                
                // Add share options here
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
