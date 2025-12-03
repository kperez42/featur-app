import SwiftUI

struct TermsOfServiceView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Terms of Service")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text("Last Updated: December 3, 2025")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Divider()

                    // 1. Acceptance of Terms
                    LegalSection(title: "1. Acceptance of Terms") {
                        Text("By downloading, installing, or using Featur (\"the App\"), you agree to be bound by these Terms of Service. If you do not agree, do not use the App.")
                    }

                    // 2. Eligibility
                    LegalSection(title: "2. Eligibility") {
                        VStack(alignment: .leading, spacing: 8) {
                            BulletPoint("You must be at least 17 years old to use Featur")
                            BulletPoint("You must have the legal capacity to enter into these Terms")
                            BulletPoint("You must not be prohibited from using the App under applicable laws")
                        }
                    }

                    // 3. Account Registration
                    LegalSection(title: "3. Account Registration") {
                        VStack(alignment: .leading, spacing: 8) {
                            BulletPoint("You must provide accurate and complete information")
                            BulletPoint("You are responsible for maintaining your account security")
                            BulletPoint("You must not share your account credentials")
                            BulletPoint("One account per person is permitted")
                        }
                    }

                    // 4. User Conduct
                    LegalSection(title: "4. User Conduct") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("You agree NOT to:")
                                .fontWeight(.medium)
                            BulletPoint("Impersonate any person or entity")
                            BulletPoint("Post false, misleading, or fraudulent content")
                            BulletPoint("Harass, abuse, or harm other users")
                            BulletPoint("Upload illegal, offensive, or inappropriate content")
                            BulletPoint("Use the App for commercial solicitation without permission")
                            BulletPoint("Attempt to hack, reverse engineer, or compromise the App")
                            BulletPoint("Violate any applicable laws or regulations")
                            BulletPoint("Create multiple accounts or fake profiles")
                        }
                    }

                    // 5. Content Guidelines
                    LegalSection(title: "5. Content Guidelines") {
                        VStack(alignment: .leading, spacing: 16) {
                            LegalSubsection(title: "Your Content") {
                                VStack(alignment: .leading, spacing: 8) {
                                    BulletPoint("You retain ownership of content you post")
                                    BulletPoint("You grant us a license to use, display, and distribute your content within the App")
                                    BulletPoint("You are responsible for content you post")
                                    BulletPoint("We may remove content that violates these Terms")
                                }
                            }

                            LegalSubsection(title: "Prohibited Content") {
                                VStack(alignment: .leading, spacing: 8) {
                                    BulletPoint("Nudity or sexual content")
                                    BulletPoint("Violence or graphic content")
                                    BulletPoint("Hate speech or discrimination")
                                    BulletPoint("Spam or commercial advertising")
                                    BulletPoint("Personal information of others without consent")
                                    BulletPoint("Copyrighted material you don't own")
                                }
                            }
                        }
                    }

                    // 6. Matching and Messaging
                    LegalSection(title: "6. Matching and Messaging") {
                        VStack(alignment: .leading, spacing: 8) {
                            BulletPoint("Matches are based on mutual interest (both users swipe right)")
                            BulletPoint("Messages are private between matched users")
                            BulletPoint("We do not guarantee compatibility or outcomes")
                            BulletPoint("Report inappropriate behavior to our support team")
                        }
                    }

                    // 7. Premium Features
                    LegalSection(title: "7. Premium Features") {
                        VStack(alignment: .leading, spacing: 8) {
                            BulletPoint("Some features may require payment")
                            BulletPoint("Purchases are processed through Apple App Store")
                            BulletPoint("Refunds are subject to Apple's refund policy")
                            BulletPoint("Prices may change with notice")
                        }
                    }

                    // 8. Intellectual Property
                    LegalSection(title: "8. Intellectual Property") {
                        VStack(alignment: .leading, spacing: 8) {
                            BulletPoint("Featur and its content are protected by intellectual property laws")
                            BulletPoint("You may not copy, modify, or distribute our trademarks or content")
                            BulletPoint("User-generated content remains yours, subject to our license")
                        }
                    }

                    // 9. Privacy
                    LegalSection(title: "9. Privacy") {
                        Text("Your use of the App is also governed by our Privacy Policy, which is incorporated by reference.")
                    }

                    // 10. Disclaimers
                    LegalSection(title: "10. Disclaimers") {
                        VStack(alignment: .leading, spacing: 8) {
                            BulletPoint("The App is provided \"AS IS\" without warranties")
                            BulletPoint("We do not guarantee uninterrupted or error-free service")
                            BulletPoint("We are not responsible for user interactions or content")
                            BulletPoint("We do not verify user identities or backgrounds")
                        }
                    }

                    // 11. Limitation of Liability
                    LegalSection(title: "11. Limitation of Liability") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("To the maximum extent permitted by law:")
                            BulletPoint("We are not liable for indirect, incidental, or consequential damages")
                            BulletPoint("Our total liability is limited to the amount you paid us in the past 12 months")
                            BulletPoint("We are not responsible for actions of other users")
                        }
                    }

                    // 12. Indemnification
                    LegalSection(title: "12. Indemnification") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("You agree to indemnify and hold us harmless from claims arising from:")
                            BulletPoint("Your use of the App")
                            BulletPoint("Your violation of these Terms")
                            BulletPoint("Your content")
                            BulletPoint("Your interactions with other users")
                        }
                    }

                    // 13. Termination
                    LegalSection(title: "13. Termination") {
                        VStack(alignment: .leading, spacing: 8) {
                            BulletPoint("You may delete your account at any time")
                            BulletPoint("We may suspend or terminate your account for violations")
                            BulletPoint("Upon termination, your right to use the App ceases")
                            BulletPoint("Certain provisions survive termination")
                        }
                    }

                    // 14. Modifications
                    LegalSection(title: "14. Modifications") {
                        Text("We may modify these Terms at any time. Continued use after changes constitutes acceptance.")
                    }

                    // 15. Governing Law
                    LegalSection(title: "15. Governing Law") {
                        Text("These Terms are governed by the laws of the State of California, USA.")
                    }

                    // 16. Dispute Resolution
                    LegalSection(title: "16. Dispute Resolution") {
                        Text("Any disputes shall be resolved through binding arbitration, except for small claims court matters.")
                    }

                    // 17. Contact
                    LegalSection(title: "17. Contact") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("For questions about these Terms:")
                            Text("Email: support@featur.app")
                                .fontWeight(.medium)
                            Text("Developer: Kevin Perez")
                                .fontWeight(.medium)
                        }
                    }

                    // 18. Entire Agreement
                    LegalSection(title: "18. Entire Agreement") {
                        Text("These Terms, along with our Privacy Policy, constitute the entire agreement between you and Featur.")
                    }

                    Divider()

                    Text("By using Featur, you acknowledge that you have read, understood, and agree to these Terms of Service.")
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

#Preview {
    TermsOfServiceView()
}
