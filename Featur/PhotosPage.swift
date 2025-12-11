import SwiftUI
import PhotosUI
import FirebaseAuth
import FirebaseStorage

struct PhotosPage: View {
    @Binding var mediaURLs: [String]
    @Binding var profileImageURL: String?
    
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var isUploading = false
    @EnvironmentObject var viewModel: ProfileViewModel

    var body: some View {
        FlowPageContainer(title: "Add Your Best Content") {
            VStack(alignment: .center, spacing: 16) {
                
                Text("Upload 1–3 of your top photos to build your Featur profile.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                
                // Upload progress
                if isUploading {
                    ProgressView("Uploading...")
                        .tint(AppTheme.accent)
                        .padding(.vertical)
                }

                // Photo picker
                PhotosPicker(
                    selection: $selectedItems,
                    maxSelectionCount: 3,
                    matching: .images
                ) {
                    VStack(spacing: 12) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 60))
                            .foregroundStyle(.secondary)
                        
                        Text(mediaURLs.isEmpty ? "Tap to choose photos" :
                             "Selected \(mediaURLs.count) photo\(mediaURLs.count > 1 ? "s" : "")")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 180)
                    .background(AppTheme.card, in: RoundedRectangle(cornerRadius: 16))
                }
                .onChange(of: selectedItems) { _, newItems in
                    Task { await uploadSelectedPhotos(newItems) }
                }

                // Preview uploaded photos
                if !mediaURLs.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(mediaURLs, id: \.self) { url in
                                AsyncImage(url: URL(string: url)) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height: 100)
                                        .clipped()
                                } placeholder: {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(width: 100, height: 100)
                                        .overlay(ProgressView().tint(AppTheme.accent))
                                }
                                .frame(width: 100, height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .onTapGesture {
                                    profileImageURL = url
                                }
                                .overlay {
                                    if profileImageURL == url {
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(AppTheme.accent, lineWidth: 3)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

                    Text("Tap a photo to set as your profile picture")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.top, 8)
                }
            }
            .frame(maxWidth: .infinity, alignment: .top)
        }
    }

    // MARK: - Upload logic
    private func uploadSelectedPhotos(_ items: [PhotosPickerItem]) async {
        guard let uid = Auth.auth().currentUser?.uid else {
            print(" No user logged in — cannot upload photos.")
            return
        }

        print(" Starting upload of \(items.count) photo(s) for user: \(uid)")
        isUploading = true
        defer { isUploading = false }

        for (index, item) in items.enumerated() {
            do {
                guard let data = try await item.loadTransferable(type: Data.self) else {
                    print(" [\(index + 1)] No image data found — skipping.")
                    continue
                }

                // Convert HEIC → JPEG if needed
                guard let image = UIImage(data: data),
                      let compressed = image.jpegData(compressionQuality: 0.7) else {
                    print(" [\(index + 1)] Failed to convert to JPEG — skipping.")
                    continue
                }

                print(" [\(index + 1)] Uploading \(compressed.count / 1024) KB...")

                let url = try await viewModel.uploadImageToStorage(userId: uid, data: compressed)

                print(" [\(index + 1)] Uploaded! URL: \(url)")

                await MainActor.run {
                    mediaURLs.append(url)
                    if profileImageURL == nil { profileImageURL = url }
                }

            } catch {
                print(" [\(index + 1)] Upload failed: \(error.localizedDescription)")
            }
        }

        print(" Finished all uploads. Final mediaURLs count: \(mediaURLs.count)")
    }
}
