import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Privacy Policy")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text("Last Updated: December 3, 2025")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Divider()

                    // Introduction
                    LegalSection(title: "Introduction") {
                        Text("Featur (\"we,\" \"our,\" or \"us\") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application.")
                    }

                    // Information We Collect
                    LegalSection(title: "Information We Collect") {
                        VStack(alignment: .leading, spacing: 16) {
                            LegalSubsection(title: "Personal Information") {
                                Text("When you create an account, we collect:")
                                BulletPoint("Account Information: Email address, display name, profile photo")
                                BulletPoint("Profile Information: Age, bio, interests, content styles, location (city/state)")
                                BulletPoint("Social Media Links: Optional links to your TikTok, Instagram, YouTube, Twitch, or other platforms")
                            }

                            LegalSubsection(title: "Usage Information") {
                                Text("We automatically collect:")
                                BulletPoint("Device Information: Device type, operating system, unique device identifiers")
                                BulletPoint("Usage Data: Features used, interactions with other users, time spent in app")
                                BulletPoint("Analytics Data: App performance, crash reports, feature usage statistics")
                            }

                            LegalSubsection(title: "User-Generated Content") {
                                BulletPoint("Photos: Profile photos and gallery images you upload")
                                BulletPoint("Messages: Content of messages sent to other users")
                                BulletPoint("Swipe Activity: Your likes, passes, and matches")
                            }
                        }
                    }

                    // How We Use Your Information
                    LegalSection(title: "How We Use Your Information") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("We use collected information to:")
                            BulletPoint("Create and manage your account")
                            BulletPoint("Display your profile to other users")
                            BulletPoint("Facilitate matches and messaging between users")
                            BulletPoint("Improve our app and develop new features")
                            BulletPoint("Send notifications about matches, messages, and app updates")
                            BulletPoint("Ensure safety and prevent fraud")
                            BulletPoint("Comply with legal obligations")
                        }
                    }

                    // Information Sharing
                    LegalSection(title: "Information Sharing") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("We do ")
                            + Text("not").fontWeight(.bold)
                            + Text(" sell your personal information. We may share information with:")

                            BulletPoint("Other Users: Your profile information is visible to other Featur users")
                            BulletPoint("Service Providers: Firebase (authentication, database, storage), analytics providers")
                            BulletPoint("Legal Requirements: When required by law or to protect our rights")
                        }
                    }

                    // Data Storage and Security
                    LegalSection(title: "Data Storage and Security") {
                        VStack(alignment: .leading, spacing: 8) {
                            BulletPoint("Your data is stored securely using Firebase/Google Cloud infrastructure")
                            BulletPoint("We use industry-standard encryption for data transmission (HTTPS/TLS)")
                            BulletPoint("Authentication is handled securely through Firebase Authentication")
                            BulletPoint("We implement access controls to protect your data")
                        }
                    }

                    // Your Rights and Choices
                    LegalSection(title: "Your Rights and Choices") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("You can:")
                            BulletPoint("Access: View your profile information at any time")
                            BulletPoint("Update: Edit your profile, photos, and preferences")
                            BulletPoint("Delete: Request account deletion through the app settings")
                            BulletPoint("Opt-out: Disable notifications in your device settings")
                        }
                    }

                    // Data Retention
                    LegalSection(title: "Data Retention") {
                        VStack(alignment: .leading, spacing: 8) {
                            BulletPoint("We retain your data while your account is active")
                            BulletPoint("Upon account deletion, we remove your personal data within 30 days")
                            BulletPoint("Some data may be retained longer for legal compliance")
                        }
                    }

                    // Children's Privacy
                    LegalSection(title: "Children's Privacy") {
                        Text("Featur is not intended for users under 17 years of age. We do not knowingly collect information from children under 17. If we discover such data, we will delete it promptly.")
                    }

                    // Third-Party Services
                    LegalSection(title: "Third-Party Services") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Our app uses:")
                            BulletPoint("Firebase (Google): Authentication, database, storage, analytics")
                            BulletPoint("Apple: Sign in with Apple authentication")
                            Text("These services have their own privacy policies.")
                                .padding(.top, 4)
                        }
                    }

                    // Changes to This Policy
                    LegalSection(title: "Changes to This Policy") {
                        Text("We may update this Privacy Policy periodically. We will notify you of significant changes through the app or via email.")
                    }

                    // California Privacy Rights
                    LegalSection(title: "California Privacy Rights (CCPA)") {
                        Text("California residents have additional rights including the right to know what personal information is collected and the right to request deletion.")
                    }

                    // European Users
                    LegalSection(title: "European Users (GDPR)") {
                        Text("If you are in the European Economic Area, you have rights under GDPR including access, rectification, erasure, and data portability.")
                    }

                    // Contact Us
                    LegalSection(title: "Contact Us") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("If you have questions about this Privacy Policy or your data:")
                            Text("Email: support@featur.app")
                                .fontWeight(.medium)
                            Text("Developer: Kevin Perez")
                                .fontWeight(.medium)
                        }
                    }

                    Divider()

                    Text("By using Featur, you agree to this Privacy Policy.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 32)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct LegalSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)

            content
                .font(.body)
                .foregroundStyle(.primary.opacity(0.9))
        }
    }
}

struct LegalSubsection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)

            content
        }
    }
}

struct BulletPoint: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .fontWeight(.bold)
            Text(text)
        }
        .padding(.leading, 8)
    }
}

#Preview {
    PrivacyPolicyView()
}
