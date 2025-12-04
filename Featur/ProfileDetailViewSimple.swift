//
import SwiftUI

struct ProfileDetailViewSimple: View {
    let profile: UserProfile
    @Environment(\.dismiss) var dismiss

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

                    // Main image
                    if let first = profile.mediaURLs?.first?.trimmingCharacters(in: .whitespacesAndNewlines),
                       let url = URL(string: first) {

                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: UIScreen.main.bounds.width - 32, height: 420)
                                    .clipped()
                                    .cornerRadius(12)


                            case .empty:
                                ZStack {
                                    Color.black.opacity(0.1)
                                    ProgressView()
                                }
                                .frame(height: 420)

                            default:
                                Color.gray.opacity(0.25)
                                    .frame(height: 420)
                            }
                        }
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

                    Spacer().frame(height: 40)
                }
            }
        }
        .interactiveDismissDisabled(false)  // ALLOW SWIPE DOWN EVEN WITH SCROLLVIEW
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
                if value.translation.height > 120 {  // Tinder-style threshold
                    dismiss()
                }
            }
        )
    }
}
