// CachedAsyncImage.swift
// High-performance image loading with memory + disk caching

import SwiftUI

/// Cached image loader with automatic memory and disk caching
struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    let url: URL?
    let targetSize: CGSize?
    let content: (Image) -> Content
    let placeholder: () -> Placeholder

    @State private var image: UIImage?
    @State private var isLoading = false

    init(
        url: URL?,
        targetSize: CGSize? = nil,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.targetSize = targetSize
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

        let cacheKey = url.absoluteString

        // Check memory cache first (instant)
        if let cachedImage = ImageCache.shared.get(forKey: cacheKey) {
            self.image = cachedImage
            return
        }

        // Check disk cache (fast)
        if let diskImage = ImageCache.shared.getFromDisk(forKey: cacheKey) {
            ImageCache.shared.set(diskImage, forKey: cacheKey) // Promote to memory
            self.image = diskImage
            return
        }

        isLoading = true

        Task.detached(priority: .userInitiated) {
            do {
                // Configure request for faster loading
                var request = URLRequest(url: url)
                request.cachePolicy = .returnCacheDataElseLoad

                let (data, response) = try await URLSession.shared.data(for: request)

                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200,
                      var downloadedImage = UIImage(data: data) else {
                    await MainActor.run { isLoading = false }
                    return
                }

                // Downsample large images for memory efficiency
                if let targetSize = await MainActor.run(body: { targetSize }),
                   downloadedImage.size.width > targetSize.width * 2 {
                    downloadedImage = downloadedImage.downsampled(to: targetSize) ?? downloadedImage
                }

                // Cache in memory and disk
                ImageCache.shared.set(downloadedImage, forKey: cacheKey)
                ImageCache.shared.saveToDisk(downloadedImage, forKey: cacheKey)

                await MainActor.run {
                    self.image = downloadedImage
                    self.isLoading = false
                }

            } catch {
                print("❌ Failed to load image: \(error.localizedDescription)")
                await MainActor.run { isLoading = false }
            }
        }
    }
}

// MARK: - Image Cache Manager (Memory + Disk)

class ImageCache {
    static let shared = ImageCache()

    private let memoryCache = NSCache<NSString, UIImage>()
    private let diskCacheURL: URL
    private let fileManager = FileManager.default
    private let diskQueue = DispatchQueue(label: "com.featur.imagecache.disk", qos: .utility)

    private init() {
        // Configure memory cache
        memoryCache.countLimit = 150
        memoryCache.totalCostLimit = 150 * 1024 * 1024 // 150 MB

        // Setup disk cache directory
        let cacheDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        diskCacheURL = cacheDir.appendingPathComponent("ImageCache", isDirectory: true)

        // Create directory if needed
        try? fileManager.createDirectory(at: diskCacheURL, withIntermediateDirectories: true)

        // Clear old cache on launch (older than 7 days)
        cleanOldDiskCache()
    }

    // MARK: - Memory Cache

    func get(forKey key: String) -> UIImage? {
        return memoryCache.object(forKey: key as NSString)
    }

    func set(_ image: UIImage, forKey key: String) {
        let cost = Int(image.size.width * image.size.height * 4)
        memoryCache.setObject(image, forKey: key as NSString, cost: cost)
    }

    // MARK: - Disk Cache

    func getFromDisk(forKey key: String) -> UIImage? {
        let fileURL = diskCacheURL.appendingPathComponent(key.md5Hash)
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return UIImage(data: data)
    }

    func saveToDisk(_ image: UIImage, forKey key: String) {
        diskQueue.async { [weak self] in
            guard let self = self,
                  let data = image.jpegData(compressionQuality: 0.8) else { return }
            let fileURL = self.diskCacheURL.appendingPathComponent(key.md5Hash)
            try? data.write(to: fileURL)
        }
    }

    private func cleanOldDiskCache() {
        diskQueue.async { [weak self] in
            guard let self = self else { return }
            let sevenDaysAgo = Date().addingTimeInterval(-7 * 24 * 60 * 60)

            guard let files = try? self.fileManager.contentsOfDirectory(
                at: self.diskCacheURL,
                includingPropertiesForKeys: [.contentModificationDateKey]
            ) else { return }

            for file in files {
                if let attrs = try? self.fileManager.attributesOfItem(atPath: file.path),
                   let modDate = attrs[.modificationDate] as? Date,
                   modDate < sevenDaysAgo {
                    try? self.fileManager.removeItem(at: file)
                }
            }
        }
    }

    func clear() {
        memoryCache.removeAllObjects()
        diskQueue.async { [weak self] in
            guard let self = self else { return }
            try? self.fileManager.removeItem(at: self.diskCacheURL)
            try? self.fileManager.createDirectory(at: self.diskCacheURL, withIntermediateDirectories: true)
        }
    }

    /// Prefetch images for smooth scrolling
    func prefetch(urls: [URL]) {
        for url in urls {
            let key = url.absoluteString
            guard get(forKey: key) == nil else { continue }

            Task.detached(priority: .utility) {
                guard let (data, _) = try? await URLSession.shared.data(from: url),
                      let image = UIImage(data: data) else { return }
                ImageCache.shared.set(image, forKey: key)
                ImageCache.shared.saveToDisk(image, forKey: key)
            }
        }
    }
}

// MARK: - UIImage Downsampling

extension UIImage {
    func downsampled(to targetSize: CGSize) -> UIImage? {
        let scale = UIScreen.main.scale
        let targetPixelSize = CGSize(width: targetSize.width * scale, height: targetSize.height * scale)

        guard let cgImage = self.cgImage else { return nil }

        let options: [CFString: Any] = [
            kCGImageSourceThumbnailMaxPixelSize: max(targetPixelSize.width, targetPixelSize.height),
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true
        ]

        guard let data = self.jpegData(compressionQuality: 1.0),
              let source = CGImageSourceCreateWithData(data as CFData, nil),
              let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return nil
        }

        return UIImage(cgImage: thumbnail, scale: scale, orientation: imageOrientation)
    }
}

// MARK: - String MD5 Hash for Cache Keys

import CryptoKit

extension String {
    var md5Hash: String {
        let data = Data(self.utf8)
        let hash = Insecure.MD5.hash(data: data)
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Convenience Initializer

extension CachedAsyncImage where Content == Image, Placeholder == AnyView {
    init(url: URL?) {
        self.url = url
        self.targetSize = nil
        self.content = { $0.resizable() }
        self.placeholder = { AnyView(ProgressView()) }
    }
}
