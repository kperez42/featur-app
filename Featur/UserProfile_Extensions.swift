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

// MARK: - Online Status (Mock)

extension UserProfile {
    var isOnline: Bool {
        // TODO: Replace with real online status from Firebase
        Bool.random()
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
