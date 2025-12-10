// ProfileSetupView.swift
// Onboarding flow for new gamers to complete their profile

import SwiftUI
import PhotosUI
import FirebaseAuth

struct ProfileSetupView: View {
    @EnvironmentObject var auth: AuthViewModel
    @StateObject private var viewModel: ProfileSetupViewModel

    init() {
        _viewModel = StateObject(wrappedValue: ProfileSetupViewModel())
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.gradient.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 8) {
                            Image(systemName: "gamecontroller.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(.white)

                            Text("Create Your Profile")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)

                            Text("Set up your gaming profile to find teammates")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.8))
                        }
                        .padding(.top, 20)

                        // Profile Photo
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.2))
                                    .frame(width: 120, height: 120)

                                if let selectedImage = viewModel.selectedImage {
                                    Image(uiImage: selectedImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 120, height: 120)
                                        .clipped()
                                        .clipShape(Circle())
                                } else {
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 50))
                                        .foregroundStyle(.white.opacity(0.6))
                                }

                                // Camera icon overlay
                                Circle()
                                    .fill(AppTheme.accent)
                                    .frame(width: 36, height: 36)
                                    .overlay {
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 16))
                                            .foregroundStyle(.white)
                                    }
                                    .offset(x: 42, y: 42)
                            }
                            .onTapGesture {
                                viewModel.showImagePicker = true
                            }

                            Text("Tap to add your avatar")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.7))
                        }
                        .padding(.vertical)

                        // Form Fields
                        VStack(spacing: 20) {
                            // Gamer Tag / Display Name
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "at")
                                        .foregroundStyle(.white.opacity(0.7))
                                    Text("Gamer Tag")
                                        .font(.headline)
                                        .foregroundStyle(.white)
                                }

                                TextField("Your gaming name", text: $viewModel.displayName)
                                    .textFieldStyle(ProfileSetupTextFieldStyle())
                            }

                            // Bio
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "text.alignleft")
                                        .foregroundStyle(.white.opacity(0.7))
                                    Text("Bio")
                                        .font(.headline)
                                        .foregroundStyle(.white)
                                }

                                TextEditor(text: $viewModel.bio)
                                    .frame(height: 80)
                                    .padding(12)
                                    .background(Color.white.opacity(0.15))
                                    .cornerRadius(12)
                                    .foregroundStyle(.white)
                                    .scrollContentBackground(.hidden)

                                Text("Describe your gaming style, achievements, or what you're looking for")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.6))
                            }

                            // Age
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "calendar")
                                        .foregroundStyle(.white.opacity(0.7))
                                    Text("Age")
                                        .font(.headline)
                                        .foregroundStyle(.white)
                                }

                                TextField("Your age", text: $viewModel.ageText)
                                    .textFieldStyle(ProfileSetupTextFieldStyle())
                                    .keyboardType(.numberPad)
                            }

                            // Account Type (Gaming-focused)
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "person.badge.shield.checkmark")
                                        .foregroundStyle(.white.opacity(0.7))
                                    Text("Account Type")
                                        .font(.headline)
                                        .foregroundStyle(.white)
                                }

                                HStack(spacing: 12) {
                                    ForEach(AccountType.allCases, id: \.self) { type in
                                        Button {
                                            viewModel.accountType = type.rawValue
                                            Haptics.impact(.light)
                                        } label: {
                                            VStack(spacing: 8) {
                                                Image(systemName: type.icon)
                                                    .font(.system(size: 24))
                                                Text(type.title)
                                                    .font(.caption.weight(.medium))
                                            }
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 14)
                                            .background(viewModel.accountType == type.rawValue ? AppTheme.accent : Color.white.opacity(0.15))
                                            .foregroundStyle(.white)
                                            .cornerRadius(12)
                                        }
                                    }
                                }
                            }

                            // Game Genres
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "gamecontroller.fill")
                                        .foregroundStyle(.white.opacity(0.7))
                                    Text("Game Genres")
                                        .font(.headline)
                                        .foregroundStyle(.white)
                                }

                                Text("Select all games you play")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.7))

                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 10) {
                                    ForEach(UserProfile.ContentStyle.allCases, id: \.self) { style in
                                        Button {
                                            viewModel.toggleContentStyle(style)
                                            Haptics.impact(.light)
                                        } label: {
                                            HStack(spacing: 4) {
                                                Image(systemName: style.icon)
                                                    .font(.caption)
                                                Text(style.rawValue)
                                                    .font(.caption)
                                                    .lineLimit(1)
                                                    .minimumScaleFactor(0.8)
                                            }
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 8)
                                            .background(viewModel.contentStyles.contains(style) ? AppTheme.accent : Color.white.opacity(0.15))
                                            .foregroundStyle(.white)
                                            .cornerRadius(20)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 24)

                        // Complete Button
                        Button {
                            Task {
                                await viewModel.completeSetup(auth: auth)
                            }
                        } label: {
                            HStack(spacing: 8) {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Start Gaming")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(viewModel.canComplete ? AppTheme.accent : Color.white.opacity(0.3))
                            .foregroundStyle(.white)
                            .cornerRadius(16)
                        }
                        .disabled(!viewModel.canComplete || viewModel.isLoading)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 30)
                    }
                }
            }
            .photosPicker(isPresented: $viewModel.showImagePicker, selection: $viewModel.selectedPhotoItem)
            .onChange(of: viewModel.selectedPhotoItem) { _, newItem in
                Task {
                    await viewModel.loadSelectedImage(from: newItem)
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage)
            }
        }
    }
}

// MARK: - Account Types

enum AccountType: String, CaseIterable {
    case gamer = "gamer"
    case streamer = "streamer"
    case esports = "esports"

    var title: String {
        switch self {
        case .gamer: return "Gamer"
        case .streamer: return "Streamer"
        case .esports: return "Pro/Esports"
        }
    }

    var icon: String {
        switch self {
        case .gamer: return "gamecontroller.fill"
        case .streamer: return "video.fill"
        case .esports: return "trophy.fill"
        }
    }
}

// MARK: - Custom Text Field Style

struct ProfileSetupTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(12)
            .background(Color.white.opacity(0.15))
            .foregroundStyle(.white)
            .cornerRadius(12)
    }
}

// MARK: - View Model

@MainActor
final class ProfileSetupViewModel: ObservableObject {
    @Published var displayName = ""
    @Published var bio = ""
    @Published var ageText = ""
    @Published var accountType: String = "gamer"
    @Published var contentStyles: [UserProfile.ContentStyle] = []

    @Published var selectedPhotoItem: PhotosPickerItem?
    @Published var selectedImage: UIImage?
    @Published var showImagePicker = false

    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""

    private let service = FirebaseService()

    var canComplete: Bool {
        !displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !ageText.isEmpty &&
        Int(ageText) != nil &&
        selectedImage != nil
    }

    func toggleContentStyle(_ style: UserProfile.ContentStyle) {
        if contentStyles.contains(style) {
            contentStyles.removeAll { $0 == style }
        } else {
            contentStyles.append(style)
        }
    }

    func loadSelectedImage(from item: PhotosPickerItem?) async {
        guard let item = item else { return }

        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                selectedImage = image
            }
        } catch {
            errorMessage = "Failed to load image"
            showError = true
            print("❌ Error loading image: \(error)")
        }
    }

    func completeSetup(auth: AuthViewModel) async {
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "Not authenticated"
            showError = true
            return
        }

        guard let age = Int(ageText) else {
            errorMessage = "Please enter a valid age"
            showError = true
            return
        }

        guard let profileImage = selectedImage else {
            errorMessage = "Please select a profile photo"
            showError = true
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            // Upload profile photo
            let photoURL = try await service.uploadProfilePhoto(userId: userId, image: profileImage)
            print("✅ Profile photo uploaded: \(photoURL)")

            // Create user profile
            let profile = UserProfile(
                uid: userId,
                displayName: displayName.trimmingCharacters(in: .whitespacesAndNewlines),
                age: age,
                bio: bio.trimmingCharacters(in: .whitespacesAndNewlines),
                location: nil,
                interests: [accountType],
                contentStyles: contentStyles.isEmpty ? [.fps] : contentStyles,
                socialLinks: nil,
                mediaURLs: nil,
                profileImageURL: photoURL,
                isVerified: false,
                followerCount: 0,
                collaborationPreferences: nil,
                createdAt: Date(),
                updatedAt: Date()
            )

            // Save to Firestore
            try await service.createProfile(profile)
            print("✅ User profile created: \(displayName)")

            // Track analytics
            AnalyticsManager.shared.setUserId(userId)
            AnalyticsManager.shared.trackSignUp(method: "apple")
            AnalyticsManager.shared.setUserProperty(name: "account_type", value: accountType)
            AnalyticsManager.shared.trackProfileEdit(field: "initial_setup")

            auth.userProfile = profile
            print("✅ Profile setup complete - navigating to main app")

        } catch {
            errorMessage = "Failed to create profile: \(error.localizedDescription)"
            showError = true
            print("❌ Error creating profile: \(error)")
        }
    }
}
