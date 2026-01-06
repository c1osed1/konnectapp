import SwiftUI

struct ReportModalView: View {
    let post: Post
    @Binding var toastMessage: String?
    @Environment(\.dismiss) private var dismiss
    @State private var selectedReason: String = ""
    @State private var description: String = ""
    @State private var isSubmitting = false
    
    let reasons = [
        ("spam", "Спам"),
        ("insult", "Оскорбление"),
        ("inappropriate_content", "Неподходящий контент"),
        ("violation", "Нарушение правил"),
        ("misinformation", "Дезинформация"),
        ("harmful_content", "Вредоносный контент"),
        ("other", "Другое")
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.06, green: 0.06, blue: 0.06),
                        Color(red: 0.1, green: 0.1, blue: 0.1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Пожаловаться на пост")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.top, 20)
                        
                        Text("Выберите причину жалобы")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                        
                        ForEach(reasons, id: \.0) { reason in
                            Button(action: {
                                selectedReason = reason.0
                            }) {
                                HStack {
                                    Text(reason.1)
                                        .font(.system(size: 15))
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    if selectedReason == reason.0 {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(Color.appAccent)
                                    }
                                }
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(selectedReason == reason.0 ? Color.appAccent.opacity(0.2) : Color(red: 0.15, green: 0.15, blue: 0.15))
                                )
                            }
                        }
                        
                        if !selectedReason.isEmpty {
                            Text("Дополнительное описание (необязательно)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.top, 8)
                            
                            TextField("Опишите проблему", text: $description, axis: .vertical)
                                .font(.system(size: 15))
                                .foregroundColor(.white)
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color(red: 0.15, green: 0.15, blue: 0.15))
                                )
                                .lineLimit(3...8)
                        }
                        
                        Button(action: {
                            Task {
                                await submitReport()
                            }
                        }) {
                            if isSubmitting {
                                ProgressView()
                                    .tint(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                            } else {
                                Text("Отправить жалобу")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                            }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedReason.isEmpty ? Color.gray : Color.red)
                        )
                        .padding(.top, 20)
                        .padding(.bottom, 20)
                        .disabled(isSubmitting || selectedReason.isEmpty)
                    }
                    .padding(.horizontal, 16)
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
    
    private func submitReport() async {
        isSubmitting = true
        defer {
            Task { @MainActor in
                isSubmitting = false
            }
        }
        
        do {
            let _ = try await PostActionService.shared.reportPost(
                postId: post.id,
                reason: selectedReason,
                description: description.isEmpty ? nil : description
            )
            await MainActor.run {
                toastMessage = "Жалоба отправлена"
                dismiss()
            }
        } catch {
            await MainActor.run {
                toastMessage = "Ошибка: \(error.localizedDescription)"
            }
        }
    }
}

