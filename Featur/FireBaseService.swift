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
    
    // ✅ FIXED: Convert PrefixSequence to Array
    func fetchDiscoverProfiles(for user: UserProfile, limit: Int = 20, excludeUserIds: [String] = []) async throws -> [UserProfile] {
        var query: Query = db.collection("users").limit(to: limit)
        
        // Exclude already swiped users
        if !excludeUserIds.isEmpty {
            // Convert PrefixSequence to Array
            let limitedIds = Array(excludeUserIds.prefix(10))
            query = query.whereField(FieldPath.documentID(), notIn: limitedIds)
        }
        
        let snapshot = try await query.getDocuments()
        var profiles = try snapshot.documents.compactMap{ try $0.data(as: UserProfile.self)}
        //remove current user
        profiles.removeAll {$0.uid == user.uid}
        
        //sort by similarity
        profiles.sort { similarityScore(current: user, other: $0) > similarityScore(current: user, other: $1)}
        
        return profiles
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
        
        // Check for mutual match
        if action.action == .like {
            try await checkAndCreateMatch(userId: action.userId, targetUserId: action.targetUserId)
        }
        
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
            // Create match
            let match = Match(
                userId1: userId,
                userId2: targetUserId,
                matchedAt: Date(),
                hasMessaged: false,
                isActive: true
            )
            try db.collection("matches").addDocument(from: match)
            // Debug statment confirm match
            print("✅ Match created between \(userId) and \(targetUserId)")

        }else{
            // Debug statement no match created
            print("❌ No reciprocal like yet for \(userId) ↔ \(targetUserId)")

        }
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
    
    func searchProfiles(query: String, filters: [String]? = nil) async throws -> [UserProfile] {
        var firestoreQuery: Query = db.collection("users")
        
        if let filters = filters, !filters.isEmpty {
            firestoreQuery = firestoreQuery.whereField("contentStyles", arrayContainsAny: filters)
        }
        
        let snapshot = try await firestoreQuery.limit(to: 50).getDocuments()
        let profiles = try snapshot.documents.compactMap { try $0.data(as: UserProfile.self) }
        
        // Filter by name if query is provided
        if !query.isEmpty {
            return profiles.filter { $0.displayName.localizedCaseInsensitiveContains(query) }
        }
        
        return profiles
    }
    
    // MARK: - Media Upload
    
    func uploadMedia(data: Data, path: String) async throws -> String {
        let ref = storage.reference().child(path)
        let _ = try await ref.putDataAsync(data)
        return try await ref.downloadURL().absoluteString
    }
    
    func uploadProfilePhoto(userId: String, imageData: Data) async throws -> String {
        let path = "profile_photos/\(userId)/\(UUID().uuidString).jpg"
        return try await uploadMedia(data: imageData, path: path)
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

}
