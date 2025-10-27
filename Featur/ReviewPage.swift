import SwiftUI

struct ReviewPage: View {
    var gender: String
    var age: Int?
    var styles: [UserProfile.ContentStyle]
    var ig: String
    var tt: String
    var media: [String]
    
    var body: some View {
        FlowPageContainer(title: "Review Your Profile") {
            VStack(alignment: .leading, spacing: 16) {
          
                // --- Summary text ---
                Text("Make sure everything looks right before you finish.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal, 4)

                // --- Basic Info ---
                GroupBox(label: Text("Basic Info").font(.headline)) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Gender: \(gender)")
                        if let age = age { Text("Age: \(age)") }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                // --- Content Styles ---
                GroupBox(label: Text("Content Styles").font(.headline)) {
                    if styles.isEmpty {
                        Text("None selected").foregroundStyle(.secondary)
                    } else {
                        Text(styles.map { $0.rawValue }.joined(separator: ", "))
                    }
                }

                // --- Social Links ---
                GroupBox(label: Text("Social Links").font(.headline)) {
                    if ig.isEmpty && tt.isEmpty {
                        Text("No socials added").foregroundStyle(.secondary)
                    } else {
                        if !ig.isEmpty { Text("Instagram: @\(ig)") }
                        if !tt.isEmpty { Text("TikTok: @\(tt)") }
                    }
                }

                // --- Media ---
                GroupBox(label: Text("Media").font(.headline)) {
                    if media.isEmpty {
                        Text("No content uploaded").foregroundStyle(.secondary)
                    } else {
                        Text("\(media.count) item\(media.count > 1 ? "s" : "") added")
                    }
                }

                Text("Tap **Finish** below to create your profile.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.top, 8)
            }
            .frame(maxWidth: .infinity, alignment: .top)
        }
    }
}
