import Foundation
import FirebaseFirestore

// MARK: - User Profile Model
struct UserProfile: Identifiable, Codable {
    @DocumentID var id: String?
    var uid: String
    var displayName: String
    var age: Int?
    var bio: String?
    var location: Location?
    var interests: [String]?
    var contentStyles: [ContentStyle]
    var socialLinks: SocialLinks?
    var mediaURLs: [String]?
    var profileImageURL: String?
    var isVerified: Bool?
    var followerCount: Int?
    var collaborationPreferences: CollaborationPreferences?
    var createdAt: Date
    var updatedAt: Date
    init(
        uid: String,
        displayName: String,
        age: Int?,
        location: Location?,
        contentStyles: [ContentStyle],
        mediaURLs: [String] = [],
        socialLinks: SocialLinks? = nil,
        profileImageURL: String? = nil
    ) {
        self.id = nil
        self.uid = uid
        self.displayName = displayName
        self.age = age
        self.bio = nil
        self.location = location
        self.interests = []
        self.contentStyles = contentStyles
        self.socialLinks = socialLinks
        self.mediaURLs = mediaURLs
        self.profileImageURL = profileImageURL
        self.isVerified = false
        self.followerCount = 0
        self.collaborationPreferences = .init(
            lookingFor: [],
            availability: [],
            responseTime: .moderate
        )
        self.createdAt = Date()
        self.updatedAt = Date()
    }


    struct Location: Codable {
        var city: String?
        var state: String?
        var country: String?
        var coordinates: GeoPoint?
        var isNearby: Bool { coordinates != nil }
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
            case twitchStream = "Twitch Streamers"
            case musicCollab = "Music Collabs"
            case podcastGuest = "Podcast Guests"
            case tiktokLive = "Tiktok Lives"
            case brandDeal = "Brand Deals"
            case contentSeries = "Content Series"
        }
        
        enum Availability: String, Codable {
            case weekdays, weekends, flexible
        }
        
        enum ResponseTime: String, Codable {
            case fast = "Usually responds within hours"
            case moderate = "Usually responds within a day"
            case slow = "Usually responds within a week"
        }
        
    }
    
    enum ContentStyle: String, Codable, CaseIterable {
        case comedy = "Comedy"
        case editing = "Editing"
        case beauty = "Beauty"
        case fashion = "Fashion"
        case fitness = "Fitness"
        case mukbang = "Mukbang"
        case cooking = "Cooking"
        case dance = "Dance"
        case music = "Music"
        case gaming = "Video Games"
        case pet = "Pet"
        case tech = "Tech"
        case art = "Art"
        case sports = "Sports"
    }
    //custom initializer that replaces any missing/null fields with safe defaults to prevent crashing when fetching
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try? container.decode(String?.self, forKey: .id)
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
