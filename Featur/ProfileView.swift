import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    @EnvironmentObject var auth: AuthViewModel

    @State private var displayName: String = ""
    @State private var email: String = ""
    @State private var appleAnon: Bool = false

    var body: some View {
        VStack(spacing: 20) {
            // Avatar (initials)
            ZStack {
                Circle().fill(.purple.opacity(0.15))
                Text(initials(from: displayName.isEmpty ? email : displayName))
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.purple)
            }
            .frame(width: 96, height: 96)

            // Name + email
            VStack(spacing: 6) {
                Text(displayName.isEmpty ? "Creator" : displayName)
                    .font(.title2).bold()
                if !email.isEmpty {
                    Text(email).foregroundStyle(.secondary)
                }
                if appleAnon {
                    Text("Signed in with Apple (private relay email)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            // Actions
            VStack(spacing: 12) {
                

                // (Optional) show UID for debugging
                if let uid = Auth.auth().currentUser?.uid {
                    Text("UID: \(uid)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                }
            }

            Spacer()
        }
        .padding()
        .onAppear(perform: loadUser)
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func loadUser() {
        let u = Auth.auth().currentUser
        displayName = u?.displayName ?? ""
        email = u?.email ?? ""
        if let provider = u?.providerData.first(where: { $0.providerID == "apple.com" }),
           let mail = provider.email, mail.contains("privaterelay.appleid.com") {
            appleAnon = true
        } else {
            appleAnon = false
        }
    }

    private func initials(from text: String) -> String {
        let parts = text.split(separator: " ")
        let letters = parts.prefix(2).compactMap { $0.first }
        if letters.isEmpty, let first = text.first { return String(first).uppercased() }
        return letters.map { String($0).uppercased() }.joined()
    }
}
