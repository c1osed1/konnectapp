import Foundation
import SwiftUI
import Combine

@MainActor
class AuthManager: ObservableObject {
    static let shared = AuthManager()
    
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    /// Получает акцентный цвет из профиля текущего пользователя
    var accentColor: Color {
        return Color.accentColor(from: currentUser)
    }
    
    private init() {
        // Безопасная проверка токена с обработкой ошибок
        do {
            if let token = try KeychainManager.getToken(), token.isEmpty == false {
                isAuthenticated = true
            }
        } catch {
            print("⚠️ Keychain access error (may be normal for unsigned builds): \(error.localizedDescription)")
            isAuthenticated = false
        }
        
        Task {
            await checkAuthStatus()
        }
    }
    
    func login(username: String, password: String) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        let response = try await AuthService.shared.login(username: username, password: password)
        
        guard response.success == true, response.token != nil, response.session_key != nil else {
            let errorMsg = response.error ?? response.message ?? "Ошибка входа"
            errorMessage = errorMsg
            throw AuthError.invalidCredentials
        }
        
        await checkAuthStatus()
    }
    
    func logout() async throws {
        try await AuthService.shared.logout()
        self.isAuthenticated = false
        self.currentUser = nil
    }
    
    func checkAuthStatus() async {
        guard let token = try? KeychainManager.getToken(), !token.isEmpty else {
            self.isAuthenticated = false
            self.currentUser = nil
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            print("🟡 AuthManager: Starting checkAuthStatus...")
            let response = try await AuthService.shared.checkAuth()
            print("🟡 AuthManager: checkAuth completed, isAuthenticated: \(response.isAuthenticated)")
            
            if response.isAuthenticated {
                self.isAuthenticated = true
                self.currentUser = response.user
                if let user = response.user {
                    print("🟢 AuthManager: User loaded successfully")
                    print("   - Username: \(user.username)")
                    print("   - profile_background_url: \(user.profile_background_url ?? "nil")")
                    print("   - avatar_url: \(user.avatar_url ?? "nil")")
                    
                    // Загружаем полный профиль для получения profile_background_url
                    // так как /api/auth/check не возвращает это поле
                    Task {
                        await loadFullProfile(username: user.username)
                    }
                    
                    // Загружаем список каналов сразу после авторизации
                    AccountSwitchManager.shared.ensureLoaded()
                } else {
                    print("⚠️ AuthManager: response.user is nil")
                }
            } else {
                print("🔵 AuthManager: Not authenticated, clearing tokens")
                try? KeychainManager.deleteTokens()
                self.isAuthenticated = false
                self.currentUser = nil
            }
        } catch {
            print("❌ AuthManager: Error in checkAuthStatus: \(error)")
            if case AuthError.unauthorized = error {
                try? KeychainManager.deleteTokens()
            }
            if case AuthError.banned = error {
                try? KeychainManager.deleteTokens()
            }
            self.isAuthenticated = false
            self.currentUser = nil
        }
    }
    
    func refreshUser() async {
        await checkAuthStatus()
    }
    
    private func loadFullProfile(username: String) async {
        do {
            print("🟡 AuthManager: Loading full profile for \(username) to get profile_background_url...")
            let profileResponse = try await ProfileService.shared.getProfile(userIdentifier: username)
            let profileUser = profileResponse.user
            
            // Обновляем currentUser с полными данными из профиля
            if let currentUser = self.currentUser, currentUser.id == profileUser.id {
                let updatedUser = User(
                    id: profileUser.id,
                    name: profileUser.name,
                    username: profileUser.username,
                    photo: profileUser.photo,
                    banner: profileUser.cover_photo,
                    about: profileUser.about,
                    avatar_url: profileUser.avatar_url,
                    banner_url: profileUser.banner_url,
                    profile_background_url: profileUser.profile_background_url,
                    profile_color: profileUser.profile_color,
                    hasCredentials: currentUser.hasCredentials,
                    account_type: profileUser.account_type,
                    main_account_id: profileUser.main_account_id
                )
                await MainActor.run {
                    self.currentUser = updatedUser
                    print("🟢 AuthManager: Updated currentUser with profile_background_url: \(profileUser.profile_background_url ?? "nil")")
                }
            }
        } catch {
            print("⚠️ AuthManager: Failed to load full profile: \(error.localizedDescription)")
        }
    }
}
