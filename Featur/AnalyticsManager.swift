// AnalyticsManager.swift
// Centralized analytics tracking for user events

import Foundation
import FirebaseAnalytics

/// Singleton manager for tracking analytics events throughout the app
@MainActor
final class AnalyticsManager {
    static let shared = AnalyticsManager()

    private init() {
        print("📊 AnalyticsManager initialized")
    }

    // MARK: - User Events

    /// Track user sign up
    func trackSignUp(method: String) {
        Analytics.logEvent(AnalyticsEventSignUp, parameters: [
            AnalyticsParameterMethod: method
        ])
        print("📊 Analytics: User signed up via \(method)")
    }

    /// Track user login
    func trackLogin(method: String) {
        Analytics.logEvent(AnalyticsEventLogin, parameters: [
            AnalyticsParameterMethod: method
        ])
        print("📊 Analytics: User logged in via \(method)")
    }

    /// Track profile view
    func trackProfileView(userId: String, source: String) {
        Analytics.logEvent("profile_view", parameters: [
            "viewed_user_id": userId,
            "source": source // "discover", "home", "search", "messages", etc.
        ])
        print("📊 Analytics: Profile viewed - \(userId) from \(source)")
    }

    /// Track profile edit
    func trackProfileEdit(field: String) {
        Analytics.logEvent("profile_edit", parameters: [
            "field": field // "photo", "bio", "interests", etc.
        ])
        print("📊 Analytics: Profile edited - \(field)")
    }

    // MARK: - Swipe Events

    /// Track swipe action
    func trackSwipe(action: String, targetUserId: String) {
        Analytics.logEvent("swipe", parameters: [
            "action": action, // "like", "pass", "super_like"
            "target_user_id": targetUserId
        ])
        print("📊 Analytics: Swipe \(action) on \(targetUserId)")
    }

    /// Track match created
    func trackMatch(matchedUserId: String) {
        Analytics.logEvent("match_created", parameters: [
            "matched_user_id": matchedUserId
        ])
        print("📊 Analytics: Match created with \(matchedUserId)")
    }

    // MARK: - Messaging Events

    /// Track message sent
    func trackMessageSent(conversationId: String, hasMedia: Bool) {
        Analytics.logEvent("message_sent", parameters: [
            "conversation_id": conversationId,
            "has_media": hasMedia
        ])
        print("📊 Analytics: Message sent in \(conversationId)")
    }

    /// Track conversation started
    func trackConversationStarted(withUserId: String) {
        Analytics.logEvent("conversation_started", parameters: [
            "other_user_id": withUserId
        ])
        print("📊 Analytics: Conversation started with \(withUserId)")
    }

    // MARK: - Discovery Events

    /// Track search performed
    func trackSearch(query: String, resultsCount: Int) {
        Analytics.logEvent(AnalyticsEventSearch, parameters: [
            AnalyticsParameterSearchTerm: query,
            "results_count": resultsCount
        ])
        print("📊 Analytics: Search '\(query)' returned \(resultsCount) results")
    }

    /// Track filter applied
    func trackFilterApplied(filterType: String, value: String) {
        Analytics.logEvent("filter_applied", parameters: [
            "filter_type": filterType,
            "value": value
        ])
        print("📊 Analytics: Filter applied - \(filterType): \(value)")
    }

    /// Track featured creator viewed
    func trackFeaturedCreatorView(userId: String) {
        Analytics.logEvent("featured_creator_view", parameters: [
            "creator_id": userId
        ])
        print("📊 Analytics: Featured creator viewed - \(userId)")
    }

    // MARK: - Content Events

    /// Track media upload
    func trackMediaUpload(type: String, count: Int) {
        Analytics.logEvent("media_upload", parameters: [
            "media_type": type, // "profile_photo", "gallery"
            "count": count
        ])
        print("📊 Analytics: Media uploaded - \(type) (\(count) items)")
    }

    /// Track share action
    func trackShare(contentType: String, method: String) {
        Analytics.logEvent(AnalyticsEventShare, parameters: [
            AnalyticsParameterContentType: contentType,
            AnalyticsParameterMethod: method
        ])
        print("📊 Analytics: Shared \(contentType) via \(method)")
    }

    // MARK: - Settings Events

    /// Track settings changed
    func trackSettingsChange(setting: String, value: String) {
        Analytics.logEvent("settings_changed", parameters: [
            "setting": setting,
            "value": value
        ])
        print("📊 Analytics: Setting changed - \(setting): \(value)")
    }

    /// Track account deletion
    func trackAccountDeletion(reason: String?) {
        Analytics.logEvent("account_deleted", parameters: [
            "reason": reason ?? "not_specified"
        ])
        print("📊 Analytics: Account deleted - reason: \(reason ?? "not specified")")
    }

    /// Track data export
    func trackDataExport() {
        Analytics.logEvent("data_exported", parameters: [:])
        print("📊 Analytics: User data exported")
    }

    // MARK: - Screen Events

    /// Track screen view
    func trackScreenView(screenName: String, screenClass: String) {
        Analytics.logEvent(AnalyticsEventScreenView, parameters: [
            AnalyticsParameterScreenName: screenName,
            AnalyticsParameterScreenClass: screenClass
        ])
        print("📊 Analytics: Screen view - \(screenName)")
    }

    // MARK: - Purchase Events

    /// Track purchase completed
    func trackPurchase(productId: String, price: String) {
        Analytics.logEvent(AnalyticsEventPurchase, parameters: [
            AnalyticsParameterItemID: productId,
            AnalyticsParameterPrice: price,
            AnalyticsParameterCurrency: "USD"
        ])
        print("📊 Analytics: Purchase completed - \(productId) at \(price)")
    }

    /// Track purchase started
    func trackPurchaseStarted(productId: String) {
        Analytics.logEvent("purchase_started", parameters: [
            AnalyticsParameterItemID: productId
        ])
        print("📊 Analytics: Purchase started - \(productId)")
    }

    /// Track purchase restored
    func trackPurchaseRestored(productId: String) {
        Analytics.logEvent("purchase_restored", parameters: [
            AnalyticsParameterItemID: productId
        ])
        print("📊 Analytics: Purchase restored - \(productId)")
    }

    /// Track subscription expired
    func trackSubscriptionExpired(productId: String) {
        Analytics.logEvent("subscription_expired", parameters: [
            AnalyticsParameterItemID: productId
        ])
        print("📊 Analytics: Subscription expired - \(productId)")
    }

    // MARK: - Error Events

    /// Track error
    func trackError(error: String, context: String) {
        Analytics.logEvent("error_occurred", parameters: [
            "error_message": error,
            "context": context
        ])
        print("📊 Analytics: Error - \(error) in \(context)")
    }

    // MARK: - User Properties

    /// Set user property
    func setUserProperty(name: String, value: String) {
        Analytics.setUserProperty(value, forName: name)
        print("📊 Analytics: User property set - \(name): \(value)")
    }

    /// Set user ID
    func setUserId(_ userId: String) {
        Analytics.setUserID(userId)
        print("📊 Analytics: User ID set - \(userId)")
    }

    /// Clear user data (on logout)
    func clearUserData() {
        Analytics.setUserID(nil)
        print("📊 Analytics: User data cleared")
    }
}
