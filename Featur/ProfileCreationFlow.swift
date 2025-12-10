import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ProfileCreationFlow: View {
    @ObservedObject var viewModel: ProfileViewModel

    enum Step: Int, CaseIterable { case gender, age, contentType, socials, photos, location, review }
    @State private var step: Step = .gender

    // Local state
    @State private var gender: String = ""
    @State private var age: Int?
    @State private var contentStyles: [UserProfile.ContentStyle] = []
    @State private var instagram: String = ""
    @State private var tiktok: String = ""
    @State private var mediaURLs: [String] = []
    @State private var profileImageURL: String?
    @StateObject private var locationManager = LocationManager()
    @EnvironmentObject var auth: AuthViewModel

    // Custom view for step progress bar
        private var stepProgressBar: some View {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background bar
                    RoundedRectangle(cornerRadius: 4)
                        .frame(height: 8)
                        .foregroundColor(AppTheme.card) //
                    
                    // Progress bar
                    RoundedRectangle(cornerRadius: 4)
                        .frame(width: geometry.size.width * CGFloat(step.rawValue + 1) / CGFloat(Step.allCases.count), height: 8)
                        .foregroundColor(AppTheme.accent) // Use your app's accent color
                }
            }
            .frame(height: 16) // step progress bar locked to 16 
            .padding(.horizontal)
            .padding(.vertical, 4)
        }

    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                
                // --- Step Progress Bar ---
                stepProgressBar
                // --- Step Header ---
                HStack {
                     
                    if step != .gender {
                        Button(action: onBack) {
                            Image(systemName: "chevron.left")
                                .font(.headline)
                                .padding(10)
                                .background(AppTheme.card, in: Circle())
                        }
                    }

                    Spacer()
                    Text("Step \(step.rawValue + 1) of \(Step.allCases.count)")
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(.secondary)
                    Spacer()

                    if step != .gender { Color.clear.frame(width: 36) }
                }
                .padding(.horizontal)
                .padding(.top, 0)//top
                .background(AppTheme.bg) // keeps color consistent under safe area
                .frame(maxWidth: .infinity)
                .frame(height: 44) // Approximate height of step header (adjust if needed)

                // --- Current Page ---
                Group {
                    switch step {
                    case .gender:
                        GenderPage(gender: $gender)
                    case .age:
                        AgePage(age: Binding(get: { age ?? 0 }, set: { age = $0 }))
                    case .contentType:
                        ContentTypePage(selected: $contentStyles)
                    case .socials:
                        SocialsPage(instagram: $instagram, tiktok: $tiktok)
                    case .photos:
                        PhotosPage(mediaURLs: $mediaURLs, profileImageURL: $profileImageURL)
                            .environmentObject(viewModel)
                    case .location:
                        LocationAccessPage(locationManager: locationManager)
                        
                    case .review:
                        ReviewPage(
                            gender: gender,
                            age: age,
                            styles: contentStyles,
                            ig: instagram,
                            tt: tiktok,
                            media: mediaURLs
                            
                        )
                    }
                }
                .animation(.easeInOut, value: step)
                .transition(.opacity)
                // Automatically advance once user grants location access
                .onChange(of: locationManager.authorizationStatus) { _, newStatus in
                    if newStatus == .authorizedWhenInUse ||
                       newStatus == .authorizedAlways {
                        withAnimation(.easeInOut) {
                            step = .review
                        }
                    }
                }


                // --- Continue Button ---
                Button(action: onContinue) {
                    Text(step == .review ? "Finish" : "Continue")
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isStepValid(step))
                .padding(.horizontal)
                .padding(.bottom, 12)
            }
        }
        .background(AppTheme.bg.ignoresSafeArea())
        .animation(.spring(), value: step)
    }

    // --- Step Validation ---
    private func isStepValid(_ s: Step) -> Bool {
        switch s {
        case .gender:      return !gender.isEmpty
        case .age:         return (age ?? 0) > 12
        case .contentType: return !contentStyles.isEmpty
        case .socials:     return true
        case .photos:      return true
        case .location:     return locationManager.authorizationStatus == .authorizedWhenInUse ||
                                    locationManager.authorizationStatus == .authorizedAlways
        case .review:      return true
        }
    }

    // --- Navigation Controls ---
    private func onBack() {
        if step.rawValue > 0 {
            step = Step(rawValue: step.rawValue - 1) ?? .gender
        }
    }

    private func onContinue() {
        if step == .review {
            Task { await saveProfile() }
        } else {
            step = Step(rawValue: step.rawValue + 1) ?? .review
        }
    }

    // --- Save Profile ---
    private func saveProfile() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let user = Auth.auth().currentUser

        var links = UserProfile.SocialLinks()
        if !instagram.isEmpty {
            links.instagram = .init(username: instagram, followerCount: nil, isVerified: false)
        }
        if !tiktok.isEmpty {
            links.tiktok = .init(username: tiktok, followerCount: nil, isVerified: false)
        }

        let db = Firestore.firestore()
        let doc = try? await db.collection("users").document(uid).getDocument()
        
        let nameFromRegistration = doc?.get("name") as? String ?? user?.displayName ?? "New Creator"

        let newProfile = UserProfile(
            uid: uid,
            displayName: nameFromRegistration,
            age: age,
            location: UserProfile.Location(
                city: locationManager.city,
                state: locationManager.state,
                country: locationManager.country,
                coordinates: locationManager.coordinates
            ),
            contentStyles: contentStyles,
            socialLinks: links,
            mediaURLs: mediaURLs,
            profileImageURL: profileImageURL
        )



        await viewModel.updateProfile(newProfile)
        try? await db.collection("users").document(uid).setData(
                ["isCompleteProfile": true],
                merge: true
            )
        //refresh user auth state
        await auth.refreshUserState()

    }
}
