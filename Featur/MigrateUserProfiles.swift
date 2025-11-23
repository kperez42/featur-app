// MigrateUserProfiles.swift
// ONE-TIME MIGRATION UTILITY - Can be deleted after running once
// This updates all existing user profiles to include the new verification fields

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct MigrateUserProfilesView: View {
    @State private var isRunning = false
    @State private var resultMessage = ""
    @State private var updatedCount = 0

    var body: some View {
        VStack(spacing: 20) {
            Text("Migrate User Profiles")
                .font(.title.bold())

            Text("This will update ALL user profiles to include the new verification fields:")
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 8) {
                Text("• email: String?")
                Text("• isEmailVerified: Bool?")
                Text("• phoneNumber: String?")
                Text("• isPhoneVerified: Bool?")
            }
            .font(.caption.monospaced())
            .padding()
            .background(.gray.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))

            if !resultMessage.isEmpty {
                Text(resultMessage)
                    .font(.subheadline)
                    .foregroundStyle(resultMessage.contains("✅") ? .green : .orange)
                    .multilineTextAlignment(.center)
                    .padding()
            }

            Button {
                Task {
                    await migrateAllProfiles()
                }
            } label: {
                if isRunning {
                    HStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        Text("Migrating... (\(updatedCount) updated)")
                    }
                } else {
                    Text("Run Migration")
                }
            }
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(isRunning ? .gray : .blue, in: RoundedRectangle(cornerRadius: 12))
            .disabled(isRunning)
            .padding(.horizontal)

            Text("⚠️ This is safe to run - it only ADDS missing fields, never deletes data")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }

    private func migrateAllProfiles() async {
        isRunning = true
        resultMessage = "Starting migration..."
        updatedCount = 0

        let db = Firestore.firestore()

        do {
            // Fetch all user profiles
            let snapshot = try await db.collection("users").getDocuments()

            resultMessage = "Found \(snapshot.documents.count) user profiles to check..."

            for document in snapshot.documents {
                let data = document.data()
                var updates: [String: Any] = [:]

                // Add email field if missing
                if data["email"] == nil {
                    // Try to get email from Firebase Auth if this is the current user
                    if document.documentID == Auth.auth().currentUser?.uid {
                        if let authEmail = Auth.auth().currentUser?.email {
                            updates["email"] = authEmail
                        }
                    } else {
                        // For other users, leave empty (they can add it later)
                        updates["email"] = ""
                    }
                }

                // Add isEmailVerified field if missing
                if data["isEmailVerified"] == nil {
                    // Check if this user's email is verified in Firebase Auth
                    if document.documentID == Auth.auth().currentUser?.uid {
                        updates["isEmailVerified"] = Auth.auth().currentUser?.isEmailVerified ?? false
                    } else {
                        updates["isEmailVerified"] = false
                    }
                }

                // Add phoneNumber field if missing
                if data["phoneNumber"] == nil {
                    updates["phoneNumber"] = "" // Empty by default
                }

                // Add isPhoneVerified field if missing
                if data["isPhoneVerified"] == nil {
                    updates["isPhoneVerified"] = false
                }

                // Only update if there are missing fields
                if !updates.isEmpty {
                    try await document.reference.updateData(updates)
                    updatedCount += 1
                    resultMessage = "Migrated \(updatedCount) profiles..."
                }
            }

            resultMessage = "✅ Migration Complete!\n\nUpdated \(updatedCount) of \(snapshot.documents.count) profiles.\n\nAll profiles now have verification fields."

        } catch {
            resultMessage = "❌ Error: \(error.localizedDescription)"
        }

        isRunning = false
    }
}

// MARK: - How to Use This Migration Utility

/*

 ## USAGE INSTRUCTIONS:

 1. Temporarily add this view to your app's navigation
    - Option A: Add it to the Settings menu
    - Option B: Add it to ContentView for quick access

 2. Run the migration ONCE by tapping the "Run Migration" button

 3. After successful migration, you can:
    - Delete this file
    - Remove the navigation link to this view

 ## EXAMPLE: Add to Settings Menu

 In your SettingsView or wherever you want to access it:

 ```swift
 NavigationLink {
     MigrateUserProfilesView()
 } label: {
     Label("Migrate Profiles (One-Time)", systemImage: "arrow.triangle.2.circlepath")
 }
 ```

 ## EXAMPLE: Add to ContentView for Quick Testing

 In ContentView:

 ```swift
 .sheet(isPresented: $showMigration) {
     NavigationStack {
         MigrateUserProfilesView()
             .navigationTitle("Migration")
     }
 }
 .toolbar {
     ToolbarItem {
         Button("Migrate") {
             showMigration = true
         }
     }
 }
 ```

 ## What This Does:

 - Scans ALL user profiles in Firestore
 - Adds missing fields: email, isEmailVerified, phoneNumber, isPhoneVerified
 - Safe to run multiple times (only adds missing fields)
 - Shows progress and results

 ## After Migration:

 All test accounts will have the new fields and their profile previews will
 look consistent with your main account's updated profile preview.

 */
