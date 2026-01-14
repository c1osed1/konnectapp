import SwiftUI

struct EditPostModalView: View {
    let postId: Int64
    let initialContent: String
    @Binding var toastMessage: String?
    
    @Environment(\.dismiss) private var dismiss
    @State private var content: String
    @State private var isSaving: Bool = false
    
    init(postId: Int64, initialContent: String, toastMessage: Binding<String?>) {
        self.postId = postId
        self.initialContent = initialContent
        self._toastMessage = toastMessage
        self._content = State(initialValue: initialContent)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            TextEditor(text: $content)
                .scrollContentBackground(.hidden)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.themeBlockBackground.opacity(0.6))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.appAccent.opacity(0.15), lineWidth: 0.5)
                )
                .disabled(isSaving)
        }
        .padding(16)
        .navigationTitle("Редактировать")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Отмена") { dismiss() }
                    .disabled(isSaving)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    Task { await save() }
                } label: {
                    if isSaving {
                        ProgressView()
                    } else {
                        Text("Сохранить")
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
                .disabled(isSaving || content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }
    
    private func save() async {
        guard !isSaving else { return }
        isSaving = true
        defer { isSaving = false }
        
        do {
            let updated = try await PostActionService.shared.editPost(
                postId: postId,
                content: content,
                deleteImages: false,
                deleteVideo: false,
                deleteMusic: false
            )
            
            await MainActor.run {
                toastMessage = "Пост обновлен"
                NotificationCenter.default.post(
                    name: NSNotification.Name("PostUpdated"),
                    object: nil,
                    userInfo: ["post": updated]
                )
                dismiss()
            }
        } catch {
            await MainActor.run {
                toastMessage = "Ошибка: \(error.localizedDescription)"
            }
        }
    }
}

