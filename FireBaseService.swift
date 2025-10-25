// FirebaseService.swift
import Foundation
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage
import CoreLocation

@MainActor
final class FirebaseService: ObservableObject {
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    
    // MARK: - User Profile Management
    
    /// Creates a new user profile in Firestore
    func createProfile(_ profile: UserProfile) async throws {
        guard !profile.uid.isEmpty else {
            throw FirebaseServiceError.invalidUID
        }
        try db.collection("users").document(profile.uid).setData(from: profile)
    }
    
    /// Fetches a user profile by UID
    func fetchProfile(uid: String) async throws -> UserProfile? {
        guard !uid.isEmpty else {
            throw FirebaseServiceError.invalidUID
        }
        
        let document = try await db.collection("users").document(uid).getDocument()
        
        guard document.exists else {
            return nil
        }
        
        return try document.data(as: UserProfile.self)
    }
    
    /// Updates an existing user profile
    func updateProfile(_ profile: UserProfile) async throws {
        guard let uid = profile.id, !uid.isEmpty else {
            throw FirebaseServiceError.invalidUID
        }
        
        var updated = profile
        updated.updatedAt = Date()
        
        try db.collection("users").document(uid).setData(from: updated, merge: true)
    }
    
    /// Deletes a user profile
    func deleteProfile(uid: String) async throws {
        guard !uid.isEmpty else {
            throw FirebaseServiceError.invalidUID
        }
        
        try await db.collection("users").document(uid).delete()
    }
    
    // MARK: - Discovery & Matching
    
    /// Fetches profiles for discovery feed with smart filtering
    /// - Parameters:
    ///   - limit: Maximum number of profiles to return
    ///   - excludeUserIds: User IDs to exclude (handles Firestore's 10-item limit)
    ///   - nearLocation: Optional location for proximity-based filtering
    ///   - maxDistance: Maximum distance in kilometers (only used if nearLocation provided)
    func fetchDiscoverProfiles(
        limit: Int = 20,
        excludeUserIds: [String] = [],
        nearLocation: CLLocation? = nil,
        maxDistance: Double = 50.0
    ) async throws -> [UserProfile] {
        
        // Firestore 'not-in' queries are limited to 10 items
        // We'll handle this by using the first 10 for the query and filtering the rest client-side
        let queryExcludeLimit = min(excludeUserIds.count, 10)
        let excludeBatch = Array(excludeUserIds.prefix(queryExcludeLimit))
        let remainingExclusions = Set(excludeUserIds.dropFirst(queryExcludeLimit))
        
        var query: Query = db.collection("users")
            .limit(to: limit * 2) // Fetch extra to account for filtering
        
        // Apply Firestore-level exclusions (max 10)
        if !excludeBatch.isEmpty {
            query = query.whereField(FieldPath.documentID(), notIn: excludeBatch)
        }
        
        // Execute query
        let snapshot = try await query.getDocuments()
        var profiles = try snapshot.documents.compactMap { document -> UserProfile? in
            try? document.data(as: UserProfile.self)
        }
        
        // Client-side filtering for remaining exclusions
        if !remainingExclusions.isEmpty {
            profiles = profiles.filter { profile in
                guard let uid = profile.id else { return false }
                return !remainingExclusions.contains(uid)
            }
        }
        
        // Location-based filtering if provided
        if let userLocation = nearLocation {
            profiles = profiles.filter { profile in
                guard let location = profile.location,
                      let coordinates = location.coordinates else {
                    return false // Exclude profiles without location
                }
                
                let profileLocation = CLLocation(
                    latitude: coordinates.latitude,
                    longitude: coordinates.longitude
                )
                
                let distance = userLocation.distance(from: profileLocation) / 1000 // Convert to km
                return distance <= maxDistance
            }
        }
        
        // Randomize order for variety
        profiles.shuffle()
        
        // Return up to the requested limit
        return Array(profiles.prefix(limit))
    }
    
    /// Records a swipe action and checks for matches
    func recordSwipe(_ action: SwipeAction) async throws {
        // Validate user IDs
        guard !action.userId.isEmpty, !action.targetUserId.isEmpty else {
            throw FirebaseServiceError.invalidUID
        }
        
        // Save swipe action
        let swipeRef = try db.collection("swipes").addDocument(from: action)
        
        // Check for mutual match if this was a like
        if action.action == .like {
            try await checkAndCreateMatch(userId: action.userId, targetUserId: action.targetUserId)
        }
        
        print("✅ Swipe recorded: \(swipeRef.documentID)")
    }
    
    /// Internal method to check for mutual likes and create matches
    private func checkAndCreateMatch(userId: String, targetUserId: String) async throws {
        // Check if target user also liked this user
        let reciprocalSwipes = try await db.collection("swipes")
            .whereField("userId", isEqualTo: targetUserId)
            .whereField("targetUserId", isEqualTo: userId)
            .whereField("action", isEqualTo: SwipeAction.Action.like.rawValue)
            .limit(to: 1)
            .getDocuments()
        
        // If reciprocal like exists, create a match
        if !reciprocalSwipes.isEmpty {
            // Check if match already exists
            let existingMatches = try await fetchMatches(forUser: userId)
            let matchExists = existingMatches.contains { match in
                (match.userId1 == userId && match.userId2 == targetUserId) ||
                (match.userId1 == targetUserId && match.userId2 == userId)
            }
            
            if !matchExists {
                let match = Match(
                    userId1: userId,
                    userId2: targetUserId,
                    matchedAt: Date(),
                    hasMessaged: false,
                    lastMessageAt: nil,
                    isActive: true,
                    profile: nil
                )
                
                let matchRef = try db.collection("matches").addDocument(from: match)
                print("🎉 New match created: \(matchRef.documentID)")
                
                // Send push notification (implement separately)
                // await sendMatchNotification(to: targetUserId, from: userId)
            }
        }
    }
    
    /// Fetches all matches for a user
    func fetchMatches(forUser userId: String) async throws -> [Match] {
        guard !userId.isEmpty else {
            throw FirebaseServiceError.invalidUID
        }
        
        // Query where user is userId1
        let matches1Query = db.collection("matches")
            .whereField("userId1", isEqualTo: userId)
            .whereField("isActive", isEqualTo: true)
        
        // Query where user is userId2
        let matches2Query = db.collection("matches")
            .whereField("userId2", isEqualTo: userId)
            .whereField("isActive", isEqualTo: true)
        
        // Execute both queries concurrently
        async let snapshot1 = matches1Query.getDocuments()
        async let snapshot2 = matches2Query.getDocuments()
        
        let (result1, result2) = try await (snapshot1, snapshot2)
        
        // Combine results
        let allDocuments = result1.documents + result2.documents
        
        // Parse matches
        var matches = try allDocuments.compactMap { document -> Match? in
            try? document.data(as: Match.self)
        }
        
        // Fetch profiles for each match
        for i in matches.indices {
            let otherUserId = matches[i].userId1 == userId ? matches[i].userId2 : matches[i].userId1
            if let profile = try? await fetchProfile(uid: otherUserId) {
                matches[i].profile = profile
            }
        }
        
        // Sort by most recent match
        matches.sort { $0.matchedAt > $1.matchedAt }
        
        return matches
    }
    
    /// Unmatches two users
    func unmatch(matchId: String) async throws {
        try await db.collection("matches").document(matchId).updateData([
            "isActive": false,
            "unmatchedAt": Date()
        ])
    }
    
    // MARK: - Messaging
    
    /// Fetches all conversations for a user
    func fetchConversations(forUser userId: String) async throws -> [Conversation] {
        guard !userId.isEmpty else {
            throw FirebaseServiceError.invalidUID
        }
        
        let snapshot = try await db.collection("conversations")
            .whereField("participantIds", arrayContains: userId)
            .order(by: "lastMessageAt", descending: true)
            .getDocuments()
        
        var conversations = try snapshot.documents.compactMap { document -> Conversation? in
            try? document.data(as: Conversation.self)
        }
        
        // Fetch participant profiles
        for i in conversations.indices {
            var participantProfiles: [String: UserProfile] = [:]
            
            for participantId in conversations[i].participantIds where participantId != userId {
                if let profile = try? await fetchProfile(uid: participantId) {
                    participantProfiles[participantId] = profile
                }
            }
            
            conversations[i].participantProfiles = participantProfiles
        }
        
        return conversations
    }
    
    /// Creates or retrieves a conversation between two users
    func getOrCreateConversation(userId: String, otherUserId: String) async throws -> Conversation {
        // Check if conversation already exists
        let existingConversations = try await db.collection("conversations")
            .whereField("participantIds", arrayContains: userId)
            .whereField("isGroupChat", isEqualTo: false)
            .getDocuments()
        
        // Find conversation with both users
        if let existingDoc = existingConversations.documents.first(where: { doc in
            if let participantIds = doc.data()["participantIds"] as? [String] {
                return participantIds.contains(otherUserId)
            }
            return false
        }) {
            return try existingDoc.data(as: Conversation.self)
        }
        
        // Create new conversation
        let conversation = Conversation(
            participantIds: [userId, otherUserId],
            participantProfiles: nil,
            lastMessage: nil,
            lastMessageAt: Date(),
            unreadCount: [:],
            isGroupChat: false,
            groupName: nil,
            createdAt: Date()
        )
        
        let docRef = try db.collection("conversations").addDocument(from: conversation)
        
        // Return conversation with ID
        var newConversation = conversation
        newConversation.id = docRef.documentID
        return newConversation
    }
    
    /// Sends a message in a conversation
    func sendMessage(_ message: Message) async throws {
        guard !message.conversationId.isEmpty,
              !message.senderId.isEmpty,
              !message.recipientId.isEmpty else {
            throw FirebaseServiceError.invalidMessageData
        }
        
        // Save message
        let messageRef = try db.collection("messages").addDocument(from: message)
        
        // Update conversation
        let conversationRef = db.collection("conversations").document(message.conversationId)
        
        try await conversationRef.updateData([
            "lastMessage": message.content,
            "lastMessageAt": message.sentAt,
            "unreadCount.\(message.recipientId)": FieldValue.increment(Int64(1))
        ])
        
        // Mark match as having messaged
        try await markMatchAsMessaged(userId: message.senderId, targetUserId: message.recipientId)
        
        print("✅ Message sent: \(messageRef.documentID)")
    }
    
    /// Marks a match as having messaged
    private func markMatchAsMessaged(userId: String, targetUserId: String) async throws {
        // Find the match
        let matches1 = try await db.collection("matches")
            .whereField("userId1", isEqualTo: userId)
            .whereField("userId2", isEqualTo: targetUserId)
            .limit(to: 1)
            .getDocuments()
        
        let matches2 = try await db.collection("matches")
            .whereField("userId1", isEqualTo: targetUserId)
            .whereField("userId2", isEqualTo: userId)
            .limit(to: 1)
            .getDocuments()
        
        let matchDoc = matches1.documents.first ?? matches2.documents.first
        
        if let matchId = matchDoc?.documentID {
            try await db.collection("matches").document(matchId).updateData([
                "hasMessaged": true,
                "lastMessageAt": Date()
            ])
        }
    }
    
    /// Fetches messages for a conversation
    func fetchMessages(conversationId: String, limit: Int = 50) async throws -> [Message] {
        guard !conversationId.isEmpty else {
            throw FirebaseServiceError.invalidConversationID
        }
        
        let snapshot = try await db.collection("messages")
            .whereField("conversationId", isEqualTo: conversationId)
            .order(by: "sentAt", descending: true)
            .limit(to: limit)
            .getDocuments()
        
        return try snapshot.documents.compactMap { document -> Message? in
            try? document.data(as: Message.self)
        }
    }
    
    /// Marks messages as read
    func markMessagesAsRead(conversationId: String, userId: String) async throws {
        guard !conversationId.isEmpty, !userId.isEmpty else {
            throw FirebaseServiceError.invalidConversationID
        }
        
        let conversationRef = db.collection("conversations").document(conversationId)
        
        try await conversationRef.updateData([
            "unreadCount.\(userId)": 0
        ])
        
        // Also mark individual messages as read
        let unreadMessages = try await db.collection("messages")
            .whereField("conversationId", isEqualTo: conversationId)
            .whereField("recipientId", isEqualTo: userId)
            .whereField("readAt", isEqualTo: NSNull())
            .getDocuments()
        
        let batch = db.batch()
        for doc in unreadMessages.documents {
            batch.updateData(["readAt": Date()], forDocument: doc.reference)
        }
        
        try await batch.commit()
    }
    
    // MARK: - Featured Creators
    
    /// Fetches currently active featured creators
    func fetchFeaturedCreators() async throws -> [FeaturedCreator] {
        let snapshot = try await db.collection("featured")
            .whereField("expiresAt", isGreaterThan: Date())
            .order(by: "priority", descending: true)
            .limit(to: 20)
            .getDocuments()
        
        var featured = try snapshot.documents.compactMap { document -> FeaturedCreator? in
            try? document.data(as: FeaturedCreator.self)
        }
        
        // Fetch profiles for each featured creator
        for i in featured.indices {
            if let profile = try? await fetchProfile(uid: featured[i].userId) {
                featured[i].profile = profile
            }
        }
        
        return featured
    }
    
    /// Creates a featured creator listing
    func createFeaturedCreator(userId: String, category: String, duration: TimeInterval, priority: Int) async throws {
        let featured = FeaturedCreator(
            userId: userId,
            profile: nil,
            featuredAt: Date(),
            expiresAt: Date().addingTimeInterval(duration),
            category: category,
            highlightText: nil,
            priority: priority
        )
        
        try db.collection("featured").addDocument(from: featured)
    }
    
    // MARK: - Search & Discovery
    
    /// Searches profiles by name and optional filters
    func searchProfiles(query: String, filters: [String]? = nil) async throws -> [UserProfile] {
        var firestoreQuery: Query = db.collection("users")
        
        // Apply content style filters if provided
        if let filters = filters, !filters.isEmpty {
            // Firestore arrayContainsAny is limited to 10 items
            let limitedFilters = Array(filters.prefix(10))
            firestoreQuery = firestoreQuery.whereField("contentStyles", arrayContainsAny: limitedFilters)
        }
        
        let snapshot = try await firestoreQuery.limit(to: 100).getDocuments()
        var profiles = try snapshot.documents.compactMap { document -> UserProfile? in
            try? document.data(as: UserProfile.self)
        }
        
        // Client-side filtering by name if query is provided
        if !query.isEmpty {
            profiles = profiles.filter { profile in
                profile.displayName.localizedCaseInsensitiveContains(query) ||
                profile.bio?.localizedCaseInsensitiveContains(query) == true ||
                profile.interests.contains { $0.localizedCaseInsensitiveContains(query) }
            }
        }
        
        return profiles
    }
    
    // MARK: - Media Upload
    
    /// Uploads media to Firebase Storage
    func uploadMedia(data: Data, path: String) async throws -> String {
        guard !path.isEmpty else {
            throw FirebaseServiceError.invalidPath
        }
        
        let ref = storage.reference().child(path)
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        let _ = try await ref.putDataAsync(data, metadata: metadata)
        let downloadURL = try await ref.downloadURL()
        
        return downloadURL.absoluteString
    }
    
    /// Uploads a profile photo
    func uploadProfilePhoto(userId: String, imageData: Data) async throws -> String {
        guard !userId.isEmpty else {
            throw FirebaseServiceError.invalidUID
        }
        
        let path = "profile_photos/\(userId)/\(UUID().uuidString).jpg"
        return try await uploadMedia(data: imageData, path: path)
    }
    
    /// Deletes media from Firebase Storage
    func deleteMedia(url: String) async throws {
        let ref = storage.reference(forURL: url)
        try await ref.delete()
    }
    
    // MARK: - Admin & Analytics
    
    /// Fetches basic analytics for admin dashboard
    func fetchAnalytics() async throws -> AppAnalytics {
        async let totalUsersTask = db.collection("users").getDocuments()
        async let totalMatchesTask = db.collection("matches")
            .whereField("isActive", isEqualTo: true)
            .getDocuments()
        
        let todayStart = Calendar.current.startOfDay(for: Date())
        async let activeTodayTask = db.collection("users")
            .whereField("lastActiveAt", isGreaterThanOrEqualTo: todayStart)
            .getDocuments()
        
        async let totalMessagesTask = db.collection("messages").count.getAggregation(source: .server)
        
        let (totalUsersSnapshot, totalMatchesSnapshot, activeTodaySnapshot, totalMessagesResult) = try await (
            totalUsersTask,
            totalMatchesTask,
            activeTodayTask,
            totalMessagesTask
        )
        
        return AppAnalytics(
            totalUsers: totalUsersSnapshot.count,
            activeToday: activeTodaySnapshot.count,
            totalMatches: totalMatchesSnapshot.count,
            totalMessages: Int(totalMessagesResult.count)
        )
    }
    
    /// Reports a user or content
    func reportUser(reporterId: String, reportedUserId: String, reason: String, description: String?) async throws {
        let report = Report(
            reporterId: reporterId,
            reportedUserId: reportedUserId,
            reason: reason,
            description: description,
            status: .pending,
            createdAt: Date()
        )
        
        try db.collection("reports").addDocument(from: report)
    }
}

// MARK: - Supporting Types

struct AppAnalytics {
    let totalUsers: Int
    let activeToday: Int
    let totalMatches: Int
    let totalMessages: Int
}

struct Report: Codable {
    let reporterId: String
    let reportedUserId: String
    let reason: String
    let description: String?
    let status: ReportStatus
    let createdAt: Date
    
    enum ReportStatus: String, Codable {
        case pending, reviewed, actionTaken, dismissed
    }
}

// MARK: - Error Handling

enum FirebaseServiceError: LocalizedError {
    case invalidUID
    case invalidConversationID
    case invalidMessageData
    case invalidPath
    case profileNotFound
    case uploadFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidUID:
            return "Invalid user ID provided"
        case .invalidConversationID:
            return "Invalid conversation ID"
        case .invalidMessageData:
            return "Message data is incomplete"
        case .invalidPath:
            return "Invalid storage path"
        case .profileNotFound:
            return "User profile not found"
        case .uploadFailed:
            return "Failed to upload media"
        }
    }
}
