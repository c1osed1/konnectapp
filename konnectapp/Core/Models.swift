//
//  Models.swift
//  konnectapp
//
//  Created by qsoul on 05.01.2026.
//

import Foundation

// MARK: - User Model
struct User: Codable {
    let id: Int64
    let name: String
    let username: String
    let photo: String?
    let banner: String?
    let about: String?
    let avatar_url: String?
    let banner_url: String?
    let hasCredentials: Bool?
    let account_type: String?
    let main_account_id: Int64?
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
    
    enum CodingKeys: String, CodingKey {
        case id, content, user, created_at, updated_at, timestamp
        case likes_count, comments_count, reposts_count, views_count
        case is_liked, is_reposted, is_repost, media, images, image
        case type, original_post, fact, edited
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

