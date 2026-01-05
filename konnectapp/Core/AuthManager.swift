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
        if let _ = try? KeychainManager.getToken() {
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
        isLoading = true
        defer { isLoading = false }
        
        do {
            let response = try await AuthService.shared.checkAuth()
            self.isAuthenticated = response.isAuthenticated
            self.currentUser = response.user
        } catch {
            self.isAuthenticated = false
            self.currentUser = nil
        }
    }
}
