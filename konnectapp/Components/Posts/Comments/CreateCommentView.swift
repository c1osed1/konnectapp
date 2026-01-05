import SwiftUI
import PhotosUI

struct CreateCommentView: View {
    let postId: Int64
    @Binding var navigationPath: NavigationPath
    @State private var commentText: String = ""
    @State private var selectedImage: UIImage?
    @State private var selectedImageItem: PhotosPickerItem?
    @State private var isPosting: Bool = false
    @State private var errorMessage: String?
    var onCommentCreated: (() -> Void)?
    
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(alignment: .bottom, spacing: 8) {
                TextField("Написать комментарий...", text: $commentText, axis: .vertical)
                    .font(.system(size: 15))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(red: 0.15, green: 0.15, blue: 0.15))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(
                                        Color(red: 0.82, green: 0.74, blue: 1.0).opacity(0.2),
                                        lineWidth: 0.5
                                    )
                            )
                    )
                    .focused($isTextFieldFocused)
                    .lineLimit(1...5)
                
                if selectedImage != nil {
                    Button {
                        selectedImage = nil
                        selectedImageItem = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                    }
                }
                
                PhotosPicker(
                    selection: $selectedImageItem,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    Image(systemName: "photo")
                        .font(.system(size: 18))
                        .foregroundColor(Color(red: 0.82, green: 0.74, blue: 1.0))
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(Color(red: 0.15, green: 0.15, blue: 0.15))
                        )
                }
                .buttonStyle(PlainButtonStyle())
                
                Button {
                    Task {
                        await postComment()
                    }
                } label: {
                    if isPosting {
                        ProgressView()
                            .tint(.white)
                            .frame(width: 36, height: 36)
                    } else {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(
                                (commentText.isEmpty && selectedImage == nil) ?
                                Color(red: 0.4, green: 0.4, blue: 0.4) :
                                Color(red: 0.82, green: 0.74, blue: 1.0)
                            )
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(isPosting || (commentText.isEmpty && selectedImage == nil))
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
        .background(
            Group {
                if #available(iOS 26.0, *) {
                    RoundedRectangle(cornerRadius: 0)
                        .fill(.ultraThinMaterial.opacity(0.2))
                        .background(
                            RoundedRectangle(cornerRadius: 0)
                                .fill(Color(red: 0.1, green: 0.1, blue: 0.1).opacity(0.9))
                        )
                        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 0))
                } else {
                    RoundedRectangle(cornerRadius: 0)
                        .fill(.ultraThinMaterial.opacity(0.2))
                        .background(
                            RoundedRectangle(cornerRadius: 0)
                                .fill(Color(red: 0.1, green: 0.1, blue: 0.1).opacity(0.9))
                        )
                }
            }
        )
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
            let response = try await CommentService.shared.createComment(
                postId: postId,
                content: commentText.isEmpty ? nil : commentText,
                image: selectedImage
            )
            
            if response.success == true {
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

