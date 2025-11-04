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
