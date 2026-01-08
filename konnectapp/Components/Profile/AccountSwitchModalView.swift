import SwiftUI

struct AccountSwitchModalView: View {
    @Binding var isPresented: Bool
    @StateObject private var authManager = AuthManager.shared
    @ObservedObject private var accountManager = AccountSwitchManager.shared
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.themeBlockBackground.ignoresSafeArea()
                
                if accountManager.isLoading {
                    ProgressView()
                        .tint(Color.appAccent)
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            if let main = accountManager.mainAccount, main.id != accountManager.currentAccount?.id {
                                AccountRow(
                                    account: main,
                                    isCurrent: false,
                                    isMain: true,
                                    onSelect: { selectAccount(main) }
                                )
                            }
                            
                            if let current = accountManager.currentAccount {
                                AccountRow(
                                    account: current,
                                    isCurrent: true,
                                    isMain: current.account_type != "channel",
                                    onSelect: nil
                                )
                            }
                            
                            ForEach(accountManager.accounts, id: \.id) { account in
                                if account.id != accountManager.currentAccount?.id {
                                    AccountRow(
                                        account: account,
                                        isCurrent: false,
                                        isMain: false,
                                        onSelect: { selectAccount(account) }
                                    )
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Выбор аккаунта")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") {
                        isPresented = false
                    }
                }
            }
        }
        .task {
            accountManager.ensureLoaded()
        }
    }
    
    private func selectAccount(_ account: User) {
        guard account.id != accountManager.currentAccount?.id else { return }
        
        Task {
            let success = await accountManager.switchAccount(accountId: account.id)
            if success {
                isPresented = false
            }
        }
    }
}

// MARK: - CompactAccountRow (для основного отображения с кнопкой разворачивания)

struct CompactAccountRow: View {
    let account: User
    let isMain: Bool
    let isExpanded: Bool
    let onToggleExpand: () -> Void
    
    var body: some View {
        Button(action: onToggleExpand) {
            HStack(spacing: 10) {
                AsyncImage(url: URL(string: account.avatar_url ?? "")) { phase in
                    switch phase {
                    case .empty, .failure:
                        Circle()
                            .fill(Color.appAccent.opacity(0.3))
                            .frame(width: 36, height: 36)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color.appAccent.opacity(0.7))
                            )
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 36, height: 36)
                            .clipShape(Circle())
                    @unknown default:
                        EmptyView()
                    }
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(account.name)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color.themeTextPrimary)
                            .lineLimit(1)
                        if isMain {
                            Text("(Основной)")
                                .font(.system(size: 11))
                                .foregroundColor(Color.themeTextSecondary)
                        }
                    }
                    Text("@\(account.username)")
                        .font(.system(size: 12))
                        .foregroundColor(Color.themeTextSecondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.themeTextSecondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.appAccent.opacity(0.1))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - AccountRow (для остальных аккаунтов в развернутом списке)

struct AccountRow: View {
    let account: User
    let isCurrent: Bool
    let isMain: Bool
    let onSelect: (() -> Void)?
    
    var body: some View {
        Button(action: {
            onSelect?()
        }) {
            HStack(spacing: 10) {
                AsyncImage(url: URL(string: account.avatar_url ?? "")) { phase in
                    switch phase {
                    case .empty, .failure:
                        Circle()
                            .fill(Color.appAccent.opacity(0.3))
                            .frame(width: 36, height: 36)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color.appAccent.opacity(0.7))
                            )
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 36, height: 36)
                            .clipShape(Circle())
                    @unknown default:
                        EmptyView()
                    }
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(account.name)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color.themeTextPrimary)
                            .lineLimit(1)
                        if isMain {
                            Text("(Основной)")
                                .font(.system(size: 11))
                                .foregroundColor(Color.themeTextSecondary)
                        }
                    }
                    Text("@\(account.username)")
                        .font(.system(size: 12))
                        .foregroundColor(Color.themeTextSecondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                if isCurrent {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(Color.appAccent)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isCurrent ? Color.appAccent.opacity(0.1) : Color.themeBlockBackground)
            )
        }
        .disabled(onSelect == nil || isCurrent)
        .buttonStyle(PlainButtonStyle())
    }
}
