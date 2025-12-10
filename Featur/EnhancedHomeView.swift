// EnhancedHomeView.swift - TINDER-LIKE SWIPE INTERFACE
import SwiftUI
import FirebaseAuth

struct EnhancedHomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @EnvironmentObject var auth: AuthViewModel
    @EnvironmentObject var appState: AppStateManager

    @State private var swipeCount = 0
    @State private var showFilters = false
    @State private var selectedProfile: UserProfile? = nil
    
    var body: some View {
        ZStack {
            AppTheme.bg.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Bar with Stats
                topBar
                
                // Main Swipe Card Stack
                if viewModel.isLoading && viewModel.profiles.isEmpty {
                    loadingView
                } else if viewModel.filteredProfiles.isEmpty {
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
        .navigationTitle("Home")
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
        .sheet(item: $selectedProfile) { profile in
            ProfileDetailViewSimple(profile: profile)
                .presentationDragIndicator(.visible)
        }

        .task {
            // Track screen view
            AnalyticsManager.shared.trackScreenView(screenName: "Home", screenClass: "EnhancedHomeView")

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
                if let match = viewModel.lastMatch {
                    appState.navigateToChat(withUserId: match.uid)
                }
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
                value: "\(viewModel.filteredProfiles.count)",
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
            ForEach(Array(viewModel.filteredProfiles.prefix(3).enumerated()), id: \.element.id) { index, profile in
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
                            Haptics.impact(.light)
                            // Track profile view analytics
                            AnalyticsManager.shared.trackProfileView(
                                userId: profile.uid,
                                source: "home"
                            )
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
                Haptics.impact(.medium)
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
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.white)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.white)

            Spacer()

            Button {
                Haptics.impact(.light)
                Task {
                    await viewModel.loadProfiles(currentUserId: auth.user?.uid ?? "")
                }
            } label: {
                Text("Retry")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.white.opacity(0.2), in: RoundedRectangle(cornerRadius: 8))
            }
        }
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
    @State private var hasTriggeredThresholdHaptic = false

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

                        // Haptic feedback when crossing threshold
                        let isOverThreshold = abs(gesture.translation.width) > swipeThreshold
                        if isOverThreshold && !hasTriggeredThresholdHaptic {
                            Haptics.impact(.medium)
                            hasTriggeredThresholdHaptic = true
                        } else if !isOverThreshold {
                            hasTriggeredThresholdHaptic = false
                        }
                    }
                    .onEnded { gesture in
                        let horizontalSwipe = gesture.translation.width
                        hasTriggeredThresholdHaptic = false

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
                            // Snap back with light haptic
                            Haptics.impact(.light)
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
    @State private var currentImageIndex = 0

    private var mediaURLs: [String] {
        profile.mediaURLs ?? []
    }

    private var hasMultipleImages: Bool {
        mediaURLs.count > 1
    }

    // Safe current index that stays within bounds
    private var safeCurrentIndex: Int {
        guard !mediaURLs.isEmpty else { return 0 }
        return min(currentImageIndex, mediaURLs.count - 1)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                // Background Image/Gradient with Carousel (CACHED)
                if !mediaURLs.isEmpty {
                    let currentURL = mediaURLs[safeCurrentIndex]
                    if let url = URL(string: currentURL.trimmingCharacters(in: .whitespacesAndNewlines)) {
                        CachedAsyncImage(url: url) { image in
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: geo.size.width, height: geo.size.height)
                                .clipped()
                                .overlay(
                                    // Add slight fade so gradient gently merges into image
                                    AppTheme.gradient.opacity(0.15)
                                )
                        } placeholder: {
                            // While loading: subtle gradient + blur shimmer
                            ZStack {
                                AppTheme.gradient
                                Rectangle()
                                    .fill(.ultraThinMaterial)
                                    .opacity(0.4)
                                ProgressView()
                                    .tint(.white)
                            }
                            .frame(width: geo.size.width, height: geo.size.height)
                        }
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                        .id(safeCurrentIndex) // Force reload when index changes
                    } else {
                        // Invalid URL fallback
                        fallbackGradient(size: geo.size)
                    }
                } else {
                    // No images fallback
                    fallbackGradient(size: geo.size)
                }

                // Image Navigation Areas (tap left/right to navigate)
                if hasMultipleImages {
                    HStack(spacing: 0) {
                        // Left tap area - previous image
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    currentImageIndex = max(0, currentImageIndex - 1)
                                }
                                Haptics.impact(.light)
                            }

                        // Right tap area - next image
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    currentImageIndex = min(mediaURLs.count - 1, currentImageIndex + 1)
                                }
                                Haptics.impact(.light)
                            }
                    }
                }

                // Image Indicators (dots at top)
                if hasMultipleImages {
                    VStack {
                        HStack(spacing: 6) {
                            ForEach(0..<mediaURLs.count, id: \.self) { index in
                                Capsule()
                                    .fill(index == safeCurrentIndex ? .white : .white.opacity(0.5))
                                    .frame(height: 4)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 12)

                        Spacer()
                    }
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

                        // Online Status Badge
                        if PresenceManager.shared.isOnline(userId: profile.uid) {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(.green)
                                    .frame(width: 8, height: 8)
                                Text("Online")
                                    .font(.caption.bold())
                                    .foregroundStyle(.white)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.green, in: Capsule())
                        }
                    }

                    if let bio = profile.bio, !bio.isEmpty {
                        Text(bio)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.9))
                            .lineLimit(2)
                    }

                    // Content Styles
                    if !profile.contentStyles.isEmpty {
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
                    }

                    // Location
                    if let location = profile.location, let city = location.city, !city.isEmpty {
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
        .onChange(of: mediaURLs.count) { _, newCount in
            // Reset index if it's out of bounds after mediaURLs changes
            if currentImageIndex >= newCount {
                currentImageIndex = max(0, newCount - 1)
            }
        }
    }

    // Fallback gradient view with person icon
    @ViewBuilder
    private func fallbackGradient(size: CGSize) -> some View {
        ZStack {
            AppTheme.gradient
            Image(systemName: "person.fill")
                .font(.system(size: 80))
                .foregroundStyle(.white.opacity(0.4))
        }
        .frame(width: size.width, height: size.height)
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

    @State private var isPressed = false

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
            .scaleEffect(isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
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
                                let safeMaxForMin = max( (viewModel.maxAge - 1), 18 )

                                Slider(
                                    value: Binding(
                                        get: { viewModel.minAge },
                                        set: { newValue in
                                            viewModel.minAge = newValue
                                        }
                                    ),
                                    in: 18...safeMaxForMin,
                                    step: 1
                                )
                                .tint(AppTheme.accent)


                            }
                            
                            VStack(alignment: .leading) {
                                Text("Max: \(Int(viewModel.maxAge))")
                                    .font(.caption)

                                let safeMinForMax = min( (viewModel.minAge + 1), 68 )

                                Slider(
                                    value: Binding(
                                        get: { viewModel.maxAge },
                                        set: { newValue in
                                            viewModel.maxAge = newValue
                                        }
                                    ),
                                    in: safeMinForMax...69,
                                    step: 1
                                )


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
                        .onChange(of: viewModel.verifiedOnly) { _, _ in
                            Haptics.selection()
                        }
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
    @Published var minAge: Double = 18 {
        didSet {
            if minAge >= maxAge {
                maxAge = minAge + 1
            }
        }
    }

    @Published var maxAge: Double = 100 {
        didSet {
            if maxAge <= minAge {
                minAge = maxAge - 1
            }
        }
    }

    @Published var verifiedOnly = false
    
    private let service = FirebaseService()
    private var swipedUserIds: Set<String> = []
    var filteredProfiles: [UserProfile] {
        profiles.filter { profile in
            
            // --- Age Filter ---
            if let age = profile.age {
                if age < Int(minAge) || age > Int(maxAge) {
                    return false
                }
            } else {
                return false
            }
            
            // --- Verified Filter ---
            if verifiedOnly {
                if profile.isVerified != true {
                    return false
                }
            }
            
            // --- Content Styles Filter ---
            if !selectedContentStyles.isEmpty {
                let profileStyles = Set(profile.contentStyles)
                if profileStyles.isDisjoint(with: selectedContentStyles) {
                    return false
                }
            }
            
            return true
        }
    }

    var currentProfile: UserProfile? {
        profiles.first
    }

    // This function loads discoverable profiles while excluding previously swiped profiles
    func loadProfiles(currentUserId: String, excludeSwipedProfiles: Bool = true) async {
        isLoading = true
        errorMessage = nil

        do {
            print("🏠 HOME: Starting profile load for user: \(currentUserId)")

            guard !currentUserId.isEmpty else {
                throw NSError(domain: "HomeViewModel", code: -1,
                             userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
            }

            guard let currentUser = try await service.fetchProfile(uid: currentUserId) else {
                throw NSError(domain: "HomeViewModel", code: -2,
                             userInfo: [NSLocalizedDescriptionKey: "User profile not found"])
            }

            // Only fetch swiped user IDs if we want to exclude them
            if excludeSwipedProfiles {
                // Fetch swiped user IDs from Firebase to ensure consistency across tabs
                let swipedIds = try await service.fetchSwipedUserIds(forUser: currentUserId)
                swipedUserIds = Set(swipedIds)
                print("🏠 HOME: Found \(swipedIds.count) swiped users to exclude")
            } else {
                // Reset to see all profiles again
                swipedUserIds.removeAll()
                print("🏠 HOME: Not excluding swiped profiles (refresh mode)")
            }

            // Fetch profiles from Firebase
            var fetched = try await service.fetchDiscoverProfiles(
                for: currentUser,
                limit: 50, // Fetch more to account for filtering
                excludeUserIds: Array(swipedUserIds)
            )
            print("🏠 HOME: Fetched \(fetched.count) profiles from Firebase")

            // Apply client-side filters
            let beforeFilters = fetched.count
            fetched = applyClientFilters(to: fetched)
            print("🏠 HOME: After client filters: \(beforeFilters) → \(fetched.count)")

            // Limit to 20 after filtering
            profiles = Array(fetched.prefix(20))
            print("🏠 HOME: Final profiles to display: \(profiles.count)")

            // Print each profile for debugging
            for (index, profile) in profiles.enumerated() {
                print("  [\(index + 1)] \(profile.displayName) (uid: \(profile.uid))")
            }

            // Fetch online status for all profiles
            if !profiles.isEmpty {
                let userIds = profiles.map { $0.uid }
                await PresenceManager.shared.fetchOnlineStatus(userIds: userIds)
            }

            isLoading = false
            print("✅ HOME: Loaded \(profiles.count) profiles for Home (exclude swiped: \(excludeSwipedProfiles))")

        } catch {
            isLoading = false
            profiles = []

            // Provide specific error messages based on error type
            if let nsError = error as NSError? {
                if nsError.domain == NSURLErrorDomain {
                    errorMessage = "No internet connection"
                } else if nsError.domain == "HomeViewModel" {
                    errorMessage = nsError.localizedDescription
                } else {
                    errorMessage = "Failed to load profiles"
                }
            } else {
                errorMessage = "Failed to load profiles"
            }

            // Don't auto-dismiss critical errors
            if errorMessage != "No internet connection" {
                try? await Task.sleep(nanoseconds: 5_000_000_000)
                errorMessage = nil
            }

            print("❌ Error loading profiles: \(error)")
        }
    }

    /// Apply client-side filters to profile list
    private func applyClientFilters(to profiles: [UserProfile]) -> [UserProfile] {
        
        var filtered = profiles
        print("🏠 FILTER: Starting with \(filtered.count) profiles")

        // Filter by age
        let beforeAge = filtered.count
        filtered = filtered.filter { profile in
            guard let age = profile.age else { return true }
            return Double(age) >= minAge && Double(age) <= maxAge
        }
        if beforeAge != filtered.count {
            print("🏠 FILTER: Age filter removed \(beforeAge - filtered.count) profiles (min: \(minAge), max: \(maxAge))")
        }

        // Filter by content styles
        if !selectedContentStyles.isEmpty {
            let beforeStyles = filtered.count
            filtered = filtered.filter { profile in
                !Set(profile.contentStyles).isDisjoint(with: selectedContentStyles)
            }
            if beforeStyles != filtered.count {
                print("🏠 FILTER: Content styles filter removed \(beforeStyles - filtered.count) profiles")
            }
        }

        // Filter by verified status
        if verifiedOnly {
            let beforeVerified = filtered.count
            filtered = filtered.filter { $0.isVerified == true }
            if beforeVerified != filtered.count {
                print("🏠 FILTER: Verified filter removed \(beforeVerified - filtered.count) profiles")
            }
        }

        print("🏠 FILTER: Final count: \(filtered.count) profiles")
        return filtered
    }
    
    func handleSwipe(profile: UserProfile, action: SwipeAction.Action) async {
        print("🏠 HOME SWIPE: User swiped \(action.rawValue) on \(profile.displayName)")
        print("🏠 HOME SWIPE: Profiles before removal: \(profiles.count)")

        guard let currentUserId = Auth.auth().currentUser?.uid else {
            errorMessage = "Please sign in to continue"
            return
        }

        // Optimistically update UI
        swipedUserIds.insert(profile.uid)
        print("🏠 HOME SWIPE: Total swiped users now: \(swipedUserIds.count)")

        let swipe = SwipeAction(
            userId: currentUserId,
            targetUserId: profile.uid,
            action: action,
            timestamp: Date()
        )

        // Add to history for undo
        let record = SwipeRecord(profile: profile, action: action, swipeData: swipe)
        swipeHistory.append(record)
        if swipeHistory.count > 10 {
            swipeHistory.removeFirst()
        }

        // Remove from UI immediately for smooth experience
        withAnimation(.spring(response: 0.3)) {
            profiles.removeAll { $0.id == profile.id }
        }

        print("🏠 HOME SWIPE: Profiles after removal: \(profiles.count)")
        print("🏠 HOME SWIPE: Remaining profiles:")
        for (index, p) in profiles.enumerated() {
            print("  [\(index + 1)] \(p.displayName)")
        }

        do {
            // Save swipe to Firebase
            try await service.recordSwipe(swipe)
            print("✅ Swipe recorded: \(action.rawValue) → \(profile.displayName)")

            // Check for match on likes
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
                    print("🎉 Match created with \(profile.displayName)")
                }
            }

            // Only load more profiles when we've run out completely
            // Don't auto-load if there are still cards to show, as this would replace the current stack
            if profiles.isEmpty {
                print("🏠 HOME AUTO-LOAD: No profiles remaining, loading more...")
                await loadProfiles(currentUserId: currentUserId)
            } else {
                print("🏠 HOME: \(profiles.count) profiles remaining in stack")
            }
        } catch {
            // Rollback on error
            swipedUserIds.remove(profile.uid)

            // Re-add profile to top of stack
            withAnimation(.spring(response: 0.3)) {
                profiles.insert(profile, at: 0)
            }

            // Remove from history
            swipeHistory.removeAll { $0.id == record.id }

            // Show error
            if let nsError = error as NSError?, nsError.domain == NSURLErrorDomain {
                errorMessage = "Connection lost - swipe not saved"
            } else {
                errorMessage = "Failed to save swipe"
            }

            try? await Task.sleep(nanoseconds: 3_000_000_000)
            errorMessage = nil

            print("❌ Error handling swipe: \(error)")
        }
    }
    
    func undoSwipe(_ record: SwipeRecord) async {
        guard let currentUserId = Auth.auth().currentUser?.uid,
              let swipeData = record.swipeData else {
            print("⚠️ Cannot undo: missing user ID or swipe data")
            return
        }

        // Optimistically update UI
        swipedUserIds.remove(record.profile.uid)
        swipeHistory.removeAll { $0.id == record.id }

        withAnimation(.spring(response: 0.3)) {
            profiles.insert(record.profile, at: 0)
        }

        Haptics.impact(.medium)

        do {
            // Remove swipe from Firebase
            try await service.deleteSwipe(
                userId: swipeData.userId,
                targetUserId: swipeData.targetUserId
            )
            print("✅ Swipe undone: \(record.profile.displayName)")
        } catch {
            // Rollback UI on error
            swipedUserIds.insert(record.profile.uid)
            swipeHistory.append(record)

            withAnimation(.spring(response: 0.3)) {
                profiles.removeAll { $0.id == record.profile.id }
            }

            errorMessage = "Failed to undo swipe"
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            errorMessage = nil

            print("❌ Error undoing swipe: \(error)")
        }
    }

    func refresh(currentUserId: String) async {
        swipedUserIds.removeAll()
        swipeHistory.removeAll()
        matchesToday = 0

        // Don't exclude swiped profiles on refresh - show all profiles again
        await loadProfiles(currentUserId: currentUserId, excludeSwipedProfiles: false)
    }

    func applyFilters() async {
        
    }
}

// MARK: - Swipe Record

struct SwipeRecord: Identifiable {
    let id = UUID()
    let profile: UserProfile
    let action: SwipeAction.Action
    let timestamp = Date()
    let swipeData: SwipeAction? // Store for undo functionality
}
