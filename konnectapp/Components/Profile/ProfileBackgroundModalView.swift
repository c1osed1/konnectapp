import SwiftUI
import PhotosUI

struct ProfileBackgroundModalView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var authManager = AuthManager.shared
    @State private var selectedImage: UIImage?
    @State private var selectedImageItem: PhotosPickerItem?
    @State private var isUploading: Bool = false
    @State private var isDeleting: Bool = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    
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
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Текущий фон
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Текущий фон")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                            
                            if let currentBackground = authManager.currentUser?.profile_background_url, !currentBackground.isEmpty {
                                AsyncImage(url: URL(string: currentBackground)) { phase in
                                    switch phase {
                                    case .empty:
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color.themeBlockBackgroundSecondary)
                                            .frame(height: 200)
                                            .overlay(
                                                ProgressView()
                                                    .tint(.white)
                                            )
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(height: 200)
                                            .clipShape(RoundedRectangle(cornerRadius: 16))
                                    case .failure:
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color.themeBlockBackgroundSecondary)
                                            .frame(height: 200)
                                            .overlay(
                                                VStack(spacing: 8) {
                                                    Image(systemName: "exclamationmark.triangle")
                                                        .foregroundColor(.white.opacity(0.5))
                                                    Text("Не удалось загрузить")
                                                        .font(.system(size: 12))
                                                        .foregroundColor(.white.opacity(0.5))
                                                }
                                            )
                                    @unknown default:
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color.themeBlockBackgroundSecondary)
                                            .frame(height: 200)
                                    }
                                }
                            } else {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(red: 0.2, green: 0.2, blue: 0.2))
                                    .frame(height: 200)
                                    .overlay(
                                        VStack(spacing: 8) {
                                            Image(systemName: "photo")
                                                .font(.system(size: 32))
                                                .foregroundColor(.white.opacity(0.3))
                                            Text("Фон не установлен")
                                                .font(.system(size: 14))
                                                .foregroundColor(.white.opacity(0.5))
                                        }
                                    )
                            }
                        }
                        
                        // Выбор нового изображения
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Новый фон")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                            
                            if let selectedImage = selectedImage {
                                Image(uiImage: selectedImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(height: 200)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                
                                Button {
                                    self.selectedImage = nil
                                    selectedImageItem = nil
                                } label: {
                                    HStack {
                                        Image(systemName: "xmark.circle.fill")
                                        Text("Удалить выбранное")
                                    }
                                    .font(.system(size: 15))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.themeBlockBackgroundSecondary)
                                    )
                                }
                            } else {
                                PhotosPicker(
                                    selection: $selectedImageItem,
                                    matching: .images,
                                    photoLibrary: .shared()
                                ) {
                                    VStack(spacing: 12) {
                                        Image(systemName: "photo.badge.plus")
                                            .font(.system(size: 40))
                                            .foregroundColor(Color.appAccent)
                                        Text("Выбрать изображение")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.white)
                                        Text("PNG, JPG, JPEG, GIF до 10MB")
                                            .font(.system(size: 13))
                                            .foregroundColor(Color.themeTextSecondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 200)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color.themeBlockBackground)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(
                                                Color.appAccent.opacity(0.3),
                                                lineWidth: 2
                                            )
                                    )
                                    )
                                }
                            }
                        }
                        
                        // Кнопки действий
                        VStack(spacing: 12) {
                            if selectedImage != nil {
                                Button {
                                    Task {
                                        await uploadBackground()
                                    }
                                } label: {
                                    if isUploading {
                                        HStack {
                                            ProgressView()
                                                .tint(.white)
                                            Text("Загрузка...")
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundColor(.white)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 56)
                                        .background(
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(Color.appAccent.opacity(0.5))
                                        )
                                    } else {
                                        Text("Загрузить фон")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 56)
                                            .background(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .fill(Color.appAccent)
                                            )
                                    }
                                }
                                .disabled(isUploading || isDeleting)
                            }
                            
                            if authManager.currentUser?.profile_background_url != nil {
                                Button {
                                    Task {
                                        await deleteBackground()
                                    }
                                } label: {
                                    if isDeleting {
                                        HStack {
                                            ProgressView()
                                                .tint(.white)
                                            Text("Удаление...")
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundColor(.white)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 56)
                                        .background(
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(Color.red.opacity(0.5))
                                        )
                                    } else {
                                        Text("Удалить фон")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 56)
                                            .background(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .fill(Color.red)
                                            )
                                    }
                                }
                                .disabled(isUploading || isDeleting)
                            }
                        }
                        
                        // Сообщения
                        if let errorMessage = errorMessage {
                            Text(errorMessage)
                                .font(.system(size: 14))
                                .foregroundColor(.red)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.red.opacity(0.1))
                                )
                        }
                        
                        if let successMessage = successMessage {
                            Text(successMessage)
                                .font(.system(size: 14))
                                .foregroundColor(.green)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.green.opacity(0.1))
                                )
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Фон профиля")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                    }
                }
            }
        }
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
    
    private func uploadBackground() async {
        guard let image = selectedImage else { return }
        
        await MainActor.run {
            isUploading = true
            errorMessage = nil
            successMessage = nil
        }
        
        do {
            _ = try await ProfileUpdateService.shared.uploadBackground(image)
            
            await MainActor.run {
                successMessage = "Фон успешно загружен"
                isUploading = false
                selectedImage = nil
                selectedImageItem = nil
            }
            
            // Обновляем профиль
            await authManager.refreshUser()
            
            // Закрываем модалку через 1.5 секунды
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            await MainActor.run {
                dismiss()
            }
        } catch {
            await MainActor.run {
                if let profileError = error as? ProfileUpdateError {
                    errorMessage = profileError.localizedDescription
                } else {
                    errorMessage = error.localizedDescription
                }
                isUploading = false
            }
        }
    }
    
    private func deleteBackground() async {
        await MainActor.run {
            isDeleting = true
            errorMessage = nil
            successMessage = nil
        }
        
        do {
            _ = try await ProfileUpdateService.shared.deleteBackground()
            
            await MainActor.run {
                successMessage = "Фон успешно удален"
                isDeleting = false
            }
            
            // Обновляем профиль
            await authManager.refreshUser()
            
            // Закрываем модалку через 1.5 секунды
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            await MainActor.run {
                dismiss()
            }
        } catch {
            await MainActor.run {
                if let profileError = error as? ProfileUpdateError {
                    errorMessage = profileError.localizedDescription
                } else {
                    errorMessage = error.localizedDescription
                }
                isDeleting = false
            }
        }
    }
}

