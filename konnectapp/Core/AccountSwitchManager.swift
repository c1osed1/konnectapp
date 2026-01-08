import Foundation
import SwiftUI
import Combine

@MainActor
class AccountSwitchManager: ObservableObject {
    static let shared = AccountSwitchManager()
    
    @Published var accounts: [User] = []
    @Published var currentAccount: User?
    @Published var mainAccount: User?
    @Published var isLoading = false
    
    private var hasLoaded = false
    
    private init() {}
    
    func ensureLoaded() {
        guard !hasLoaded && !isLoading else { return }
        hasLoaded = true
        Task {
            await loadAccounts()
        }
    }
    
    func loadAccounts() async {
        isLoading = true
        
        do {
            let response = try await AccountSwitchService.shared.getMyChannels()
            if response.success {
                currentAccount = response.current_account
                mainAccount = response.main_account
                accounts = response.channels
                print("🟢 AccountSwitchManager: Loaded \(accounts.count) channels, current: \(currentAccount?.username ?? "nil"), main: \(mainAccount?.username ?? "nil")")
            } else {
                print("⚠️ AccountSwitchManager: Failed to load channels: \(response.error ?? "unknown error")")
            }
            isLoading = false
        } catch {
            print("❌ AccountSwitchManager: Error loading channels: \(error.localizedDescription)")
            isLoading = false
        }
    }
    
    func switchAccount(accountId: Int64) async -> Bool {
        guard accountId != currentAccount?.id else {
            print("🔵 AccountSwitchManager: Already on account \(accountId)")
            return false
        }
        
        print("🟡 AccountSwitchManager: Switching to account \(accountId)")
        isLoading = true
        
        do {
            let response = try await AccountSwitchService.shared.switchAccount(accountId: accountId)
            if response.success {
                // Проверяем, что API действительно вернул запрошенный аккаунт
                // (дополнительная проверка на случай, если AccountSwitchService пропустил ошибку)
                if let returnedAccount = response.account, returnedAccount.id == accountId {
                    print("🟢 AccountSwitchManager: Switch successful to account \(returnedAccount.username) (ID: \(returnedAccount.id)), refreshing auth status...")
                    await AuthManager.shared.checkAuthStatus()
                    print("🟢 AccountSwitchManager: Auth status refreshed, reloading accounts...")
                    await loadAccounts()
                    print("🟢 AccountSwitchManager: Accounts reloaded, current: \(currentAccount?.username ?? "nil") (ID: \(currentAccount?.id ?? -1))")
                    isLoading = false
                    return true
                } else {
                    let errorMessage = "API вернул другой аккаунт (запрошен: \(accountId), получен: \(response.account?.id ?? -1))"
                    print("❌ AccountSwitchManager: \(errorMessage)")
                    print("⚠️ AccountSwitchManager: Это критическая ошибка - переключение не выполнено")
                    
                    // Показываем ошибку пользователю
                    ToastHelper.showToast(message: "Ошибка переключения аккаунта")
                    
                    isLoading = false
                    return false
                }
            } else {
                let errorMessage = response.error ?? "Неизвестная ошибка при переключении аккаунта"
                print("❌ AccountSwitchManager: Switch failed: \(errorMessage)")
                
                // Показываем ошибку пользователю
                ToastHelper.showToast(message: errorMessage)
                
                isLoading = false
                return false
            }
        } catch {
            let errorMessage = "Ошибка при переключении аккаунта: \(error.localizedDescription)"
            print("❌ AccountSwitchManager: \(errorMessage)")
            
            // Показываем ошибку пользователю
            ToastHelper.showToast(message: "Не удалось переключить аккаунт")
            
            isLoading = false
            return false
        }
    }
}
