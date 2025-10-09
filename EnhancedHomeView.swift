import SwiftUI
import FirebaseAuth

struct EnhancedHomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @EnvironmentObject var auth: AuthViewModel
    
    var body: some View {
        ZStack {
            AppTheme.bg.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Hero Header
                    heroHeader
                    
                    // Main Swipe Card Stack
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(height: 500)
                    } else if viewModel.profiles.isEmpty {
                        emptyState
                    } else {
                        swipeCardStack
                        actionButtons
                    }
                    
                    // Featured Section
                    if !viewModel.featuredCreators.isEmpty {
                        featuredSection
                    }
                    
                    // Trending Categories
                    trendingSection
                }
                .padding(.bottom, 24)
            }
        }
        .task {
            await viewModel.loadProfiles(currentUserId: auth.user?.uid ?? "")
            await viewModel.loadFeaturedCreators()
        }
        .refreshable {
            await viewModel.refresh(currentUserId: auth.user?.uid ?? "")
        }
        .alert("It's a Match!", isPresented: $viewModel.showMatchAlert) {
            Button("Send Message", role: .none) {
                // Navigate to chat
            }
            Button("Keep Swiping", role: .cancel) { }
        } message: {
            if let match = viewModel.lastMatch {
                Text("You and \(match.displayName) liked each other!")
            }
        }
    }
    
    // MARK: - Components
    
    private var heroHeader: some View {
        ZStack(alignment: .bottomLeading) {
            AppTheme.gradient
                .frame(height: 140)
                .clipShape(RoundedRectangle(cornerRadius: 22))
            
            VStack(alignment: .leading, spacing: 6) {
                Text("FEATUR")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                Text("Discover creators near you")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.85))
            }
            .padding(20)
        }
        .foregroundStyle(.white)
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    private var swipeCardStack: some View {
        ZStack {
            ForEach(Array(viewModel.profiles.prefix(3).enumerated()), id: \.element.id) { index, profile in
                if index == 0 {
                    SwipeCard(
                        onSwipeLeft: {
                            Task {
                                await viewModel.handleSwipe(profile: profile, action: .pass)
                            }
                        },
                        onSwipeRight: {
                            Task {
                                await viewModel.handleSwipe(profile: profile, action: .like)
                            }
                        }
                    ) {
                        ProfileCard(profile: profile)
                    }
                    .zIndex(Double(3 - index))
                } else {
                    ProfileCard(profile: profile)
                        .scaleEffect(1 - CGFloat(index) * 0.05)
                        .offset(y: CGFloat(index) * 10)
                        .opacity(1 - Double(index) * 0.2)
                        .zIndex(Double(3 - index))
                }
            }
        }
        .frame(height: 520)
        .padding(.horizontal)
    }
    
    private var actionButtons: some View {
        HStack(spacing: 32) {
            Button {
                Haptics.impact(.rigid)
                if let current = viewModel.currentProfile {
                    Task { await viewModel.handleSwipe(profile: current, action: .pass) }
                }
            } label: {
                ActionButtonView(icon: "xmark", color: .red, size: 62)
            }
            
            Button {
                Haptics.impact(.soft)
                // TODO: Undo last swipe
            } label: {
                ActionButtonView(icon: "arrow.uturn.left", color: AppTheme.accent, size: 50)
            }
            
            Button {
                Haptics.impact(.heavy)
                if let current = viewModel.currentProfile {
                    Task { await viewModel.handleSwipe(profile: current, action: .like) }
                }
            } label: {
                ActionButtonView(icon: "heart.fill", color: .green, size: 62)
            }
        }
        .padding(.horizontal)
    }
    
    private var featuredSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Featured Today")
                .font(.title2.bold())
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(viewModel.featuredCreators) { creator in
                        FeaturedCreatorCard(creator: creator)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private var trendingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Trending Categories")
                .font(.title2.bold())
                .padding(.horizontal)
            
            TagPills(
                tags: UserProfile.ContentStyle.allCases.map { $0.rawValue },
                selected: .constant(nil)
            )
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            
            Text("No More Profiles")
                .font(.title2.bold())
            
            Text("Check back later for new creators in your area")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Refresh") {
                Task {
                    await viewModel.refresh(currentUserId: auth.user?.uid ?? "")
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.accent)
        }
        .frame(height: 400)
        .padding()
    }
}

// MARK: - Profile Card

struct ProfileCard: View {
    let profile: UserProfile
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Main Photo
            AsyncImage(url: URL(string: profile.mediaURLs.first ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(AppTheme.card)
                    .overlay {
                        Image(systemName: "person.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                    }
            }
            .frame(height: 380)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            
            // Location Badge
            if profile.location?.isNearby == true {
                HStack(spacing: 6) {
                    Image(systemName: "location.fill")
                        .font(.caption2)
                    Text("Nearby")
                        .font(.caption2.weight(.semibold))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(AppTheme.card, in: Capsule())
                .foregroundStyle(.secondary)
            }
            
            // Name & Age
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(profile.displayName)
                    .font(.system(size: 28, weight: .bold))
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
            
            // Bio
            if let bio = profile.bio {
                Text(bio)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            
            // Interests Tags
            FlowLayout(spacing: 8) {
                ForEach(profile.interests.prefix(6), id: \.self) { interest in
                    Text(interest)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(AppTheme.card, in: Capsule())
                        .foregroundStyle(.primary)
                }
            }
            
            // Social Stats
            HStack(spacing: 20) {
                if let tiktok = profile.socialLinks.tiktok {
                    SocialStat(icon: "tiktok", count: tiktok.followerCount ?? 0)
                }
                if let instagram = profile.socialLinks.instagram {
                    SocialStat(icon: "instagram", count: instagram.followerCount ?? 0)
                }
                if let youtube = profile.socialLinks.youtube {
                    SocialStat(icon: "youtube", count: youtube.followerCount ?? 0)
                }
            }
        }
        .padding(16)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.08)))
    }
}

struct SocialStat: View {
    let icon: String
    let count: Int
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "person.2.fill")
                .font(.caption2)
            Text(formatCount(count))
                .font(.caption.weight(.semibold))
        }
        .foregroundStyle(.secondary)
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

struct ActionButtonView: View {
    let icon: String
    let color: Color
    let size: CGFloat
    
    var body: some View {
        Image(systemName: icon)
            .font(.system(size: size * 0.4, weight: .bold))
            .frame(width: size, height: size)
            .foregroundStyle(.white)
            .background(color, in: Circle())
            .shadow(color: color.opacity(0.4), radius: 12, y: 6)
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.replacingUnspecifiedDimensions().width, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth, x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                lineHeight = max(lineHeight, size.height)
                x += size.width + spacing
            }
            
            self.size = CGSize(width: maxWidth, height: y + lineHeight)
        }
    }
}

// MARK: - View Model

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var profiles: [UserProfile] = []
    @Published var featuredCreators: [FeaturedCreator] = []
    @Published var isLoading = false
    @Published var showMatchAlert = false
    @Published var lastMatch: UserProfile?
    
    private let service = FirebaseService()
    private var swipedUserIds: Set<String> = []
    
    var currentProfile: UserProfile? {
        profiles.first
    }
    
    func loadProfiles(currentUserId: String) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let fetched = try await service.fetchDiscoverProfiles(
                limit: 20,
                excludeUserIds: Array(swipedUserIds)
            )
            profiles = fetched.filter { $0.uid != currentUserId }
        } catch {
            print("Error loading profiles: \(error)")
        }
    }
    
    func loadFeaturedCreators() async {
        do {
            featuredCreators = try await service.fetchFeaturedCreators()
        } catch {
            print("Error loading featured: \(error)")
        }
    }
    
    func handleSwipe(profile: UserProfile, action: SwipeAction.Action) async {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        swipedUserIds.insert(profile.uid)
        
        let swipe = SwipeAction(
            userId: currentUserId,
            targetUserId: profile.uid,
            action: action,
            timestamp: Date()
        )
        
        do {
            try await service.recordSwipe(swipe)
            
            // Check for match
            if action == .like {
                let matches = try await service.fetchMatches(forUser: currentUserId)
                if matches.contains(where: {
                    $0.userId1 == profile.uid || $0.userId2 == profile.uid
                }) {
                    lastMatch = profile
                    showMatchAlert = true
                    Haptics.notify(.success)
                }
            }
            
            // Remove from stack
            withAnimation(.spring(response: 0.3)) {
                profiles.removeAll { $0.id == profile.id }
            }
            
            // Load more if running low
            if profiles.count < 3 {
                await loadProfiles(currentUserId: currentUserId)
            }
        } catch {
            print("Error handling swipe: \(error)")
        }
    }
    
    func refresh(currentUserId: String) async {
        swipedUserIds.removeAll()
        await loadProfiles(currentUserId: currentUserId)
        await loadFeaturedCreators()
    }
}

struct FeaturedCreatorCard: View {
    let creator: FeaturedCreator
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let profile = creator.profile {
                HStack(spacing: 12) {
                    AsyncImage(url: URL(string: profile.mediaURLs.first ?? "")) { image in
                        image.resizable()
                    } placeholder: {
                        Circle().fill(AppTheme.accent.opacity(0.2))
                    }
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(profile.displayName)
                            .font(.headline)
                        Text("@\(profile.displayName.lowercased())")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                if let highlight = creator.highlightText {
                    Text(highlight)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }
                
                Button("View Profile") {
                    // Navigate
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.accent)
                .frame(maxWidth: .infinity)
            }
        }
        .padding(16)
        .frame(width: 260)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.06)))
    }
}
