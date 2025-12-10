//
import SwiftUI
import FirebaseAuth

struct ProfileDetailViewSimple: View {
    let profile: UserProfile
    @Environment(\.dismiss) var dismiss
    @State private var isLiked = false
    @State private var showMessageSheet = false
    @State private var isLoading = false

    private let service = FirebaseService()

    var body: some View {
        VStack(spacing: 0) {

            // --- DRAG HANDLE ---
            Capsule()
                .fill(Color.gray.opacity(0.35))
                .frame(width: 40, height: 5)
                .padding(.top, 12)
                .padding(.bottom, 8)

            // --- CONTENT ---
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {

                    // Main image - fixed dimensions for consistency
                    let imageWidth = UIScreen.main.bounds.width - 32
                    let imageHeight: CGFloat = 420

                    if let first = profile.mediaURLs?.first?.trimmingCharacters(in: .whitespacesAndNewlines),
                       let url = URL(string: first) {

                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: imageWidth, height: imageHeight)
                                    .clipped()
                                    .cornerRadius(12)

                            case .empty:
                                ZStack {
                                    AppTheme.gradient.opacity(0.3)
                                    ProgressView()
                                        .tint(AppTheme.accent)
                                }
                                .frame(width: imageWidth, height: imageHeight)
                                .cornerRadius(12)

                            default:
                                ZStack {
                                    AppTheme.gradient.opacity(0.3)
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 80))
                                        .foregroundStyle(.white.opacity(0.6))
                                }
                                .frame(width: imageWidth, height: imageHeight)
                                .cornerRadius(12)
                            }
                        }
                        .frame(width: imageWidth, height: imageHeight)
                        .cornerRadius(12)
                        .padding(.horizontal)
                    } else {
                        // Fallback when no image URL exists
                        ZStack {
                            AppTheme.gradient.opacity(0.3)
                            Image(systemName: "person.fill")
                                .font(.system(size: 80))
                                .foregroundStyle(.white.opacity(0.6))
                        }
                        .frame(width: imageWidth, height: imageHeight)
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }

                    // Name & age
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            Text(profile.displayName)
                                .font(.largeTitle.bold())

                            if let age = profile.age {
                                Text("\(age)")
                                    .font(.title2)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        if let bio = profile.bio, !bio.isEmpty {
                            Text(bio)
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)

                    // Content Styles
                    if !profile.contentStyles.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Content Styles")
                                .font(.headline)

                            FlowLayout(spacing: 8) {
                                ForEach(profile.contentStyles, id: \.self) { style in
                                    Text(style.rawValue)
                                        .font(.caption.bold())
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.gray.opacity(0.15), in: Capsule())
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Location
                    if let city = profile.location?.city {
                        HStack(spacing: 8) {
                            Image(systemName: "mappin.circle.fill")
                            Text(city)
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                    }

                    // Action Buttons
                    HStack(spacing: 16) {
                        // Like Button
                        QuickActionButton(
                            icon: isLiked ? "heart.fill" : "heart",
                            color: isLiked ? .pink : .gray,
                            isLoading: isLoading
                        ) {
                            toggleLike()
                        }

                        // Message Button
                        QuickActionButton(
                            icon: "message.fill",
                            color: AppTheme.accent,
                            isLoading: false
                        ) {
                            Haptics.impact(.light)
                            showMessageSheet = true
                        }
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 10)

                    Spacer().frame(height: 40)
                }
            }
        }
        .interactiveDismissDisabled(false)
        .background(AppTheme.bg)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.headline)
                        .foregroundColor(.primary)
                }
            }
        }
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
                // Revert on error
                withAnimation {
                    isLiked.toggle()
                }
                Haptics.notify(.error)
            }
        }
    }
}

// MARK: - Quick Action Button

private struct QuickActionButton: View {
    let icon: String
    let color: Color
    let isLoading: Bool
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 60, height: 60)

                if isLoading {
                    ProgressView()
                        .tint(color)
                } else {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundStyle(color)
                }
            }
            .scaleEffect(isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}
