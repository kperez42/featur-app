import SwiftUI

struct EnhancedDiscoverView: View {
    @StateObject private var viewModel = DiscoverViewModel()
    @State private var selectedCategory: String?
    @State private var searchText = ""
    
    let featuredCategories = [
        "Twitch Streamers",
        "Music Collabs",
        "Podcast Guests",
        "Tiktok Lives"
    ]
    
    var body: some View {
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
                
                // Results Grid
                if viewModel.isLoading {
                    ProgressView()
                        .frame(height: 200)
                } else if viewModel.filteredProfiles.isEmpty {
                    emptyState
                } else {
                    profilesGrid
                }
            }
            .padding(.bottom, 24)
        }
        .background(AppTheme.bg.ignoresSafeArea())
        .navigationTitle("Discover")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadProfiles()
        }
        .refreshable {
            await viewModel.loadProfiles()
        }
    }
    
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
            Text("Featured")
                .font(.headline)
                .padding(.horizontal)
            
            ForEach(featuredCategories, id: \.self) { category in
                NavigationLink(destination: CategoryDetailView(category: category)) {
                    GlassCard {
                        HStack {
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
    
    private var profilesGrid: some View {
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
        }
        .frame(height: 200)
        .padding()
    }
}

// MARK: - Discover Profile Card

struct DiscoverProfileCard: View {
    let profile: UserProfile
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Profile Photo
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
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Photo Gallery
                TabView {
                    ForEach(profile.mediaURLs, id: \.self) { url in
                        AsyncImage(url: URL(string: url)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Rectangle().fill(AppTheme.card)
                        }
                        .frame(height: 450)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
                .tabViewStyle(.page)
                .frame(height: 450)
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
                    }
                    
                    // Location
                    if let location = profile.location, let city = location.city {
                        HStack(spacing: 6) {
                            Image(systemName: "location.fill")
                            Text(city)
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }
                    
                    // Bio
                    if let bio = profile.bio {
                        Text(bio)
                            .font(.body)
                    }
                    
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
                    
                    // Social Links
                    if profile.socialLinks.tiktok != nil ||
                       profile.socialLinks.instagram != nil ||
                       profile.socialLinks.youtube != nil {
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
}

struct SocialStatRow: View {
    let platform: String
    let username: String
    let followers: Int?
    
    var body: some View {
        HStack {
            Text(platform)
                .font(.subheadline.weight(.medium))
            Text("@\(username)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            if let followers = followers {
                Text(formatCount(followers))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 12))
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
    @StateObject private var viewModel = DiscoverViewModel()
    
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
                                Text(profile.displayName)
                                    .font(.headline)
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
            // Load profiles for this category
            await viewModel.loadProfiles()
        }
    }
}

// MARK: - Discover View Model

@MainActor
final class DiscoverViewModel: ObservableObject {
    @Published var allProfiles: [UserProfile] = []
    @Published var filteredProfiles: [UserProfile] = []
    @Published var isLoading = false
    
    private let service = FirebaseService()
    private var currentFilter: String?
    private var currentSearchQuery: String = ""
    
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
            } catch {
                print("Error searching: \(error)")
            }
        } else {
            applyFilters()
        }
    }
    
    private func applyFilters() {
        var results = allProfiles
        
        if let filter = currentFilter {
            results = results.filter { profile in
                profile.contentStyles.contains { $0.rawValue == filter }
            }
        }
        
        if !currentSearchQuery.isEmpty {
            results = results.filter { profile in
                profile.displayName.localizedCaseInsensitiveContains(currentSearchQuery)
            }
        }
        
        filteredProfiles = results
    }
}
