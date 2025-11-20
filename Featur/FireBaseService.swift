import Foundation
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage

@MainActor
final class FirebaseService: ObservableObject {
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    
    // MARK: - User Profile Management
    
    func createProfile(_ profile: UserProfile) async throws {
        try db.collection("users").document(profile.uid).setData(from: profile)
    }
    
    func fetchProfile(uid: String) async throws -> UserProfile? {
        guard !uid.isEmpty else {
            print("⚠️ fetchProfile: UID is empty. Returning nil.")
            return nil
        }

        do {
            let profile = try await db.collection("users")
                .document(uid)
                .getDocument(as: UserProfile.self)

            print("✅ Fetched profile for uid \(uid): \(profile.displayName)")
            return profile

        } catch {
            print("❌ Error fetching profile for uid \(uid): \(error)")
            throw error
        }
    }

    
    func updateProfile(_ profile: UserProfile) async throws {
        // Use uid, not id
        var updated = profile
        updated.updatedAt = Date()

        try db.collection("users")
            .document(profile.uid)
            .setData(from: updated, merge: true)
    }

    
    // MARK: - Discovery & Matching
    
    // ✅ FIXED: Improved swipe exclusion to handle more than 10 users
    func fetchDiscoverProfiles(for user: UserProfile, limit: Int = 20, excludeUserIds: [String] = []) async throws -> [UserProfile] {
        // Fetch more profiles than needed to account for client-side filtering
        // This allows us to exclude more than 10 users (Firestore notIn limit)
        let fetchLimit = excludeUserIds.count > 10 ? limit * 3 : limit
        var query: Query = db.collection("users").limit(to: fetchLimit)

        // Use Firestore notIn for first 10 excluded users (Firestore limit)
        if !excludeUserIds.isEmpty {
            let limitedIds = Array(excludeUserIds.prefix(10))
            query = query.whereField(FieldPath.documentID(), notIn: limitedIds)
        }

        let snapshot = try await query.getDocuments()
        var profiles = try snapshot.documents.compactMap{ try $0.data(as: UserProfile.self)}

        // Remove current user
        profiles.removeAll { $0.uid == user.uid }

        // Client-side filtering for ALL excluded users (beyond the first 10)
        let excludedSet = Set(excludeUserIds)
        profiles.removeAll { excludedSet.contains($0.uid) }

        // Sort by similarity
        profiles.sort { similarityScore(current: user, other: $0) > similarityScore(current: user, other: $1) }

        // Return only the requested limit
        return Array(profiles.prefix(limit))
    }
    
    func recordSwipe(_ action: SwipeAction) async throws {
        // Guard for valid IDs
            guard !action.userId.isEmpty, !action.targetUserId.isEmpty else {
                print("⚠️ recordSwipe: Missing userId or targetUserId. Skipping swipe.")
                return
            }
        //debug to confirm swipes
        print(" recordSwipe: \(action.userId) → \(action.targetUserId), action=\(action.action)")

        try db.collection("swipes").addDocument(from: action)

        // Track analytics
        await AnalyticsManager.shared.trackSwipe(action: action.action.rawValue, targetUserId: action.targetUserId)

        // Check for mutual match
        if action.action == .like {
            try await checkAndCreateMatch(userId: action.userId, targetUserId: action.targetUserId)
        }

    }

    /// Delete a swipe action (for undo functionality)
    func deleteSwipe(userId: String, targetUserId: String) async throws {
        guard !userId.isEmpty, !targetUserId.isEmpty else {
            print("⚠️ deleteSwipe: Missing userId or targetUserId.")
            return
        }

        // Find and delete the swipe document
        let snapshot = try await db.collection("swipes")
            .whereField("userId", isEqualTo: userId)
            .whereField("targetUserId", isEqualTo: targetUserId)
            .getDocuments()

        for document in snapshot.documents {
            try await document.reference.delete()
        }

        print("✅ Deleted swipe: \(userId) → \(targetUserId)")
    }

    // Fetch all user IDs that the current user has swiped on
    func fetchSwipedUserIds(forUser userId: String) async throws -> [String] {
        let snapshot = try await db.collection("swipes")
            .whereField("userId", isEqualTo: userId)
            .getDocuments()

        return snapshot.documents.compactMap { doc in
            try? doc.data(as: SwipeAction.self)
        }.map { $0.targetUserId }
    }

    // Check if current user has liked a specific profile
    func checkLikeStatus(userId: String, targetUserId: String) async throws -> Bool {
        guard !userId.isEmpty, !targetUserId.isEmpty else {
            print("⚠️ checkLikeStatus: Missing user IDs.")
            return false
        }

        let snapshot = try await db.collection("swipes")
            .whereField("userId", isEqualTo: userId)
            .whereField("targetUserId", isEqualTo: targetUserId)
            .whereField("action", isEqualTo: SwipeAction.Action.like.rawValue)
            .getDocuments()

        return !snapshot.isEmpty
    }

    // Save a like from profile detail page (same as swipe right)
    func saveLike(userId: String, targetUserId: String) async throws -> Bool {
        guard !userId.isEmpty, !targetUserId.isEmpty else {
            print("⚠️ saveLike: Missing user IDs.")
            return false
        }

        let swipe = SwipeAction(
            userId: userId,
            targetUserId: targetUserId,
            action: .like,
            timestamp: Date()
        )

        try await recordSwipe(swipe)
        print("✅ Like saved: \(userId) → \(targetUserId)")

        // Return true if this created a match
        let matches = try await fetchMatches(forUser: userId)
        return matches.contains(where: {
            $0.userId1 == targetUserId || $0.userId2 == targetUserId
        })
    }

    // Remove a like (unlike)
    func removeLike(userId: String, targetUserId: String) async throws {
        guard !userId.isEmpty, !targetUserId.isEmpty else {
            print("⚠️ removeLike: Missing user IDs.")
            return
        }

        let snapshot = try await db.collection("swipes")
            .whereField("userId", isEqualTo: userId)
            .whereField("targetUserId", isEqualTo: targetUserId)
            .whereField("action", isEqualTo: SwipeAction.Action.like.rawValue)
            .getDocuments()

        for doc in snapshot.documents {
            try await doc.reference.delete()
        }

        print("✅ Like removed: \(userId) → \(targetUserId)")
    }


    private func checkAndCreateMatch(userId: String, targetUserId: String) async throws {
        guard !userId.isEmpty, !targetUserId.isEmpty else {
                print("⚠️ checkAndCreateMatch: Missing user IDs. Skipping match check.")
                return
            }
        //debug statement to verify match detection
        print("🟣 checkAndCreateMatch: checking \(userId) ↔ \(targetUserId)")

        // Check if target user also liked this user
        let reciprocalSwipe = try await db.collection("swipes")
            .whereField("userId", isEqualTo: targetUserId)
            .whereField("targetUserId", isEqualTo: userId)
            .whereField("action", isEqualTo: SwipeAction.Action.like.rawValue)
            .getDocuments()
        
        if !reciprocalSwipe.isEmpty {
            // Check if match already exists to avoid duplicates
            let existingMatches = try await db.collection("matches")
                .whereField("userId1", isEqualTo: userId)
                .whereField("userId2", isEqualTo: targetUserId)
                .whereField("isActive", isEqualTo: true)
                .getDocuments()

            let existingMatchesReverse = try await db.collection("matches")
                .whereField("userId1", isEqualTo: targetUserId)
                .whereField("userId2", isEqualTo: userId)
                .whereField("isActive", isEqualTo: true)
                .getDocuments()

            if existingMatches.isEmpty && existingMatchesReverse.isEmpty {
                // Create match
                let match = Match(
                    userId1: userId,
                    userId2: targetUserId,
                    matchedAt: Date(),
                    hasMessaged: false,
                    isActive: true
                )
                try db.collection("matches").addDocument(from: match)
                print("✅ Match created between \(userId) and \(targetUserId)")

                // Track analytics
                await AnalyticsManager.shared.trackMatch(matchedUserId: targetUserId)

                // IMPORTANT: Automatically create a conversation for the match
                try await createConversationForMatch(userId1: userId, userId2: targetUserId)
            } else {
                print("ℹ️ Match already exists between \(userId) and \(targetUserId)")
            }

            // Create conversation for the match
            do {
                let conversation = try await getOrCreateConversation(between: userId, and: targetUserId)
                print("✅ Conversation created for match: \(conversation.id ?? "unknown")")
            } catch {
                print("⚠️ Failed to create conversation for match: \(error)")
            }

        }else{
            // Debug statement no match created
            print("❌ No reciprocal like yet for \(userId) ↔ \(targetUserId)")

        }
    }

    /// Automatically create a conversation when a match happens
    private func createConversationForMatch(userId1: String, userId2: String) async throws {
        // Use existing getOrCreateConversation to create the conversation
        let conversation = try await getOrCreateConversation(between: userId1, and: userId2)
        print("✅ Conversation created for match: \(conversation.id ?? "unknown")")

        // Track analytics
        await AnalyticsManager.shared.trackConversationStarted(withUserId: userId2)
    }

    func fetchMatches(forUser userId: String) async throws -> [Match] {
        guard !userId.isEmpty else {
                print("⚠️ fetchMatches: Empty userId. Returning no matches.")
                return []
            }
        let matches1 = try await db.collection("matches")
            .whereField("userId1", isEqualTo: userId)
            .whereField("isActive", isEqualTo: true)
            .getDocuments()
        
        let matches2 = try await db.collection("matches")
            .whereField("userId2", isEqualTo: userId)
            .whereField("isActive", isEqualTo: true)
            .getDocuments()
        
        let all = matches1.documents + matches2.documents
        return try all.compactMap { try $0.data(as: Match.self) }
    }
    
    // MARK: - Messaging
    // MARK: - Conversations (create/get)

    func getOrCreateConversation(between userA: String, and userB: String) async throws -> Conversation {
        // 1) Try to find an existing conversation with both participants
        let snapshot = try await db.collection("conversations")
            .whereField("participantIds", arrayContains: userA)
            .getDocuments()
        
        if let existing = snapshot.documents
            .compactMap({ try? $0.data(as: Conversation.self) })
            .first(where: { Set($0.participantIds) == Set([userA, userB]) }) {
            return existing
        }
        
        // 2) Create a new conversation
        let newRef = db.collection("conversations").document()
        let conv = Conversation(
            id: newRef.documentID,
            participantIds: [userA, userB],
            lastMessage: nil,
            lastMessageAt: Date(),
            unreadCount: [userA: 0, userB: 0],
            isGroupChat: false,
            createdAt: Date()
        )
        try newRef.setData(from: conv)
        return conv
    }

    // Optional: mark match as messaged once a conversation is created or first message sent
    func markMatchAsMessaged(userA: String, userB: String) async {
        do {
            let q1 = try await db.collection("matches")
                .whereField("userId1", isEqualTo: userA)
                .whereField("userId2", isEqualTo: userB)
                .getDocuments()
            let q2 = try await db.collection("matches")
                .whereField("userId1", isEqualTo: userB)
                .whereField("userId2", isEqualTo: userA)
                .getDocuments()
            let docs = q1.documents + q2.documents
            for doc in docs {
                try await doc.reference.updateData(["hasMessaged": true])
            }
        } catch {
            print("⚠️ markMatchAsMessaged failed: \(error)")
        }
    }

    func fetchConversations(forUser userId: String) async throws -> [Conversation] {
        guard !userId.isEmpty else {
               print("⚠️ fetchConversations: Empty userId. Returning no conversations.")
               return []
           }
        let snapshot = try await db.collection("conversations")
            .whereField("participantIds", arrayContains: userId)
            .order(by: "lastMessageAt", descending: true)
            .getDocuments()
        
        return try snapshot.documents.compactMap { try $0.data(as: Conversation.self) }
    }
    
    func sendMessage(_ message: Message) async throws {
        try db.collection("messages").addDocument(from: message)

        // Update conversation
        try await db.collection("conversations").document(message.conversationId).updateData([
            "lastMessage": message.content,
            "lastMessageAt": message.sentAt,
            "unreadCount.\(message.recipientId)": FieldValue.increment(Int64(1))
        ])

        // Track analytics
        await AnalyticsManager.shared.trackMessageSent(
            conversationId: message.conversationId,
            hasMedia: message.mediaURL != nil
        )
    }
    
    func fetchMessages(conversationId: String, limit: Int = 50) async throws -> [Message] {
        let snapshot = try await db.collection("messages")
            .whereField("conversationId", isEqualTo: conversationId)
            .order(by: "sentAt", descending: true)
            .limit(to: limit)
            .getDocuments()
        
        return try snapshot.documents.compactMap { try $0.data(as: Message.self) }
    }
    
    func markMessagesAsRead(conversationId: String, userId: String) async throws {
        // Guard against invalid IDs
          guard !conversationId.isEmpty, !userId.isEmpty else {
              print("⚠️ markMessagesAsRead: Missing conversationId or userId. Skipping update.")
              return
          }
        try await db.collection("conversations").document(conversationId).updateData([
            "unreadCount.\(userId)": 0
        ])
    }
    // real time listener on Firestore's messages collection for a specfic conversation
    func listenForMessages(conversationId: String, completion: @escaping ([Message]) -> Void) -> ListenerRegistration {
        // set up query
        db.collection("messages")
          .whereField("conversationId", isEqualTo: conversationId)
          .order(by: "sentAt")
        // add snapshot to listen that the query is live
          .addSnapshotListener { snapshot, error in
              guard let snapshot = snapshot else { return }
              // map documents to message model
              let messages = snapshot.documents.compactMap { try? $0.data(as: Message.self) }
              print(" New messages fetched: \(messages.count) for conversation \(conversationId)")

              completion(messages)
          }
    }

    
    // MARK: - Featured Creators
    
    func fetchFeaturedCreators() async throws -> [FeaturedCreator] {
        let snapshot = try await db.collection("featured")
            .whereField("expiresAt", isGreaterThan: Date())
            .order(by: "priority", descending: true)
            .getDocuments()
        
        var featured = try snapshot.documents.compactMap { try $0.data(as: FeaturedCreator.self) }
        
        // Fetch profiles
        for i in featured.indices {
            if let profile = try? await fetchProfile(uid: featured[i].userId) {
                featured[i].profile = profile
            }
        }
        
        return featured
    }
    
    // MARK: - Search & Discovery

    /// Enhanced search with multi-field matching and relevance scoring
    func searchProfiles(query: String, filters: [String]? = nil) async throws -> [UserProfile] {
        // Return empty if query is too short
        guard query.count >= 2 else {
            return []
        }

        var firestoreQuery: Query = db.collection("users")

        // Apply content style filters
        if let filters = filters, !filters.isEmpty {
            firestoreQuery = firestoreQuery.whereField("contentStyles", arrayContainsAny: filters)
        }

        let snapshot = try await firestoreQuery.limit(to: 100).getDocuments()
        let profiles = try snapshot.documents.compactMap { try $0.data(as: UserProfile.self) }

        // Return all if query is empty
        if query.isEmpty {
            return profiles
        }

        // Enhanced multi-field search with relevance scoring
        let searchTerm = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        struct ScoredProfile {
            let profile: UserProfile
            let score: Int
        }

        let scoredProfiles = profiles.compactMap { profile -> ScoredProfile? in
            var score = 0

            // Display name match (highest priority)
            let displayName = profile.displayName.lowercased()
            if displayName == searchTerm {
                score += 100 // Exact match
            } else if displayName.hasPrefix(searchTerm) {
                score += 50 // Starts with query
            } else if displayName.contains(searchTerm) {
                score += 25 // Contains query
            } else if displayName.contains(where: { searchTerm.contains($0) }) {
                score += 5 // Partial character match
            }

            // Bio match
            if let bio = profile.bio?.lowercased() {
                if bio.contains(searchTerm) {
                    score += 15
                }
            }

            // Interests match
            if let interests = profile.interests {
                for interest in interests {
                    if interest.lowercased().contains(searchTerm) {
                        score += 10
                    }
                }
            }

            // Content styles match
            for style in profile.contentStyles {
                if style.rawValue.lowercased().contains(searchTerm) {
                    score += 8
                }
            }

            // Location match
            if let location = profile.location {
                if let city = location.city, city.lowercased().contains(searchTerm) {
                    score += 12
                }
                if let state = location.state, state.lowercased().contains(searchTerm) {
                    score += 10
                }
            }

            // Boost verified profiles slightly
            if profile.isVerified == true {
                score += 3
            }

            // Only return profiles with some relevance
            return score > 0 ? ScoredProfile(profile: profile, score: score) : nil
        }

        // Sort by relevance score (descending)
        let sortedProfiles = scoredProfiles
            .sorted { $0.score > $1.score }
            .map { $0.profile }

        return sortedProfiles
    }
    
    // MARK: - Media Upload
    
    func uploadMedia(data: Data, path: String) async throws -> String {
        let ref = storage.reference().child(path)

        // Retry logic for network errors
        var lastError: Error?
        let maxRetries = 3

        for attempt in 0..<maxRetries {
            do {
                print("⬆️ Upload attempt \(attempt + 1)/\(maxRetries) to: \(path)")
                let _ = try await ref.putDataAsync(data)
                let url = try await ref.downloadURL().absoluteString
                print("✅ Upload successful: \(url)")
                return url
            } catch let error as NSError {
                lastError = error
                print("⚠️ Upload attempt \(attempt + 1) failed: \(error.localizedDescription)")
                print("   Error code: \(error.code), domain: \(error.domain)")

                // Check if it's a retryable network error
                let isNetworkError = error.domain == NSURLErrorDomain &&
                    (error.code == NSURLErrorTimedOut ||
                     error.code == NSURLErrorCannotConnectToHost ||
                     error.code == NSURLErrorNetworkConnectionLost ||
                     error.code == NSURLErrorSecureConnectionFailed ||
                     error.code == NSURLErrorNotConnectedToInternet)

                if isNetworkError && attempt < maxRetries - 1 {
                    let delay = pow(2.0, Double(attempt)) // Exponential backoff: 1s, 2s, 4s
                    print("   Retrying in \(delay)s...")
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                } else if !isNetworkError {
                    // Not a network error, don't retry
                    print("   Non-retryable error, failing immediately")
                    throw error
                } else {
                    // Last attempt or non-retryable
                    print("   All retry attempts exhausted")
                    throw error
                }
            }
        }

        throw lastError ?? NSError(domain: "FirebaseService", code: -1,
                                   userInfo: [NSLocalizedDescriptionKey: "Upload failed after \(maxRetries) attempts"])
    }
    
    func uploadProfilePhoto(userId: String, imageData: Data) async throws -> String {
        let path = "profile_photos/\(userId)/\(UUID().uuidString).jpg"
        return try await uploadMedia(data: imageData, path: path)
    }

    func uploadProfilePhoto(userId: String, image: UIImage) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "FirebaseService", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data"])
        }
        return try await uploadProfilePhoto(userId: userId, imageData: imageData)
    }

    /// Delete media from Firebase Storage using its download URL
    func deleteMedia(url: String) async throws {
        guard !url.isEmpty else {
            print("⚠️ deleteMedia: Empty URL")
            return
        }

        do {
            let storageRef = storage.reference(forURL: url)
            try await storageRef.delete()
            print("✅ Deleted media from Storage: \(url)")
        } catch {
            print("❌ Error deleting media from Storage: \(error.localizedDescription)")
            throw error
        }
    }
    /// Calculates how similar two user profiles are based on shared traits.
    ///
    /// - Parameters:
    ///   - current: The logged-in user's profile.
    ///   - other: Another user's profile to compare against.
    /// - Returns: An integer score representing compatibility.
    ///
    /// The score is calculated by:
    /// 1. Counting how many content styles they share, weighted ×2.
    /// 2. Counting how many interests they share, weighted ×1.
    ///
    /// Example: If both users share 2 content styles and 1 interest,
    /// the score is (2 * 2) + 1 = 5.

    private func similarityScore(current: UserProfile, other: UserProfile) -> Int {
        let sharedStyles = Set(current.contentStyles).intersection(other.contentStyles).count
        let sharedInterests = Set(current.interests ?? []).intersection(other.interests ?? []).count
        return sharedStyles * 2 + sharedInterests // weight content styles higher
    }

    // MARK: - Presence & Online Status

    /// Update user's last active timestamp
    func updatePresence(userId: String) async throws {
        guard !userId.isEmpty else {
            print("⚠️ updatePresence: Empty userId")
            return
        }

        try await db.collection("presence").document(userId).setData([
            "lastActive": FieldValue.serverTimestamp(),
            "status": "online"
        ], merge: true)

        print("✅ Updated presence for user: \(userId)")
    }

    /// Get user's last active timestamp
    func getLastActive(userId: String) async throws -> Date? {
        guard !userId.isEmpty else {
            print("⚠️ getLastActive: Empty userId")
            return nil
        }

        let doc = try await db.collection("presence").document(userId).getDocument()

        guard let data = doc.data(),
              let timestamp = data["lastActive"] as? Timestamp else {
            return nil
        }

        return timestamp.dateValue()
    }

    /// Check if user is currently online (active within last 5 minutes)
    func isUserOnline(userId: String) async throws -> Bool {
        guard let lastActive = try await getLastActive(userId: userId) else {
            return false
        }

        let fiveMinutesAgo = Date().addingTimeInterval(-5 * 60)
        return lastActive > fiveMinutesAgo
    }

    /// Set user status to offline
    func setOffline(userId: String) async throws {
        guard !userId.isEmpty else {
            print("⚠️ setOffline: Empty userId")
            return
        }

        try await db.collection("presence").document(userId).setData([
            "status": "offline",
            "lastActive": FieldValue.serverTimestamp()
        ], merge: true)

        print("✅ Set offline for user: \(userId)")
    }

}
