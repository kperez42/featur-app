// EnhancedDiscoverView.swift
import SwiftUI

struct EnhancedDiscoverView: View {
    @StateObject private var viewModel = DiscoverViewModel()
    @EnvironmentObject var adManager: AdManager
    @State private var selectedCategory: String?
    @State private var searchText = ""
    @State private var showFilterSheet = false
    
    let featuredCategories = [
        "Twitch Streamers",
        "Music Collabs",
        "Podcast Guests",
        "Tiktok Lives"
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 20) {
                    // Hero Header
                    heroHeader
                    
                    // Search Bar
                    SearchBar(text: $searchText, placeholder: "Search creators")
                        .onChange(of: searchText) { _ in
                            Task { await viewModel.search(query: searchText) }
                        }
                    
                    // Featured Categories
                    featuredSection
                    
                    // Filter Chips
                    filterChipsSection
                    
                    // Results Grid
                    resultsSection
                }
                .padding(.bottom, 24)
            }
            
            // Banner Ad at Bottom
            adManager.createBannerView()
                .frame(height: 50)
                .background(AppTheme.card)
                .shadow(color: .black.opacity(0.1), radius: 4, y: -2)
        }
        .background(AppTheme.bg.ignoresSafeArea())
        .navigationTitle("Discover")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showFilterSheet = true
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .foregroundStyle(AppTheme.accent)
                }
            }
        }
        .sheet(isPresented: $showFilterSheet) {
            AdvancedFilterSheet(
                selectedFilters: $viewModel.activeFilters,
                onApply: {
                    Task {
                        await viewModel.applyAdvancedFilters()
                    }
                }
            )
        }
        .task {
            await viewModel.loadProfiles()
        }
        .refreshable {
            await viewModel.loadProfiles()
        }
    }
    
    // MARK: - Components
    
    private var heroHeader: some View {
        ZStack(alignment: .bottomLeading) {
            AppTheme.gradient
                .frame(height: 140)
                .clipShape(RoundedRectangle(cornerRadius: 22))
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Discover Your Next Collab")
                    .font(.title2.bold())
                Text("Find creators with similar interests")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
            }
            .padding(16)
        }
        .foregroundStyle(.white)
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    private var featuredSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Featured")
                    .font(.headline)
                Spacer()
                Button("See All") {
                    // Navigate to all featured
                }
                .font(.caption)
                .foregroundStyle(AppTheme.accent)
            }
            .padding(.horizontal)
            
            ForEach(featuredCategories, id: \.self) { category in
                NavigationLink(destination: CategoryDetailView(category: category, viewModel: viewModel)) {
                    GlassCard {
                        HStack {
                            Image(systemName: categoryIcon(for: category))
                                .font(.title3)
                                .foregroundStyle(AppTheme.accent)
                                .frame(width: 40)
                            
                            Text(category)
                                .font(.subheadline.bold())
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal)
        }
    }
    
    private var filterChipsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Filters")
                    .font(.headline)
                    .padding(.horizontal)
                
                Spacer()
                
                // ✅ Fixed: Check if filters are active
                if !viewModel.activeFilters.isEmpty {
                    Button("Clear All") {
                        withAnimation {
                            selectedCategory = nil
                            viewModel.activeFilters.removeAll()
                        }
                        Task {
                            await viewModel.filterByCategory(nil)
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.trailing)
                }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(UserProfile.ContentStyle.allCases, id: \.self) { style in
                        let isSelected = selectedCategory == style.rawValue
                        Button {
                            withAnimation {
                                if isSelected {
                                    selectedCategory = nil
                                } else {
                                    selectedCategory = style.rawValue
                                }
                            }
                            Task {
                                await viewModel.filterByCategory(selectedCategory)
                            }
                        } label: {
                            TagChip(title: style.rawValue, active: isSelected)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
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
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("\(viewModel.filteredProfiles.count) Results")
                    .font(.headline)
                
                Spacer()
                
                Menu {
                    Button {
                        viewModel.sortBy(.relevance)
                    } label: {
                        Label("Relevance", systemImage: "star.fill")
                    }
                    
                    Button {
                        viewModel.sortBy(.distance)
                    } label: {
                        Label("Distance", systemImage: "location.fill")
                    }
                    
                    Button {
                        viewModel.sortBy(.followers)
                    } label: {
                        Label("Most Popular", systemImage: "person.2.fill")
                    }
                    
                    Button {
                        viewModel.sortBy(.newest)
                    } label: {
                        Label("Newest", systemImage: "clock.fill")
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text("Sort")
                            .font(.caption)
                        Image(systemName: "arrow.up.arrow.down")
                            .font(.caption2)
                    }
                    .foregroundStyle(AppTheme.accent)
                }
            }
            .padding(.horizontal)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                ForEach(viewModel.filteredProfiles) { profile in
                    NavigationLink(destination: ProfileDetailView(profile: profile)) {
                        DiscoverProfileCard(profile: profile)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Finding creators...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(height: 200)
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            
            Text("No Results")
                .font(.headline)
            
            Text("Try adjusting your filters or search terms")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Clear Filters") {
                searchText = ""
                selectedCategory = nil
                viewModel.activeFilters.removeAll()
                Task {
                    await viewModel.loadProfiles()
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.accent)
        }
        .frame(height: 200)
        .padding()
    }
    
    // MARK: - Helper Methods
    
    private func categoryIcon(for category: String) -> String {
        switch category {
        case "Twitch Streamers": return "gamecontroller.fill"
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
        VStack(alignment: .leading, spacing: 10) {
            // Profile Photo
            ZStack(alignment: .topTrailing) {
                AsyncImage(url: URL(string: profile.mediaURLs.first ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(AppTheme.card)
                        .overlay {
                            Image(systemName: "person.fill")
                                .foregroundStyle(.secondary)
                        }
                }
                .frame(height: 180)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Online indicator
                if profile.isOnline {
                    Circle()
                        .fill(.green)
                        .frame(width: 12, height: 12)
                        .overlay(
                            Circle()
                                .stroke(.white, lineWidth: 2)
                        )
                        .padding(8)
                }
            }
            
            // Info
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text(profile.displayName)
                        .font(.headline)
                        .lineLimit(1)
                    
                    if profile.isVerified {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.caption)
                            .foregroundStyle(AppTheme.accent)
                    }
                }
                
                if let age = profile.age, let city = profile.location?.city {
                    Text("\(age) • \(city)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                // Top interests
                HStack(spacing: 4) {
                    ForEach(profile.interests.prefix(2), id: \.self) { interest in
                        Text(interest)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(AppTheme.accent.opacity(0.2), in: Capsule())
                            .foregroundStyle(AppTheme.accent)
                            .lineLimit(1)
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
        }
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.06)))
    }
}

// MARK: - Profile Detail View

struct ProfileDetailView: View {
    let profile: UserProfile
    @Environment(\.dismiss) private var dismiss
    @State private var showMatchAlert = false
    @State private var currentPhotoIndex = 0
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Photo Gallery with Page Indicator
                ZStack(alignment: .bottom) {
                    TabView(selection: $currentPhotoIndex) {
                        ForEach(Array(profile.mediaURLs.enumerated()), id: \.offset) { index, url in
                            AsyncImage(url: URL(string: url)) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Rectangle().fill(AppTheme.card)
                            }
                            .frame(height: 450)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .frame(height: 450)
                    
                    // Custom Page Indicator
                    HStack(spacing: 6) {
                        ForEach(0..<profile.mediaURLs.count, id: \.self) { index in
                            Capsule()
                                .fill(index == currentPhotoIndex ? Color.white : Color.white.opacity(0.5))
                                .frame(width: index == currentPhotoIndex ? 20 : 8, height: 8)
                        }
                    }
                    .padding(.bottom, 16)
                }
                .padding(.horizontal)
                
                // Profile Info
                VStack(alignment: .leading, spacing: 16) {
                    // Name & Age
                    HStack(spacing: 8) {
                        Text(profile.displayName)
                            .font(.title.bold())
                        
                        if let age = profile.age {
                            Text("\(age)")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                        }
                        
                        if profile.isVerified {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(AppTheme.accent)
                        }
                        
                        Spacer()
                        
                        if profile.isOnline {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(.green)
                                    .frame(width: 8, height: 8)
                                Text("Online")
                                    .font(.caption)
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                    
                    // Location
                    if let location = profile.location, let city = location.city {
                        HStack(spacing: 6) {
                            Image(systemName: "location.fill")
                            Text(city)
                            
                            if location.isNearby {
                                Text("• Nearby")
                                    .foregroundStyle(AppTheme.accent)
                            }
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }
                    
                    // Bio
                    if let bio = profile.bio {
                        Text(bio)
                            .font(.body)
                    }
                    
                    Divider()
                    
                    // Interests
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Interests")
                            .font(.headline)
                        
                        FlowLayout(spacing: 8) {
                            ForEach(profile.interests, id: \.self) { interest in
                                TagChip(title: interest, active: false)
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Content Styles
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Content Style")
                            .font(.headline)
                        
                        FlowLayout(spacing: 8) {
                            ForEach(profile.contentStyles, id: \.self) { style in
                                TagChip(title: style.rawValue, active: true)
                            }
                        }
                    }
                    
                    // Social Links
                    if hasSocialLinks {
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Social Media")
                                .font(.headline)
                            
                            if let tiktok = profile.socialLinks.tiktok {
                                SocialStatRow(platform: "TikTok", username: tiktok.username, followers: tiktok.followerCount)
                            }
                            if let instagram = profile.socialLinks.instagram {
                                SocialStatRow(platform: "Instagram", username: instagram.username, followers: instagram.followerCount)
                            }
                            if let youtube = profile.socialLinks.youtube {
                                SocialStatRow(platform: "YouTube", username: youtube.username, followers: youtube.followerCount)
                            }
                            if let twitch = profile.socialLinks.twitch {
                                SocialStatRow(platform: "Twitch", username: twitch.username, followers: twitch.followerCount)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                // Action Buttons
                HStack(spacing: 16) {
                    Button {
                        dismiss()
                    } label: {
                        Label("Pass", systemImage: "xmark")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                    
                    Button {
                        showMatchAlert = true
                        Haptics.notify(.success)
                    } label: {
                        Label("Like", systemImage: "heart.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.accent)
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 32)
        }
        .background(AppTheme.bg)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(role: .destructive) {
                        // Report user
                    } label: {
                        Label("Report", systemImage: "exclamationmark.triangle")
                    }
                    
                    Button {
                        // Share profile
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .alert("It's a Match!", isPresented: $showMatchAlert) {
            Button("Send Message", role: .none) {
                dismiss()
            }
            Button("Keep Browsing", role: .cancel) {
                dismiss()
            }
        } message: {
            Text("You and \(profile.displayName) liked each other!")
        }
    }
    
    private var hasSocialLinks: Bool {
        profile.socialLinks.tiktok != nil ||
        profile.socialLinks.instagram != nil ||
        profile.socialLinks.youtube != nil ||
        profile.socialLinks.twitch != nil
    }
}

struct SocialStatRow: View {
    let platform: String
    let username: String
    let followers: Int?
    
    var body: some View {
        HStack {
            Image(systemName: platformIcon)
                .font(.title3)
                .foregroundStyle(AppTheme.accent)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(platform)
                    .font(.subheadline.weight(.medium))
                Text("@\(username)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if let followers = followers {
                Text(formatCount(followers))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            
            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 12))
    }
    
    private var platformIcon: String {
        switch platform {
        case "TikTok": return "music.note"
        case "Instagram": return "camera"
        case "YouTube": return "play.rectangle"
        case "Twitch": return "gamecontroller"
        default: return "link"
        }
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

// MARK: - Category Detail View

struct CategoryDetailView: View {
    let category: String
    @ObservedObject var viewModel: DiscoverViewModel
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                ForEach(viewModel.filteredProfiles) { profile in
                    NavigationLink(destination: ProfileDetailView(profile: profile)) {
                        HStack(spacing: 12) {
                            AsyncImage(url: URL(string: profile.mediaURLs.first ?? "")) { image in
                                image.resizable()
                            } placeholder: {
                                Circle().fill(AppTheme.card)
                            }
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())
                            
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 4) {
                                    Text(profile.displayName)
                                        .font(.headline)
                                    
                                    if profile.isVerified {
                                        Image(systemName: "checkmark.seal.fill")
                                            .font(.caption)
                                            .foregroundStyle(AppTheme.accent)
                                    }
                                }
                                
                                if let bio = profile.bio {
                                    Text(bio)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                }
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .background(AppTheme.bg)
        .navigationTitle(category)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            // Filter by category
            await viewModel.filterByCategory(category)
        }
    }
}

// MARK: - Advanced Filter Sheet

struct AdvancedFilterSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedFilters: DiscoverFilters
    let onApply: () -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Distance") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(Int(selectedFilters.maxDistance)) km")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Slider(value: $selectedFilters.maxDistance, in: 1...100, step: 1)
                            .tint(AppTheme.accent)
                    }
                }
                
                Section("Follower Count") {
                    Picker("Minimum Followers", selection: $selectedFilters.minFollowers) {
                        Text("Any").tag(0)
                        Text("1K+").tag(1000)
                        Text("10K+").tag(10000)
                        Text("50K+").tag(50000)
                        Text("100K+").tag(100000)
                    }
                }
                
                Section("Verification") {
                    Toggle("Verified Only", isOn: $selectedFilters.verifiedOnly)
                }
                
                Section("Online Status") {
                    Toggle("Online Now", isOn: $selectedFilters.onlineOnly)
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        onApply()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Discover Filters with Helper Methods

struct DiscoverFilters {
    var maxDistance: Double = 50
    var minFollowers: Int = 0
    var verifiedOnly: Bool = false
    var onlineOnly: Bool = false
    
    /// Check if any filters are active (non-default values)
    var isEmpty: Bool {
        return maxDistance == 50 &&
               minFollowers == 0 &&
               !verifiedOnly &&
               !onlineOnly
    }
    
    /// Reset all filters to default values
    mutating func removeAll() {
        maxDistance = 50
        minFollowers = 0
        verifiedOnly = false
        onlineOnly = false
    }
}

enum SortOption {
    case relevance, distance, followers, newest
}

@MainActor
final class DiscoverViewModel: ObservableObject {
    @Published var allProfiles: [UserProfile] = []
    @Published var filteredProfiles: [UserProfile] = []
    @Published var isLoading = false
    @Published var activeFilters = DiscoverFilters()
    
    private let service = FirebaseService()
    private var currentFilter: String?
    private var currentSearchQuery: String = ""
    private var currentSort: SortOption = .relevance
    
    func loadProfiles() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            allProfiles = try await service.fetchDiscoverProfiles(limit: 50)
            applyFilters()
        } catch {
            print("Error loading profiles: \(error)")
        }
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
                print("Error searching: \(error)")
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
    
    private func applyFilters() {
        var results = allProfiles
        
        // Category filter
        if let filter = currentFilter {
            results = results.filter { profile in
                profile.contentStyles.contains { $0.rawValue == filter }
            }
        }
        
        // Search query filter
        if !currentSearchQuery.isEmpty {
            results = results.filter { profile in
                profile.displayName.localizedCaseInsensitiveContains(currentSearchQuery)
            }
        }
        
        // Advanced filters
        if activeFilters.verifiedOnly {
            results = results.filter { $0.isVerified }
        }
        
        if activeFilters.onlineOnly {
            results = results.filter { $0.isOnline }
        }
        
        if activeFilters.minFollowers > 0 {
            results = results.filter { $0.followerCount >= activeFilters.minFollowers }
        }
        
        filteredProfiles = results
        applySorting()
    }
    
    private func applySorting() {
        switch currentSort {
        case .relevance:
            // Already in default order
            break
        case .distance:
            filteredProfiles.sort { ($0.location?.isNearby ?? false) && !($1.location?.isNearby ?? false) }
        case .followers:
            filteredProfiles.sort { $0.followerCount > $1.followerCount }
        case .newest:
            filteredProfiles.sort { $0.createdAt > $1.createdAt }
        }
    }
}

// MARK: - UserProfile Extension for Online Status

extension UserProfile {
    var isOnline: Bool {
        // This should be implemented based on your backend logic
        // For now, return false as placeholder
        return false
    }
}
