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
        try await db.collection("users").document(uid).getDocument(as: UserProfile.self)
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
    func fetchDiscoverProfiles(limit: Int = 20, excludeUserIds: [String] = []) async throws -> [UserProfile] {
        var query: Query = db.collection("users").limit(to: limit)
        
        // Exclude already swiped users
        if !excludeUserIds.isEmpty {
            // Convert PrefixSequence to Array
            let limitedIds = Array(excludeUserIds.prefix(10))
            query = query.whereField(FieldPath.documentID(), notIn: limitedIds)
        }
        
        let snapshot = try await query.getDocuments()
        return try snapshot.documents.compactMap { try $0.data(as: UserProfile.self) }
    }
    
    func recordSwipe(_ action: SwipeAction) async throws {
        try db.collection("swipes").addDocument(from: action)
        
        // Check for mutual match
        if action.action == .like {
            try await checkAndCreateMatch(userId: action.userId, targetUserId: action.targetUserId)
        }
    }
    
    private func checkAndCreateMatch(userId: String, targetUserId: String) async throws {
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
        }
    }
    
    func fetchMatches(forUser userId: String) async throws -> [Match] {
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
    
    func fetchConversations(forUser userId: String) async throws -> [Conversation] {
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
        try await db.collection("conversations").document(conversationId).updateData([
            "unreadCount.\(userId)": 0
        ])
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
}
