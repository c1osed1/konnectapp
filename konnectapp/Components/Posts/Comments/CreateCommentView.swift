import SwiftUI
import PhotosUI

struct CreateCommentView: View {
    let postId: Int64
    @Binding var navigationPath: NavigationPath
    @Binding var replyingToComment: Comment?
    @Binding var replyingToReply: Reply?
    @Binding var replyingToReplyCommentId: Int64?
    @StateObject private var themeManager = ThemeManager.shared
    @State private var commentText: String = ""
    @State private var selectedImage: UIImage?
    @State private var selectedImageItem: PhotosPickerItem?
    @State private var isPosting: Bool = false
    @State private var errorMessage: String?
    var onCommentCreated: (() -> Void)?
    
    @FocusState private var isTextFieldFocused: Bool
    
    private var placeholder: String {
        if let replyingTo = replyingToReply, let username = replyingTo.user?.username {
            return "Ответить @\(username)..."
        }
        if let replyingTo = replyingToComment, let username = replyingTo.user?.username {
            return "Ответить @\(username)..."
        }
        return "Написать комментарий..."
    }
    
    var body: some View {
        VStack(spacing: 12) {
            if let replyingTo = replyingToComment {
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "arrowshape.turn.up.left")
                            .font(.system(size: 14))
                            .foregroundColor(Color.appAccent)
                        if let username = replyingTo.user?.username {
                            Text("Ответ @\(username)")
                                .font(.system(size: 13))
                                .foregroundColor(Color.appAccent)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.appAccent.opacity(0.2))
                    )
                    
                    Spacer()
                    
                    Button {
                        replyingToComment = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(Color.themeTextSecondary)
                    }
                }
                .padding(.bottom, 8)
            }
            
            HStack(alignment: .bottom, spacing: 8) {
                Group {
                    if #available(iOS 26.0, *) {
                        GlassEffectContainer(spacing: 0) {
                            TextField(placeholder, text: $commentText, axis: .vertical)
                                .font(.system(size: 15))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(.ultraThinMaterial.opacity(0.1))
                                        .background(
                                            RoundedRectangle(cornerRadius: 20)
                                                .fill(Color.themeBlockBackground.opacity(0.6))
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 20)
                                                .stroke(
                                                    Color.appAccent.opacity(0.15),
                                                    lineWidth: 0.5
                                                )
                                        )
                                )
                                .glassEffect(GlassEffectStyle.regular, in: RoundedRectangle(cornerRadius: 20))
                                .focused($isTextFieldFocused)
                                .lineLimit(1...5)
                        }
                    } else {
                        TextField(placeholder, text: $commentText, axis: .vertical)
                            .font(.system(size: 15))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(.ultraThinMaterial.opacity(0.1))
                                    .background(
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(Color(red: 0.1, green: 0.1, blue: 0.1).opacity(0.6))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(
                                                Color.appAccent.opacity(0.15),
                                                lineWidth: 0.5
                                            )
                                    )
                            )
                            .focused($isTextFieldFocused)
                            .lineLimit(1...5)
                    }
                }
                
                if selectedImage != nil {
                    Button {
                        selectedImage = nil
                        selectedImageItem = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                    }
                }
                
                Group {
                    if #available(iOS 26.0, *) {
                        GlassEffectContainer(spacing: 0) {
                            PhotosPicker(
                                selection: $selectedImageItem,
                                matching: .images,
                                photoLibrary: .shared()
                            ) {
                                Image(systemName: "photo")
                                    .font(.system(size: 16))
                                    .foregroundColor(Color.appAccent)
                                    .frame(width: 32, height: 32)
                                    .background(
                                        Circle()
                                            .fill(.ultraThinMaterial.opacity(0.1))
                                            .background(
                                                Circle()
                                                    .fill(Color.themeBlockBackground.opacity(0.6))
                                            )
                                            .overlay(
                                                Circle()
                                                    .stroke(
                                                        Color.appAccent.opacity(0.15),
                                                        lineWidth: 0.5
                                                    )
                                            )
                                    )
                                    .glassEffect(GlassEffectStyle.regular, in: Circle())
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    } else {
                        PhotosPicker(
                            selection: $selectedImageItem,
                            matching: .images,
                            photoLibrary: .shared()
                        ) {
                            Image(systemName: "photo")
                                .font(.system(size: 16))
                                .foregroundColor(Color.appAccent)
                                .frame(width: 32, height: 32)
                                .background(
                                    Circle()
                                        .fill(.ultraThinMaterial.opacity(0.1))
                                        .background(
                                            Circle()
                                                .fill(Color.themeBlockBackground.opacity(0.6))
                                        )
                                        .overlay(
                                            Circle()
                                                .stroke(
                                                    Color.appAccent.opacity(0.15),
                                                    lineWidth: 0.5
                                                )
                                        )
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                Group {
                    if #available(iOS 26.0, *) {
                        GlassEffectContainer(spacing: 0) {
                            Button {
                                Task {
                                    await postComment()
                                }
                            } label: {
                                if isPosting {
                                    ProgressView()
                                        .tint(.white)
                                        .frame(width: 32, height: 32)
                                } else {
                                    Image(systemName: "paperplane.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(
                                            (commentText.isEmpty && selectedImage == nil) ?
                                            Color(red: 0.4, green: 0.4, blue: 0.4) :
                                            Color.appAccent
                                        )
                                        .frame(width: 32, height: 32)
                                        .background(
                                            Circle()
                                                .fill(.ultraThinMaterial.opacity(0.1))
                                                .background(
                                                    Circle()
                                                        .fill(Color.themeBlockBackground.opacity(0.6))
                                                )
                                                .overlay(
                                                    Circle()
                                                        .stroke(
                                                            Color.appAccent.opacity(0.15),
                                                            lineWidth: 0.5
                                                        )
                                                )
                                        )
                                        .glassEffect(GlassEffectStyle.regular, in: Circle())
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            .disabled(isPosting || (commentText.isEmpty && selectedImage == nil))
                        }
                    } else {
                        Button {
                            Task {
                                await postComment()
                            }
                        } label: {
                            if isPosting {
                                ProgressView()
                                    .tint(.white)
                                    .frame(width: 32, height: 32)
                            } else {
                                Image(systemName: "paperplane.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(
                                        (commentText.isEmpty && selectedImage == nil) ?
                                        Color(red: 0.4, green: 0.4, blue: 0.4) :
                                        Color.appAccent
                                    )
                                    .frame(width: 32, height: 32)
                                    .background(
                                        Circle()
                                            .fill(.ultraThinMaterial.opacity(0.1))
                                            .background(
                                                Circle()
                                                    .fill(Color.themeBlockBackground.opacity(0.6))
                                            )
                                            .overlay(
                                                Circle()
                                                    .stroke(
                                                        Color.appAccent.opacity(0.15),
                                                        lineWidth: 0.5
                                                    )
                                            )
                                    )
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(isPosting || (commentText.isEmpty && selectedImage == nil))
                    }
                }
            }
            
            if let selectedImage = selectedImage {
                HStack {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    Spacer()
                }
            }
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(.system(size: 13))
                    .foregroundColor(.red)
                    .padding(.horizontal, 12)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .onChange(of: selectedImageItem) { oldValue, newValue in
            Task {
                if let data = try? await newValue?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await MainActor.run {
                        selectedImage = image
                    }
                }
            }
        }
    }
    
    private func postComment() async {
        guard !isPosting else { return }
        guard !commentText.isEmpty || selectedImage != nil else { return }
        
        isPosting = true
        errorMessage = nil
        
        defer {
            Task { @MainActor in
                isPosting = false
            }
        }
        
        do {
            // Если это ответ на ответ (reply), используем createReply с parentReplyId
            if let replyingTo = replyingToReply, let commentId = replyingToReplyCommentId {
                let response = try await CommentService.shared.createReply(
                    commentId: commentId,
                    content: commentText.isEmpty ? nil : commentText,
                    image: selectedImage,
                    parentReplyId: replyingTo.id
                )
                
                if response.success == true || response.reply != nil {
                    await MainActor.run {
                        commentText = ""
                        selectedImage = nil
                        selectedImageItem = nil
                        isTextFieldFocused = false
                        replyingToReply = nil
                        replyingToReplyCommentId = nil
                        onCommentCreated?()
                    }
                } else {
                    await MainActor.run {
                        errorMessage = response.error ?? "Ошибка создания ответа"
                    }
                }
            }
            // Если это ответ на комментарий, используем createReply
            else if let replyingTo = replyingToComment {
                let response = try await CommentService.shared.createReply(
                    commentId: replyingTo.id,
                    content: commentText.isEmpty ? nil : commentText,
                    image: selectedImage,
                    parentReplyId: nil
                )
                
                if response.success == true || response.reply != nil {
                    await MainActor.run {
                        commentText = ""
                        selectedImage = nil
                        selectedImageItem = nil
                        isTextFieldFocused = false
                        replyingToComment = nil
                        onCommentCreated?()
                    }
                } else {
                    await MainActor.run {
                        errorMessage = response.error ?? "Ошибка создания ответа"
                    }
                }
            } else {
                // Обычный комментарий
                let response = try await CommentService.shared.createComment(
                    postId: postId,
                    content: commentText.isEmpty ? nil : commentText,
                    image: selectedImage,
                    parentCommentId: nil
                )
                
                if response.success == true || response.comment != nil {
                    await MainActor.run {
                        commentText = ""
                        selectedImage = nil
                        selectedImageItem = nil
                        isTextFieldFocused = false
                        onCommentCreated?()
                    }
                } else {
                    await MainActor.run {
                        errorMessage = response.error ?? "Ошибка создания комментария"
                    }
                }
            }
        } catch {
            await MainActor.run {
                if case CommentError.rateLimit = error {
                    errorMessage = "Слишком много запросов. Подождите немного."
                } else {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

