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
    @State private var selectedProfile: UserProfile?

    let featuredCategories = [
        "Music",
        "Video Games",
        "Art",
        "Cooking"
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
            // Track screen view
            AnalyticsManager.shared.trackScreenView(screenName: "Discover", screenClass: "EnhancedDiscoverView")

            // Don't exclude swiped profiles on Discover page - show everyone
            await viewModel.loadProfiles(excludeSwipedProfiles: false)
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

                            // Track analytics
                            AnalyticsManager.shared.trackFilterApplied(
                                filterType: "category",
                                value: category
                            )
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
                DiscoverProfileCard(profile: profile)
                    .contentShape(RoundedRectangle(cornerRadius: 16))
                    .onTapGesture {
                        Haptics.impact(.light)
                        selectedProfile = profile
                        // Track profile view analytics
                        AnalyticsManager.shared.trackProfileView(
                            userId: profile.uid,
                            source: "discover"
                        )
                    }
            }
        }
        .padding(.horizontal)
        .sheet(item: $selectedProfile) { profile in
            ProfileDetailViewSimple(profile: profile)
                .interactiveDismissDisabled(false)
        }
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
                Haptics.impact(.medium)
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
                    await viewModel.loadProfiles()
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
    
    // MARK: - Helper
    
    private func categoryIcon(for category: String) -> String {
        switch category {
        case "Music": return "music.note"
        case "Video Games": return "gamecontroller.fill"
        case "Art": return "paintbrush.fill"
        case "Cooking": return "fork.knife"
        default: return "star.fill"
        }
    }
}

// MARK: - Discover Profile Card

struct DiscoverProfileCard: View {
    let profile: UserProfile
    @State private var currentImageIndex = 0
    @State private var isPressed = false

    // Fixed card dimensions for consistency
    private let cardWidth: CGFloat = UIScreen.main.bounds.width / 2 - 24
    private let imageHeight: CGFloat = 200
    private let infoMinHeight: CGFloat = 90

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
        VStack(spacing: 0) {
            // Profile Image with Carousel
            ZStack(alignment: .topTrailing) {
                if !mediaURLs.isEmpty {
                    let currentURL = mediaURLs[safeCurrentIndex]
                    CachedAsyncImage(url: URL(string: currentURL)) { image in
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: cardWidth, height: imageHeight)
                            .clipped()
                    } placeholder: {
                        ZStack {
                            AppTheme.gradient
                            ProgressView()
                                .tint(.white)
                        }
                        .frame(width: cardWidth, height: imageHeight)
                    }
                    .frame(width: cardWidth, height: imageHeight)
                    .clipped()
                    .id(safeCurrentIndex) // Force reload when index changes
                } else {
                    // Fallback placeholder with fixed dimensions
                    ZStack {
                        AppTheme.gradient
                        Image(systemName: "person.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    .frame(width: cardWidth, height: imageHeight)
                }

                // Image Indicators (dots)
                if hasMultipleImages {
                    VStack {
                        HStack(spacing: 4) {
                            ForEach(0..<mediaURLs.count, id: \.self) { index in
                                Circle()
                                    .fill(index == safeCurrentIndex ? .white : .white.opacity(0.5))
                                    .frame(width: 6, height: 6)
                            }
                        }
                        .padding(8)
                        .background(.black.opacity(0.3), in: Capsule())
                        .padding(.top, 8)

                        Spacer()
                    }
                }

                // Verified Badge
                if profile.isVerified ?? false {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(.blue)
                        .background(Circle().fill(.white).padding(2))
                        .padding(8)
                }
            }
            .frame(width: cardWidth, height: imageHeight)
            .clipped()
            .contentShape(Rectangle())
            .overlay(
                // Image Navigation Areas (tap left/right)
                HStack(spacing: 0) {
                    if hasMultipleImages {
                        // Left tap area
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    currentImageIndex = max(0, currentImageIndex - 1)
                                }
                                Haptics.impact(.light)
                            }

                        // Right tap area
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
            )

            // Profile Info - Fixed minimum height for consistency
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text(profile.displayName)
                        .font(.headline)
                        .lineLimit(1)

                    Spacer(minLength: 0)

                    // Online Status Badge
                    if PresenceManager.shared.isOnline(userId: profile.uid) {
                        HStack(spacing: 3) {
                            Circle()
                                .fill(.green)
                                .frame(width: 6, height: 6)
                            Text("Online")
                                .font(.caption2.bold())
                                .foregroundStyle(.green)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(.green.opacity(0.15), in: Capsule())
                    }
                }

                Text(profile.bio ?? " ")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Content Style Tag - always show space even if no style
                if let firstStyle = profile.contentStyles.first {
                    Text(firstStyle.rawValue)
                        .font(.caption2.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppTheme.accent.opacity(0.2), in: Capsule())
                        .foregroundStyle(AppTheme.accent)
                } else {
                    // Invisible placeholder to maintain consistent height
                    Text(" ")
                        .font(.caption2.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .opacity(0)
                }
            }
            .padding(12)
            .frame(width: cardWidth, minHeight: infoMinHeight, alignment: .topLeading)
        }
        .frame(width: cardWidth)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .onChange(of: mediaURLs.count) { newCount in
            // Reset index if it's out of bounds after mediaURLs changes
            if currentImageIndex >= newCount && newCount > 0 {
                currentImageIndex = newCount - 1
            }
        }
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
    private var searchTask: Task<Void, Never>?
    private var currentPage = 0
    private let pageSize = 20

    // Search optimization
    private var searchCache: [String: (results: [UserProfile], timestamp: Date)] = [:]
    private let cacheValidityDuration: TimeInterval = 300 // 5 minutes
    
    var totalProfiles: Int { filteredProfiles.count }
    var onlineCount: Int {
        filteredProfiles.filter { profile in
            PresenceManager.shared.isOnline(userId: profile.uid)
        }.count
    }
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
    
    func loadProfiles(excludeSwipedProfiles: Bool = true) async {
        loadTask?.cancel()

        loadTask = Task {
            guard !Task.isCancelled else { return }

            isLoading = true
            errorMessage = nil
            currentPage = 0

            do {
                //  Step 1: Get current user ID from Firebase Auth
                guard let currentUserId = Auth.auth().currentUser?.uid else {
                    throw NSError(domain: "DiscoverViewModel", code: -1,
                                 userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
                }

                //  Step 2: Fetch the user's profile from Firestore
                guard let currentUser = try await service.fetchProfile(uid: currentUserId) else {
                    throw NSError(domain: "DiscoverViewModel", code: -2,
                                 userInfo: [NSLocalizedDescriptionKey: "User profile not found"])
                }

                //  Step 2.5: Fetch swiped user IDs to exclude them from discovery (only if requested)
                var swipedUserIds: [String] = []
                if excludeSwipedProfiles {
                    swipedUserIds = try await service.fetchSwipedUserIds(forUser: currentUserId)
                }

                //  Step 3: Fetch discoverable profiles using that user
                allProfiles = try await service.fetchDiscoverProfiles(for: currentUser, limit: 100, excludeUserIds: swipedUserIds)

                guard !Task.isCancelled else { return }

                // Step 3.5: Fetch online status for all profiles
                if !allProfiles.isEmpty {
                    let userIds = allProfiles.map { $0.uid }
                    await PresenceManager.shared.fetchOnlineStatus(userIds: userIds)
                }

                // Step 4: Apply filters & finish
                applyFilters()
                isLoading = false

                print("✅ Loaded \(filteredProfiles.count) profiles for Discover")

            } catch {
                guard !Task.isCancelled else { return }

                isLoading = false
                allProfiles = []
                filteredProfiles = []

                // Provide specific error messages based on error type
                if let nsError = error as NSError? {
                    if nsError.domain == NSURLErrorDomain {
                        errorMessage = "No internet connection"
                    } else if nsError.domain == "DiscoverViewModel" {
                        errorMessage = nsError.localizedDescription
                    } else {
                        errorMessage = "Failed to load creators"
                    }
                } else {
                    errorMessage = "Failed to load creators"
                }

                // Don't auto-dismiss critical errors
                if errorMessage != "No internet connection" {
                    try? await Task.sleep(nanoseconds: 5_000_000_000)
                    if !Task.isCancelled {
                        errorMessage = nil
                    }
                }

                print("❌ Error loading profiles: \(error.localizedDescription)")
            }
        }
    }


    func loadMore() async {
        guard !isLoadingMore else { return }

        isLoadingMore = true
        currentPage += 1

        do {
            guard let currentUserId = Auth.auth().currentUser?.uid else {
                errorMessage = "Please sign in to continue"
                isLoadingMore = false
                return
            }

            guard let currentUser = try await service.fetchProfile(uid: currentUserId) else {
                errorMessage = "User profile not found"
                isLoadingMore = false
                return
            }

            // Don't exclude swiped profiles on Discover page - show everyone
            // Fetch more profiles
            let newProfiles = try await service.fetchDiscoverProfiles(
                for: currentUser,
                limit: 50,
                excludeUserIds: [] // Empty - don't exclude swiped profiles
            )

            // Fetch online status for new profiles
            if !newProfiles.isEmpty {
                let userIds = newProfiles.map { $0.uid }
                await PresenceManager.shared.fetchOnlineStatus(userIds: userIds)

                // Add new profiles to existing list
                allProfiles.append(contentsOf: newProfiles)
                applyFilters()

                print("✅ Loaded \(newProfiles.count) more profiles")
            }

        } catch {
            if let nsError = error as NSError?, nsError.domain == NSURLErrorDomain {
                errorMessage = "Connection lost"
            } else {
                errorMessage = "Failed to load more"
            }

            try? await Task.sleep(nanoseconds: 3_000_000_000)
            errorMessage = nil

            print("❌ Error loading more: \(error)")
        }

        isLoadingMore = false
    }

    func refresh() async {
        // On refresh, show all profiles again including previously swiped ones
        await loadProfiles(excludeSwipedProfiles: false)
    }
    
    func filterByCategory(_ category: String?) async {
        currentFilter = category
        applyFilters()
    }
    
    func search(query: String) async {
        // Cancel any existing search task (debouncing)
        searchTask?.cancel()

        currentSearchQuery = query

        // If query is empty, show all profiles with filters
        if query.isEmpty {
            applyFilters()
            return
        }

        // Minimum query length
        guard query.count >= 2 else {
            filteredProfiles = []
            return
        }

        searchTask = Task {
            // Debounce: wait 300ms before searching
            try? await Task.sleep(nanoseconds: 300_000_000)

            guard !Task.isCancelled else { return }

            // Check cache first
            let cacheKey = "\(query)_\(currentFilter ?? "")"
            if let cached = searchCache[cacheKey],
               Date().timeIntervalSince(cached.timestamp) < cacheValidityDuration {
                print("✅ Using cached search results for '\(query)'")
                filteredProfiles = cached.results
                applySorting()
                return
            }

            // Perform search
            do {
                let results = try await service.searchProfiles(
                    query: query,
                    filters: currentFilter.map { [$0] }
                )

                guard !Task.isCancelled else { return }

                // Cache the results
                searchCache[cacheKey] = (results, Date())

                // Limit cache size to prevent memory issues
                if searchCache.count > 20 {
                    // Remove oldest entries
                    let sortedKeys = searchCache.keys.sorted {
                        searchCache[$0]!.timestamp < searchCache[$1]!.timestamp
                    }
                    for key in sortedKeys.prefix(5) {
                        searchCache.removeValue(forKey: key)
                    }
                }

                filteredProfiles = results
                applySorting()

                // Track analytics
                await AnalyticsManager.shared.trackSearch(query: query, resultsCount: results.count)

                print("✅ Search completed: \(results.count) results for '\(query)'")

            } catch {
                guard !Task.isCancelled else { return }
                errorMessage = "Search failed"
                print("❌ Search error: \(error)")
            }
        }
    }

    /// Clear the search cache (useful when data changes)
    func clearSearchCache() {
        searchCache.removeAll()
        print("🗑️ Search cache cleared")
    }
    
    func sortBy(_ option: SortOption) {
        currentSort = option
        applySorting()

        // Track analytics
        let sortValue: String
        switch option {
        case .relevance: sortValue = "relevance"
        case .distance: sortValue = "distance"
        case .followers: sortValue = "followers"
        case .newest: sortValue = "newest"
        }
        AnalyticsManager.shared.trackFilterApplied(filterType: "sort", value: sortValue)
    }

    func applyAdvancedFilters() async {
        applyFilters()

        // Track analytics for advanced filters
        if activeFilters.verifiedOnly {
            AnalyticsManager.shared.trackFilterApplied(filterType: "verified", value: "true")
        }
        if activeFilters.onlineOnly {
            AnalyticsManager.shared.trackFilterApplied(filterType: "online", value: "true")
        }
        if activeFilters.maxDistance < 1000 {
            AnalyticsManager.shared.trackFilterApplied(filterType: "distance", value: "\(Int(activeFilters.maxDistance))mi")
        }
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
            matchesCategory(profile: profile, category: category)
        }.count
    }

    private func matchesCategory(profile: UserProfile, category: String) -> Bool {
        // Match by content style
        return profile.contentStyles.contains { $0.rawValue == category }
    }
    
    private func applyFilters() {
        var results = allProfiles

        if let filter = currentFilter {
            results = results.filter { profile in
                matchesCategory(profile: profile, category: filter)
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
            results = results.filter { profile in
                PresenceManager.shared.isOnline(userId: profile.uid)
            }
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
