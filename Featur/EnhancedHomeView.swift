// EnhancedHomeView.swift - TINDER-LIKE SWIPE INTERFACE
import SwiftUI
import FirebaseAuth


struct EnhancedHomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @EnvironmentObject var auth: AuthViewModel
    
    @State private var swipeCount = 0
    @State private var showFilters = false
    @State private var selectedProfile: UserProfile? = nil
    @State private var showProfileDetail = false
    
    var body: some View {
        ZStack {
            AppTheme.bg.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Bar with Stats
                topBar
                
                // Main Swipe Card Stack
                if viewModel.isLoading && viewModel.profiles.isEmpty {
                    loadingView
                } else if viewModel.profiles.isEmpty {
                    emptyState
                } else {
                    swipeCardStack
                        .frame(maxHeight: .infinity)
                    
                    // Action Buttons
                    actionButtons
                        .padding(.vertical, 20)
                }
            }
            
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
        .navigationTitle("Discover")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 12) {
                    Button {
                        showFilters = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .foregroundStyle(AppTheme.accent)
                    }
                    
                    Button {
                        // Show notifications
                    } label: {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "bell.fill")
                                .foregroundStyle(AppTheme.accent)
                            
                            if viewModel.hasNewMatches {
                                Circle()
                                    .fill(.red)
                                    .frame(width: 8, height: 8)
                                    .offset(x: 4, y: -4)
                            }
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showFilters) {
            HomeFiltersSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $showProfileDetail) {
            if let profile = selectedProfile {
                ProfileDetailPlaceholder(profile: profile)
            }
        }
        .task {
           // fetch the latest profiles using current user id, if nil default to an empty string
            await viewModel.loadProfiles(currentUserId: auth.user?.uid ?? "")
        }
        .refreshable {
            await viewModel.refresh(currentUserId: auth.user?.uid ?? "")
            swipeCount = 0
            Haptics.notify(.success)
        }
        .alert("It's a Match! 🎉", isPresented: $viewModel.showMatchAlert) {
            Button("Send Message") {
                // Navigate to chat
            }
            Button("Keep Swiping", role: .cancel) { }
        } message: {
            if let match = viewModel.lastMatch {
                Text("You and \(match.displayName) liked each other!")
            }
        }
    }
    
    // MARK: - Top Bar
    
    private var topBar: some View {
        HStack(spacing: 16) {
            StatBadge(
                icon: "person.3.fill",
                value: "\(viewModel.profiles.count)",
                label: "Available",
                color: .blue
            )
            
            StatBadge(
                icon: "heart.fill",
                value: "\(swipeCount)",
                label: "Likes",
                color: .pink
            )
            
            if viewModel.matchesToday > 0 {
                StatBadge(
                    icon: "star.fill",
                    value: "\(viewModel.matchesToday)",
                    label: "Matches",
                    color: .yellow
                )
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }
    
    // MARK: - Swipe Card Stack
    
    private var swipeCardStack: some View {
        ZStack {
            ForEach(Array(viewModel.profiles.prefix(3).enumerated()), id: \.element.id) { index, profile in
                if index == 0 {
                    TinderSwipeCard(
                        profile: profile,
                        onSwipeLeft: {
                            Task {
                                await viewModel.handleSwipe(profile: profile, action: .pass)
                                Haptics.impact(.medium)
                            }
                        },
                        onSwipeRight: {
                            Task {
                                swipeCount += 1
                                await viewModel.handleSwipe(profile: profile, action: .like)
                                Haptics.impact(.heavy)
                            }
                        },
                        onTap: {
                            selectedProfile = profile
                            showProfileDetail = true
                            Haptics.impact(.light)
                        }
                    )
                    .zIndex(Double(3 - index))
                    .transition(.identity)
                } else {
                    ProfileCardView(profile: profile)
                        .scaleEffect(1 - CGFloat(index) * 0.05)
                        .offset(y: CGFloat(index) * 10)
                        .opacity(1 - Double(index) * 0.3)
                        .zIndex(Double(3 - index))
                        .allowsHitTesting(false)
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.profiles.count)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        HStack(spacing: 24) {
            // Pass Button
            ActionButton(
                icon: "xmark",
                color: .red,
                size: 60
            ) {
                Haptics.impact(.rigid)
                if let current = viewModel.currentProfile {
                    Task {
                        await viewModel.handleSwipe(profile: current, action: .pass)
                    }
                }
            }
            
            // Undo Button
            ActionButton(
                icon: "arrow.uturn.left",
                color: AppTheme.accent,
                size: 50
            ) {
                Haptics.impact(.soft)
                if let last = viewModel.swipeHistory.last {
                    Task {
                        await viewModel.undoSwipe(last)
                    }
                }
            }
            .disabled(viewModel.swipeHistory.isEmpty)
            .opacity(viewModel.swipeHistory.isEmpty ? 0.5 : 1.0)
            
            // Super Like Button
            ActionButton(
                icon: "star.fill",
                color: .blue,
                size: 50
            ) {
                Haptics.notify(.success)
                if let current = viewModel.currentProfile {
                    Task {
                        swipeCount += 1
                        await viewModel.handleSwipe(profile: current, action: .superLike)
                    }
                }
            }
            
            // Like Button
            ActionButton(
                icon: "heart.fill",
                color: .green,
                size: 60
            ) {
                Haptics.impact(.heavy)
                if let current = viewModel.currentProfile {
                    Task {
                        swipeCount += 1
                        await viewModel.handleSwipe(profile: current, action: .like)
                    }
                }
            }
        }
        .padding(.horizontal, 24)
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(AppTheme.accent)
            
            Text("Finding creators for you...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            
            Text("No More Profiles")
                .font(.title2.bold())
            
            Text("Check back later or adjust your filters")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Button {
                Task {
                    await viewModel.refresh(currentUserId: auth.user?.uid ?? "")
                }
            } label: {
                Text("Refresh")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(width: 200, height: 50)
                    .background(AppTheme.accent, in: RoundedRectangle(cornerRadius: 25))
            }
            .padding(.top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
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

// MARK: - Tinder Swipe Card

struct TinderSwipeCard: View {
    let profile: UserProfile
    let onSwipeLeft: () -> Void
    let onSwipeRight: () -> Void
    let onTap: () -> Void
    
    @State private var offset: CGSize = .zero
    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 1.0
    
    private let swipeThreshold: CGFloat = 100
    
    var body: some View {
        ProfileCardView(profile: profile)
            .overlay(alignment: .topLeading) {
                if offset.width > 20 {
                    LikeOverlay(type: .like)
                        .opacity(Double(offset.width / swipeThreshold))
                        .padding(40)
                }
            }
            .overlay(alignment: .topTrailing) {
                if offset.width < -20 {
                    LikeOverlay(type: .pass)
                        .opacity(Double(-offset.width / swipeThreshold))
                        .padding(40)
                }
            }
            .scaleEffect(scale)
            .offset(offset)
            .rotationEffect(.degrees(rotation))
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        offset = gesture.translation
                        rotation = Double(gesture.translation.width / 20)
                        scale = 0.95
                    }
                    .onEnded { gesture in
                        let horizontalSwipe = gesture.translation.width
                        
                        if abs(horizontalSwipe) > swipeThreshold {
                            // Swipe completed
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                offset = CGSize(
                                    width: horizontalSwipe > 0 ? 500 : -500,
                                    height: gesture.translation.height
                                )
                                rotation = horizontalSwipe > 0 ? 15 : -15
                            }
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                if horizontalSwipe > 0 {
                                    onSwipeRight()
                                } else {
                                    onSwipeLeft()
                                }
                            }
                        } else {
                            // Snap back
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                offset = .zero
                                rotation = 0
                                scale = 1.0
                            }
                        }
                    }
            )
            .onTapGesture {
                onTap()
            }
    }
}

// MARK: - Profile Card View

struct ProfileCardView: View {
    let profile: UserProfile
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                // Background Image/Gradient
                if let firstMediaURL = profile.mediaURLs?.first,
                   let url = URL(string: firstMediaURL.trimmingCharacters(in: .whitespacesAndNewlines)) {
                    
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            // While loading: subtle gradient + blur shimmer
                            ZStack {
                                AppTheme.gradient
                                Rectangle()
                                    .fill(.ultraThinMaterial)
                                    .opacity(0.4)
                                ProgressView()
                                    .tint(.white)
                            }
                            .transition(.opacity)
                            
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .overlay(
                                    // Add slight fade so gradient gently merges into image
                                    AppTheme.gradient.opacity(0.15)
                                )
                                .transition(.opacity)
                                .animation(.easeInOut(duration: 0.4), value: UUID()) // harmless trigger

                        case .failure:
                            AppTheme.gradient
                        @unknown default:
                            AppTheme.gradient
                        }
                    }
                    
                } else {
                    AppTheme.gradient
                }

                
                // Gradient Overlay
                LinearGradient(
                    colors: [.clear, .black.opacity(0.8)],
                    startPoint: .center,
                    endPoint: .bottom
                )
                
                // Profile Info
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(profile.displayName)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(.white)
                        
                        if let age = profile.age {
                            Text("\(age)")
                                .font(.system(size: 28, weight: .medium))
                                .foregroundStyle(.white.opacity(0.9))
                        }
                        
                        if profile.isVerified ?? false {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(.blue)
                                .font(.title3)
                        }
                    }
                    
                    if let bio = profile.bio {
                        Text(bio)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.9))
                            .lineLimit(2)
                    }
                    
                    // Content Styles
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(profile.contentStyles.prefix(3), id: \.self) { style in
                                Text(style.rawValue)
                                    .font(.caption.bold())
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(.white.opacity(0.2), in: Capsule())
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                    
                    // Location
                    if let location = profile.location, let city = location.city {
                        HStack(spacing: 4) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.caption)
                            Text(city)
                                .font(.caption)
                        }
                        .foregroundStyle(.white.opacity(0.8))
                    }
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
        }
        .aspectRatio(0.7, contentMode: .fit)
    }
}

// MARK: - Like Overlay

struct LikeOverlay: View {
    enum OverlayType {
        case like, pass
    }
    
    let type: OverlayType
    
    var body: some View {
        Text(type == .like ? "LIKE" : "PASS")
            .font(.system(size: 48, weight: .heavy))
            .foregroundStyle(type == .like ? .green : .red)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(type == .like ? Color.green : Color.red, lineWidth: 5)
            )
            .rotationEffect(.degrees(type == .like ? -20 : 20))
    }
}

// MARK: - Action Button

struct ActionButton: View {
    let icon: String
    let color: Color
    let size: CGFloat
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(.white)
                    .frame(width: size, height: size)
                    .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                
                Image(systemName: icon)
                    .font(.system(size: size * 0.4, weight: .bold))
                    .foregroundStyle(color)
            }
        }
    }
}

// MARK: - Stats Badge

struct StatBadge: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.caption)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.headline)
                    .fontWeight(.bold)
                
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Profile Detail Placeholder

// MARK: - Flow Layout (for tags)
// MARK: - Home Filters Sheet

struct HomeFiltersSheet: View {
    @ObservedObject var viewModel: HomeViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Content Styles Filter
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Content Styles")
                            .font(.headline)
                        
                        FlowLayout(spacing: 8) {
                            ForEach(UserProfile.ContentStyle.allCases, id: \.self) { style in
                                FilterChip(
                                    text: style.rawValue,
                                    isSelected: viewModel.selectedContentStyles.contains(style)
                                ) {
                                    if viewModel.selectedContentStyles.contains(style) {
                                        viewModel.selectedContentStyles.remove(style)
                                    } else {
                                        viewModel.selectedContentStyles.insert(style)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
                    
                    // Age Range
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Age Range: \(Int(viewModel.minAge)) - \(Int(viewModel.maxAge))")
                            .font(.headline)
                        
                        HStack(spacing: 16) {
                            VStack(alignment: .leading) {
                                Text("Min: \(Int(viewModel.minAge))")
                                    .font(.caption)
                                Slider(value: $viewModel.minAge, in: 18...viewModel.maxAge, step: 1)
                                    .tint(AppTheme.accent)
                            }
                            
                            VStack(alignment: .leading) {
                                Text("Max: \(Int(viewModel.maxAge))")
                                    .font(.caption)
                                Slider(value: $viewModel.maxAge, in: viewModel.minAge...100, step: 1)
                                    .tint(AppTheme.accent)
                            }
                        }
                    }
                    .padding()
                    .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
                    
                    // Verified Only
                    Toggle("Verified Creators Only", isOn: $viewModel.verifiedOnly)
                        .padding()
                        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
                }
                .padding()
            }
            .background(AppTheme.bg)
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        Task {
                            await viewModel.applyFilters()
                        }
                        dismiss()
                        Haptics.notify(.success)
                    }
                    .fontWeight(.bold)
                }
            }
        }
    }
}
 

// MARK: - View Model

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var profiles: [UserProfile] = []
    @Published var isLoading = false
    @Published var showMatchAlert = false
    @Published var lastMatch: UserProfile?
    @Published var swipeHistory: [SwipeRecord] = []
    @Published var errorMessage: String?
    @Published var hasNewMatches = false
    
    // Stats
    @Published var matchesToday = 0
    
    // Filters
    @Published var selectedContentStyles: Set<UserProfile.ContentStyle> = []
    @Published var minAge: Double = 18
    @Published var maxAge: Double = 100
    @Published var verifiedOnly = false
    
    private let service = FirebaseService()
    private var swipedUserIds: Set<String> = []
    
    var currentProfile: UserProfile? {
        profiles.first
    }
    // this function loads discoverable profiles while excluding all the profiles each user has ever
    // previously swiped on
    func loadProfiles(currentUserId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            guard let currentUser = try await service.fetchProfile(uid: currentUserId) else {
                throw NSError(domain: "Missing current user profile", code: 0)
            }
            let previouslySwiped = try await service.fetchSwipedUserIds(for: currentUserId)
            swipedUserIds.formUnion(previouslySwiped)

            // 2. Load profiles excluding all of them
            let fetched = try await service.fetchDiscoverProfiles(
                for: currentUser,
                limit: 20,
                excludeUserIds: Array(swipedUserIds)
            )
            
            profiles = fetched
            isLoading = false
            
        } catch {
            isLoading = false
            profiles = []
            errorMessage = "Unable to load profiles. Pull to refresh."
            
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            errorMessage = nil
            
            print("❌ Error loading profiles: \(error)")
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
        
        swipeHistory.append(SwipeRecord(profile: profile, action: action))
        if swipeHistory.count > 10 {
            swipeHistory.removeFirst()
        }
        
        do {
            try await service.recordSwipe(swipe)
            print("Swipe recorded to Firestore: \(action) → \(profile.displayName) (\(profile.uid))")

            
            if action == .like || action == .superLike {
                let matches = try await service.fetchMatches(forUser: currentUserId)
                if matches.contains(where: {
                    $0.userId1 == profile.uid || $0.userId2 == profile.uid
                }) {
                    lastMatch = profile
                    showMatchAlert = true
                    matchesToday += 1
                    hasNewMatches = true
                    Haptics.notify(.success)
                }
            }
            
            withAnimation(.spring(response: 0.3)) {
                profiles.removeAll { $0.id == profile.id }
            }
            
            if profiles.count < 3 {
                await loadProfiles(currentUserId: currentUserId)
            }
        } catch {
            errorMessage = "Failed to process swipe"
            print("❌ Error handling swipe: \(error)")
        }
    }
    
    func undoSwipe(_ record: SwipeRecord) async {
        swipedUserIds.remove(record.profile.uid)
        swipeHistory.removeAll { $0.id == record.id }
        
        withAnimation(.spring(response: 0.3)) {
            profiles.insert(record.profile, at: 0)
        }
        
        Haptics.impact(.medium)
    }
    
    func refresh(currentUserId: String) async {
        swipedUserIds.removeAll()
        swipeHistory.removeAll()
        await loadProfiles(currentUserId: currentUserId)
    }

    func applyFilters() async {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        await loadProfiles(currentUserId: currentUserId)
    }
}

// MARK: - Swipe Record

struct SwipeRecord: Identifiable {
    let id = UUID()
    let profile: UserProfile
    let action: SwipeAction.Action
    let timestamp = Date()
}

// MARK: - Haptics Helper

struct Haptics2 {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    static func notify(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }
}
