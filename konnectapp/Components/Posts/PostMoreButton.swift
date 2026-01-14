import SwiftUI

struct PostMoreButton: View {
    let post: Post
    @Binding var toastMessage: String?
    @State private var showRepostModal = false
    @State private var showFactsModal = false
    @State private var showReportModal = false
    @State private var showDeleteConfirmation = false
    @State private var showEditModal = false
    @State private var editDraft: String = ""
    
    var body: some View {
        Menu {
            PostMoreMenuContent(
                post: post,
                toastMessage: $toastMessage,
                showRepostModal: $showRepostModal,
                showFactsModal: $showFactsModal,
                showReportModal: $showReportModal,
                showDeleteConfirmation: $showDeleteConfirmation,
                showEditModal: $showEditModal,
                editDraft: $editDraft
            )
        } label: {
            Group {
                if #available(iOS 26.0, *) {
                    Button {} label: {
                        HStack(spacing: 4) {
                            Image(systemName: "list.bullet")
                                .font(.system(size: 16))
                                .foregroundColor(Color.themeTextPrimary)
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 11)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.ultraThinMaterial)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                Color.appAccent.opacity(0.15),
                                lineWidth: 0.5
                            )
                    )
                    .allowsHitTesting(false)
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "list.bullet")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 11)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.ultraThinMaterial.opacity(0.1))
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.themeBlockBackground.opacity(0.9))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(
                                        Color.appAccent.opacity(0.15),
                                        lineWidth: 0.5
                                    )
                            )
                    )
                }
            }
        }
        .menuStyle(.borderlessButton)
        .sheet(isPresented: $showRepostModal) {
            RepostModalView(post: post, toastMessage: $toastMessage)
        }
        .sheet(isPresented: $showFactsModal) {
            FactsModalView(post: post, toastMessage: $toastMessage)
        }
        .sheet(isPresented: $showReportModal) {
            ReportModalView(post: post, toastMessage: $toastMessage)
        }
        .sheet(isPresented: $showEditModal) {
            NavigationStack {
                EditPostModalView(
                    postId: post.id,
                    initialContent: editDraft,
                    toastMessage: $toastMessage
                )
            }
        }
        .alert("Удалить пост?", isPresented: $showDeleteConfirmation) {
            Button("Отмена", role: .cancel) {}
            Button("Удалить", role: .destructive) {
                Task {
                    await performDelete()
                }
            }
        } message: {
            Text("Вы уверены, что хотите удалить этот пост? Это действие нельзя отменить.")
        }
    }
    
    private func performDelete() async {
        do {
            let _ = try await PostActionService.shared.deletePost(postId: post.id)
            await MainActor.run {
                toastMessage = "Пост удален"
                NotificationCenter.default.post(name: NSNotification.Name("PostDeleted"), object: nil, userInfo: ["postId": post.id])
            }
        } catch {
            await MainActor.run {
                toastMessage = "Ошибка: \(error.localizedDescription)"
            }
        }
    }
}

struct PostMoreMenuContent: View {
    let post: Post
    @Binding var toastMessage: String?
    @Binding var showRepostModal: Bool
    @Binding var showFactsModal: Bool
    @Binding var showReportModal: Bool
    @Binding var showDeleteConfirmation: Bool
    @Binding var showEditModal: Bool
    @Binding var editDraft: String
    @StateObject private var authManager = AuthManager.shared
    @State private var isUserBlocked = false
    @State private var isLoadingBlockStatus = false
    
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
            
            // Change vote button for polls
            if let poll = post.poll, (poll.user_voted ?? false) && !(poll.is_expired ?? false) {
                changeVoteButton
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
            editDraft = post.content ?? ""
            // Откладываем показ модалки, чтобы Menu успел закрыться
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                showEditModal = true
            }
        }) {
            Label("Редактировать", systemImage: "pencil")
        }
    }
    
    private var deleteButton: some View {
        Button(role: .destructive, action: {
            // Откладываем показ диалога, чтобы Menu успел закрыться
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                showDeleteConfirmation = true
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
    
    private var changeVoteButton: some View {
        Button(action: {
            Task {
                await performChangeVote()
            }
        }) {
            Label("Изменить голос", systemImage: "arrow.uturn.backward")
        }
    }
    
    private func checkBlockStatus() async {
        guard post.user?.id != nil else { return }
        isLoadingBlockStatus = true
        defer { isLoadingBlockStatus = false }
        
        // TODO: Implement block status check API call
        // For now, set to false
        await MainActor.run {
            isUserBlocked = false
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
    
    private func performChangeVote() async {
        guard let poll = post.poll else { return }
        
        do {
            let updatedPoll = try await PollService.shared.removeVote(pollId: poll.id)
            await MainActor.run {
                toastMessage = "Голос отменен"
                NotificationCenter.default.post(
                    name: NSNotification.Name("PollVoteChanged"),
                    object: nil,
                    userInfo: ["postId": post.id, "poll": updatedPoll]
                )
            }
        } catch {
            await MainActor.run {
                toastMessage = "Ошибка: \(error.localizedDescription)"
            }
        }
    }
}


