import SwiftUI

struct SocialsPage: View {
    @Binding var instagram: String
    @Binding var tiktok: String
    
    var body: some View {
        FlowPageContainer(title: "Connect your socials") {
            VStack(alignment: .center, spacing: 16) {
                
                Text("Let others find your creative work.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                
                VStack(spacing: 16) {
                    SocialTextField(
                        icon: "camera",
                        platform: "Instagram",
                        placeholder: "@username",
                        text: $instagram
                    )
                    
                    SocialTextField(
                        icon: "music.note",
                        platform: "TikTok",
                        placeholder: "@username",
                        text: $tiktok
                    )
                }
                .padding(.horizontal)
                
                if !instagram.isEmpty || !tiktok.isEmpty {
                    Text("Added: \(instagram.isEmpty ? "" : "Instagram") \(tiktok.isEmpty ? "" : "TikTok")")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.top, 8)
                }
            }
            .frame(maxWidth: .infinity, alignment: .top)
        }
    }
}

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
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField(placeholder, text: $text)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .font(.subheadline)
            }
        }
        .padding()
        .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 14))
    }
}
