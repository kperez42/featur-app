// StoreKitManager.swift
// Handles in-app purchases for Featured placements

import SwiftUI
import StoreKit
import FirebaseAuth
import FirebaseFirestore

// MARK: - Product IDs

enum FeaturedProduct: String, CaseIterable {
    case featured24h = "com.featur.featured.24h"
    case featured7d = "com.featur.featured.7d"
    case featured30d = "com.featur.featured.30d"

    var displayName: String {
        switch self {
        case .featured24h: return "24 Hours"
        case .featured7d: return "7 Days"
        case .featured30d: return "30 Days"
        }
    }

    var duration: Int {
        switch self {
        case .featured24h: return 1
        case .featured7d: return 7
        case .featured30d: return 30
        }
    }
}

// MARK: - User-Friendly Error Messages

private func userFriendlyPurchaseError(_ error: Error) -> String {
    if let storeKitError = error as? StoreKitError {
        switch storeKitError {
        case .networkError:
            return "Network connection failed. Please check your internet and try again."
        case .systemError:
            return "A system error occurred. Please restart the app and try again."
        case .notAvailableInStorefront:
            return "This purchase is not available in your region."
        case .userCancelled:
            return "Purchase was cancelled."
        case .notEntitled:
            return "You're not eligible for this purchase."
        default:
            return "Purchase failed. Please try again later."
        }
    }

    // Handle common error patterns
    let errorDescription = error.localizedDescription.lowercased()
    if errorDescription.contains("network") || errorDescription.contains("internet") {
        return "Network connection failed. Please check your internet and try again."
    } else if errorDescription.contains("payment") {
        return "Payment could not be processed. Please check your payment method in Settings."
    } else if errorDescription.contains("cancel") {
        return "Purchase was cancelled."
    }

    return "Purchase failed. Please try again or contact support."
}

// MARK: - Store Manager

@MainActor
class StoreKitManager: ObservableObject {
    static let shared = StoreKitManager()

    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasedProductIDs: Set<String> = []
    @Published var isPurchasing = false
    @Published var purchaseError: String?

    private let service = FirebaseService()
    private var updateListenerTask: Task<Void, Error>?

    private init() {
        updateListenerTask = listenForTransactions()
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Product Loading

    func loadProducts() async {
        #if DEBUG
        // 🧪 In DEBUG mode, simulate products if none are configured in App Store Connect
        do {
            let productIDs = FeaturedProduct.allCases.map { $0.rawValue }
            let storeProducts = try await Product.products(for: productIDs)

            if storeProducts.isEmpty {
                print("⚠️ No products in App Store Connect - using simulated products for testing")
                purchaseError = nil // Clear any error
                // Products will remain empty but we'll handle this in the UI with a test mode
                // The purchase flow will be simulated in the purchase() function
            } else {
                products = storeProducts
                print("✅ Loaded \(products.count) real products from App Store Connect")
            }
        } catch {
            print("⚠️ Failed to load products: \(error) - using simulated mode for testing")
            purchaseError = nil // Clear error in debug mode
        }
        #else
        // Production mode - load real products
        do {
            let productIDs = FeaturedProduct.allCases.map { $0.rawValue }
            products = try await Product.products(for: productIDs)

            // Verify all products loaded
            if products.isEmpty {
                purchaseError = "No products available. Please try again later."
                print("⚠️ Warning: No products loaded from App Store")
            } else if products.count != productIDs.count {
                print("⚠️ Warning: Only \(products.count) of \(productIDs.count) products loaded")
                // Some products might not be approved yet
            }

            print("✅ Loaded \(products.count) products")
        } catch {
            print("❌ Failed to load products: \(error)")
            purchaseError = "Failed to load products. Check your internet connection."

            // Track analytics for debugging
            AnalyticsManager.shared.trackError(
                error: "products_load_failed",
                context: error.localizedDescription
            )
        }
        #endif
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async throws {
        // Check if user is already featured
        if try await isUserCurrentlyFeatured() {
            purchaseError = "You're already featured! Wait for your current placement to expire."
            Haptics.notify(.warning)
            return
        }

        isPurchasing = true
        purchaseError = nil
        defer { isPurchasing = false }

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                // Verify transaction
                let transaction = try checkVerified(verification)

                // Grant access to featured placement
                try await grantFeaturedPlacement(for: transaction)

                // Finish transaction
                await transaction.finish()

                // Update purchased products
                await updateCustomerProductStatus()

                // Track analytics - purchase completed
                print("✅ Analytics: Purchase completed - \(product.id) at \(product.displayPrice)")

                print("✅ Purchase successful: \(product.id)")
                Haptics.notify(.success)

            case .userCancelled:
                print("⚠️ User cancelled purchase")
                Haptics.notify(.warning)

            case .pending:
                print("⏳ Purchase pending")
                purchaseError = "Purchase is pending approval"

            @unknown default:
                print("❌ Unknown purchase result")
                purchaseError = "Unknown purchase result"
            }
        } catch StoreKitError.userCancelled {
            // User cancelled - not an error
            print("⚠️ User cancelled purchase")
        } catch {
            print("❌ Purchase failed: \(error)")
            purchaseError = userFriendlyPurchaseError(error)
            AnalyticsManager.shared.trackError(error: "purchase_failed", context: product.id)
            Haptics.notify(.error)
            throw error
        }
    }

    // MARK: - Restore Purchases

    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await updateCustomerProductStatus()
            print("✅ Purchases restored")
            Haptics.notify(.success)
        } catch {
            print("❌ Failed to restore purchases: \(error)")
            purchaseError = "Failed to restore purchases"
        }
    }

    #if DEBUG
    // MARK: - 🧪 Simulate Test Purchase (DEBUG only)

    func simulateTestPurchase(productId: String) async throws {
        print("🧪 DEBUG: Simulating purchase for product: \(productId)")

        // Check if user is already featured
        if try await isUserCurrentlyFeatured() {
            purchaseError = "You're already featured! Wait for your current placement to expire."
            throw NSError(domain: "TestPurchase", code: -1, userInfo: [NSLocalizedDescriptionKey: "Already featured"])
        }

        guard let currentUserId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "TestPurchase", code: -2, userInfo: [NSLocalizedDescriptionKey: "No authenticated user"])
        }

        // Determine duration based on product ID
        let duration: Int
        if productId.contains("24h") {
            duration = 1
        } else if productId.contains("7d") {
            duration = 7
        } else if productId.contains("30d") {
            duration = 30
        } else {
            duration = 1
        }

        // Calculate expiration date
        let expiresAt = Calendar.current.date(byAdding: .day, value: duration, to: Date()) ?? Date()

        // Fetch user profile
        let profile = try await service.fetchProfile(uid: currentUserId)

        // Create featured entry in Firestore
        let featuredData: [String: Any] = [
            "userId": currentUserId,
            "category": "Featured",
            "highlightText": profile?.bio ?? "Content creator on Featur",
            "featuredAt": FieldValue.serverTimestamp(),
            "expiresAt": expiresAt,
            "priority": 1,
            "transactionId": "test_\(UUID().uuidString)",
            "productId": productId,
            "status": "active",
            "testMode": true // Mark as test purchase
        ]

        try await Firestore.firestore()
            .collection("featured")
            .document(currentUserId)
            .setData(featuredData, merge: true)

        print("✅ 🧪 Test featured placement granted until \(expiresAt)")
    }
    #endif

    // MARK: - Check if User Already Featured

    func isUserCurrentlyFeatured() async throws -> Bool {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            return false
        }

        let snapshot = try await Firestore.firestore()
            .collection("featured")
            .document(currentUserId)
            .getDocument()

        guard let data = snapshot.data(),
              let expiresAt = (data["expiresAt"] as? Timestamp)?.dateValue() else {
            return false
        }

        // Check if still valid
        return expiresAt > Date()
    }

    // MARK: - Private Helpers

    nonisolated private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreKitError.unknown
        case .verified(let safe):
            return safe
        }
    }

    private func grantFeaturedPlacement(for transaction: StoreKit.Transaction) async throws {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "StoreKitManager", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "No authenticated user"])
        }

        // Determine duration based on product ID
        let productID = transaction.productID
        let duration: Int

        if productID.contains("24h") {
            duration = 1
        } else if productID.contains("7d") {
            duration = 7
        } else if productID.contains("30d") {
            duration = 30
        } else {
            duration = 1
        }

        // Calculate expiration date
        let expiresAt = Calendar.current.date(byAdding: .day, value: duration, to: Date()) ?? Date()

        // Fetch user profile
        let profile = try await service.fetchProfile(uid: currentUserId)

        // Create featured entry in Firestore
        let featuredData: [String: Any] = [
            "userId": currentUserId,
            "category": "Featured",
            "highlightText": profile?.bio ?? "Content creator on Featur",
            "featuredAt": FieldValue.serverTimestamp(),
            "expiresAt": expiresAt,
            "priority": 1,
            "transactionId": transaction.id,
            "productId": productID,
            "status": "active"
        ]

        try await Firestore.firestore()
            .collection("featured")
            .document(currentUserId)
            .setData(featuredData, merge: true)

        print("✅ Featured placement granted until \(expiresAt)")
    }

    private func updateCustomerProductStatus() async {
        var purchasedProducts: Set<String> = []

        for await result in StoreKit.Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)

                // Check if transaction is still valid
                if let expirationDate = transaction.expirationDate,
                   expirationDate < Date() {
                    // Expired
                    continue
                }

                purchasedProducts.insert(transaction.productID)
            } catch {
                print("❌ Failed to verify transaction: \(error)")
            }
        }

        purchasedProductIDs = purchasedProducts
    }

    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached { [weak self] in
            guard let self = self else { return }
            for await result in StoreKit.Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)

                    // Grant access
                    try await self.grantFeaturedPlacement(for: transaction)

                    // Finish transaction
                    await transaction.finish()

                    // Update status
                    await self.updateCustomerProductStatus()
                } catch {
                    print("❌ Transaction update failed: \(error)")
                }
            }
        }
    }
}

// MARK: - Product Extensions

extension Product {
    var localizedPrice: String {
        return displayPrice
    }
}
