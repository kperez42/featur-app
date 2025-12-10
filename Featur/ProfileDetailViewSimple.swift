// ProfileDetailViewSimple.swift - Quick Profile View from Home/Discover
import SwiftUI
import FirebaseAuth

struct ProfileDetailViewSimple: View {
    let profile: UserProfile
    @Environment(\.dismiss) var dismiss
    @State private var isLiked = false
    @State private var showMessageSheet = false
    @State private var isLoading = false
    @State private var currentImageIndex = 0

    private let service = FirebaseService()

    private var mediaURLs: [String] {
        profile.mediaURLs ?? []
    }

    private var hasMultipleImages: Bool {
        mediaURLs.count > 1
    }

    private var safeCurrentIndex: Int {
        guard !mediaURLs.isEmpty else { return 0 }
        return min(currentImageIndex, mediaURLs.count - 1)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Drag Handle
            Capsule()
                .fill(Color.gray.opacity(0.35))
                .frame(width: 40, height: 5)
                .padding(.top, 12)
                .padding(.bottom, 8)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Image Gallery with Carousel
                    imageGallery

                    // Profile Info
                    profileInfo

                    // Stats Row
                    statsRow

                    // Content Styles
                    if !profile.contentStyles.isEmpty {
                        contentStylesSection
                    }

                    // Bio
                    if let bio = profile.bio, !bio.isEmpty {
                        bioSection(bio)
                    }

                    // Interests
                    if let interests = profile.interests, !interests.isEmpty {
                        interestsSection(interests)
                    }

                    // Action Buttons
                    actionButtons

                    Spacer().frame(height: 40)
                }
            }
        }
        .interactiveDismissDisabled(false)
        .background(AppTheme.bg)
        .gesture(
            DragGesture().onEnded { value in
                if value.translation.height > 120 {
                    dismiss()
                }
            }
        )
        .task {
            await loadLikeStatus()
        }
        .sheet(isPresented: $showMessageSheet) {
            MessageSheet(recipientProfile: profile)
        }
    }

    // MARK: - Image Gallery

    private var imageGallery: some View {
        let imageWidth = UIScreen.main.bounds.width - 32
        let imageHeight: CGFloat = 450

        return ZStack(alignment: .top) {
            if !mediaURLs.isEmpty {
                let currentURL = mediaURLs[safeCurrentIndex]
                CachedAsyncImage(url: URL(string: currentURL)) { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: imageWidth, height: imageHeight)
                        .clipped()
                } placeholder: {
                    ZStack {
                        AppTheme.gradient.opacity(0.3)
                        ProgressView()
                            .tint(AppTheme.accent)
                    }
                    .frame(width: imageWidth, height: imageHeight)
                }
                .frame(width: imageWidth, height: imageHeight)
                .clipped()
                .id(safeCurrentIndex)
            } else {
                ZStack {
                    AppTheme.gradient.opacity(0.3)
                    Image(systemName: "person.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(.white.opacity(0.6))
                }
                .frame(width: imageWidth, height: imageHeight)
            }

            // Image indicators
            if hasMultipleImages {
                HStack(spacing: 6) {
                    ForEach(0..<mediaURLs.count, id: \.self) { index in
                        Capsule()
                            .fill(index == safeCurrentIndex ? .white : .white.opacity(0.5))
                            .frame(height: 4)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
            }

            // Verified badge
            if profile.isVerified ?? false {
                HStack {
                    Spacer()
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(.blue)
                        .font(.title2)
                        .background(Circle().fill(.white).padding(-4))
                        .padding(16)
                }
            }

            // Navigation overlay for multiple images
            if hasMultipleImages {
                HStack(spacing: 0) {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                currentImageIndex = max(0, currentImageIndex - 1)
                            }
                            Haptics.impact(.light)
                        }

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
        }
        .frame(width: imageWidth, height: imageHeight)
        .cornerRadius(16)
        .padding(.horizontal)
    }

    // MARK: - Profile Info

    private var profileInfo: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Text(profile.displayName)
                    .font(.largeTitle.bold())

                if let age = profile.age {
                    Text("\(age)")
                        .font(.title)
                        .foregroundStyle(.secondary)
                }

                if profile.isVerified ?? false {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(.blue)
                        .font(.title3)
                }

                Spacer()

                // Online Status
                if PresenceManager.shared.isOnline(userId: profile.uid) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(.green)
                            .frame(width: 8, height: 8)
                        Text("Online")
                            .font(.caption.bold())
                            .foregroundStyle(.green)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.green.opacity(0.15), in: Capsule())
                }
            }

            // Location
            if let city = profile.location?.city, !city.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundStyle(AppTheme.accent)
                    Text(city)
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: 0) {
            StatItem(value: "\(mediaURLs.count)", label: "Photos")

            Divider().frame(height: 36)

            StatItem(value: "\(profile.contentStyles.count)", label: "Styles")

            Divider().frame(height: 36)

            StatItem(value: "\(profile.interests?.count ?? 0)", label: "Interests")
        }
        .padding(.vertical, 14)
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal)
    }

    // MARK: - Content Styles Section

    private var contentStylesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Content Styles")
                .font(.headline)

            FlowLayout(spacing: 8) {
                ForEach(profile.contentStyles, id: \.self) { style in
                    HStack(spacing: 6) {
                        Image(systemName: style.icon)
                            .font(.caption)
                        Text(style.rawValue)
                    }
                    .font(.subheadline.weight(.medium))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(AppTheme.accent.opacity(0.15), in: Capsule())
                    .foregroundStyle(AppTheme.accent)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
    }

    // MARK: - Bio Section

    private func bioSection(_ bio: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("About")
                .font(.headline)

            Text(bio)
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
    }

    // MARK: - Interests Section

    private func interestsSection(_ interests: [String]) -> some View {
        let genderValues = ["Male", "Female", "Non-binary", "Prefer not to say"]
        let filteredInterests = interests.filter { !genderValues.contains($0) }

        return VStack(alignment: .leading, spacing: 10) {
            Text("Interests")
                .font(.headline)

            FlowLayout(spacing: 8) {
                ForEach(filteredInterests, id: \.self) { interest in
                    Text(interest)
                        .font(.subheadline.weight(.medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.gray.opacity(0.15), in: Capsule())
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 20) {
            // Like Button
            Button {
                toggleLike()
            } label: {
                HStack(spacing: 8) {
                    if isLoading {
                        ProgressView()
                            .tint(isLiked ? .white : AppTheme.accent)
                    } else {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .symbolEffect(.bounce, value: isLiked)
                    }
                    Text(isLiked ? "Liked" : "Like")
                        .fontWeight(.semibold)
                }
                .font(.headline)
                .foregroundStyle(isLiked ? .white : AppTheme.accent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    isLiked ? AppTheme.accent : AppTheme.card,
                    in: RoundedRectangle(cornerRadius: 14)
                )
            }
            .disabled(isLoading)

            // Message Button
            Button {
                Haptics.impact(.light)
                showMessageSheet = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "message.fill")
                    Text("Message")
                        .fontWeight(.semibold)
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(AppTheme.accent, in: RoundedRectangle(cornerRadius: 14))
            }
        }
        .padding(.horizontal)
        .padding(.top, 10)
    }

    // MARK: - Helpers

    private func loadLikeStatus() async {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        do {
            isLiked = try await service.checkLikeStatus(userId: currentUserId, targetUserId: profile.uid)
        } catch {
            print("Error loading like status: \(error)")
        }
    }

    private func toggleLike() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }

        withAnimation(.spring(response: 0.3)) {
            isLiked.toggle()
        }
        Haptics.impact(isLiked ? .medium : .light)

        Task {
            isLoading = true
            defer { isLoading = false }

            do {
                if isLiked {
                    _ = try await service.saveLike(userId: currentUserId, targetUserId: profile.uid)
                } else {
                    try await service.removeLike(userId: currentUserId, targetUserId: profile.uid)
                }
            } catch {
                withAnimation {
                    isLiked.toggle()
                }
                Haptics.notify(.error)
            }
        }
    }
}

// MARK: - Stat Item

private struct StatItem: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(AppTheme.accent)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
