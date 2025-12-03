// CachedAsyncImage.swift
// High-performance image loading with automatic caching

import SwiftUI

/// Cached image loader with automatic memory and disk caching
struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    let url: URL?
    let content: (Image) -> Content
    let placeholder: () -> Placeholder

    @State private var image: UIImage?
    @State private var isLoading = false

    init(
        url: URL?,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.content = content
        self.placeholder = placeholder
    }

    var body: some View {
        Group {
            if let image = image {
                content(Image(uiImage: image))
            } else {
                placeholder()
                    .onAppear {
                        loadImage()
                    }
            }
        }
    }

    private func loadImage() {
        guard let url = url, !isLoading else { return }

        // Check memory cache first
        if let cachedImage = ImageCache.shared.get(forKey: url.absoluteString) {
            self.image = cachedImage
            return
        }

        isLoading = true

        Task {
            do {
                // Use URLSession with caching enabled
                let (data, response) = try await URLSession.shared.data(from: url)

                // Validate response
                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200,
                      let downloadedImage = UIImage(data: data) else {
                    isLoading = false
                    return
                }

                // Store in memory cache
                ImageCache.shared.set(downloadedImage, forKey: url.absoluteString)

                await MainActor.run {
                    self.image = downloadedImage
                    self.isLoading = false
                }

            } catch {
                print("❌ Failed to load image from \(url): \(error)")
                isLoading = false
            }
        }
    }
}

// MARK: - Image Cache Manager

class ImageCache {
    static let shared = ImageCache()

    private let cache = NSCache<NSString, UIImage>()

    private init() {
        // Configure cache limits
        cache.countLimit = 100 // Max 100 images in memory
        cache.totalCostLimit = 100 * 1024 * 1024 // Max 100 MB
    }

    func get(forKey key: String) -> UIImage? {
        return cache.object(forKey: key as NSString)
    }

    func set(_ image: UIImage, forKey key: String) {
        // Estimate cost based on image size
        let cost = image.size.width * image.size.height * 4 // 4 bytes per pixel (RGBA)
        cache.setObject(image, forKey: key as NSString, cost: Int(cost))
    }

    func clear() {
        cache.removeAllObjects()
    }
}

// MARK: - Convenience Initializer

extension CachedAsyncImage where Content == Image, Placeholder == AnyView {
    init(url: URL?) {
        self.url = url
        self.content = { $0.resizable() }
        self.placeholder = { AnyView(ProgressView()) }
    }
}
