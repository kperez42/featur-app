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
        do {
            let productIDs = FeaturedProduct.allCases.map { $0.rawValue }
            products = try await Product.products(for: productIDs)
            print("✅ Loaded \(products.count) products")
        } catch {
            print("❌ Failed to load products: \(error)")
            purchaseError = "Failed to load products"
        }
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async throws {
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

                // Track analytics
                AnalyticsManager.shared.trackPurchaseCompleted(
                    productId: product.id,
                    price: product.displayPrice
                )

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
            purchaseError = error.localizedDescription
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

    // MARK: - Private Helpers

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreKitError.unknown
        case .verified(let safe):
            return safe
        }
    }

    private func grantFeaturedPlacement(for transaction: Transaction) async throws {
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
        let profile = try await service.fetchProfile(forUser: currentUserId)

        // Create featured entry in Firestore
        let featuredData: [String: Any] = [
            "userId": currentUserId,
            "category": "Featured",
            "highlightText": profile.bio ?? "Content creator on Featur",
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

        for await result in Transaction.currentEntitlements {
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
        return Task.detached {
            for await result in Transaction.updates {
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
