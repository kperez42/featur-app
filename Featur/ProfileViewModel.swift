import SwiftUI
import PhotosUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var profile: UserProfile?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var needsSetup = false

    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    private let firebaseService = FirebaseService()

    // Cache to prevent unnecessary reloads
    private var cachedUID: String?
    private var lastLoadTime: Date?
    private let cacheValidDuration: TimeInterval = 60 // 60 seconds cache

    // MARK: - Load Profile

    func loadProfile(uid: String) async {
        // Check cache first - only reload if cache is invalid or different user
        if let cachedUID = cachedUID,
           cachedUID == uid,
           let lastLoad = lastLoadTime,
           Date().timeIntervalSince(lastLoad) < cacheValidDuration {
            print("📦 Using cached profile for \(uid)")
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let document = try await db.collection("users").document(uid).getDocument()

            if document.exists {
                do {
                    var profile = try document.data(as: UserProfile.self)
                    // Ensure uid is set (use document ID as fallback)
                    if profile.uid.isEmpty {
                        profile.uid = document.documentID
                    }
                    self.profile = profile
                } catch {
                    // Fallback: manually decode with document ID as uid
                    if let profile = decodeProfileWithFallback(document: document, uid: uid) {
                        self.profile = profile
                    } else {
                        throw error
                    }
                }
                self.needsSetup = false
                // Update cache
                self.cachedUID = uid
                self.lastLoadTime = Date()
            } else {
                self.needsSetup = true
                self.profile = nil
                self.cachedUID = nil
                self.lastLoadTime = nil
            }
        } catch {
            self.errorMessage = "Failed to load profile: \(error.localizedDescription)"
            self.needsSetup = true
            print("❌ Error loading profile: \(error)")
        }

        isLoading = false
    }
    
    // MARK: - Update Profile

    func updateProfile(_ updatedProfile: UserProfile) async {
        isLoading = true
        errorMessage = nil

        do {
            var profileToSave = updatedProfile
            profileToSave.updatedAt = Date()

            try await db.collection("users")
                .document(updatedProfile.uid)
                .setData(from: profileToSave, merge: true)

            self.profile = profileToSave
            // Refresh cache timestamp
            self.lastLoadTime = Date()
            print("✅ Profile updated successfully")
        } catch {
            self.errorMessage = "Failed to update profile: \(error.localizedDescription)"
            print("❌ Error updating profile: \(error)")
        }

        isLoading = false
    }
    
    // MARK: - Create Profile
    
    func createProfile(_ newProfile: UserProfile) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await db.collection("users")
                .document(newProfile.uid)
                .setData(from: newProfile)

            self.profile = newProfile
            self.needsSetup = false
            print("✅ Profile created successfully")
        } catch {
            self.errorMessage = "Failed to create profile: \(error.localizedDescription)"
            print("❌ Error creating profile: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - Upload Image

    func uploadImageToStorage(userId: String, data: Data, isGalleryPhoto: Bool = false) async throws -> String {
        let filename = UUID().uuidString + ".jpg"
        // Use media/ path for gallery photos, profile_photos/ for profile picture
        let path = isGalleryPhoto ? "media/\(userId)/\(filename)" : "profile_photos/\(userId)/\(filename)"

        print("📤 Uploading image to: \(path)")

        // Use FireBaseService which has retry logic
        let url = try await firebaseService.uploadMedia(data: data, path: path)

        print("✅ Upload successful: \(url)")
        return url
    }
    
    // MARK: - Update Profile Photo

    func updateProfilePhoto(userId: String, imageData: Data) async {
        isLoading = true

        do {
            let url = try await uploadImageToStorage(userId: userId, data: imageData)

            // Update profile with new photo URL
            if var currentProfile = self.profile {
                currentProfile.profileImageURL = url
                await updateProfile(currentProfile)
            } else {
                // Update just the photo URL in Firestore
                try await db.collection("users")
                    .document(userId)
                    .updateData(["profileImageURL": url])

                print("✅ Profile photo updated")
            }
        } catch {
            self.errorMessage = "Failed to upload photo: \(error.localizedDescription)"
            print("❌ Error uploading photo: \(error)")
        }

        isLoading = false
    }

    // MARK: - Upload Gallery Photo

    func uploadGalleryPhoto(userId: String, imageData: Data) async -> String? {
        do {
            print("📸 Starting gallery photo upload for user: \(userId)")
            print("   Image size: \(imageData.count / 1024)KB")

            let url = try await uploadImageToStorage(userId: userId, data: imageData, isGalleryPhoto: true)
            print("✅ Gallery photo uploaded: \(url)")
            return url
        } catch let error as NSError {
            // Check if this is a network/WiFi blocking issue
            var isWiFiBlocking = false
            if error.domain == NSURLErrorDomain && error.code == -1200 {
                isWiFiBlocking = true
            } else if error.domain == "FIRStorageErrorDomain",
                      let underlying = error.userInfo[NSUnderlyingErrorKey] as? NSError,
                      underlying.domain == NSURLErrorDomain && underlying.code == -1200 {
                isWiFiBlocking = true
            }

            if isWiFiBlocking {
                self.errorMessage = "⚠️ WiFi network blocking uploads. Please switch to cellular data and try again."
                print("❌ WiFi network is blocking Firebase Storage connection")
                print("   💡 Solution: Turn OFF WiFi and use cellular data for uploads")
            } else {
                self.errorMessage = "Failed to upload photo: \(error.localizedDescription)"
                print("❌ Error uploading gallery photo: \(error)")
            }
            print("   Error details: code=\(error.code), domain=\(error.domain)")
            return nil
        }
    }
    
    // MARK: - Add Media URLs

    func addMediaURL(userId: String, url: String) async {
        do {
            try await db.collection("users")
                .document(userId)
                .updateData([
                    "mediaURLs": FirebaseFirestore.FieldValue.arrayUnion([url])
                ])

            // Update local profile
            if var currentProfile = self.profile {

                // If mediaURLs is nil, create it
                var urls = currentProfile.mediaURLs ?? []
                urls.append(url)

                // Reassign back into the struct
                currentProfile.mediaURLs = urls
                self.profile = currentProfile
                // Refresh cache timestamp
                self.lastLoadTime = Date()

                print("✅ Media URL added to profile")
                print("   Total photos in profile: \(urls.count)")
                print("   URLs: \(urls.map { String($0.suffix(20)) })")
            } else {
                print("⚠️ No current profile found to update")
            }

        } catch {
            self.errorMessage = "Failed to add media: \(error.localizedDescription)"
            print("❌ Error adding media: \(error)")
        }
    }

    // MARK: - Remove Media URL

    func removeMediaURL(userId: String, url: String) async {
        do {
            try await db.collection("users")
                .document(userId)
                .updateData([
                    "mediaURLs": FirebaseFirestore.FieldValue.arrayRemove([url])
                ])

            // Update local profile
            if var currentProfile = self.profile {
                var urls = currentProfile.mediaURLs ?? []
                urls.removeAll { $0 == url }

                // Reassign back into the struct
                currentProfile.mediaURLs = urls.isEmpty ? nil : urls
                self.profile = currentProfile
                // Refresh cache timestamp
                self.lastLoadTime = Date()
            }

            print("✅ Media URL removed")
        } catch {
            self.errorMessage = "Failed to remove media: \(error.localizedDescription)"
            print("❌ Error removing media: \(error)")
        }
    }
    
    // MARK: - Delete Profile
    
    func deleteProfile(uid: String) async {
        isLoading = true
        
        do {
            try await db.collection("users").document(uid).delete()
            self.profile = nil
            self.needsSetup = true
            print("✅ Profile deleted")
        } catch {
            self.errorMessage = "Failed to delete profile: \(error.localizedDescription)"
            print("❌ Error deleting profile: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - Helper Methods

    func refreshProfile() async {
        guard let uid = profile?.uid ?? Auth.auth().currentUser?.uid else { return }
        print("🔄 Refreshing profile from Firestore...")
        // Force refresh by clearing cache
        cachedUID = nil
        lastLoadTime = nil
        await loadProfile(uid: uid)
        if let refreshedProfile = self.profile {
            print("✅ Profile refreshed - photos: \(refreshedProfile.mediaURLs?.count ?? 0)")
            if let urls = refreshedProfile.mediaURLs {
                print("   URLs: \(urls.map { String($0.suffix(20)) })")
            }
        }
    }

    func clearError() {
        errorMessage = nil
    }

    // Force clear cache to reload fresh data
    func invalidateCache() {
        cachedUID = nil
        lastLoadTime = nil
    }
    
    func uploadPhotos(_ items: [PhotosUI.PhotosPickerItem]) async {
        guard let uid = profile?.uid else { return }

        var urls: [String] = profile?.mediaURLs ?? []

        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self) {
                if let url = try? await uploadImageToStorage(userId: uid, data: data) {
                    urls.append(url)
                }
            }
        }

        if var updatedProfile = profile {
            updatedProfile.mediaURLs = urls
            await updateProfile(updatedProfile)
        }
    }

    // MARK: - Fallback Decoding

    /// Helper to decode a profile when standard Codable decoding fails (e.g., missing uid field)
    private func decodeProfileWithFallback(document: DocumentSnapshot, uid: String) -> UserProfile? {
        guard let data = document.data() else { return nil }

        // Use document ID or provided uid
        let profileUid = (data["uid"] as? String) ?? uid
        let displayName = (data["displayName"] as? String) ?? "Unknown"

        // Parse content styles
        var contentStyles: [UserProfile.ContentStyle] = []
        if let stylesArray = data["contentStyles"] as? [String] {
            contentStyles = stylesArray.compactMap { UserProfile.ContentStyle(rawValue: $0) }
        }

        // Parse dates
        let createdAt: Date
        if let timestamp = data["createdAt"] as? Timestamp {
            createdAt = timestamp.dateValue()
        } else {
            createdAt = Date()
        }

        let updatedAt: Date
        if let timestamp = data["updatedAt"] as? Timestamp {
            updatedAt = timestamp.dateValue()
        } else {
            updatedAt = Date()
        }

        // Create profile with required fields
        var profile = UserProfile(
            uid: profileUid,
            displayName: displayName,
            contentStyles: contentStyles,
            createdAt: createdAt,
            updatedAt: updatedAt
        )

        // Set optional fields
        profile.age = data["age"] as? Int
        profile.bio = data["bio"] as? String
        profile.interests = data["interests"] as? [String]
        profile.mediaURLs = data["mediaURLs"] as? [String]
        profile.profileImageURL = data["profileImageURL"] as? String
        profile.isVerified = data["isVerified"] as? Bool
        profile.followerCount = data["followerCount"] as? Int
        profile.email = data["email"] as? String
        profile.isEmailVerified = data["isEmailVerified"] as? Bool
        profile.phoneNumber = data["phoneNumber"] as? String
        profile.isPhoneVerified = data["isPhoneVerified"] as? Bool

        // Parse location if present
        if let locationData = data["location"] as? [String: Any] {
            var location = UserProfile.Location()
            location.city = locationData["city"] as? String
            location.state = locationData["state"] as? String
            location.country = locationData["country"] as? String
            if let geoPoint = locationData["coordinates"] as? GeoPoint {
                location.coordinates = geoPoint
            }
            profile.location = location
        }

        print("✅ Decoded profile with fallback: \(displayName) (uid: \(profileUid))")
        return profile
    }
}
