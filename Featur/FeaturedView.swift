import SwiftUI

struct FeaturedView: View {
    @StateObject private var viewModel = FeaturedViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Hero Banner
                heroBanner
                
                // Featured Creators List
                if viewModel.isLoading {
                    ProgressView()
                        .frame(height: 300)
                } else if viewModel.featuredCreators.isEmpty {
                    emptyState
                } else {
                    featuredList
                }
                
                // Call to Action
                ctaSection
            }
            .padding(.bottom, 24)
        }
        .background(AppTheme.bg.ignoresSafeArea())
        .navigationTitle("FEATUREd")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadFeatured()
        }
        .refreshable {
            await viewModel.loadFeatured()
        }
    }
    
    private var heroBanner: some View {
        ZStack(alignment: .bottomLeading) {
            AppTheme.gradient
                .frame(height: 180)
                .clipShape(RoundedRectangle(cornerRadius: 22))
            
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: "star.fill")
                    .font(.title)
                
                Text("FEATUREd Creators")
                    .font(.system(size: 28, weight: .bold))
                
                Text("Handpicked talent across categories")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.85))
            }
            .padding(20)
        }
        .foregroundStyle(.white)
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    private var featuredList: some View {
        LazyVStack(spacing: 16) {
            ForEach(viewModel.featuredCreators) { featured in
                if let profile = featured.profile {
                    NavigationLink(destination: ProfileDetailView(profile: profile)) {
                        FeaturedCreatorRow(featured: featured, profile: profile)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal)
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "star.slash")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
            
            Text("No Featured Creators")
                .font(.title3.bold())
            
            Text("Check back soon for new featured talent")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(height: 300)
        .padding()
    }
    
    private var ctaSection: some View {
        VStack(spacing: 16) {
            Text("Want to be featured?")
                .font(.title2.bold())
            
            Text("Build your profile, grow your following, and get discovered by our community")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button("Featur Your Profile") {
                // Navigate to profile or payment
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.accent)
            .controlSize(.large)
        }
        .padding(.vertical, 32)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal)
    }
}

struct FeaturedCreatorRow: View {
    let featured: FeaturedCreator
    let profile: UserProfile
    
    var body: some View {
        HStack(spacing: 14) {
            // Profile Photo
            AsyncImage(url: URL(string: profile.mediaURLs.first ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(AppTheme.accent.opacity(0.2))
                    .overlay {
                        Image(systemName: "person.fill")
                            .foregroundStyle(AppTheme.accent)
                    }
            }
            .frame(width: 70, height: 70)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(AppTheme.accent.opacity(0.3), lineWidth: 2)
            )
            
            // Info
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text(profile.displayName)
                        .font(.headline)
                    
                    if profile.isVerified {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.caption)
                            .foregroundStyle(AppTheme.accent)
                    }
                }
                
                Text(featured.category)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppTheme.accent.opacity(0.2), in: Capsule())
                    .foregroundStyle(AppTheme.accent)
                
                if let highlight = featured.highlightText {
                    Text(highlight)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                
                HStack(spacing: 12) {
                    if let tiktok = profile.socialLinks.tiktok, let count = tiktok.followerCount {
                        StatBadge(icon: "music.note", value: formatCount(count))
                    }
                    if let instagram = profile.socialLinks.instagram, let count = instagram.followerCount {
                        StatBadge(icon: "camera", value: formatCount(count))
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.06)))
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

struct StatBadge: View {
    let icon: String
    let value: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(value)
                .font(.caption2.weight(.semibold))
        }
        .foregroundStyle(.secondary)
    }
}

// MARK: - Featured View Model

@MainActor
final class FeaturedViewModel: ObservableObject {
    @Published var featuredCreators: [FeaturedCreator] = []
    @Published var isLoading = false
    
    private let service = FirebaseService()
    
    func loadFeatured() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            featuredCreators = try await service.fetchFeaturedCreators()
        } catch {
            print("Error loading featured: \(error)")
        }
    }
}
