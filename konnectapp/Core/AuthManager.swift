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
    
    private init() {
        if let token = try? KeychainManager.getToken(), token.isEmpty == false {
            isAuthenticated = true
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
            let response = try await AuthService.shared.checkAuth()
            if response.isAuthenticated {
                self.isAuthenticated = true
            self.currentUser = response.user
            } else {
                try? KeychainManager.deleteTokens()
                self.isAuthenticated = false
                self.currentUser = nil
            }
        } catch {
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
}
