// UserProfile+Extensions.swift
// Shared extensions for UserProfile and related types

import SwiftUI
import FirebaseFirestore

// MARK: - ContentStyle Icon Extension

extension UserProfile.ContentStyle {
    var icon: String {
        switch self {
        case .comedy: return "theatermasks.fill"
        case .editing: return "scissors"
        case .beauty: return "sparkles"
        case .fashion: return "tshirt.fill"
        case .fitness: return "figure.run"
        case .mukbang: return "fork.knife"
        case .cooking: return "frying.pan.fill"
        case .dance: return "figure.dance"
        case .music: return "music.note"
        case .gaming: return "gamecontroller.fill"
        case .pet: return "pawprint.fill"
        case .tech: return "laptopcomputer"
        case .art: return "paintpalette.fill"
        case .sports: return "sportscourt.fill"
        }
    }
}

// MARK: - Response Time Display Text

extension UserProfile.CollaborationPreferences.ResponseTime {
    var displayText: String {
        switch self {
        case .fast: return "within hours"
        case .moderate: return "within a day"
        case .slow: return "within a week"
        }
    }
}

// MARK: - Presence Manager

/// Singleton manager for caching and tracking user online status
@MainActor
class PresenceManager: ObservableObject {
    static let shared = PresenceManager()

    @Published private(set) var onlineStatusCache: [String: (isOnline: Bool, lastChecked: Date)] = [:]
    private let cacheValidityDuration: TimeInterval = 60 // 1 minute cache

    private let service = FirebaseService()

    private init() {}

    /// Check if user is online (uses cache if available)
    func isOnline(userId: String) -> Bool {
        // Check cache first
        if let cached = onlineStatusCache[userId],
           Date().timeIntervalSince(cached.lastChecked) < cacheValidityDuration {
            return cached.isOnline
        }

        // Return false as default (will be updated asynchronously)
        return false
    }

    /// Fetch and cache online status for a user
    func fetchOnlineStatus(userId: String) async {
        do {
            let isOnline = try await service.isUserOnline(userId: userId)
            onlineStatusCache[userId] = (isOnline, Date())
        } catch {
            print("❌ Error fetching online status: \(error)")
        }
    }

    /// Batch fetch online status for multiple users
    func fetchOnlineStatus(userIds: [String]) async {
        await withTaskGroup(of: Void.self) { group in
            for userId in userIds {
                group.addTask {
                    await self.fetchOnlineStatus(userId: userId)
                }
            }
        }
    }

    /// Update current user's presence to online
    func updatePresence(userId: String) async {
        do {
            try await service.updatePresence(userId: userId)
            onlineStatusCache[userId] = (true, Date())
        } catch {
            print("❌ Error updating presence: \(error)")
        }
    }

    /// Set current user as offline
    func setOffline(userId: String) async {
        do {
            try await service.setOffline(userId: userId)
            onlineStatusCache[userId] = (false, Date())
        } catch {
            print("❌ Error setting offline: \(error)")
        }
    }

    /// Clear cache
    func clearCache() {
        onlineStatusCache.removeAll()
    }
}

// MARK: - Helper Functions

/// Format follower count into readable format (e.g., 1.2K, 3.5M)
func formatFollowerCount(_ count: Int) -> String {
    if count >= 1_000_000 {
        return String(format: "%.1fM", Double(count) / 1_000_000)
    } else if count >= 1_000 {
        return String(format: "%.1fK", Double(count) / 1_000)
    } else {
        return "\(count)"
    }
}
