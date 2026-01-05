import SwiftUI

struct PostMoreButton: View {
    let post: Post
    @Binding var toastMessage: String?
    
    var body: some View {
        Menu {
            PostMoreMenuContent(post: post, toastMessage: $toastMessage)
        } label: {
            if #available(iOS 26.0, *) {
                Image(systemName: "list.bullet")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
            } else {
                Image(systemName: "list.bullet")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.ultraThinMaterial.opacity(0.2))
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color(red: 0.1, green: 0.1, blue: 0.1).opacity(0.8))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(
                                        Color(red: 0.82, green: 0.74, blue: 1.0).opacity(0.15),
                                        lineWidth: 0.5
                                    )
                            )
                    )
            }
        }
        .menuStyle(.borderlessButton)
        .overlay(
            Group {
                if #available(iOS 26.0, *) {
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            Color(red: 0.82, green: 0.74, blue: 1.0).opacity(0.15),
                            lineWidth: 0.5
                        )
                        .allowsHitTesting(false)
                } else {
                    EmptyView()
                }
            }
        )
    }
}

struct PostMoreMenuContent: View {
    let post: Post
    @Binding var toastMessage: String?
    @StateObject private var authManager = AuthManager.shared
    @State private var isUserBlocked = false
    @State private var isLoadingBlockStatus = false
    @State private var showRepostModal = false
    @State private var showFactsModal = false
    @State private var showReportModal = false
    
    private var isCurrentUserPost: Bool {
        guard let currentUserId = authManager.currentUser?.id,
              let postUserId = post.user?.id else { return false }
        return postUserId == currentUserId
    }
    
    private var isUserID3: Bool {
        authManager.currentUser?.id == 3
    }
    
    private var isPinned: Bool {
        post.is_pinned ?? false
    }
    
    var body: some View {
        Group {
            copyLinkButton
            
            repostButton
            
            if isUserID3 {
                factsButton
            }
            
            if isCurrentUserPost {
                editButton
                deleteButton
                pinButton
            }
            
            if !isCurrentUserPost {
                blockButton
                reportButton
            }
        }
        .task {
            if !isCurrentUserPost {
                await checkBlockStatus()
            }
        }
        .sheet(isPresented: $showRepostModal) {
            RepostModalView(post: post, toastMessage: $toastMessage)
        }
        .sheet(isPresented: $showFactsModal) {
            FactsModalView(post: post, toastMessage: $toastMessage)
        }
        .sheet(isPresented: $showReportModal) {
            ReportModalView(post: post, toastMessage: $toastMessage)
        }
    }
    
    private var copyLinkButton: some View {
        Button(action: {
            let postURL = "https://k-connect.ru/post/\(post.id)"
            UIPasteboard.general.string = postURL
            toastMessage = "Ссылка скопирована"
        }) {
            Label("Копировать ссылку", systemImage: "link")
        }
    }
    
    private var repostButton: some View {
        Button(action: {
            showRepostModal = true
        }) {
            Label("Репост", systemImage: "arrow.2.squarepath")
        }
    }
    
    private var factsButton: some View {
        Button(action: {
            showFactsModal = true
        }) {
            Label("Факты", systemImage: "checkmark.seal")
        }
    }
    
    private var editButton: some View {
        Button(action: {
            // TODO: Implement edit post
        }) {
            Label("Редактировать", systemImage: "pencil")
        }
    }
    
    private var deleteButton: some View {
        Button(role: .destructive, action: {
            Task {
                await performDelete()
            }
        }) {
            Label("Удалить", systemImage: "trash")
        }
    }
    
    private var pinButton: some View {
        Button(action: {
            Task {
                await performPinToggle()
            }
        }) {
            Label(isPinned ? "Открепить" : "Закрепить", systemImage: isPinned ? "pin.slash" : "pin")
        }
    }
    
    private var blockButton: some View {
        Button(role: isUserBlocked ? .none : .destructive, action: {
            Task {
                await performBlockToggle()
            }
        }) {
            Label(isUserBlocked ? "Разблокировать" : "Заблокировать", systemImage: isUserBlocked ? "person.badge.plus" : "person.fill.xmark")
        }
    }
    
    private var reportButton: some View {
        Button(role: .destructive, action: {
            showReportModal = true
        }) {
            Label("Пожаловаться", systemImage: "flag")
        }
    }
    
    private func checkBlockStatus() async {
        guard let userId = post.user?.id else { return }
        isLoadingBlockStatus = true
        defer { isLoadingBlockStatus = false }
        
        // TODO: Implement block status check API call
        // For now, set to false
        await MainActor.run {
            isUserBlocked = false
        }
    }
    
    
    private func performDelete() async {
        do {
            let _ = try await PostActionService.shared.deletePost(postId: post.id)
            await MainActor.run {
                toastMessage = "Пост удален"
            }
        } catch {
            await MainActor.run {
                toastMessage = "Ошибка: \(error.localizedDescription)"
            }
        }
    }
    
    private func performPinToggle() async {
        do {
            if isPinned {
                let _ = try await PostActionService.shared.unpinPost()
                await MainActor.run {
                    toastMessage = "Пост откреплен"
                }
            } else {
                let _ = try await PostActionService.shared.pinPost(postId: post.id)
                await MainActor.run {
                    toastMessage = "Пост закреплен"
                }
            }
        } catch {
            await MainActor.run {
                toastMessage = "Ошибка: \(error.localizedDescription)"
            }
        }
    }
    
    private func performBlockToggle() async {
        // TODO: Show confirmation dialog first
        // TODO: Implement block/unblock API call
        await MainActor.run {
            isUserBlocked.toggle()
        }
    }
}

