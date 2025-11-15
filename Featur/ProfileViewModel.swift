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
    
    // MARK: - Load Profile
    
    func loadProfile(uid: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let document = try await db.collection("users").document(uid).getDocument()
            
            if document.exists {
                self.profile = try document.data(as: UserProfile.self)
                self.needsSetup = false
            } else {
                self.needsSetup = true
                self.profile = nil
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
            
            try db.collection("users")
                .document(updatedProfile.uid)
                .setData(from: profileToSave, merge: true)
            
            self.profile = profileToSave
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
            try db.collection("users")
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
    
    func uploadImageToStorage(userId: String, data: Data) async throws -> String {
        let filename = UUID().uuidString + ".jpg"
        let path = "profile_photos/\(userId)/\(filename)"
        let ref = storage.reference().child(path)
        
        // Upload the image
        let _ = try await ref.putDataAsync(data)
        
        // Get download URL
        let downloadURL = try await ref.downloadURL()
        return downloadURL.absoluteString
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
    
    // MARK: - Add Media URLs
    
    func addMediaURL(userId: String, url: String) async {
        do {
            try await db.collection("users")
                .document(userId)
                .updateData([
                    "mediaURLs": FieldValue.arrayUnion([url])
                ])
            
            // Update local profile
            if var currentProfile = self.profile {

                // If mediaURLs is nil, create it
                var urls = currentProfile.mediaURLs ?? []
                urls.append(url)

                // Reassign back into the struct
                currentProfile.mediaURLs = urls
                self.profile = currentProfile
            }
            
            print("✅ Media URL added")
        } catch {
            self.errorMessage = "Failed to add media: \(error.localizedDescription)"
            print("❌ Error adding media: \(error)")
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
        await loadProfile(uid: uid)
    }
    
    func clearError() {
        errorMessage = nil
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
}
