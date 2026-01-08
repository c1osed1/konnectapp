import SwiftUI

struct AccountSwitchContextMenu: View {
    let accounts: [User]
    let currentAccount: User?
    let mainAccount: User?
    let onAccountSelected: ((Int64) -> Void)?
    
    @StateObject private var authManager = AuthManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            if let current = currentAccount {
                AccountContextRow(
                    account: current,
                    isCurrent: true,
                    isMain: current.account_type != "channel"
                )
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                
                if mainAccount != nil || !accounts.isEmpty {
                    Divider()
                        .padding(.horizontal, 12)
                }
            }
            
            if let main = mainAccount, main.id != currentAccount?.id {
                AccountContextRow(
                    account: main,
                    isCurrent: false,
                    isMain: true,
                    onSelect: { onAccountSelected?(main.id) }
                )
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                
                if !accounts.isEmpty {
                    Divider()
                        .padding(.horizontal, 12)
                }
            }
            
            ForEach(accounts, id: \.id) { account in
                if account.id != currentAccount?.id {
                    AccountContextRow(
                        account: account,
                        isCurrent: false,
                        isMain: false,
                        onSelect: { onAccountSelected?(account.id) }
                    )
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    
                    if account.id != accounts.last?.id {
                        Divider()
                            .padding(.horizontal, 12)
                    }
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.themeBlockBackground)
                .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
        )
        .frame(width: 280)
    }
}

struct AccountContextRow: View {
    let account: User
    let isCurrent: Bool
    let isMain: Bool
    var onSelect: (() -> Void)? = nil
    
    var body: some View {
        Button(action: {
            onSelect?()
        }) {
            HStack(spacing: 12) {
                AsyncImage(url: URL(string: account.avatar_url ?? "")) { phase in
                    switch phase {
                    case .empty, .failure:
                        Circle()
                            .fill(Color.appAccent.opacity(0.3))
                            .frame(width: 40, height: 40)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(Color.appAccent.opacity(0.7))
                            )
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                    @unknown default:
                        EmptyView()
                    }
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(account.name)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(Color.themeTextPrimary)
                        if isMain {
                            Text("(Основной)")
                                .font(.system(size: 11))
                                .foregroundColor(Color.themeTextSecondary)
                        }
                    }
                    Text("@\(account.username)")
                        .font(.system(size: 13))
                        .foregroundColor(Color.themeTextSecondary)
                }
                
                Spacer()
                
                if isCurrent {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color.appAccent)
                }
            }
        }
        .disabled(onSelect == nil || isCurrent)
        .buttonStyle(PlainButtonStyle())
    }
}
