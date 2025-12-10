import Foundation
import FirebaseFirestore

// MARK: - User Profile Model
struct UserProfile: Identifiable, Codable {
    @DocumentID var firestoreID: String?
    var uid: String
    var id: String {uid}
    var displayName: String
    var age: Int?
    var bio: String?
    var location: Location?
    var interests: [String]?
    var contentStyles: [ContentStyle]
    var socialLinks: SocialLinks?
    var mediaURLs: [String]? {
        didSet {
            mediaURLs = mediaURLs?.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        }
    }
    var profileImageURL: String?
    var isVerified: Bool?
    var followerCount: Int?
    var collaborationPreferences: CollaborationPreferences?
    var createdAt: Date
    var updatedAt: Date

    // Verification fields
    var email: String?
    var isEmailVerified: Bool?
    var phoneNumber: String?
    var isPhoneVerified: Bool?

    // MARK: - Initializer for fallback decoding
    init(
        id: String? = nil,
        uid: String,
        displayName: String,
        age: Int? = nil,
        bio: String? = nil,
        location: Location? = nil,
        interests: [String]? = nil,
        contentStyles: [ContentStyle] = [],
        socialLinks: SocialLinks? = nil,
        mediaURLs: [String]? = nil,
        profileImageURL: String? = nil,
        isVerified: Bool? = nil,
        followerCount: Int? = nil,
        collaborationPreferences: CollaborationPreferences? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        email: String? = nil,
        isEmailVerified: Bool? = nil,
        phoneNumber: String? = nil,
        isPhoneVerified: Bool? = nil
    ) {
        self.uid = uid
        self.displayName = displayName
        self.age = age
        self.bio = bio
        self.location = location
        self.interests = interests
        self.contentStyles = contentStyles
        self.socialLinks = socialLinks
        self.mediaURLs = mediaURLs
        self.profileImageURL = profileImageURL
        self.isVerified = isVerified
        self.followerCount = followerCount
        self.collaborationPreferences = collaborationPreferences
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.email = email
        self.isEmailVerified = isEmailVerified
        self.phoneNumber = phoneNumber
        self.isPhoneVerified = isPhoneVerified
    }

    struct Location: Codable {
        var city: String?
        var state: String?
        var country: String?
        var coordinates: GeoPoint?
        var isNearby: Bool { coordinates != nil }

        init(city: String? = nil, state: String? = nil, country: String? = nil, coordinates: GeoPoint? = nil) {
            self.city = city
            self.state = state
            self.country = country
            self.coordinates = coordinates
        }
    }
    
    struct SocialLinks: Codable {
        var tiktok: SocialAccount?
        var instagram: SocialAccount?
        var youtube: SocialAccount?
        var twitch: SocialAccount?
        var spotify: String?
        var snapchat: String?
        
        struct SocialAccount: Codable {
            var username: String
            var followerCount: Int?
            var isVerified: Bool
        }
    }
    
    struct CollaborationPreferences: Codable {
        var lookingFor: [CollabType]
        var availability: [Availability]
        var responseTime: ResponseTime

        enum CollabType: String, Codable, CaseIterable {
            case coopStreams = "Co-op Streams"
            case tournamentTeam = "Tournament Teams"
            case contentCollab = "Content Collabs"
            case coaching = "Coaching/Mentoring"
            case gameReviews = "Game Reviews"
            case modDev = "Mod Development"
            case esportsTeam = "Esports Teams"
            case voiceActing = "Voice Acting"
        }

        enum Availability: String, Codable {
            case weekdays, weekends, flexible, lateNight
        }

        enum ResponseTime: String, Codable {
            case fast = "Usually responds within hours"
            case moderate = "Usually responds within a day"
            case slow = "Usually responds within a week"
        }
    }

    // Gaming-focused content styles
    enum ContentStyle: String, Codable, CaseIterable {
        case fps = "FPS/Shooters"
        case battleRoyale = "Battle Royale"
        case rpg = "RPG/MMO"
        case strategy = "Strategy/RTS"
        case sports = "Sports Games"
        case racing = "Racing"
        case fighting = "Fighting Games"
        case horror = "Horror"
        case indie = "Indie Games"
        case retro = "Retro Gaming"
        case mobile = "Mobile Gaming"
        case vr = "VR Gaming"
        case esports = "Esports"
        case gameDev = "Game Dev"
        case speedrun = "Speedrunning"
        case letsPlay = "Let's Play"
    }
    //custom initializer that replaces any missing/null fields with safe defaults to prevent crashing when fetching
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        firestoreID = try? container.decode(String?.self, forKey: .firestoreID)
        uid = (try? container.decode(String.self, forKey: .uid)) ?? "unknown"
        displayName = (try? container.decode(String.self, forKey: .displayName)) ?? "Unknown"

        age = try? container.decode(Int?.self, forKey: .age)
        bio = try? container.decode(String?.self, forKey: .bio)
        location = try? container.decode(Location.self, forKey: .location)
        interests = try? container.decode([String].self, forKey: .interests)

        // Default to []
        contentStyles = (try? container.decode([ContentStyle].self, forKey: .contentStyles)) ?? []

        socialLinks = try? container.decode(SocialLinks.self, forKey: .socialLinks)
        mediaURLs = try? container.decode([String].self, forKey: .mediaURLs)
        profileImageURL = try? container.decode(String?.self, forKey: .profileImageURL)
        isVerified = try? container.decode(Bool.self, forKey: .isVerified)
        followerCount = try? container.decode(Int.self, forKey: .followerCount)
        collaborationPreferences = try? container.decode(CollaborationPreferences.self, forKey: .collaborationPreferences)

        createdAt = (try? container.decode(Date.self, forKey: .createdAt)) ?? Date()
        updatedAt = (try? container.decode(Date.self, forKey: .updatedAt)) ?? Date()
    }

}
// MARK: - Safe decode for CollaborationPreferences
extension UserProfile.CollaborationPreferences {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        // If any field is missing in Firestore, we provide a safe default instead of crashing
        lookingFor = (try? c.decode([UserProfile.CollaborationPreferences.CollabType].self, forKey: .lookingFor)) ?? []
        availability = (try? c.decode([UserProfile.CollaborationPreferences.Availability].self, forKey: .availability)) ?? []
        responseTime = (try? c.decode(UserProfile.CollaborationPreferences.ResponseTime.self, forKey: .responseTime)) ?? .moderate
    }
}

// MARK: - Match Model
struct Match: Identifiable, Codable {
    @DocumentID var id: String?
    var userId1: String
    var userId2: String
    var matchedAt: Date
    var hasMessaged: Bool
    var lastMessageAt: Date?
    var isActive: Bool
    var profile: UserProfile?
}

// MARK: - Message Model
struct Message: Identifiable, Codable {
    @DocumentID var id: String?
    var conversationId: String
    var senderId: String
    var recipientId: String
    var content: String
    var mediaURL: String?
    var sentAt: Date
    var readAt: Date?
    var isRead: Bool { readAt != nil }
}

// MARK: - Conversation Model
struct Conversation: Identifiable, Codable {
    @DocumentID var id: String?
    var participantIds: [String]
    var participantProfiles: [String: UserProfile]?
    var lastMessage: String?
    var lastMessageAt: Date
    var unreadCount: [String: Int]
    var isGroupChat: Bool
    var groupName: String?
    var createdAt: Date
}

// MARK: - Swipe Action Model
struct SwipeAction: Codable {
    var userId: String
    var targetUserId: String
    var action: Action
    var timestamp: Date
    
    enum Action: String, Codable {
        case like, pass, superLike
    }
}

// MARK: - Featured Creator Model
struct FeaturedCreator: Identifiable, Codable {
    @DocumentID var id: String?
    var userId: String
    var profile: UserProfile?
    var featuredAt: Date
    var expiresAt: Date
    var category: String
    var highlightText: String?
    var priority: Int
}

// MARK: - Testimonial Model
struct Testimonial: Identifiable, Codable {
    @DocumentID var id: String?
    var profileUserId: String // User who receives the testimonial
    var authorUserId: String // User who writes the testimonial
    var authorName: String
    var authorImageURL: String?
    var authorRole: String? // e.g., "Content Creator", "Video Editor"
    var rating: Int // 1-5 stars
    var text: String
    var createdAt: Date
    var isVerified: Bool // True if they actually collaborated
}

// MARK: - Collaboration Model
struct Collaboration: Identifiable, Codable {
    @DocumentID var id: String?
    var user1Id: String // First user in collaboration
    var user2Id: String // Second user in collaboration
    var projectName: String
    var projectDescription: String?
    var status: CollabStatus
    var startedAt: Date
    var completedAt: Date?
    var createdAt: Date

    enum CollabStatus: String, Codable {
        case active = "Active"
        case completed = "Completed"
        case pending = "Pending"

        var color: String {
            switch self {
            case .active: return "green"
            case .completed: return "blue"
            case .pending: return "orange"
            }
        }

        var icon: String {
            switch self {
            case .active: return "checkmark.circle.fill"
            case .completed: return "checkmark.seal.fill"
            case .pending: return "clock.fill"
            }
        }
    }

    // Helper to get the other user's ID
    func getPartnerUserId(currentUserId: String) -> String? {
        if user1Id == currentUserId {
            return user2Id
        } else if user2Id == currentUserId {
            return user1Id
        }
        return nil
    }
}
