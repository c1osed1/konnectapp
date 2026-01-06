import SwiftUI

struct RepostModalView: View {
    let post: Post
    @Binding var toastMessage: String?
    @Environment(\.dismiss) private var dismiss
    @State private var repostText: String = ""
    @State private var isReposting = false
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [
                        Color.themeBackgroundStart,
                        Color.themeBackgroundEnd
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    Text("Репост")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.top, 20)
                    
                    TextField("Добавьте комментарий к репосту (необязательно)", text: $repostText, axis: .vertical)
                        .font(.system(size: 15))
                        .foregroundColor(.white)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.themeBlockBackground)
                        )
                        .lineLimit(5...10)
                        .padding(.horizontal, 16)
                    
                    Spacer()
                    
                    Button(action: {
                        Task {
                            await performRepost()
                        }
                    }) {
                        if isReposting {
                            ProgressView()
                                .tint(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                        } else {
                            Text("Репостнуть")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.appAccent)
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                    .disabled(isReposting)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
    
    private func performRepost() async {
        isReposting = true
        defer {
            Task { @MainActor in
                isReposting = false
            }
        }
        
        do {
            let _ = try await PostActionService.shared.repostPost(
                postId: post.id,
                text: repostText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : repostText
            )
            await MainActor.run {
                toastMessage = "Пост репостнут"
                dismiss()
            }
        } catch {
            await MainActor.run {
                toastMessage = "Ошибка: \(error.localizedDescription)"
            }
        }
    }
}

