import SwiftUI

struct SocialsPage: View {
    @Binding var instagram: String
    @Binding var tiktok: String

    var body: some View {
        FlowPageContainer(title: "Link your gaming profiles") {
            VStack(alignment: .center, spacing: 16) {

                Text("Connect your streaming and social accounts so teammates can find you.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                VStack(spacing: 16) {
                    // Twitch (using tiktok field for backwards compatibility)
                    SocialTextField(
                        icon: "tv",
                        platform: "Twitch",
                        placeholder: "your_channel",
                        text: $tiktok
                    )

                    // Discord/Gaming Tag (using instagram field)
                    SocialTextField(
                        icon: "message.fill",
                        platform: "Discord",
                        placeholder: "username#0000",
                        text: $instagram
                    )
                }
                .padding(.horizontal)

                // Gaming platform suggestions
                VStack(spacing: 8) {
                    Text("More platforms coming soon!")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)

                    HStack(spacing: 12) {
                        GamingPlatformBadge(name: "Steam", icon: "gamecontroller")
                        GamingPlatformBadge(name: "Xbox", icon: "xmark.circle")
                        GamingPlatformBadge(name: "PlayStation", icon: "play.circle")
                    }
                }
                .padding(.top, 16)

                if !instagram.isEmpty || !tiktok.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("Accounts linked!")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 8)
                }
            }
            .frame(maxWidth: .infinity, alignment: .top)
        }
    }
}

// MARK: - Gaming Platform Badge

struct GamingPlatformBadge: View {
    let name: String
    let icon: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(name)
                .font(.caption2)
        }
        .foregroundStyle(.secondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(AppTheme.card.opacity(0.5), in: Capsule())
    }
}

// MARK: - Social Text Field

struct SocialTextField: View {
    let icon: String
    let platform: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(AppTheme.accent)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(platform)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                TextField(placeholder, text: $text)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .font(.subheadline)
            }

            Spacer()

            if !text.isEmpty {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.caption)
            }
        }
        .padding()
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 14))
    }
}
