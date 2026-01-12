//
//  Models.swift
//  konnectapp
//
//  Created by qsoul on 05.01.2026.
//

import Foundation

// MARK: - User Model
struct User: Codable, Equatable {
    let id: Int64
    let name: String
    let username: String
    let photo: String?
    let banner: String?
    let about: String?
    let avatar_url: String?
    let banner_url: String?
    let profile_background_url: String?
    let profile_color: String?
    let hasCredentials: Bool?
    let account_type: String?
    let main_account_id: Int64?
    
    static func == (lhs: User, rhs: User) -> Bool {
        return lhs.id == rhs.id &&
               lhs.profile_background_url == rhs.profile_background_url
    }
}

// MARK: - BanInfo Model
struct BanInfo: Codable {
    let reason: String?
    let until: String? // ISO 8601 format
}

// MARK: - Login Request
struct LoginRequest: Codable {
    let username: String
    let password: String
}

// MARK: - Error Response
struct ErrorResponse: Codable {
    let error: String?
    let message: String?
}

// MARK: - Login Response
struct LoginResponse: Codable {
    let success: Bool?
    let user: User?
    let sessionKey: String?
    let session_key: String?
    let token: String?
    let error: String?
    let ban_info: BanInfo?
    let message: String?
}

// MARK: - Check Auth Response
struct CheckAuthResponse: Codable {
    let isAuthenticated: Bool
    let user: User?
    let sessionExists: Bool?
    let needsProfileSetup: Bool?
    let user_id: Int64?
    let hasAuthMethod: Bool?
    let chat_id: String?
    let error: String?
    let ban_info: BanInfo?
    let message: String?
}

// MARK: - Comment Model
struct Comment: Codable, Identifiable, Equatable {
    let id: Int64
    let content: String?
    let image: String?
    let likes_count: Int?
    let timestamp: String?
    let user: PostUser?
    let user_liked: Bool?
    let replies_count: Int?
    let replies: [Reply]?
    
    static func == (lhs: Comment, rhs: Comment) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Reply Model
struct Reply: Codable, Identifiable, Equatable {
    let id: Int64
    let content: String?
    let image: String?
    let timestamp: String?
    let parent_reply_id: Int64?
    let likes_count: Int?
    let user_liked: Bool?
    let user: PostUser?
    
    // Parent reply info (only basic info, not full Reply to avoid recursion)
    let parent_reply_user: PostUser?
    let parent_reply_content: String?
    
    static func == (lhs: Reply, rhs: Reply) -> Bool {
        return lhs.id == rhs.id
    }
    
    enum CodingKeys: String, CodingKey {
        case id, content, image, timestamp, parent_reply_id
        case likes_count, user_liked, user
        case parent_reply
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int64.self, forKey: .id)
        content = try container.decodeIfPresent(String.self, forKey: .content)
        image = try container.decodeIfPresent(String.self, forKey: .image)
        timestamp = try container.decodeIfPresent(String.self, forKey: .timestamp)
        parent_reply_id = try container.decodeIfPresent(Int64.self, forKey: .parent_reply_id)
        likes_count = try container.decodeIfPresent(Int.self, forKey: .likes_count)
        user_liked = try container.decodeIfPresent(Bool.self, forKey: .user_liked)
        user = try container.decodeIfPresent(PostUser.self, forKey: .user)
        
        // Handle parent_reply - extract only user and content to avoid recursion
        if let parentReplyContainer = try? container.nestedContainer(keyedBy: DynamicCodingKeys.self, forKey: .parent_reply) {
            parent_reply_user = try? parentReplyContainer.decodeIfPresent(PostUser.self, forKey: DynamicCodingKeys(stringValue: "user")!)
            parent_reply_content = try? parentReplyContainer.decodeIfPresent(String.self, forKey: DynamicCodingKeys(stringValue: "content")!)
        } else {
            parent_reply_user = nil
            parent_reply_content = nil
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(content, forKey: .content)
        try container.encodeIfPresent(image, forKey: .image)
        try container.encodeIfPresent(timestamp, forKey: .timestamp)
        try container.encodeIfPresent(parent_reply_id, forKey: .parent_reply_id)
        try container.encodeIfPresent(likes_count, forKey: .likes_count)
        try container.encodeIfPresent(user_liked, forKey: .user_liked)
        try container.encodeIfPresent(user, forKey: .user)
    }
}

// Helper for dynamic coding keys
struct DynamicCodingKeys: CodingKey {
    var stringValue: String
    var intValue: Int?
    
    init?(stringValue: String) {
        self.stringValue = stringValue
    }
    
    init?(intValue: Int) {
        return nil
    }
}

// MARK: - Comments Response
struct CommentsResponse: Codable {
    let comments: [Comment]
    let pagination: Pagination?
}

// MARK: - Pagination Model
struct Pagination: Codable {
    let page: Int
    let limit: Int
    let total: Int
    let totalPages: Int?
    let hasNext: Bool
    let hasPrev: Bool
    
    enum CodingKeys: String, CodingKey {
        case page, limit, total
        case totalPages = "total_pages"
        case hasNext = "has_next"
        case hasPrev = "has_prev"
    }
}

// MARK: - Create Comment Response
struct CreateCommentResponse: Codable {
    let success: Bool?
    let comment: Comment?
    let error: String?
}

// MARK: - Create Reply Response
struct CreateReplyResponse: Codable {
    let success: Bool?
    let reply: Reply?
    let error: String?
}

// MARK: - Post Detail Response
struct PostDetailResponse: Codable {
    let success: Bool?
    let post: Post?
    let comments: [Comment]?
    let error: String?
}

// MARK: - Poll Voter Model
struct PollVoter: Codable, Identifiable {
    let id: Int64
    let username: String
    let name: String?
    let photo: String?
    let avatar_url: String?
    let voted_at: String?
}

// MARK: - Poll Option Model
struct PollOption: Codable, Identifiable {
    let id: Int64
    let text: String
    let votes_count: Int?
    let percentage: Double?
    let voters: [PollVoter]?
}

// MARK: - Poll Model
struct Poll: Codable, Identifiable {
    let id: Int64
    let question: String
    let options: [PollOption]
    let expires_at: String?
    let is_anonymous: Bool?
    let is_expired: Bool?
    let is_multiple_choice: Bool?
    let total_votes: Int?
    let user_vote_option_ids: [Int64]?
    let user_voted: Bool?
}

// MARK: - Post Model
struct Post: Codable, Identifiable {
    let id: Int64
    let content: String?
    let user: PostUser?
    let created_at: String?
    let updated_at: String?
    let timestamp: String?
    let likes_count: Int?
    let comments_count: Int?
    let reposts_count: Int?
    let views_count: Int?
    let is_liked: Bool?
    let is_reposted: Bool?
    let is_repost: Bool?
    let media: [String]?
    let images: [String]?
    let image: String?
    let type: String?
    let original_post: OriginalPost?
    let fact: Fact?
    let edited: Bool?
    let last_comment: Comment?
    let is_nsfw: Bool?
    let music: [MusicTrack]?
    let is_pinned: Bool?
    let video: String?
    let video_poster: String?
    let poll: Poll?
    
    enum CodingKeys: String, CodingKey {
        case id, content, user, created_at, updated_at, timestamp
        case likes_count, comments_count, reposts_count, views_count
        case is_liked, is_reposted, is_repost, media, images, image
        case type, original_post, fact, edited, last_comment, is_nsfw, music, is_pinned
        case video, video_poster, poll
    }
}

// MARK: - Original Post Model (для репостов)
struct OriginalPost: Codable {
    let id: Int64
    let content: String?
    let user: PostUser?
    let created_at: String?
    let updated_at: String?
    let timestamp: String?
    let likes_count: Int?
    let comments_count: Int?
    let reposts_count: Int?
    let views_count: Int?
    let is_liked: Bool?
    let is_reposted: Bool?
    let is_repost: Bool?
    let media: [String]?
    let images: [String]?
    let image: String?
    let type: String?
    let fact: Fact?
    let edited: Bool?
    let is_nsfw: Bool?
    let music: [MusicTrack]?
    let video: String?
    let video_poster: String?
    let poll: Poll?
}

// MARK: - Post User Model
struct PostUser: Codable {
    let id: Int64
    let username: String
    let name: String?
    let photo: String?
    let avatar_url: String?
    let is_verified: Bool?
    let is_following: Bool?
    let account_type: String?
    let last_active_utc: String?
    let time_diff_seconds: Double?
    let achievement: PostUserAchievement?
    
    enum CodingKeys: String, CodingKey {
        case id, username, name, photo
        case avatar_url = "avatar_url"
        case is_verified = "is_verified"
        case is_following = "is_following"
        case account_type = "account_type"
        case last_active_utc = "last_active_utc"
        case time_diff_seconds = "time_diff_seconds"
        case achievement
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int64.self, forKey: .id)
        username = try container.decode(String.self, forKey: .username)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        photo = try container.decodeIfPresent(String.self, forKey: .photo)
        avatar_url = try container.decodeIfPresent(String.self, forKey: .avatar_url)
        is_verified = try container.decodeIfPresent(Bool.self, forKey: .is_verified)
        is_following = try container.decodeIfPresent(Bool.self, forKey: .is_following)
        account_type = try container.decodeIfPresent(String.self, forKey: .account_type)
        last_active_utc = try container.decodeIfPresent(String.self, forKey: .last_active_utc)
        time_diff_seconds = try container.decodeIfPresent(Double.self, forKey: .time_diff_seconds)
        achievement = try container.decodeIfPresent(PostUserAchievement.self, forKey: .achievement)
    }
}

// MARK: - Post User Achievement Model
struct PostUserAchievement: Codable {
    let bage: String?
    let image_path: String?
}

// MARK: - Fact Model
struct Fact: Codable {
    let id: Int64
    let who_provided: String?
    let explanation_text: String?
}

// MARK: - Feed Response
struct FeedResponse: Codable {
    let posts: [Post]
    let has_next: Bool
    let total: Int
    let page: Int
    let pages: Int
}

// MARK: - Feed Type
enum FeedType: String, Codable {
    case all = "all"
    case following = "following"
    case recommended = "recommended"
}

// MARK: - Music Track Model
struct MusicTrack: Codable, Identifiable {
    let id: Int64
    let title: String
    let artist: String?
    let album: String?
    let cover_path: String?
    let file_path: String?
    let duration: Int
    let genre: String?
    let is_liked: Bool?
    let likes_count: Int?
    let plays_count: Int?
    let user_id: Int64?
    let user_name: String?
    let user_username: String?
    let verified: Bool?
    let created_at: String?
    let description: String?
    let artist_id: Int64?
    let trend: String?
    let trend_data: TrendData?
}

// MARK: - Trend Data Model
struct TrendData: Codable {
    let trend: String
    let change_percent: Double?
    let position_change: Int?
    let current_plays: Int?
    let previous_chart_position: Int?
    let chart_position: Int?
}

// MARK: - Music Response
struct MusicResponse: Codable {
    let current_page: Int
    let pages: Int
    let success: Bool?
    let total: Int
    let tracks: [MusicTrack]
}

// MARK: - My Vibe Response
struct MyVibeResponse: Codable {
    let success: Bool
    let tracks: [MusicTrack]
    let message: String?
}

// MARK: - Charts Response
struct ChartsResponse: Codable {
    let success: Bool
    let charts: ChartsData
}

struct ChartsData: Codable {
    let popular: [MusicTrack]?
    let most_played: [MusicTrack]?
    let most_liked: [MusicTrack]?
    let new_releases: [MusicTrack]?
}

// MARK: - Tracks Response
struct TracksResponse: Codable {
    let success: Bool
    let tracks: [MusicTrack]
    let total: Int?
    let offset: Int?
    let limit: Int?
    let has_more: Bool?
}

// MARK: - Play Response
struct PlayResponse: Codable {
    let success: Bool
    let message: String
    let plays_count: Int
    let cooldown: Bool?
}

// MARK: - Like Response
struct LikeResponse: Codable {
    let success: Bool
    let message: String
    let likes_count: Int
}

// MARK: - Track Detail Response
struct TrackDetailResponse: Codable {
    let success: Bool
    let track: MusicTrackDetail
}

// MARK: - Music Track Detail (расширенная версия)
struct MusicTrackDetail: Codable {
    let id: Int64
    let title: String
    let artist: String?
    let album: String?
    let duration: Int
    let file_path: String?
    let cover_path: String?
    let user_id: Int64?
    let user_name: String?
    let user_username: String?
    let genre: String?
    let description: String?
    let plays_count: Int?
    let likes_count: Int?
    let verified: Bool?
    let artist_id: Int64?
    let created_at: String?
    let artist_info: ArtistInfo?
}

// MARK: - Artist Info
struct ArtistInfo: Codable {
    let id: Int64
    let avatar_url: String?
    let verified: Bool?
}

// MARK: - Lyrics Response
struct LyricsResponse: Codable {
    let track_id: Int64
    let has_lyrics: Bool
    let has_synced_lyrics: Bool
    let lyrics: String?
    let synced_lyrics: [SyncedLyricLine]?
    let lyrics_url: String?
    let source_url: String?
}

// MARK: - Synced Lyric Line
struct SyncedLyricLine: Codable, Identifiable {
    let text: String
    let startTimeMs: Int
    let lineId: String
    
    var id: String { lineId }
}

// MARK: - Profile Models
struct ProfileUser: Codable {
    let id: Int64
    let name: String
    let username: String
    let about: String?
    let photo: String?
    let cover_photo: String?
    let status_text: String?
    let status_color: String?
    let profile_color: String?
    let profile_id: Int?
    let followers_count: Int?
    let following_count: Int?
    let friends_count: Int?
    let posts_count: Int?
    let photos_count: Int?
    let total_likes: Int?
    let avatar_url: String?
    let banner_url: String?
    let verification_status: VerificationStatus?
    let verification: Verification?
    let achievement: Achievement?
    let interests: [String]?
    let purchased_usernames: [PurchasedUsername]?
    let registration_date: String?
    let ban: BanInfo?
    let scam: ScamStatus?
    let account_type: String?
    let main_account_id: Int64?
    let is_private: Bool?
    let subscription: Subscription?
    let music: ProfileMusic?
    let musician_type: String?
    let total_artists_count: Int?
    let profile_background_url: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, username, about, photo, cover_photo
        case status_text, status_color, profile_color, profile_id
        case followers_count, following_count, friends_count, posts_count
        case photos_count, total_likes, avatar_url, banner_url
        case verification_status, verification, achievement, interests
        case purchased_usernames, registration_date, ban, scam
        case account_type, main_account_id, is_private, subscription
        case music, musician_type, total_artists_count, profile_background_url
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int64.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        username = try container.decode(String.self, forKey: .username)
        about = try container.decodeIfPresent(String.self, forKey: .about)
        photo = try container.decodeIfPresent(String.self, forKey: .photo)
        cover_photo = try container.decodeIfPresent(String.self, forKey: .cover_photo)
        status_text = try container.decodeIfPresent(String.self, forKey: .status_text)
        status_color = try container.decodeIfPresent(String.self, forKey: .status_color)
        profile_color = try container.decodeIfPresent(String.self, forKey: .profile_color)
        profile_id = try container.decodeIfPresent(Int.self, forKey: .profile_id)
        followers_count = try container.decodeIfPresent(Int.self, forKey: .followers_count)
        following_count = try container.decodeIfPresent(Int.self, forKey: .following_count)
        friends_count = try container.decodeIfPresent(Int.self, forKey: .friends_count)
        posts_count = try container.decodeIfPresent(Int.self, forKey: .posts_count)
        photos_count = try container.decodeIfPresent(Int.self, forKey: .photos_count)
        total_likes = try container.decodeIfPresent(Int.self, forKey: .total_likes)
        avatar_url = try container.decodeIfPresent(String.self, forKey: .avatar_url)
        banner_url = try container.decodeIfPresent(String.self, forKey: .banner_url)
        
        if let statusInt = try? container.decodeIfPresent(Int.self, forKey: .verification_status) {
            verification_status = VerificationStatus.fromInt(statusInt)
        } else if let statusString = try? container.decodeIfPresent(String.self, forKey: .verification_status) {
            verification_status = VerificationStatus.fromString(statusString)
        } else {
            verification_status = nil
        }
        
        verification = try container.decodeIfPresent(Verification.self, forKey: .verification)
        achievement = try container.decodeIfPresent(Achievement.self, forKey: .achievement)
        
        if let interestsArray = try? container.decodeIfPresent([String].self, forKey: .interests) {
            interests = interestsArray
        } else if let interestsString = try? container.decodeIfPresent(String.self, forKey: .interests) {
            if interestsString.isEmpty {
                interests = []
            } else {
                interests = [interestsString]
            }
        } else {
            interests = nil
        }
        
        purchased_usernames = try container.decodeIfPresent([PurchasedUsername].self, forKey: .purchased_usernames)
        registration_date = try container.decodeIfPresent(String.self, forKey: .registration_date)
        ban = try container.decodeIfPresent(BanInfo.self, forKey: .ban)
        
        if let scamInt = try? container.decodeIfPresent(Int.self, forKey: .scam) {
            scam = ScamStatus.fromInt(scamInt)
        } else if let scamBool = try? container.decodeIfPresent(Bool.self, forKey: .scam) {
            scam = ScamStatus.fromBool(scamBool)
        } else {
            scam = nil
        }
        
        account_type = try container.decodeIfPresent(String.self, forKey: .account_type)
        main_account_id = try container.decodeIfPresent(Int64.self, forKey: .main_account_id)
        is_private = try container.decodeIfPresent(Bool.self, forKey: .is_private)
        subscription = try container.decodeIfPresent(Subscription.self, forKey: .subscription)
        music = try container.decodeIfPresent(ProfileMusic.self, forKey: .music)
        musician_type = try container.decodeIfPresent(String.self, forKey: .musician_type)
        total_artists_count = try container.decodeIfPresent(Int.self, forKey: .total_artists_count)
        profile_background_url = try container.decodeIfPresent(String.self, forKey: .profile_background_url)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(username, forKey: .username)
        try container.encodeIfPresent(about, forKey: .about)
        try container.encodeIfPresent(photo, forKey: .photo)
        try container.encodeIfPresent(cover_photo, forKey: .cover_photo)
        try container.encodeIfPresent(status_text, forKey: .status_text)
        try container.encodeIfPresent(status_color, forKey: .status_color)
        try container.encodeIfPresent(profile_color, forKey: .profile_color)
        try container.encodeIfPresent(profile_id, forKey: .profile_id)
        try container.encodeIfPresent(followers_count, forKey: .followers_count)
        try container.encodeIfPresent(following_count, forKey: .following_count)
        try container.encodeIfPresent(friends_count, forKey: .friends_count)
        try container.encodeIfPresent(posts_count, forKey: .posts_count)
        try container.encodeIfPresent(photos_count, forKey: .photos_count)
        try container.encodeIfPresent(total_likes, forKey: .total_likes)
        try container.encodeIfPresent(avatar_url, forKey: .avatar_url)
        try container.encodeIfPresent(banner_url, forKey: .banner_url)
        
        if let verificationStatus = verification_status {
            if case .verified = verificationStatus {
                try container.encode(4, forKey: .verification_status)
            } else if case .unverified = verificationStatus {
                try container.encode(0, forKey: .verification_status)
            } else if case .pending = verificationStatus {
                try container.encode(1, forKey: .verification_status)
            } else if case .rejected = verificationStatus {
                try container.encode(2, forKey: .verification_status)
            } else if case .custom(let value) = verificationStatus {
                try container.encode(value, forKey: .verification_status)
            }
        }
        
        try container.encodeIfPresent(verification, forKey: .verification)
        try container.encodeIfPresent(achievement, forKey: .achievement)
        try container.encodeIfPresent(interests, forKey: .interests)
        try container.encodeIfPresent(purchased_usernames, forKey: .purchased_usernames)
        try container.encodeIfPresent(registration_date, forKey: .registration_date)
        try container.encodeIfPresent(ban, forKey: .ban)
        
        if let scamStatus = scam {
            try container.encode(scamStatus.isScam ? 1 : 0, forKey: .scam)
        }
        
        try container.encodeIfPresent(account_type, forKey: .account_type)
        try container.encodeIfPresent(main_account_id, forKey: .main_account_id)
        try container.encodeIfPresent(is_private, forKey: .is_private)
        try container.encodeIfPresent(subscription, forKey: .subscription)
        try container.encodeIfPresent(music, forKey: .music)
        try container.encodeIfPresent(musician_type, forKey: .musician_type)
        try container.encodeIfPresent(total_artists_count, forKey: .total_artists_count)
        try container.encodeIfPresent(profile_background_url, forKey: .profile_background_url)
    }
}

enum VerificationStatus {
    case verified
    case unverified
    case pending
    case rejected
    case custom(Int)
    
    static func fromInt(_ value: Int) -> VerificationStatus? {
        switch value {
        case 0: return .unverified
        case 1: return .pending
        case 2: return .rejected
        case 4: return .verified
        default: return .custom(value)
        }
    }
    
    static func fromString(_ value: String) -> VerificationStatus? {
        switch value.lowercased() {
        case "verified": return .verified
        case "unverified": return .unverified
        case "pending": return .pending
        case "rejected": return .rejected
        default: return nil
        }
    }
    
    var isVerified: Bool {
        if case .verified = self {
            return true
        }
        return false
    }
}

enum ScamStatus {
    case scam
    case notScam
    
    static func fromInt(_ value: Int) -> ScamStatus? {
        return value != 0 ? .scam : .notScam
    }
    
    static func fromBool(_ value: Bool) -> ScamStatus {
        return value ? .scam : .notScam
    }
    
    var isScam: Bool {
        if case .scam = self {
            return true
        }
        return false
    }
}

struct Verification: Codable {
    let status: VerificationStatusValue
    let date: String?
    
    enum CodingKeys: String, CodingKey {
        case status, date
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        if let statusInt = try? container.decode(Int.self, forKey: .status) {
            status = .int(statusInt)
        } else if let statusString = try? container.decode(String.self, forKey: .status) {
            status = .string(statusString)
        } else {
            throw DecodingError.dataCorrupted(DecodingError.Context(
                codingPath: container.codingPath,
                debugDescription: "Cannot decode status as Int or String"
            ))
        }
        
        date = try container.decodeIfPresent(String.self, forKey: .date)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch status {
        case .int(let value):
            try container.encode(value, forKey: .status)
        case .string(let value):
            try container.encode(value, forKey: .status)
        }
        
        try container.encodeIfPresent(date, forKey: .date)
    }
}

enum VerificationStatusValue {
    case int(Int)
    case string(String)
    
    var stringValue: String {
        switch self {
        case .int(let value):
            switch value {
            case 0: return "unverified"
            case 1: return "pending"
            case 2: return "rejected"
            case 4: return "verified"
            default: return "unknown"
            }
        case .string(let value):
            return value
        }
    }
    
    var isVerified: Bool {
        switch self {
        case .int(let value):
            return value == 4
        case .string(let value):
            return value.lowercased() == "verified"
        }
    }
}

struct Achievement: Codable {
    let bage: String
    let image_path: String
    let upgrade: String?
    let color_upgrade: String?
}

// MARK: - Achievement List Models
struct UserAchievement: Codable, Identifiable {
    let id: Int64
    let bage: String
    let image_path: String
    let date_awarded: String?
    let is_active: Bool
    let is_active_badge: Bool
    let profile_name: String?
    let upgrade: String?
    let color_upgrade: String?
}

struct AchievementsResponse: Codable {
    let achievements: [UserAchievement]
}

struct ActivateAchievementRequest: Codable {
    let achievement_id: Int64
}

struct ActivateAchievementResponse: Codable {
    let success: Bool
    let message: String?
    let achievement: Achievement?
}

struct DeactivateAchievementResponse: Codable {
    let success: Bool
    let message: String?
}

struct PurchasedUsername: Codable {
    let id: Int
    let username: String
    let price_paid: Int?
    let purchase_date: String
    let is_active: Bool
}

struct Subscription: Codable {
    let type: String
    let subscription_date: String
    let expires_at: String?
    let total_duration_months: Double
    let active: Bool
    let is_lifetime: Bool?
}

struct ProfileMusic: Codable {
    let id: Int
    let title: String
    let artist: String
    let album: String?
    let duration: Int?
    let plays_count: Int?
    let is_verified: Bool?
    let display_mode: String?
    let lyrics_display_mode: String?
}

struct Social: Codable {
    let name: String
    let link: String
}

struct ProfileResponse: Codable {
    let user: ProfileUser
    let is_following: Bool?
    let is_friend: Bool?
    let notifications_enabled: Bool?
    let socials: [Social]?
    let verification: Verification?
    let achievement: Achievement?
    let followers_count: Int?
    let following_count: Int?
    let friends_count: Int?
    let posts_count: Int?
    let ban: BanInfo?
    let current_user_is_moderator: Bool?
    let is_private: Bool?
    let message: String?
}

// MARK: - Notification Models
struct Notification: Codable, Identifiable {
    let id: Int64
    let type: String
    let message: String
    let created_at: String?
    let is_read: Bool?
    let link: String?
    let content_type: String?
    let sender_id: Int64?
    let user_id: Int64?
    let sender_user: PostUser?
    let post_content: String?
    let post_data: PostData?
    let comment_content: String?
    let comment_data: CommentData?
    let reply_content: String?
    let reply_data: ReplyData?
    
    enum CodingKeys: String, CodingKey {
        case id, type, message, link
        case created_at = "created_at"
        case is_read = "is_read"
        case content_type = "content_type"
        case sender_id = "sender_id"
        case user_id = "user_id"
        case sender_user = "sender_user"
        case post_content = "post_content"
        case post_data = "post_data"
        case comment_content = "comment_content"
        case comment_data = "comment_data"
        case reply_content = "reply_content"
        case reply_data = "reply_data"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int64.self, forKey: .id)
        type = try container.decode(String.self, forKey: .type)
        message = try container.decode(String.self, forKey: .message)
        created_at = try container.decodeIfPresent(String.self, forKey: .created_at)
        is_read = try container.decodeIfPresent(Bool.self, forKey: .is_read)
        link = try container.decodeIfPresent(String.self, forKey: .link)
        content_type = try container.decodeIfPresent(String.self, forKey: .content_type)
        sender_id = try container.decodeIfPresent(Int64.self, forKey: .sender_id)
        user_id = try container.decodeIfPresent(Int64.self, forKey: .user_id)
        
        do {
            sender_user = try container.decodeIfPresent(PostUser.self, forKey: .sender_user)
            if sender_user == nil {
                print("⚠️ Notification: sender_user is nil after decoding for notification \(id)")
            } else {
                print("✅ Notification: sender_user decoded successfully for notification \(id), name: \(sender_user?.name ?? "nil"), username: \(sender_user?.username ?? "nil")")
            }
        } catch {
            print("❌ Notification: Error decoding sender_user for notification \(id): \(error)")
            sender_user = nil
        }
        
        post_content = try container.decodeIfPresent(String.self, forKey: .post_content)
        post_data = try container.decodeIfPresent(PostData.self, forKey: .post_data)
        comment_content = try container.decodeIfPresent(String.self, forKey: .comment_content)
        comment_data = try container.decodeIfPresent(CommentData.self, forKey: .comment_data)
        reply_content = try container.decodeIfPresent(String.self, forKey: .reply_content)
        reply_data = try container.decodeIfPresent(ReplyData.self, forKey: .reply_data)
    }
}

struct PostData: Codable {
    let id: Int64
    let created_at: String?
    let image_url: String?
    let preview: String?
    let text: String?
    let title: String?
    let user_id: Int64?
}

struct CommentData: Codable {
    let id: Int64
    let author: PostUser?
    let created_at: String?
    let image_url: String?
    let post_id: Int64?
    let preview: String?
    let text: String?
    let user_id: Int64?
}

struct ReplyData: Codable {
    let id: Int64
    let author: PostUser?
    let created_at: String?
    let image_url: String?
    let post_id: Int64?
    let preview: String?
    let text: String?
    let user_id: Int64?
}

struct NotificationsResponse: Codable {
    let success: Bool
    let notifications: [Notification]
    let unread_count: Int?
}

// MARK: - Search Models
struct Decoration: Codable {
    let background: String?
    let item_path: String?
}

struct SearchUser: Codable, Identifiable {
    let id: Int64
    let username: String
    let name: String?
    let photo: String?
    let avatar_url: String?
    let about: String?
    let is_verified: Bool?
    let verification_status: String?
    let decoration: Decoration?
}

struct UsersSearchResponse: Codable {
    let has_next: Bool
    let users: [SearchUser]
}

struct SearchChannel: Codable, Identifiable {
    let id: Int64
    let username: String
    let name: String?
    let photo: String?
    let avatar_url: String?
    let about: String?
    let is_verified: Bool?
    let verification_status: String?
    let decoration: Decoration?
    let followers_count: Int?
    let is_following: Bool?
}

struct ChannelsSearchResponse: Codable {
    let channels: [SearchChannel]
    let has_next: Bool
    let total: Int
}

// MARK: - Auth Errors
enum AuthError: Error, LocalizedError {
    case invalidCredentials
    case unauthorized
    case banned
    case networkError
    case invalidResponse
    case keychainError
    case logoutFailed
    case tokenExpired
    case accountLocked
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Неверное имя пользователя или пароль"
        case .unauthorized:
            return "Требуется авторизация"
        case .banned:
            return "Ваш аккаунт заблокирован"
        case .networkError:
            return "Ошибка сети"
        case .invalidResponse:
            return "Неверный ответ сервера"
        case .keychainError:
            return "Ошибка сохранения токенов"
        case .logoutFailed:
            return "Ошибка при выходе"
        case .tokenExpired:
            return "Токен истек. Войдите снова"
        case .accountLocked:
            return "Аккаунт временно заблокирован"
        }
    }
}

// MARK: - Account Switch Models
struct MyChannelsResponse: Codable {
    let success: Bool
    let current_account: User?
    let main_account: User?
    let channels: [User]
    let error: String?
}

struct SwitchAccountRequest: Codable {
    let account_id: Int64
}

struct SwitchAccountResponse: Codable {
    let success: Bool
    let account: User?
    let error: String?
}

// MARK: - Session Models
struct Session: Codable, Identifiable {
    let id: Int64
    let browser: String
    let device: String
    let ip_address: String
    let created_at: String
    let expires_at: String
    let last_activity: String
    let is_current: Bool
    let session_key: String
}

struct SessionsResponse: Codable {
    let sessions: [Session]
}

struct DeleteSessionResponse: Codable {
    let success: Bool
    let message: String
}
