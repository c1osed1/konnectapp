import Foundation
import Security

class KeychainManager {
    private static let tokenKey = "com.kconnect.jwt.token"
    private static let sessionKeyKey = "com.kconnect.session.key"
    private static let service = "com.kconnect.auth"
    
    static func save(token: String, sessionKey: String) throws {
        try saveToKeychain(key: tokenKey, value: token)
        try saveToKeychain(key: sessionKeyKey, value: sessionKey)
    }
    
    static func getToken() throws -> String? {
        return try getFromKeychain(key: tokenKey)
    }
    
    static func getSessionKey() throws -> String? {
        return try getFromKeychain(key: sessionKeyKey)
    }
    
    static func deleteTokens() throws {
        try deleteFromKeychain(key: tokenKey)
        try deleteFromKeychain(key: sessionKeyKey)
    }
    
    private static func saveToKeychain(key: String, value: String) throws {
        let data = value.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw AuthError.keychainError
        }
    }
    
    private static func getFromKeychain(key: String) throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return value
    }
    
    private static func deleteFromKeychain(key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw AuthError.keychainError
        }
    }
}
