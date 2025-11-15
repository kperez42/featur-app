// EnhancedDiscoverView.swift - COMPLETE VERSION
import SwiftUI
import FirebaseAuth

struct EnhancedDiscoverView: View {
    @StateObject private var viewModel = DiscoverViewModel()
    @State private var selectedCategory: String?
    @State private var searchText = ""
    @State private var showFilterSheet = false
    @State private var showSortMenu = false
    @State private var scrollOffset: CGFloat = 0
    
    let featuredCategories = [
        "Twitch Streamers",
        "Music Collabs",
        "Podcast Guests",
        "Tiktok Lives"
    ]
    
    var body: some View {
        ZStack(alignment: .bottom) {
            AppTheme.bg.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Animated Hero Header
                    AnimatedHeroHeader()
                    
                    // Search Bar
                    EnhancedSearchBar(text: $searchText)
                        .onChange(of: searchText) { _ in
                            Task { await viewModel.search(query: searchText) }
                        }
                    
                    // Quick Stats
                    if !viewModel.isLoading {
                        quickStatsBar
                    }
                    
                    // Featured Categories Grid
                    featuredCategoriesGrid
                    
                    // Active Filters Display
                    if viewModel.hasActiveFilters {
                        activeFiltersView
                    }
                    
                    // Filter & Sort Bar
                    filterSortBar
                    
                    // Results Section
                    resultsSection
                    
                    // Load More Indicator
                    if viewModel.canLoadMore {
                        Button {
                            Task { await viewModel.loadMore() }
                        } label: {
                            if viewModel.isLoadingMore {
                                ProgressView()
                                    .tint(AppTheme.accent)
                            } else {
                                Text("Load More")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(AppTheme.accent)
                            }
                        }
                        .disabled(viewModel.isLoadingMore)
                        .opacity(viewModel.isLoadingMore ? 0.6 : 1)
                        .frame(height: 44)
                        .frame(maxWidth: .infinity)
                        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                    }

                }
                .padding(.bottom, 80)
            }
            
            // Floating Banner Ad
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
        .navigationTitle("Discover")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showFilterSheet = true
                    Haptics.impact(.light)
                } label: {
                    Image(systemName: viewModel.hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                        .foregroundStyle(viewModel.hasActiveFilters ? AppTheme.accent : .primary)
                }
            }
        }
        .sheet(isPresented: $showFilterSheet) {
            ImprovedFilterSheet(viewModel: viewModel)
        }
        .task {
            await viewModel.loadProfiles()
        }
        .refreshable {
            await viewModel.refresh()
            Haptics.notify(.success)
        }
    }
    
    // MARK: - Quick Stats Bar
    
    private var quickStatsBar: some View {
        HStack(spacing: 20) {
            StatPill(
                icon: "person.3.fill",
                value: "\(viewModel.totalProfiles)",
                label: "Creators"
            )
            
            StatPill(
                icon: "wifi",
                value: "\(viewModel.onlineCount)",
                label: "Online"
            )
            
            StatPill(
                icon: "sparkles",
                value: "\(viewModel.newTodayCount)",
                label: "New Today"
            )
        }
        .padding(.horizontal)
    }
    
    // MARK: - Featured Categories Grid
    
    private var featuredCategoriesGrid: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Popular Categories")
                    .font(.title3.bold())
                Spacer()
                NavigationLink("See All") {
                    AllCategoriesView()
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.accent)
            }
            .padding(.horizontal)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(featuredCategories, id: \.self) { category in
                    CategoryCard(
                        category: category,
                        icon: categoryIcon(for: category),
                        count: viewModel.categoryCount(for: category)
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedCategory = category
                            Task { await viewModel.filterByCategory(category) }
                        }
                        Haptics.impact(.medium)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Active Filters View
    
    private var activeFiltersView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Text("Active:")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                
                ForEach(viewModel.activeFilterTags, id: \.self) { tag in
                    FilterTag(text: tag) {
                        viewModel.removeFilter(tag)
                        Haptics.impact(.light)
                    }
                }
                
                Button {
                    withAnimation {
                        viewModel.clearAllFilters()
                        selectedCategory = nil
                    }
                    Haptics.impact(.rigid)
                } label: {
                    Text("Clear All")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.red)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.red.opacity(0.1), in: Capsule())
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Filter & Sort Bar
    
    private var filterSortBar: some View {
        HStack {
            // Content Style Pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(Array(UserProfile.ContentStyle.allCases.prefix(6)), id: \.self) { style in
                        let isSelected = selectedCategory == style.rawValue
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                if isSelected {
                                    selectedCategory = nil
                                    Task { await viewModel.filterByCategory(nil) }
                                } else {
                                    selectedCategory = style.rawValue
                                    Task { await viewModel.filterByCategory(style.rawValue) }
                                }
                            }
                            Haptics.impact(.light)
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: style.icon)
                                    .font(.caption)
                                Text(style.rawValue)
                                    .font(.caption.weight(.semibold))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(isSelected ? AppTheme.accent : AppTheme.card, in: Capsule())
                            .foregroundStyle(isSelected ? .white : .primary)
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            // Sort Menu
            Menu {
                Button {
                    viewModel.sortBy(.relevance)
                } label: {
                    Label("Relevance", systemImage: currentSort == .relevance ? "checkmark" : "")
                }
                
                Button {
                    viewModel.sortBy(.newest)
                } label: {
                    Label("Newest", systemImage: currentSort == .newest ? "checkmark" : "")
                }
                
                Button {
                    viewModel.sortBy(.distance)
                } label: {
                    Label("Nearby", systemImage: currentSort == .distance ? "checkmark" : "")
                }
            } label: {
                Image(systemName: "arrow.up.arrow.down.circle.fill")
                    .foregroundStyle(AppTheme.accent)
                    .imageScale(.large)
            }
            .padding(.trailing)
        }
    }
    
    private var currentSort: SortOption {
        viewModel.currentSort
    }
    
    // MARK: - Results Section
    
    private var resultsSection: some View {
        Group {
            if viewModel.isLoading {
                loadingView
            } else if viewModel.filteredProfiles.isEmpty {
                emptyState
            } else {
                profilesGrid
            }
        }
    }
    
    private var profilesGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            ForEach(viewModel.filteredProfiles) { profile in
                NavigationLink {
                    ProfileDetailPlaceholder(profile: profile)
                } label: {
                    DiscoverProfileCard(profile: profile)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal)
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(AppTheme.accent)
            
            Text("Finding creators...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            
            Text("No Creators Found")
                .font(.title2.bold())
            
            Text("Try adjusting your filters or search terms")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Button {
                withAnimation {
                    viewModel.clearAllFilters()
                    selectedCategory = nil
                    searchText = ""
                }
            } label: {
                Text("Clear Filters")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(width: 200, height: 50)
                    .background(AppTheme.accent, in: RoundedRectangle(cornerRadius: 25))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
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
    
    // MARK: - Helper
    
    private func categoryIcon(for category: String) -> String {
        switch category {
        case "Twitch Streamers": return "play.rectangle.fill"
        case "Music Collabs": return "music.note"
        case "Podcast Guests": return "mic.fill"
        case "Tiktok Lives": return "video.fill"
        default: return "star.fill"
        }
    }
}

// MARK: - Discover Profile Card

struct DiscoverProfileCard: View {
    let profile: UserProfile
    
    var body: some View {
        VStack(spacing: 0) {
            // Profile Image
            ZStack(alignment: .topTrailing) {
                if let firstMediaURL = (profile.mediaURLs ?? []).first {
                    AsyncImage(url: URL(string: firstMediaURL)) { phase in
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
                
                // Verified Badge
                if profile.isVerified ?? false {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(.blue)
                        .background(Circle().fill(.white).padding(2))
                        .padding(8)
                }
            }
            .frame(height: 200)
            .clipped()
            
            // Profile Info
            VStack(alignment: .leading, spacing: 6) {
                Text(profile.displayName)
                    .font(.headline)
                    .lineLimit(1)
                
                if let bio = profile.bio {
                    Text(bio)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                
                // Content Style Tag
                if let firstStyle = profile.contentStyles.first {
                    Text(firstStyle.rawValue)
                        .font(.caption2.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppTheme.accent.opacity(0.2), in: Capsule())
                        .foregroundStyle(AppTheme.accent)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
    }
}

// MARK: - Supporting Views

struct AnimatedHeroHeader: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            AppTheme.gradient
                .frame(height: 120)
                .overlay(
                    VStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 40))
                            .foregroundStyle(.white)
                            .scaleEffect(animate ? 1.2 : 1.0)
                            .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animate)
                        
                        Text("Discover Creators")
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .padding(.horizontal)
        }
        .onAppear { animate = true }
    }
}

struct EnhancedSearchBar: View {
    @Binding var text: String
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                
                TextField("Search creators...", text: $text)
                    .focused($isFocused)
                
                if !text.isEmpty {
                    Button {
                        text = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(12)
            .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 12))
        }
        .padding(.horizontal)
    }
}

struct StatPill: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text(value)
                    .font(.headline.bold())
            }
            .foregroundStyle(AppTheme.accent)
            
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct CategoryCard: View {
    let category: String
    let icon: String
    let count: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundStyle(AppTheme.accent)
                    Spacer()
                    Text("\(count)")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                }
                
                Text(category)
                    .font(.subheadline.bold())
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 100)
            .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
        }
    }
}

struct FilterTag: View {
    let text: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 6) {
            Text(text)
                .font(.caption.weight(.semibold))
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(AppTheme.accent.opacity(0.2), in: Capsule())
        .foregroundStyle(AppTheme.accent)
    }
}

// MARK: - Improved Filter Sheet

struct ImprovedFilterSheet: View {
    @ObservedObject var viewModel: DiscoverViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Content Styles Section
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
                    
                    // Distance Filter
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Maximum Distance")
                            .font(.headline)
                        
                        HStack {
                            Text("\(Int(viewModel.activeFilters.maxDistance)) miles")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            Spacer()
                            
                            if viewModel.activeFilters.maxDistance < 1000 {
                                Button("Any Distance") {
                                    viewModel.activeFilters.maxDistance = 1000
                                }
                                .font(.caption)
                                .foregroundStyle(AppTheme.accent)
                            }
                        }
                        
                        Slider(value: $viewModel.activeFilters.maxDistance, in: 1...1000, step: 5)
                            .tint(AppTheme.accent)
                    }
                    .padding()
                    .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
                    
                    // Quick Filters
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Quick Filters")
                            .font(.headline)
                        
                        Toggle("Verified Creators Only", isOn: $viewModel.activeFilters.verifiedOnly)
                        
                        Divider()
                        
                        Toggle("Currently Online", isOn: $viewModel.activeFilters.onlineOnly)
                    }
                    .padding()
                    .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
                    
                    // Collaboration Preferences
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Looking For")
                            .font(.headline)
                        
                        FlowLayout(spacing: 8) {
                            ForEach(UserProfile.CollaborationPreferences.CollabType.allCases, id: \.self) { type in
                                FilterChip(
                                    text: type.rawValue,
                                    isSelected: viewModel.selectedCollabTypes.contains(type)
                                ) {
                                    if viewModel.selectedCollabTypes.contains(type) {
                                        viewModel.selectedCollabTypes.remove(type)
                                    } else {
                                        viewModel.selectedCollabTypes.insert(type)
                                    }
                                }
                            }
                        }
                    }
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
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        Task {
                            await viewModel.applyAdvancedFilters()
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

// MARK: - All Categories View

struct AllCategoriesView: View {
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(UserProfile.ContentStyle.allCases, id: \.self) { style in
                    NavigationLink {
                        Text("Category: \(style.rawValue)")
                    } label: {
                        VStack {
                            Image(systemName: style.icon)
                                .font(.largeTitle)
                                .foregroundStyle(AppTheme.accent)
                            
                            Text(style.rawValue)
                                .font(.caption.bold())
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 100)
                        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .navigationTitle("All Categories")
        .background(AppTheme.bg)
    }
}

// MARK: - View Model

@MainActor
final class DiscoverViewModel: ObservableObject {
    @Published var allProfiles: [UserProfile] = []
    @Published var filteredProfiles: [UserProfile] = []
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var errorMessage: String?
    
    @Published var currentSort: SortOption = .relevance
    @Published var currentFilter: String?
    @Published var currentSearchQuery: String = ""
    
    @Published var activeFilters = DiscoverFilters()
    @Published var selectedContentStyles: Set<UserProfile.ContentStyle> = []
    @Published var selectedCollabTypes: Set<UserProfile.CollaborationPreferences.CollabType> = []
    
    private let service = FirebaseService()
    private var loadTask: Task<Void, Never>?
    private var currentPage = 0
    private let pageSize = 20
    
    var totalProfiles: Int { filteredProfiles.count }
    var onlineCount: Int { filteredProfiles.filter { $0.isOnline }.count }
    var newTodayCount: Int { filteredProfiles.filter { Calendar.current.isDateInToday($0.createdAt) }.count }
    
    var hasActiveFilters: Bool {
        !activeFilters.isEmpty || !selectedContentStyles.isEmpty || !selectedCollabTypes.isEmpty || currentFilter != nil
    }
    
    var activeFilterTags: [String] {
        var tags: [String] = []
        
        if activeFilters.verifiedOnly {
            tags.append("Verified")
        }
        
        if activeFilters.onlineOnly {
            tags.append("Online")
        }
        
        if activeFilters.maxDistance < 1000 {
            tags.append("Within \(Int(activeFilters.maxDistance))mi")
        }
        
        tags.append(contentsOf: selectedContentStyles.map { $0.rawValue })
        tags.append(contentsOf: selectedCollabTypes.map { $0.rawValue })
        
        return tags
    }
    
    var canLoadMore: Bool {
        filteredProfiles.count >= pageSize && !isLoadingMore
    }
    
    func loadProfiles() async {
        loadTask?.cancel()

        loadTask = Task {
            guard !Task.isCancelled else { return }

            isLoading = true
            errorMessage = nil
            currentPage = 0

            do {
                //  Step 1: Get current user ID from Firebase Auth
                guard let currentUserId = Auth.auth().currentUser?.uid else {
                    print(" No logged-in user found")
                    isLoading = false
                    return
                }

                //  Step 2: Fetch the user's profile from Firestore
                guard let currentUser = try await service.fetchProfile(uid: currentUserId) else {
                    print(" Could not fetch current user profile")
                    isLoading = false
                    return
                }

                //  Step 2.5: Fetch swiped user IDs to exclude them from discovery
                let swipedUserIds = try await service.fetchSwipedUserIds(forUser: currentUserId)

                //  Step 3: Fetch discoverable profiles using that user
                allProfiles = try await service.fetchDiscoverProfiles(for: currentUser, limit: pageSize, excludeUserIds: swipedUserIds)

                guard !Task.isCancelled else { return }

                // Step 4: Apply filters & finish
                applyFilters()
                isLoading = false

            } catch {
                guard !Task.isCancelled else { return }

                isLoading = false
                allProfiles = []
                filteredProfiles = []

                errorMessage = "Unable to load profiles. Please check your connection."

                try? await Task.sleep(nanoseconds: 5_000_000_000)
                if !Task.isCancelled {
                    errorMessage = nil
                }

                print("❌ Error loading profiles: \(error.localizedDescription)")
            }
        }
    }


    /**
    #if DEBUG
    // MARK: - 🧪 TEST DATA
    func loadTestProfiles() {
        allProfiles = [
            UserProfile(
                id: "discover1",
                uid: "discover1",
                displayName: "Emma Rodriguez",
                age: 23,
                bio: "Travel vlogger ✈️ Exploring the world one video at a time!",
                location: UserProfile.Location(city: "Austin", state: "TX", country: "USA", coordinates: nil),
                interests: ["Travel", "Photography", "Lifestyle"],
                contentStyles: [.fashion, .art],
                socialLinks: UserProfile.SocialLinks(
                    tiktok: UserProfile.SocialLinks.SocialAccount(username: "@emmatravels", followerCount: 89000, isVerified: false),
                    instagram: UserProfile.SocialLinks.SocialAccount(username: "@emmaontheroad", followerCount: 52000, isVerified: true),
                    youtube: UserProfile.SocialLinks.SocialAccount(username: "@EmmaRodriguez", followerCount: 145000, isVerified: true),
                    twitch: nil, spotify: nil, snapchat: nil
                ),
                mediaURLs: [],
                isVerified: true,
                followerCount: 89000,
                collaborationPreferences: UserProfile.CollaborationPreferences(
                    lookingFor: [.contentSeries, .brandDeal],
                    availability: [.flexible],
                    responseTime: .fast
                ),
                createdAt: Date().addingTimeInterval(-86400 * 30),
                updatedAt: Date()
            ),
            UserProfile(
                id: "discover2",
                uid: "discover2",
                displayName: "Jake Morrison",
                age: 27,
                bio: "Tech reviewer 📱 Latest gadgets and honest reviews!",
                location: UserProfile.Location(city: "Seattle", state: "WA", country: "USA", coordinates: nil),
                interests: ["Technology", "Gaming", "Reviews"],
                contentStyles: [.tech, .gaming],
                socialLinks: UserProfile.SocialLinks(
                    tiktok: UserProfile.SocialLinks.SocialAccount(username: "@jaketech", followerCount: 210000, isVerified: true),
                    instagram: nil,
                    youtube: UserProfile.SocialLinks.SocialAccount(username: "@JakeMorrisonTech", followerCount: 380000, isVerified: true),
                    twitch: UserProfile.SocialLinks.SocialAccount(username: "jaketech", followerCount: 45000, isVerified: false),
                    spotify: nil, snapchat: nil
                ),
                mediaURLs: [],
                isVerified: true,
                followerCount: 210000,
                collaborationPreferences: UserProfile.CollaborationPreferences(
                    lookingFor: [.brandDeal, .twitchStream, .contentSeries],
                    availability: [.weekdays, .weekends],
                    responseTime: .moderate
                ),
                createdAt: Date().addingTimeInterval(-86400 * 60),
                updatedAt: Date()
            ),
            UserProfile(
                id: "discover3",
                uid: "discover3",
                displayName: "Sophia Lee",
                age: 21,
                bio: "Dance & choreography 💃 Let's create something amazing!",
                location: UserProfile.Location(city: "Los Angeles", state: "CA", country: "USA", coordinates: nil),
                interests: ["Dance", "Music", "Fitness"],
                contentStyles: [.dance, .music, .fitness],
                socialLinks: UserProfile.SocialLinks(
                    tiktok: UserProfile.SocialLinks.SocialAccount(username: "@sophiadance", followerCount: 675000, isVerified: true),
                    instagram: UserProfile.SocialLinks.SocialAccount(username: "@sophialee", followerCount: 320000, isVerified: true),
                    youtube: UserProfile.SocialLinks.SocialAccount(username: "@SophiaLeeChoreography", followerCount: 150000, isVerified: true),
                    twitch: nil, spotify: nil, snapchat: nil
                ),
                mediaURLs: [],
                isVerified: true,
                followerCount: 675000,
                collaborationPreferences: UserProfile.CollaborationPreferences(
                    lookingFor: [.musicCollab, .tiktokLive, .contentSeries],
                    availability: [.flexible],
                    responseTime: .fast
                ),
                createdAt: Date(),
                updatedAt: Date()
            ),
            UserProfile(
                id: "discover4",
                uid: "discover4",
                displayName: "Michael Chen",
                age: 29,
                bio: "Comedy & sketches 😂 Making people laugh daily!",
                location: UserProfile.Location(city: "Chicago", state: "IL", country: "USA", coordinates: nil),
                interests: ["Comedy", "Acting", "Writing"],
                contentStyles: [.comedy, .editing],
                socialLinks: UserProfile.SocialLinks(
                    tiktok: UserProfile.SocialLinks.SocialAccount(username: "@michaelcomedy", followerCount: 420000, isVerified: true),
                    instagram: UserProfile.SocialLinks.SocialAccount(username: "@mikechencomedy", followerCount: 185000, isVerified: false),
                    youtube: UserProfile.SocialLinks.SocialAccount(username: "@MichaelChenComedy", followerCount: 290000, isVerified: true),
                    twitch: nil, spotify: nil, snapchat: nil
                ),
                mediaURLs: [],
                isVerified: true,
                followerCount: 420000,
                collaborationPreferences: UserProfile.CollaborationPreferences(
                    lookingFor: [.contentSeries, .podcastGuest],
                    availability: [.weekends],
                    responseTime: .moderate
                ),
                createdAt: Date().addingTimeInterval(-86400 * 45),
                updatedAt: Date()
            ),
            UserProfile(
                id: "discover5",
                uid: "discover5",
                displayName: "Olivia Martinez",
                age: 25,
                bio: "Pet content creator 🐾 Dogs, cats, and everything cute!",
                location: UserProfile.Location(city: "Denver", state: "CO", country: "USA", coordinates: nil),
                interests: ["Pets", "Animals", "Lifestyle"],
                contentStyles: [.pet, .comedy],
                socialLinks: UserProfile.SocialLinks(
                    tiktok: UserProfile.SocialLinks.SocialAccount(username: "@oliviapets", followerCount: 550000, isVerified: true),
                    instagram: UserProfile.SocialLinks.SocialAccount(username: "@oliviaandpets", followerCount: 380000, isVerified: true),
                    youtube: UserProfile.SocialLinks.SocialAccount(username: "@OliviaPetLife", followerCount: 205000, isVerified: true),
                    twitch: nil, spotify: nil, snapchat: nil
                ),
                mediaURLs: [],
                isVerified: true,
                followerCount: 550000,
                collaborationPreferences: UserProfile.CollaborationPreferences(
                    lookingFor: [.brandDeal, .contentSeries],
                    availability: [.flexible],
                    responseTime: .fast
                ),
                createdAt: Date().addingTimeInterval(-86400 * 15),
                updatedAt: Date()
            ),
            UserProfile(
                id: "discover6",
                uid: "discover6",
                displayName: "David Park",
                age: 26,
                bio: "Sports content & commentary ⚽ Game highlights and analysis!",
                location: UserProfile.Location(city: "Boston", state: "MA", country: "USA", coordinates: nil),
                interests: ["Sports", "Fitness", "Gaming"],
                contentStyles: [.sports, .gaming],
                socialLinks: UserProfile.SocialLinks(
                    tiktok: UserProfile.SocialLinks.SocialAccount(username: "@davidsports", followerCount: 98000, isVerified: false),
                    instagram: UserProfile.SocialLinks.SocialAccount(username: "@davidparksp", followerCount: 75000, isVerified: false),
                    youtube: UserProfile.SocialLinks.SocialAccount(username: "@DavidParkSports", followerCount: 175000, isVerified: true),
                    twitch: UserProfile.SocialLinks.SocialAccount(username: "davidparksports", followerCount: 32000, isVerified: false),
                    spotify: nil, snapchat: nil
                ),
                mediaURLs: [],
                isVerified: false,
                followerCount: 98000,
                collaborationPreferences: UserProfile.CollaborationPreferences(
                    lookingFor: [.twitchStream, .podcastGuest],
                    availability: [.weekends],
                    responseTime: .slow
                ),
                createdAt: Date().addingTimeInterval(-86400 * 90),
                updatedAt: Date()
            ),
            UserProfile(
                id: "discover7",
                uid: "discover7",
                displayName: "Isabella Santos",
                age: 24,
                bio: "Makeup artist & tutorials 💄 Glam looks and everyday beauty!",
                location: UserProfile.Location(city: "Miami", state: "FL", country: "USA", coordinates: nil),
                interests: ["Beauty", "Fashion", "Photography"],
                contentStyles: [.beauty, .fashion],
                socialLinks: UserProfile.SocialLinks(
                    tiktok: UserProfile.SocialLinks.SocialAccount(username: "@isabellamakeup", followerCount: 780000, isVerified: true),
                    instagram: UserProfile.SocialLinks.SocialAccount(username: "@isabellasantos", followerCount: 620000, isVerified: true),
                    youtube: UserProfile.SocialLinks.SocialAccount(username: "@IsabellaSantosBeauty", followerCount: 340000, isVerified: true),
                    twitch: nil, spotify: nil, snapchat: nil
                ),
                mediaURLs: [],
                isVerified: true,
                followerCount: 780000,
                collaborationPreferences: UserProfile.CollaborationPreferences(
                    lookingFor: [.brandDeal, .tiktokLive, .contentSeries],
                    availability: [.flexible],
                    responseTime: .fast
                ),
                createdAt: Date(),
                updatedAt: Date()
            ),
            UserProfile(
                id: "discover8",
                uid: "discover8",
                displayName: "Ryan Kim",
                age: 28,
                bio: "Fitness coach & nutrition 💪 Helping you reach your goals!",
                location: UserProfile.Location(city: "San Diego", state: "CA", country: "USA", coordinates: nil),
                interests: ["Fitness", "Health", "Nutrition"],
                contentStyles: [.fitness, .cooking],
                socialLinks: UserProfile.SocialLinks(
                    tiktok: UserProfile.SocialLinks.SocialAccount(username: "@ryanfitcoach", followerCount: 340000, isVerified: true),
                    instagram: UserProfile.SocialLinks.SocialAccount(username: "@ryankimfit", followerCount: 290000, isVerified: true),
                    youtube: UserProfile.SocialLinks.SocialAccount(username: "@RyanKimFitness", followerCount: 185000, isVerified: true),
                    twitch: nil, spotify: nil, snapchat: nil
                ),
                mediaURLs: [],
                isVerified: true,
                followerCount: 340000,
                collaborationPreferences: UserProfile.CollaborationPreferences(
                    lookingFor: [.brandDeal, .contentSeries],
                    availability: [.weekdays],
                    responseTime: .moderate
                ),
                createdAt: Date().addingTimeInterval(-86400 * 20),
                updatedAt: Date()
            )
        ]
        filteredProfiles = allProfiles
    }
    #endif
    */
    func loadMore() async {
        guard !isLoadingMore else { return }
        
        isLoadingMore = true
        currentPage += 1
        
        do {
            // You can optionally pass the current user for consistency
            guard let currentUserId = Auth.auth().currentUser?.uid,
                  let currentUser = try await service.fetchProfile(uid: currentUserId) else {
                print("⚠️ Missing current user while loading more profiles.")
                isLoadingMore = false
                return
            }

            // ✅ Fetch more profiles (real Firestore data)
            let newProfiles = try await service.fetchDiscoverProfiles(for: currentUser, limit: pageSize)
            allProfiles.append(contentsOf: newProfiles)
            applyFilters()
        } catch {
            print("❌ Error loading more: \(error)")
        }
        
        isLoadingMore = false
    }

    func refresh() async {
        await loadProfiles()
    }
    
    func filterByCategory(_ category: String?) async {
        currentFilter = category
        applyFilters()
    }
    
    func search(query: String) async {
        currentSearchQuery = query
        
        if !query.isEmpty {
            do {
                let results = try await service.searchProfiles(
                    query: query,
                    filters: currentFilter.map { [$0] }
                )
                filteredProfiles = results
                applySorting()
            } catch {
                errorMessage = "Search failed"
            }
        } else {
            applyFilters()
        }
    }
    
    func sortBy(_ option: SortOption) {
        currentSort = option
        applySorting()
    }
    
    func applyAdvancedFilters() async {
        applyFilters()
    }
    
    func clearAllFilters() {
        activeFilters = DiscoverFilters()
        selectedContentStyles.removeAll()
        selectedCollabTypes.removeAll()
        currentFilter = nil
        currentSearchQuery = ""
        applyFilters()
    }
    
    func removeFilter(_ tag: String) {
        if tag == "Verified" {
            activeFilters.verifiedOnly = false
        } else if tag == "Online" {
            activeFilters.onlineOnly = false
        } else if tag.contains("Within") {
            activeFilters.maxDistance = 1000
        } else if let style = UserProfile.ContentStyle.allCases.first(where: { $0.rawValue == tag }) {
            selectedContentStyles.remove(style)
        } else if let collabType = UserProfile.CollaborationPreferences.CollabType.allCases.first(where: { $0.rawValue == tag }) {
            selectedCollabTypes.remove(collabType)
        }
        
        applyFilters()
    }
    
    func categoryCount(for category: String) -> Int {
        allProfiles.filter { profile in
            profile.contentStyles.contains { $0.rawValue.lowercased().contains(category.lowercased()) }
        }.count
    }
    
    private func applyFilters() {
        var results = allProfiles
        
        if let filter = currentFilter {
            results = results.filter { profile in
                profile.contentStyles.contains { $0.rawValue == filter }
            }
        }
        
        if !selectedContentStyles.isEmpty {
            results = results.filter { profile in
                !Set(profile.contentStyles).isDisjoint(with: selectedContentStyles)
            }
        }
        
        if !selectedCollabTypes.isEmpty {
            results = results.filter { profile in
                !Set(profile.collaborationPreferences?.lookingFor ?? [])
                    .isDisjoint(with: Set(selectedCollabTypes ?? []))
            }
        }
        
        if !currentSearchQuery.isEmpty {
            results = results.filter { profile in
                profile.displayName.localizedCaseInsensitiveContains(currentSearchQuery) ||
                profile.bio?.localizedCaseInsensitiveContains(currentSearchQuery) == true ||
                !currentSearchQuery.isEmpty && (profile.interests ?? []).contains {
                    $0.localizedCaseInsensitiveContains(currentSearchQuery)
                }
            }
        }
        
        if activeFilters.verifiedOnly {
            results = results.filter { $0.isVerified ?? false }
        }
        
        if activeFilters.onlineOnly {
            results = results.filter { $0.isOnline }
        }
        
        if activeFilters.maxDistance < 1000 {
            results = results.filter { profile in
                profile.location?.isNearby ?? false
            }
        }
        
        filteredProfiles = results
        applySorting()
    }
    
    private func applySorting() {
        switch currentSort {
        case .relevance:
            break
        case .distance:
            filteredProfiles.sort { ($0.location?.isNearby ?? false) && !($1.location?.isNearby ?? false) }
        case .followers:
            filteredProfiles.sort { ($0.followerCount ?? 0) > ($1.followerCount ?? 0) }
        case .newest:
            filteredProfiles.sort { $0.createdAt > $1.createdAt }
        }
    }
}

// MARK: - Supporting Types

enum SortOption {
    case relevance, distance, followers, newest
}

struct DiscoverFilters {
    var maxDistance: Double = 1000
    var verifiedOnly: Bool = false
    var onlineOnly: Bool = false
    
    var isEmpty: Bool {
        maxDistance >= 1000 &&
        !verifiedOnly &&
        !onlineOnly
    }
    
    mutating func removeAll() {
        maxDistance = 1000
        verifiedOnly = false
        onlineOnly = false
    }
}

// MARK: - Extensions
// Note: Extensions for UserProfile and UserProfile.ContentStyle are in UserProfile+Extensions.swift
