import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: ProfileViewModel
    @StateObject private var themeManager = ThemeManager.shared
    
    @State private var name: String
    @State private var username: String
    @State private var selectedProfileStyle: Int
    @State private var selectedAvatarItem: PhotosPickerItem?
    @State private var selectedBannerItem: PhotosPickerItem?
    @State private var avatarImage: UIImage?
    @State private var bannerImage: UIImage?
    @State private var isUploading: Bool = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @FocusState private var focusedField: Field?
    
    enum Field {
        case name, username
    }
    
    private var hasChanges: Bool {
        avatarImage != nil ||
        bannerImage != nil ||
        name != (viewModel.profile?.user.name ?? "") ||
        username != (viewModel.profile?.user.username ?? "") ||
        selectedProfileStyle != (viewModel.profile?.user.profile_id ?? 1)
    }
    
    init(viewModel: ProfileViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
        if let profile = viewModel.profile {
            _name = State(initialValue: profile.user.name)
            _username = State(initialValue: profile.user.username)
            _selectedProfileStyle = State(initialValue: profile.user.profile_id ?? 1)
        } else {
            _name = State(initialValue: "")
            _username = State(initialValue: "")
            _selectedProfileStyle = State(initialValue: 1)
        }
    }
    
    var body: some View {
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
                VStack(spacing: 16) {
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
                    
                    avatarSection
                    bannerSection
                    nameSection
                    usernameSection
                    profileStyleSection
                    
                    saveButton
                }
                .padding(16)
            }
        }
        .navigationTitle("Редактировать профиль")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: selectedAvatarItem) { oldValue, newValue in
            Task {
                if let data = try? await newValue?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await MainActor.run {
                        avatarImage = image
                    }
                }
            }
        }
        .onChange(of: selectedBannerItem) { oldValue, newValue in
            Task {
                if let data = try? await newValue?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await MainActor.run {
                        bannerImage = image
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var avatarSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Аватар")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                if let avatarImage = avatarImage {
                    Image(uiImage: avatarImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                } else if let avatarURL = viewModel.profile?.user.avatar_url,
                          let url = URL(string: avatarURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        default:
                            Circle()
                                .fill(Color.themeBlockBackgroundSecondary)
                        }
                    }
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color.themeBlockBackgroundSecondary)
                        .frame(width: 100, height: 100)
                }
                
                PhotosPicker(selection: $selectedAvatarItem, matching: .images) {
                    Text("Изменить")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(red: 0.82, green: 0.74, blue: 1.0))
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(16)
        .background(glassBackground)
    }
    
    @ViewBuilder
    private var bannerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Баннер")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            
            if let bannerImage = bannerImage {
                Image(uiImage: bannerImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else if let bannerURL = viewModel.profile?.user.banner_url,
                      let url = URL(string: bannerURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    default:
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.themeBlockBackgroundSecondary)
                    }
                }
                .frame(height: 150)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.themeBlockBackgroundSecondary)
                    .frame(height: 150)
            }
            
            PhotosPicker(selection: $selectedBannerItem, matching: .images) {
                Text("Изменить баннер")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.appAccent)
                    )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(16)
        .background(glassBackground)
    }
    
    @ViewBuilder
    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Имя")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
            
            TextField("Введите имя", text: $name)
                .font(.system(size: 15))
                .foregroundColor(.white)
                .focused($focusedField, equals: .name)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.themeBlockBackground)
                )
        }
        .padding(16)
        .background(glassBackground)
    }
    
    @ViewBuilder
    private var usernameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Юзернейм")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
            
            TextField("Введите юзернейм", text: $username)
                .font(.system(size: 15))
                .foregroundColor(.white)
                .focused($focusedField, equals: .username)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.themeBlockBackground)
                )
        }
        .padding(16)
        .background(glassBackground)
    }
    
    @ViewBuilder
    private var profileStyleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Стиль профиля")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ProfileStyleButton(
                        title: "Обычный",
                        description: "Стандартный стиль",
                        isSelected: selectedProfileStyle == 1,
                        action: { selectedProfileStyle = 1 }
                    )
                    
                    ProfileStyleButton(
                        title: "No-Баннер",
                        description: "Баннер-фон",
                        isSelected: selectedProfileStyle == 2,
                        action: { selectedProfileStyle = 2 }
                    )
                    
                    ProfileStyleButton(
                        title: "Альт",
                        description: "Реверс",
                        isSelected: selectedProfileStyle == 3,
                        action: { selectedProfileStyle = 3 }
                    )
                    
                }
                .padding(.horizontal, 4)
            }
        }
        .padding(16)
        .background(glassBackground)
    }
    
    @ViewBuilder
    private var saveButton: some View {
        Button(action: {
            Task {
                await saveChanges()
            }
        }) {
            HStack(spacing: 8) {
                if isUploading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                }
                Text(isUploading ? "Сохранение..." : "Сохранить")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(hasChanges && !isUploading ? Color.appAccent : Color(red: 0.5, green: 0.5, blue: 0.5))
        )
        .disabled(isUploading || !hasChanges)
    }
    
    @ViewBuilder
    private var glassBackground: some View {
        Group {
            if #available(iOS 26.0, *) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial.opacity(0.1))
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(red: 0.1, green: 0.1, blue: 0.1).opacity(0.5))
                        )
                }
                .glassEffect(GlassEffectStyle.regular, in: RoundedRectangle(cornerRadius: 16))
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial.opacity(0.1))
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(red: 0.1, green: 0.1, blue: 0.1).opacity(0.5))
                        )
                    
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            Color.appAccent.opacity(0.15),
                            lineWidth: 0.5
                        )
                }
            }
        }
    }
    
    private func saveChanges() async {
        await MainActor.run {
            isUploading = true
            errorMessage = nil
            successMessage = nil
        }
        
        do {
            if let avatarImage = avatarImage {
                print("🔄 Загрузка аватарки...")
                let _ = try await ProfileUpdateService.shared.uploadAvatar(avatarImage)
                print("✅ Аватарка загружена")
            }
            
            if let bannerImage = bannerImage {
                print("🔄 Загрузка баннера...")
                let _ = try await ProfileUpdateService.shared.uploadBanner(bannerImage)
                print("✅ Баннер загружен")
            }
            
            if name != viewModel.profile?.user.name {
                print("🔄 Обновление имени...")
                let _ = try await ProfileUpdateService.shared.updateName(name)
                print("✅ Имя обновлено")
            }
            
            if username != viewModel.profile?.user.username {
                print("🔄 Обновление юзернейма...")
                let _ = try await ProfileUpdateService.shared.updateUsername(username)
                print("✅ Юзернейм обновлен")
            }
            
            if selectedProfileStyle != (viewModel.profile?.user.profile_id ?? 1) {
                print("🔄 Обновление стиля профиля...")
                let _ = try await ProfileUpdateService.shared.updateProfileStyle(selectedProfileStyle)
                print("✅ Стиль профиля обновлен")
            }
            
            await MainActor.run {
                successMessage = "Профиль успешно обновлен"
                isUploading = false
            }
            
            await viewModel.loadProfile(userIdentifier: viewModel.profile?.user.username ?? "")
            
            await MainActor.run {
                dismiss()
            }
        } catch {
            print("❌ Ошибка при сохранении: \(error.localizedDescription)")
            await MainActor.run {
                errorMessage = error.localizedDescription
                isUploading = false
            }
        }
    }
}

struct ProfileStyleButton: View {
    let title: String
    let description: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(Color(red: 0.7, green: 0.7, blue: 0.7))
            }
            .frame(width: 140)
            .padding(12)
            .background(
                Group {
                    if #available(iOS 26.0, *) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.ultraThinMaterial.opacity(0.1))
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(isSelected ? Color.appAccent.opacity(0.3) : Color(red: 0.13, green: 0.13, blue: 0.13).opacity(0.6))
                                )
                        }
                        .glassEffect(GlassEffectStyle.regular, in: RoundedRectangle(cornerRadius: 12))
                    } else {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.ultraThinMaterial.opacity(0.1))
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(isSelected ? Color.appAccent.opacity(0.3) : Color(red: 0.13, green: 0.13, blue: 0.13).opacity(0.6))
                                )
                            
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    isSelected ? Color.appAccent : Color.appAccent.opacity(0.15),
                                    lineWidth: isSelected ? 1.5 : 0.5
                                )
                        }
                    }
                }
            )
        }
    }
}

