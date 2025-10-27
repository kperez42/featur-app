// FeaturedView.swift - IMPROVED VERSION (Uses SharedComponents - No Duplicates!)
import SwiftUI
import FirebaseAuth

struct FeaturedView: View {
    @StateObject private var viewModel = FeaturedViewModel()
    @State private var selectedCategory: FeaturedCategory = .all
    @State private var showPaymentSheet = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            AppTheme.bg.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // ✨ IMPROVED: Animated Hero Header (like Discover page)
                    FeaturedHeroHeader()
                    
                    // Quick Stats Bar
                    if !viewModel.isLoading {
                        quickStatsBar
                    }
                    
                    // Category Filter
                    categoryFilter
                    
                    // Featured Content
                    if viewModel.isLoading && viewModel.featuredCreators.isEmpty {
                        loadingView
                    } else if viewModel.filteredCreators.isEmpty {
                        emptyStateView
                    } else {
                        featuredCreatorsList
                    }
                    
                    // Promotion CTA
                    promotionCTA
                }
                .padding(.bottom, 80)
            }
            
            // Floating Banner Ad (like Discover) - Uses SharedComponents
            VStack {
                Spacer()
                BannerAdPlaceholder()
                    .frame(height: 50)
                    .background(
                        AppTheme.card
                            .shadow(color: .black.opacity(0.15), radius: 12, y: -4)
                    )
            }
            .ignoresSafeArea(edges: .bottom)
            
            // Error Toast
            if let error = viewModel.errorMessage {
                VStack {
                    errorToast(error)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .padding(.top, 60)
                    Spacer()
                }
                .animation(.spring(), value: viewModel.errorMessage)
            }
        }
        .navigationTitle("FEATUREd")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        Task { await viewModel.loadFeatured(forceRefresh: true) }
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                    
                    Button {
                        showPaymentSheet = true
                    } label: {
                        Label("Get Featured", systemImage: "star.circle")
                    }
                    
                    Divider()
                    
                    Button {
                        selectedCategory = .all
                    } label: {
                        Label("Show All", systemImage: "square.grid.2x2")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(AppTheme.accent)
                }
            }
        }
        .sheet(isPresented: $showPaymentSheet) {
            GetFeaturedSheet()
        }
        .task {
            await viewModel.loadFeatured()
        }
        .refreshable {
            await viewModel.loadFeatured(forceRefresh: true)
            Haptics.notify(.success) // Uses SharedComponents Haptics
        }
    }
    
    // MARK: - Quick Stats Bar
    
    private var quickStatsBar: some View {
        HStack(spacing: 20) {
            FeaturedStatPill(
                icon: "star.fill",
                value: "\(viewModel.featuredCreators.count)",
                label: "Featured",
                color: AppTheme.accent
            )
            
            FeaturedStatPill(
                icon: "flame.fill",
                value: "\(viewModel.trendingCount)",
                label: "Trending",
                color: AppTheme.accent
            )
            
            FeaturedStatPill(
                icon: "eye.fill",
                value: "\(viewModel.totalViews)",
                label: "Views",
                color: AppTheme.accent
            )
        }
        .padding(.horizontal)
    }
    
    // MARK: - Category Filter
    
    private var categoryFilter: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Categories")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(FeaturedCategory.allCases, id: \.self) { category in
                        FeaturedCategoryChip(
                            category: category,
                            isSelected: selectedCategory == category
                        ) {
                            withAnimation(.spring(response: 0.3)) {
                                selectedCategory = category
                                viewModel.filterByCategory(category)
                            }
                            Haptics.impact(.light)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Featured Creators List
    
    private var featuredCreatorsList: some View {
        LazyVStack(spacing: 16) {
            ForEach(viewModel.filteredCreators) { creator in
                NavigationLink {
                    if let profile = creator.profile {
                        ProfileDetailPlaceholder(profile: profile) // Uses SharedComponents
                    }
                } label: {
                    FeaturedCreatorCard(creator: creator)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Promotion CTA
    
    private var promotionCTA: some View {
        VStack(spacing: 16) {
            Text("Want to be FEATUREd?")
                .font(.title2.bold())
            
            Text("Get your profile seen by thousands of potential collaborators")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Button {
                showPaymentSheet = true
                Haptics.impact(.medium)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "star.fill")
                    Text("Get Featured")
                        .fontWeight(.semibold)
                    Image(systemName: "arrow.right")
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    LinearGradient(
                        colors: [
                            AppTheme.accent,
                            AppTheme.accent.opacity(0.8)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    in: RoundedRectangle(cornerRadius: 16)
                )
                .shadow(color: AppTheme.accent.opacity(0.3), radius: 12, y: 6)
            }
        }
        .padding()
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal)
        .padding(.vertical, 20)
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(AppTheme.accent)
            
            Text("Loading featured creators...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "star.slash")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            
            Text("No Featured Creators")
                .font(.title2.bold())
            
            Text("Check back soon for handpicked talent")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Button {
                selectedCategory = .all
                Task { await viewModel.loadFeatured(forceRefresh: true) }
            } label: {
                Text("Refresh")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(width: 200, height: 50)
                    .background(AppTheme.accent, in: RoundedRectangle(cornerRadius: 25))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
        .padding(.horizontal)
    }
    
    // MARK: - Error Toast
    
    private func errorToast(_ message: String) -> some View {
        Text(message)
            .font(.subheadline)
            .foregroundStyle(.white)
            .padding()
            .background(.red, in: RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
    }
}

// MARK: - Featured Hero Header (NEW - Like Discover!)

struct FeaturedHeroHeader: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            // Gradient Background with Animated Stars
            AppTheme.gradient
                .frame(height: 140)
                .overlay(
                    GeometryReader { geo in
                        ZStack {
                            ForEach(0..<20, id: \.self) { index in
                                AnimatedStar(
                                    size: CGFloat.random(in: 8...24),
                                    delay: Double(index) * 0.3,
                                    duration: Double.random(in: 2...4)
                                )
                                .position(
                                    x: CGFloat.random(in: 20...geo.size.width-20),
                                    y: CGFloat.random(in: 20...geo.size.height-20)
                                )
                            }
                        }
                    }
                )
                .overlay(
                    // Header Content
                    VStack(spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 40))
                                .scaleEffect(animate ? 1.2 : 1.0)
                            Image(systemName: "sparkles")
                                .font(.system(size: 32))
                        }
                        .foregroundStyle(.yellow)
                        .shadow(color: .yellow.opacity(0.3), radius: 8)
                        
                        Text("FEATUREd Creators")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        
                        Text("Handpicked talent • Updated daily")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.9))
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .padding(.horizontal)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
    }
}

// MARK: - Animated Star (for header effect)

struct AnimatedStar: View {
    let size: CGFloat
    let delay: Double
    let duration: Double
    
    @State private var isAnimating = false
    @State private var opacity: Double = 0
    
    var body: some View {
        Image(systemName: "star.fill")
            .font(.system(size: size))
            .foregroundStyle(.yellow)
            .opacity(opacity)
            .scaleEffect(isAnimating ? 1.2 : 0.8)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: duration)
                    .repeatForever(autoreverses: true)
                    .delay(delay)
                ) {
                    isAnimating = true
                }
                
                withAnimation(
                    .easeInOut(duration: duration * 0.5)
                    .repeatForever(autoreverses: true)
                    .delay(delay)
                ) {
                    opacity = Double.random(in: 0.3...0.8)
                }
            }
    }
}

// MARK: - Featured Stat Pill (Similar to Discover page)

struct FeaturedStatPill: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text(value)
                    .font(.headline.bold())
            }
            .foregroundStyle(color)
            
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Featured Category Chip

struct FeaturedCategoryChip: View {
    let category: FeaturedCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.caption)
                Text(category.displayName)
                    .font(.subheadline.weight(.semibold))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                isSelected ? AppTheme.accent : AppTheme.card,
                in: Capsule()
            )
            .foregroundStyle(isSelected ? .white : .primary)
            .overlay(
                Capsule()
                    .stroke(isSelected ? AppTheme.accent.opacity(0.3) : Color.clear, lineWidth: 2)
            )
        }
    }
}

// MARK: - Featured Creator Card

struct FeaturedCreatorCard: View {
    let creator: FeaturedCreator
    
    var body: some View {
        HStack(spacing: 16) {
            // Profile Image / Avatar
            ZStack {
                if let profile = creator.profile, let firstMedia = profile.mediaURLs.first {
                    AsyncImage(url: URL(string: firstMedia)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        default:
                            AppTheme.gradient
                        }
                    }
                } else {
                    AppTheme.gradient
                }
                
                // Featured Badge
                VStack {
                    HStack {
                        Spacer()
                        Image(systemName: "star.fill")
                            .foregroundStyle(.yellow)
                            .padding(6)
                            .background(Circle().fill(.black.opacity(0.6)))
                            .padding(8)
                    }
                    Spacer()
                }
            }
            .frame(width: 100, height: 100)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            
            // Creator Info
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text(creator.profile?.displayName ?? "Creator")
                        .font(.headline)
                    
                    if creator.profile?.isVerified == true {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(.blue)
                            .font(.caption)
                    }
                }
                
                Text(creator.category)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                if let highlight = creator.highlightText {
                    Text(highlight)
                        .font(.caption)
                        .foregroundStyle(AppTheme.accent)
                        .lineLimit(2)
                }
                
                // Stats
                HStack(spacing: 12) {
                    if let followerCount = creator.profile?.followerCount {
                        HStack(spacing: 4) {
                            Image(systemName: "person.2.fill")
                                .font(.caption2)
                            Text("\(formatNumber(followerCount))")
                                .font(.caption2.weight(.semibold))
                        }
                        .foregroundStyle(.secondary)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.caption2)
                        Text(timeAgo(from: creator.featuredAt))
                            .font(.caption2)
                    }
                    .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            // Arrow
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
    
    private func formatNumber(_ number: Int) -> String {
        if number >= 1_000_000 {
            return String(format: "%.1fM", Double(number) / 1_000_000.0)
        } else if number >= 1_000 {
            return String(format: "%.1fK", Double(number) / 1_000.0)
        } else {
            return "\(number)"
        }
    }
    
    private func timeAgo(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        let days = Int(interval / 86400)
        
        if days == 0 {
            return "Today"
        } else if days == 1 {
            return "Yesterday"
        } else if days < 7 {
            return "\(days)d ago"
        } else {
            return "\(days / 7)w ago"
        }
    }
}

// MARK: - Get Featured Sheet

struct GetFeaturedSheet: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "star.circle.fill")
                            .font(.system(size: 64))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.yellow, .orange],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Text("Get Featured")
                            .font(.title.bold())
                        
                        Text("Boost your profile visibility and reach thousands of potential collaborators")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top)
                    
                    // Benefits
                    VStack(alignment: .leading, spacing: 16) {
                        Text("What You Get")
                            .font(.headline)
                        
                        BenefitRow(
                            icon: "eye.fill",
                            title: "Prime Visibility",
                            description: "Top placement in FEATUREd tab"
                        )
                        
                        BenefitRow(
                            icon: "person.3.fill",
                            title: "Reach Thousands",
                            description: "Get seen by active creators"
                        )
                        
                        BenefitRow(
                            icon: "chart.line.uptrend.xyaxis",
                            title: "Boost Engagement",
                            description: "Increase profile views by 10x"
                        )
                        
                        BenefitRow(
                            icon: "sparkles",
                            title: "Featured Badge",
                            description: "Stand out with special badge"
                        )
                    }
                    .padding()
                    .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
                    
                    // Pricing
                    VStack(spacing: 16) {
                        Text("Choose Your Plan")
                            .font(.headline)
                        
                        PricingCard(
                            duration: "24 Hours",
                            price: "$4.99",
                            features: ["24-hour spotlight", "Featured badge", "Priority support"]
                        )
                        
                        PricingCard(
                            duration: "7 Days",
                            price: "$19.99",
                            popular: true,
                            features: ["Full week featured", "Featured badge", "Analytics dashboard", "Priority support"]
                        )
                        
                        PricingCard(
                            duration: "30 Days",
                            price: "$59.99",
                            features: ["Monthly spotlight", "Featured badge", "Advanced analytics", "Dedicated support", "Best value"]
                        )
                    }
                    
                    Text("Payment processed securely via Apple Pay")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
            .background(AppTheme.bg)
            .navigationTitle("Get Featured")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct BenefitRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(AppTheme.accent)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
    }
}

struct PricingCard: View {
    let duration: String
    let price: String
    var popular: Bool = false
    let features: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(duration)
                        .font(.headline)
                    Text(price)
                        .font(.title.bold())
                        .foregroundStyle(AppTheme.accent)
                }
                
                Spacer()
                
                if popular {
                    Text("POPULAR")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppTheme.accent, in: Capsule())
                }
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(features, id: \.self) { feature in
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.caption)
                        Text(feature)
                            .font(.caption)
                    }
                }
            }
            
            Button {
                // Handle purchase
                Haptics.impact(.medium)
            } label: {
                Text("Select Plan")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(AppTheme.accent, in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
        .background(
            popular ? AppTheme.accent.opacity(0.1) : AppTheme.card,
            in: RoundedRectangle(cornerRadius: 16)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(popular ? AppTheme.accent : Color.clear, lineWidth: 2)
        )
    }
}

// MARK: - Featured Category

enum FeaturedCategory: String, CaseIterable {
    case all = "All"
    case trending = "Trending"
    case topRated = "Top Rated"
    case newTalent = "New Talent"
    case verified = "Verified"
    
    var displayName: String { rawValue }
    
    var icon: String {
        switch self {
        case .all: return "square.grid.2x2"
        case .trending: return "flame.fill"
        case .topRated: return "star.fill"
        case .newTalent: return "sparkles"
        case .verified: return "checkmark.seal.fill"
        }
    }
}

// MARK: - Featured View Model

@MainActor
final class FeaturedViewModel: ObservableObject {
    @Published var featuredCreators: [FeaturedCreator] = []
    @Published var filteredCreators: [FeaturedCreator] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let service = FirebaseService()
    
    var trendingCount: Int {
        featuredCreators.filter { $0.category == "Trending" }.count
    }
    
    var totalViews: String {
        let total = featuredCreators.reduce(0) { $0 + ($1.profile?.followerCount ?? 0) }
        if total >= 1_000_000 {
            return String(format: "%.1fM", Double(total) / 1_000_000.0)
        } else if total >= 1_000 {
            return String(format: "%.1fK", Double(total) / 1_000.0)
        } else {
            return "\(total)"
        }
    }
    
    func loadFeatured(forceRefresh: Bool = false) async {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        #if DEBUG
        // 🧪 TEST DATA - Load immediately in debug mode
        loadTestFeatured()
        isLoading = false
        return
        #endif
        
        do {
            featuredCreators = try await service.fetchFeaturedCreators()
            filteredCreators = featuredCreators
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = "Unable to load featured creators"
            print("❌ Error loading featured: \(error)")
            
            // Clear error after delay
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            errorMessage = nil
        }
    }
    
    #if DEBUG
    // MARK: - 🧪 TEST DATA
    func loadTestFeatured() {
        featuredCreators = [
            FeaturedCreator(
                id: "featured1",
                userId: "test1",
                profile: UserProfile(
                    id: "test1",
                    uid: "test1",
                    displayName: "Sarah Johnson",
                    age: 24,
                    bio: "Fitness & wellness content creator 💪 Let's collab!",
                    location: UserProfile.Location(city: "Los Angeles", state: "CA", country: "USA", coordinates: nil),
                    interests: ["Fitness", "Wellness", "Yoga"],
                    contentStyles: [.fitness, .dance],
                    socialLinks: UserProfile.SocialLinks(
                        tiktok: UserProfile.SocialLinks.SocialAccount(username: "@sarahfit", followerCount: 125000, isVerified: true),
                        instagram: UserProfile.SocialLinks.SocialAccount(username: "@sarahfitness", followerCount: 85000, isVerified: true),
                        youtube: nil, twitch: nil, spotify: nil, snapchat: nil
                    ),
                    mediaURLs: [],
                    isVerified: true,
                    followerCount: 125000,
                    collaborationPreferences: UserProfile.CollaborationPreferences(
                        lookingFor: [.twitchStream, .contentSeries],
                        availability: [.weekdays, .flexible],
                        responseTime: .fast
                    ),
                    createdAt: Date(),
                    updatedAt: Date()
                ),
                featuredAt: Date(),
                expiresAt: Date().addingTimeInterval(86400 * 7),
                category: "Trending",
                highlightText: "🔥 Top fitness creator this week!",
                priority: 100
            ),
            FeaturedCreator(
                id: "featured2",
                userId: "test2",
                profile: UserProfile(
                    id: "test2",
                    uid: "test2",
                    displayName: "Marcus Chen",
                    age: 28,
                    bio: "Gaming streamer & editor 🎮 Creating epic content!",
                    location: UserProfile.Location(city: "San Francisco", state: "CA", country: "USA", coordinates: nil),
                    interests: ["Gaming", "Editing", "Tech"],
                    contentStyles: [.gaming, .editing],
                    socialLinks: UserProfile.SocialLinks(
                        tiktok: nil, instagram: nil,
                        youtube: UserProfile.SocialLinks.SocialAccount(username: "@marcusgaming", followerCount: 250000, isVerified: true),
                        twitch: UserProfile.SocialLinks.SocialAccount(username: "marcusplays", followerCount: 180000, isVerified: true),
                        spotify: nil, snapchat: nil
                    ),
                    mediaURLs: [],
                    isVerified: true,
                    followerCount: 250000,
                    collaborationPreferences: UserProfile.CollaborationPreferences(
                        lookingFor: [.twitchStream, .contentSeries],
                        availability: [.weekends, .flexible],
                        responseTime: .moderate
                    ),
                    createdAt: Date(),
                    updatedAt: Date()
                ),
                featuredAt: Date().addingTimeInterval(-86400),
                expiresAt: Date().addingTimeInterval(86400 * 6),
                category: "Gaming",
                highlightText: "⭐ Top gaming streamer",
                priority: 90
            ),
            FeaturedCreator(
                id: "featured3",
                userId: "test3",
                profile: UserProfile(
                    id: "test3",
                    uid: "test3",
                    displayName: "Zoe Martinez",
                    age: 22,
                    bio: "Beauty & fashion influencer ✨ Always down for creative collabs!",
                    location: UserProfile.Location(city: "Miami", state: "FL", country: "USA", coordinates: nil),
                    interests: ["Beauty", "Fashion", "Lifestyle"],
                    contentStyles: [.beauty, .fashion],
                    socialLinks: UserProfile.SocialLinks(
                        tiktok: UserProfile.SocialLinks.SocialAccount(username: "@zoebeauty", followerCount: 500000, isVerified: true),
                        instagram: UserProfile.SocialLinks.SocialAccount(username: "@zoestyle", followerCount: 320000, isVerified: true),
                        youtube: nil, twitch: nil, spotify: nil, snapchat: nil
                    ),
                    mediaURLs: [],
                    isVerified: true,
                    followerCount: 500000,
                    collaborationPreferences: UserProfile.CollaborationPreferences(
                        lookingFor: [.brandDeal, .contentSeries, .tiktokLive],
                        availability: [.flexible],
                        responseTime: .fast
                    ),
                    createdAt: Date(),
                    updatedAt: Date()
                ),
                featuredAt: Date(),
                expiresAt: Date().addingTimeInterval(86400 * 7),
                category: "Trending",
                highlightText: "💄 Beauty influencer of the week",
                priority: 95
            ),
            FeaturedCreator(
                id: "featured4",
                userId: "test4",
                profile: UserProfile(
                    id: "test4",
                    uid: "test4",
                    displayName: "Alex Thompson",
                    age: 26,
                    bio: "Chef & food content creator 🍳 Let's cook up something amazing!",
                    location: UserProfile.Location(city: "New York", state: "NY", country: "USA", coordinates: nil),
                    interests: ["Cooking", "Food", "Travel"],
                    contentStyles: [.cooking, .mukbang],
                    socialLinks: UserProfile.SocialLinks(
                        tiktok: UserProfile.SocialLinks.SocialAccount(username: "@chefalexx", followerCount: 180000, isVerified: false),
                        instagram: UserProfile.SocialLinks.SocialAccount(username: "@alexcooks", followerCount: 95000, isVerified: true),
                        youtube: UserProfile.SocialLinks.SocialAccount(username: "@AlexThompsonCooks", followerCount: 220000, isVerified: true),
                        twitch: nil, spotify: nil, snapchat: nil
                    ),
                    mediaURLs: [],
                    isVerified: true,
                    followerCount: 180000,
                    collaborationPreferences: UserProfile.CollaborationPreferences(
                        lookingFor: [.brandDeal, .contentSeries],
                        availability: [.weekdays],
                        responseTime: .moderate
                    ),
                    createdAt: Date(),
                    updatedAt: Date()
                ),
                featuredAt: Date().addingTimeInterval(-172800),
                expiresAt: Date().addingTimeInterval(86400 * 5),
                category: "Food",
                highlightText: "👨‍🍳 Rising culinary creator",
                priority: 85
            ),
            FeaturedCreator(
                id: "featured5",
                userId: "test5",
                profile: UserProfile(
                    id: "test5",
                    uid: "test5",
                    displayName: "Riley Peterson",
                    age: 25,
                    bio: "Musician & producer 🎵 Making beats and vibes!",
                    location: UserProfile.Location(city: "Nashville", state: "TN", country: "USA", coordinates: nil),
                    interests: ["Music", "Production", "Art"],
                    contentStyles: [.music, .art],
                    socialLinks: UserProfile.SocialLinks(
                        tiktok: UserProfile.SocialLinks.SocialAccount(username: "@rileymusic", followerCount: 75000, isVerified: false),
                        instagram: UserProfile.SocialLinks.SocialAccount(username: "@rileybeats", followerCount: 45000, isVerified: false),
                        youtube: UserProfile.SocialLinks.SocialAccount(username: "@RileyPeterson", followerCount: 150000, isVerified: true),
                        twitch: nil,
                        spotify: "RileyPeterson",
                        snapchat: nil
                    ),
                    mediaURLs: [],
                    isVerified: false,
                    followerCount: 75000,
                    collaborationPreferences: UserProfile.CollaborationPreferences(
                        lookingFor: [.musicCollab, .contentSeries],
                        availability: [.flexible],
                        responseTime: .fast
                    ),
                    createdAt: Date(),
                    updatedAt: Date()
                ),
                featuredAt: Date(),
                expiresAt: Date().addingTimeInterval(86400 * 7),
                category: "New Talent",
                highlightText: "🎸 Fresh talent on the rise!",
                priority: 80
            )
        ]
        filteredCreators = featuredCreators
    }
    #endif
    
    func filterByCategory(_ category: FeaturedCategory) {
        switch category {
        case .all:
            filteredCreators = featuredCreators
        case .trending:
            filteredCreators = featuredCreators.filter { $0.category == "Trending" }
        case .topRated:
            filteredCreators = featuredCreators.sorted { ($0.profile?.followerCount ?? 0) > ($1.profile?.followerCount ?? 0) }
        case .newTalent:
            filteredCreators = featuredCreators.filter {
                Calendar.current.isDateInToday($0.featuredAt) ||
                Calendar.current.isDateInYesterday($0.featuredAt)
            }
        case .verified:
            filteredCreators = featuredCreators.filter { $0.profile?.isVerified == true }
        }
    }
}
