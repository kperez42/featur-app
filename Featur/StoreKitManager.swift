// StoreKitManager.swift
// Handles in-app purchases and subscriptions for Featured placements

import SwiftUI
import StoreKit
import FirebaseAuth
import FirebaseFirestore
import UserNotifications

// MARK: - Product IDs

enum FeaturedProduct: String, CaseIterable {
    case featured24h = "com.featur.featured.24h"
    case featured7d = "com.featur.featured.7d"
    case featured30d = "com.featur.featured.30d"

    // Auto-renewable subscription products (if configured)
    case featuredMonthly = "com.featur.featured.monthly"
    case featuredYearly = "com.featur.featured.yearly"

    var displayName: String {
        switch self {
        case .featured24h: return "24 Hours"
        case .featured7d: return "7 Days"
        case .featured30d: return "30 Days"
        case .featuredMonthly: return "Monthly"
        case .featuredYearly: return "Yearly"
        }
    }

    var duration: Int {
        switch self {
        case .featured24h: return 1
        case .featured7d: return 7
        case .featured30d: return 30
        case .featuredMonthly: return 30
        case .featuredYearly: return 365
        }
    }

    var isSubscription: Bool {
        switch self {
        case .featuredMonthly, .featuredYearly:
            return true
        default:
            return false
        }
    }

    // One-time purchase products only (for initial implementation)
    static var consumableProducts: [FeaturedProduct] {
        [.featured24h, .featured7d, .featured30d]
    }
}

// MARK: - Subscription Status

enum SubscriptionStatus: Equatable {
    case notSubscribed
    case active(expiresAt: Date, productId: String, isAutoRenewing: Bool)
    case expired(expiredAt: Date)
    case pending

    var isActive: Bool {
        if case .active = self { return true }
        return false
    }

    var expirationDate: Date? {
        switch self {
        case .active(let date, _, _): return date
        case .expired(let date): return date
        default: return nil
        }
    }
}

// MARK: - Store Manager

@MainActor
class StoreKitManager: ObservableObject {
    static let shared = StoreKitManager()

    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasedProductIDs: Set<String> = []
    @Published private(set) var subscriptionStatus: SubscriptionStatus = .notSubscribed
    @Published var isPurchasing = false
    @Published var purchaseError: String?
    @Published var isRestoring = false
    @Published var featuredExpiresAt: Date?

    private let service = FirebaseService()
    private var updateListenerTask: Task<Void, Error>?
    private var statusCheckTimer: Timer?

    // UserDefaults keys for local caching
    private let kFeaturedExpiresAt = "featured_expires_at"
    private let kFeaturedProductId = "featured_product_id"
    private let kFeaturedIsAutoRenewing = "featured_is_auto_renewing"

    private init() {
        // Start listening for transactions
        updateListenerTask = listenForTransactions()

        // Load cached subscription status
        loadCachedSubscriptionStatus()

        // Start periodic status check
        startStatusCheckTimer()

        // Check subscription status on init
        Task {
            await checkAndUpdateSubscriptionStatus()
        }
    }

    deinit {
        updateListenerTask?.cancel()
        statusCheckTimer?.invalidate()
    }

    // MARK: - Status Check Timer

    private func startStatusCheckTimer() {
        // Check subscription status every 5 minutes
        statusCheckTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.checkAndUpdateSubscriptionStatus()
            }
        }
    }

    // MARK: - Product Loading

    func loadProducts() async {
        #if DEBUG
        // In DEBUG mode, simulate products if none are configured in App Store Connect
        do {
            let productIDs = FeaturedProduct.consumableProducts.map { $0.rawValue }
            let storeProducts = try await Product.products(for: productIDs)

            if storeProducts.isEmpty {
                print("⚠️ No products in App Store Connect - using simulated products for testing")
                purchaseError = nil
            } else {
                products = storeProducts.sorted { p1, p2 in
                    // Sort by duration (24h, 7d, 30d)
                    let d1 = FeaturedProduct(rawValue: p1.id)?.duration ?? 0
                    let d2 = FeaturedProduct(rawValue: p2.id)?.duration ?? 0
                    return d1 < d2
                }
                print("✅ Loaded \(products.count) real products from App Store Connect")
            }
        } catch {
            print("⚠️ Failed to load products: \(error) - using simulated mode for testing")
            purchaseError = nil
        }
        #else
        // Production mode - load real products
        do {
            let productIDs = FeaturedProduct.consumableProducts.map { $0.rawValue }
            products = try await Product.products(for: productIDs)

            // Sort products by duration
            products.sort { p1, p2 in
                let d1 = FeaturedProduct(rawValue: p1.id)?.duration ?? 0
                let d2 = FeaturedProduct(rawValue: p2.id)?.duration ?? 0
                return d1 < d2
            }

            if products.isEmpty {
                purchaseError = "No products available. Please try again later."
                print("⚠️ Warning: No products loaded from App Store")
                AnalyticsManager.shared.trackError(error: "no_products_available", context: "Product list empty")
            } else if products.count != productIDs.count {
                print("⚠️ Warning: Only \(products.count) of \(productIDs.count) products loaded")
            }

            print("✅ Loaded \(products.count) products")
        } catch {
            print("❌ Failed to load products: \(error)")
            purchaseError = "Failed to load products. Check your internet connection."
            AnalyticsManager.shared.trackError(error: "products_load_failed", context: error.localizedDescription)
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

                // Update purchased products and subscription status
                await updateCustomerProductStatus()
                await checkAndUpdateSubscriptionStatus()

                // Schedule expiration notification
                await scheduleExpirationNotification(for: transaction)

                // Track analytics
                AnalyticsManager.shared.trackPurchase(productId: product.id, price: product.displayPrice)
                print("✅ Purchase successful: \(product.id)")
                Haptics.notify(.success)

            case .userCancelled:
                print("⚠️ User cancelled purchase")
                Haptics.notify(.warning)

            case .pending:
                print("⏳ Purchase pending")
                purchaseError = "Purchase is pending approval. You'll be featured once approved."
                subscriptionStatus = .pending
                Haptics.notify(.warning)

            @unknown default:
                print("❌ Unknown purchase result")
                purchaseError = "Unknown purchase result. Please try again."
            }
        } catch StoreKitError.userCancelled {
            print("⚠️ User cancelled purchase")
        } catch {
            print("❌ Purchase failed: \(error)")
            purchaseError = "Purchase failed: \(error.localizedDescription)"
            AnalyticsManager.shared.trackError(error: "purchase_failed", context: "\(product.id): \(error.localizedDescription)")
            Haptics.notify(.error)
            throw error
        }
    }

    // MARK: - Restore Purchases

    func restorePurchases() async {
        isRestoring = true
        purchaseError = nil
        defer { isRestoring = false }

        do {
            // Sync with App Store
            try await AppStore.sync()

            // Verify and process all current entitlements
            var hasValidPurchase = false
            var latestTransaction: StoreKit.Transaction?
            var latestExpirationDate: Date?

            for await result in StoreKit.Transaction.currentEntitlements {
                do {
                    let transaction = try checkVerified(result)

                    // Check if this is a featured product
                    guard FeaturedProduct(rawValue: transaction.productID) != nil else {
                        continue
                    }

                    // Check expiration
                    if let expirationDate = transaction.expirationDate {
                        if expirationDate > Date() {
                            hasValidPurchase = true
                            if latestExpirationDate == nil || expirationDate > latestExpirationDate! {
                                latestExpirationDate = expirationDate
                                latestTransaction = transaction
                            }
                        }
                    } else {
                        // Non-expiring consumable - check Firestore for expiration
                        let firestoreExpiration = try await getFirestoreExpiration(for: transaction.productID)
                        if let expDate = firestoreExpiration, expDate > Date() {
                            hasValidPurchase = true
                            if latestExpirationDate == nil || expDate > latestExpirationDate! {
                                latestExpirationDate = expDate
                                latestTransaction = transaction
                            }
                        }
                    }
                } catch {
                    print("❌ Failed to verify restored transaction: \(error)")
                }
            }

            // If we found a valid purchase, restore the featured placement
            if hasValidPurchase, let transaction = latestTransaction {
                // Re-grant featured placement if needed
                let isCurrentlyFeatured = try await isUserCurrentlyFeatured()
                if !isCurrentlyFeatured {
                    try await grantFeaturedPlacement(for: transaction)
                }

                await updateCustomerProductStatus()
                await checkAndUpdateSubscriptionStatus()

                print("✅ Purchases restored successfully")
                Haptics.notify(.success)
            } else {
                print("ℹ️ No active purchases to restore")
                purchaseError = "No active purchases found to restore."
                Haptics.notify(.warning)
            }
        } catch {
            print("❌ Failed to restore purchases: \(error)")
            purchaseError = "Failed to restore purchases: \(error.localizedDescription)"
            AnalyticsManager.shared.trackError(error: "restore_failed", context: error.localizedDescription)
            Haptics.notify(.error)
        }
    }

    // MARK: - Get Firestore Expiration

    private func getFirestoreExpiration(for productId: String) async throws -> Date? {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            return nil
        }

        let snapshot = try await Firestore.firestore()
            .collection("featured")
            .document(currentUserId)
            .getDocument()

        guard let data = snapshot.data(),
              let expiresAt = (data["expiresAt"] as? Timestamp)?.dateValue() else {
            return nil
        }

        return expiresAt
    }

    #if DEBUG
    // MARK: - Simulate Test Purchase (DEBUG only)

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
            "testMode": true,
            "isAutoRenewing": false
        ]

        try await Firestore.firestore()
            .collection("featured")
            .document(currentUserId)
            .setData(featuredData, merge: true)

        // Update local state
        featuredExpiresAt = expiresAt
        subscriptionStatus = .active(expiresAt: expiresAt, productId: productId, isAutoRenewing: false)
        cacheSubscriptionStatus(expiresAt: expiresAt, productId: productId, isAutoRenewing: false)

        // Schedule expiration notification
        await scheduleExpirationNotificationForDate(expiresAt, productId: productId)

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
        let isValid = expiresAt > Date()

        // Update local state if valid
        if isValid {
            let productId = data["productId"] as? String ?? ""
            let isAutoRenewing = data["isAutoRenewing"] as? Bool ?? false
            featuredExpiresAt = expiresAt
            subscriptionStatus = .active(expiresAt: expiresAt, productId: productId, isAutoRenewing: isAutoRenewing)
        }

        return isValid
    }

    // MARK: - Get Featured Status Details

    func getFeaturedStatusDetails() async throws -> (expiresAt: Date?, productId: String?, isAutoRenewing: Bool) {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            return (nil, nil, false)
        }

        let snapshot = try await Firestore.firestore()
            .collection("featured")
            .document(currentUserId)
            .getDocument()

        guard let data = snapshot.data(),
              let expiresAt = (data["expiresAt"] as? Timestamp)?.dateValue(),
              expiresAt > Date() else {
            return (nil, nil, false)
        }

        let productId = data["productId"] as? String
        let isAutoRenewing = data["isAutoRenewing"] as? Bool ?? false

        return (expiresAt, productId, isAutoRenewing)
    }

    // MARK: - Check and Update Subscription Status

    func checkAndUpdateSubscriptionStatus() async {
        do {
            let (expiresAt, productId, isAutoRenewing) = try await getFeaturedStatusDetails()

            if let expiresAt = expiresAt, let productId = productId {
                featuredExpiresAt = expiresAt
                subscriptionStatus = .active(expiresAt: expiresAt, productId: productId, isAutoRenewing: isAutoRenewing)
                cacheSubscriptionStatus(expiresAt: expiresAt, productId: productId, isAutoRenewing: isAutoRenewing)
            } else {
                // Check if there was a previous expiration
                if let cachedExpiration = UserDefaults.standard.object(forKey: kFeaturedExpiresAt) as? Date,
                   cachedExpiration < Date() {
                    subscriptionStatus = .expired(expiredAt: cachedExpiration)
                    featuredExpiresAt = nil
                } else {
                    subscriptionStatus = .notSubscribed
                    featuredExpiresAt = nil
                }
                clearCachedSubscriptionStatus()
            }
        } catch {
            print("❌ Failed to check subscription status: \(error)")
        }
    }

    // MARK: - Expiration Notifications

    private func scheduleExpirationNotification(for transaction: StoreKit.Transaction) async {
        guard let featuredProduct = FeaturedProduct(rawValue: transaction.productID) else { return }

        let duration = featuredProduct.duration
        let expiresAt = Calendar.current.date(byAdding: .day, value: duration, to: Date()) ?? Date()

        await scheduleExpirationNotificationForDate(expiresAt, productId: transaction.productID)
    }

    private func scheduleExpirationNotificationForDate(_ expiresAt: Date, productId: String) async {
        // Request notification permission if needed
        let center = UNUserNotificationCenter.current()

        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            guard granted else { return }
        } catch {
            print("❌ Failed to request notification permission: \(error)")
            return
        }

        // Remove any existing expiration notifications
        center.removePendingNotificationRequests(withIdentifiers: ["featured_expiring_soon", "featured_expired"])

        // Schedule "expiring soon" notification (24 hours before)
        let warningDate = Calendar.current.date(byAdding: .hour, value: -24, to: expiresAt) ?? expiresAt
        if warningDate > Date() {
            let warningContent = UNMutableNotificationContent()
            warningContent.title = "Featured Placement Expiring"
            warningContent.body = "Your featured placement expires in 24 hours. Renew now to stay visible!"
            warningContent.sound = .default
            warningContent.badge = 1

            let warningTrigger = UNCalendarNotificationTrigger(
                dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: warningDate),
                repeats: false
            )

            let warningRequest = UNNotificationRequest(identifier: "featured_expiring_soon", content: warningContent, trigger: warningTrigger)
            try? await center.add(warningRequest)
        }

        // Schedule "expired" notification
        let expiredContent = UNMutableNotificationContent()
        expiredContent.title = "Featured Placement Expired"
        expiredContent.body = "Your featured placement has ended. Get featured again to boost your visibility!"
        expiredContent.sound = .default
        expiredContent.badge = 1

        let expiredTrigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: expiresAt),
            repeats: false
        )

        let expiredRequest = UNNotificationRequest(identifier: "featured_expired", content: expiredContent, trigger: expiredTrigger)
        try? await center.add(expiredRequest)

        print("✅ Scheduled expiration notifications for \(expiresAt)")
    }

    // MARK: - Cache Management

    private func loadCachedSubscriptionStatus() {
        guard let expiresAt = UserDefaults.standard.object(forKey: kFeaturedExpiresAt) as? Date else {
            subscriptionStatus = .notSubscribed
            return
        }

        let productId = UserDefaults.standard.string(forKey: kFeaturedProductId) ?? ""
        let isAutoRenewing = UserDefaults.standard.bool(forKey: kFeaturedIsAutoRenewing)

        if expiresAt > Date() {
            featuredExpiresAt = expiresAt
            subscriptionStatus = .active(expiresAt: expiresAt, productId: productId, isAutoRenewing: isAutoRenewing)
        } else {
            subscriptionStatus = .expired(expiredAt: expiresAt)
        }
    }

    private func cacheSubscriptionStatus(expiresAt: Date, productId: String, isAutoRenewing: Bool) {
        UserDefaults.standard.set(expiresAt, forKey: kFeaturedExpiresAt)
        UserDefaults.standard.set(productId, forKey: kFeaturedProductId)
        UserDefaults.standard.set(isAutoRenewing, forKey: kFeaturedIsAutoRenewing)
    }

    private func clearCachedSubscriptionStatus() {
        UserDefaults.standard.removeObject(forKey: kFeaturedExpiresAt)
        UserDefaults.standard.removeObject(forKey: kFeaturedProductId)
        UserDefaults.standard.removeObject(forKey: kFeaturedIsAutoRenewing)
    }

    // MARK: - Private Helpers

    nonisolated private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            print("❌ Transaction verification failed: \(error)")
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
        guard let featuredProduct = FeaturedProduct(rawValue: productID) else {
            throw NSError(domain: "StoreKitManager", code: -2,
                         userInfo: [NSLocalizedDescriptionKey: "Unknown product ID"])
        }

        let duration = featuredProduct.duration

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
            "transactionId": String(transaction.id),
            "originalTransactionId": String(transaction.originalID),
            "productId": productID,
            "status": "active",
            "isAutoRenewing": featuredProduct.isSubscription,
            "purchaseDate": transaction.purchaseDate,
            "environment": transaction.environment.rawValue
        ]

        try await Firestore.firestore()
            .collection("featured")
            .document(currentUserId)
            .setData(featuredData, merge: true)

        // Also store in purchase history
        let historyData: [String: Any] = [
            "userId": currentUserId,
            "transactionId": String(transaction.id),
            "productId": productID,
            "purchaseDate": FieldValue.serverTimestamp(),
            "expiresAt": expiresAt,
            "status": "completed"
        ]

        try await Firestore.firestore()
            .collection("purchase_history")
            .document(String(transaction.id))
            .setData(historyData)

        // Update local state
        featuredExpiresAt = expiresAt
        subscriptionStatus = .active(expiresAt: expiresAt, productId: productID, isAutoRenewing: featuredProduct.isSubscription)
        cacheSubscriptionStatus(expiresAt: expiresAt, productId: productID, isAutoRenewing: featuredProduct.isSubscription)

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

                    print("📦 Transaction update received: \(transaction.productID)")

                    // Check if this is a renewal or new purchase
                    if transaction.revocationDate != nil {
                        // Transaction was revoked (refund, etc.)
                        print("⚠️ Transaction revoked: \(transaction.id)")
                        await MainActor.run {
                            self.handleRevocation(transaction: transaction)
                        }
                    } else {
                        // Grant access
                        try await self.grantFeaturedPlacement(for: transaction)

                        // Schedule expiration notification
                        await self.scheduleExpirationNotification(for: transaction)
                    }

                    // Finish transaction
                    await transaction.finish()

                    // Update status
                    await self.updateCustomerProductStatus()
                    await self.checkAndUpdateSubscriptionStatus()

                } catch {
                    print("❌ Transaction update failed: \(error)")
                }
            }
        }
    }

    // MARK: - Handle Revocation (Refunds)

    private func handleRevocation(transaction: StoreKit.Transaction) {
        Task {
            guard let currentUserId = Auth.auth().currentUser?.uid else { return }

            // Update Firestore to mark as revoked
            try? await Firestore.firestore()
                .collection("featured")
                .document(currentUserId)
                .updateData([
                    "status": "revoked",
                    "revokedAt": FieldValue.serverTimestamp()
                ])

            // Update local state
            subscriptionStatus = .notSubscribed
            featuredExpiresAt = nil
            clearCachedSubscriptionStatus()

            // Remove pending notifications
            UNUserNotificationCenter.current().removePendingNotificationRequests(
                withIdentifiers: ["featured_expiring_soon", "featured_expired"]
            )

            print("✅ Handled transaction revocation")
        }
    }

    // MARK: - Extend Featured Placement

    func extendFeaturedPlacement(with product: Product) async throws {
        // This allows users to extend their featured time by purchasing again
        // even if they're already featured

        isPurchasing = true
        purchaseError = nil
        defer { isPurchasing = false }

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)

                // Get current expiration
                let currentExpiration = featuredExpiresAt ?? Date()
                let baseDate = currentExpiration > Date() ? currentExpiration : Date()

                // Calculate new expiration
                guard let featuredProduct = FeaturedProduct(rawValue: transaction.productID) else {
                    throw NSError(domain: "StoreKitManager", code: -2,
                                 userInfo: [NSLocalizedDescriptionKey: "Unknown product ID"])
                }

                let newExpiration = Calendar.current.date(byAdding: .day, value: featuredProduct.duration, to: baseDate) ?? Date()

                // Update Firestore with extended expiration
                guard let currentUserId = Auth.auth().currentUser?.uid else {
                    throw NSError(domain: "StoreKitManager", code: -1,
                                 userInfo: [NSLocalizedDescriptionKey: "No authenticated user"])
                }

                try await Firestore.firestore()
                    .collection("featured")
                    .document(currentUserId)
                    .updateData([
                        "expiresAt": newExpiration,
                        "lastExtendedAt": FieldValue.serverTimestamp(),
                        "lastExtensionTransactionId": String(transaction.id)
                    ])

                await transaction.finish()

                // Update local state
                featuredExpiresAt = newExpiration
                subscriptionStatus = .active(expiresAt: newExpiration, productId: transaction.productID, isAutoRenewing: false)
                cacheSubscriptionStatus(expiresAt: newExpiration, productId: transaction.productID, isAutoRenewing: false)

                // Reschedule notifications
                await scheduleExpirationNotificationForDate(newExpiration, productId: transaction.productID)

                print("✅ Extended featured placement until \(newExpiration)")
                Haptics.notify(.success)

            case .userCancelled:
                print("⚠️ User cancelled extension purchase")

            case .pending:
                purchaseError = "Extension purchase is pending approval."

            @unknown default:
                purchaseError = "Unknown result. Please try again."
            }
        } catch {
            purchaseError = "Failed to extend: \(error.localizedDescription)"
            throw error
        }
    }

    // MARK: - Format Remaining Time

    func formatRemainingTime() -> String {
        guard let expiresAt = featuredExpiresAt, expiresAt > Date() else {
            return "Not featured"
        }

        let interval = expiresAt.timeIntervalSince(Date())
        let days = Int(interval / 86400)
        let hours = Int((interval.truncatingRemainder(dividingBy: 86400)) / 3600)
        let minutes = Int((interval.truncatingRemainder(dividingBy: 3600)) / 60)

        if days > 0 {
            return "\(days)d \(hours)h remaining"
        } else if hours > 0 {
            return "\(hours)h \(minutes)m remaining"
        } else {
            return "\(minutes)m remaining"
        }
    }
}

// MARK: - Product Extensions

extension Product {
    var localizedPrice: String {
        return displayPrice
    }
}

// MARK: - Haptics (if not defined elsewhere)

#if !canImport(SharedComponents)
enum Haptics {
    static func notify(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }

    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
}
#endif
