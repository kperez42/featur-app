// ProfileSetupView.swift
// Onboarding flow for new users to complete their profile

import SwiftUI
import PhotosUI
import FirebaseAuth

struct ProfileSetupView: View {
    @EnvironmentObject var auth: AuthViewModel
    @StateObject private var viewModel: ProfileSetupViewModel

    init() {
        // Initialize with a temporary viewModel - will set auth reference later
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
                            Text("Complete Your Profile")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)

                            Text("Let's set up your creator profile")
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

                            Text("Tap to add photo")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.7))
                        }
                        .padding(.vertical)

                        // Form Fields
                        VStack(spacing: 20) {
                            // Display Name
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Display Name")
                                    .font(.headline)
                                    .foregroundStyle(.white)

                                TextField("Enter your name", text: $viewModel.displayName)
                                    .textFieldStyle(ProfileSetupTextFieldStyle())
                            }

                            // Bio
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Bio")
                                    .font(.headline)
                                    .foregroundStyle(.white)

                                TextEditor(text: $viewModel.bio)
                                    .frame(height: 100)
                                    .padding(12)
                                    .background(Color.white.opacity(0.15))
                                    .cornerRadius(12)
                                    .foregroundStyle(.white)
                                    .scrollContentBackground(.hidden)
                            }

                            // Age
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Age")
                                    .font(.headline)
                                    .foregroundStyle(.white)

                                TextField("Enter your age", text: $viewModel.ageText)
                                    .textFieldStyle(ProfileSetupTextFieldStyle())
                                    .keyboardType(.numberPad)
                            }

                            // Gender
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Gender")
                                    .font(.headline)
                                    .foregroundStyle(.white)

                                Menu {
                                    ForEach(["Male", "Female", "Non-binary", "Other", "Prefer not to say"], id: \.self) { gender in
                                        Button(gender) {
                                            viewModel.gender = gender
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Text(viewModel.gender.isEmpty ? "Select gender" : viewModel.gender)
                                            .foregroundStyle(viewModel.gender.isEmpty ? .white.opacity(0.5) : .white)
                                        Spacer()
                                        Image(systemName: "chevron.down")
                                            .foregroundStyle(.white.opacity(0.5))
                                    }
                                    .padding(12)
                                    .background(Color.white.opacity(0.15))
                                    .cornerRadius(12)
                                }
                            }

                            // Account Type
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Account Type")
                                    .font(.headline)
                                    .foregroundStyle(.white)

                                HStack(spacing: 12) {
                                    ForEach([AccountType.creator, .business], id: \.self) { type in
                                        Button {
                                            viewModel.accountType = type
                                        } label: {
                                            VStack(spacing: 8) {
                                                Image(systemName: type == .creator ? "person.fill" : "briefcase.fill")
                                                    .font(.system(size: 24))
                                                Text(type.rawValue.capitalized)
                                                    .font(.caption)
                                            }
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(viewModel.accountType == type ? AppTheme.accent : Color.white.opacity(0.15))
                                            .foregroundStyle(.white)
                                            .cornerRadius(12)
                                        }
                                    }
                                }
                            }

                            // Content Styles
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Content Styles")
                                    .font(.headline)
                                    .foregroundStyle(.white)

                                Text("Select all that apply")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.7))

                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 12) {
                                    ForEach(ContentStyle.allCases, id: \.self) { style in
                                        Button {
                                            viewModel.toggleContentStyle(style.rawValue)
                                        } label: {
                                            Text(style.rawValue)
                                                .font(.caption)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 8)
                                                .background(viewModel.contentStyles.contains(style.rawValue) ? AppTheme.accent : Color.white.opacity(0.15))
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
                            HStack {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Complete Setup")
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
    @Published var gender = ""
    @Published var accountType: AccountType = .creator
    @Published var contentStyles: [String] = []

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
        !gender.isEmpty &&
        selectedImage != nil
    }

    func toggleContentStyle(_ style: String) {
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
                email: Auth.auth().currentUser?.email ?? "",
                displayName: displayName.trimmingCharacters(in: .whitespacesAndNewlines),
                bio: bio.trimmingCharacters(in: .whitespacesAndNewlines),
                age: age,
                gender: gender,
                profilePhotoURL: photoURL,
                accountType: accountType,
                contentStyles: contentStyles.isEmpty ? ["lifestyle"] : contentStyles,
                interests: [],
                createdAt: Date(),
                isVerified: false,
                location: nil,
                socialLinks: [:],
                galleries: [],
                mediaCount: 0
            )

            // Save to Firestore
            try await service.saveProfile(profile: profile)
            print("✅ User profile created: \(displayName)")

            // Track analytics
            AnalyticsManager.shared.setUserId(userId)
            AnalyticsManager.shared.trackSignUp(method: "apple")
            AnalyticsManager.shared.setUserProperty(name: "account_type", value: accountType.rawValue)
            AnalyticsManager.shared.trackProfileEdit(field: "initial_setup")

            // Manually reload the profile in AuthViewModel to trigger UI update
            // The auth state listener should pick this up automatically, but we'll trigger it manually to be safe
            auth.userProfile = profile
            print("✅ Profile setup complete - navigating to main app")

        } catch {
            errorMessage = "Failed to create profile: \(error.localizedDescription)"
            showError = true
            print("❌ Error creating profile: \(error)")
        }
    }
}

// MARK: - Content Style Enum

enum ContentStyle: String, CaseIterable {
    case fashion = "Fashion"
    case beauty = "Beauty"
    case lifestyle = "Lifestyle"
    case fitness = "Fitness"
    case food = "Food"
    case travel = "Travel"
    case tech = "Tech"
    case gaming = "Gaming"
    case music = "Music"
    case art = "Art"
    case photography = "Photography"
    case comedy = "Comedy"
    case education = "Education"
    case business = "Business"
}
