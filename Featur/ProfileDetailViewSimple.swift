//

import SwiftUI

struct ProfileDetailViewSimple: View {
    let profile: UserProfile
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Main image
                if let first = profile.mediaURLs?.first, let url = URL(string: first) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().scaledToFill()
                        default:
                            Rectangle().fill(Color.gray.opacity(0.3))
                        }
                    }
                    .frame(height: 420)
                    .clipped()
                }

                // Name & age
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(profile.displayName)
                            .font(.largeTitle.bold())
                        if let age = profile.age {
                            Text("\\(age)")
                                .font(.title2)
                                .foregroundColor(.secondary)
                        }
                    }

                    if let bio = profile.bio, !bio.isEmpty {
                        Text(bio)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

                // Content styles
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
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                }

                Spacer(minLength: 40)
            }
        }
        .background(AppTheme.bg)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.primary)
                }
            }
        }
    }
}
