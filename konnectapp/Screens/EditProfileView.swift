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
        Group {
            if #available(iOS 26.0, *) {
                liquidGlassEditProfile
            } else {
                fallbackEditProfile
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
    private var mediaSection: some View {
        let appAccent = Color.appAccent
        
        VStack(alignment: .leading, spacing: 16) {
            Text("Медиа")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
            
            // Превью аватара и баннера
            HStack(spacing: 16) {
                // Аватар превью
                VStack(spacing: 12) {
                    if let avatarImage = avatarImage {
                        Image(uiImage: avatarImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.2), lineWidth: 2)
                            )
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
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.2), lineWidth: 2)
                        )
                    } else {
                        Circle()
                            .fill(Color.themeBlockBackgroundSecondary)
                            .frame(width: 100, height: 100)
                            .overlay(
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.white.opacity(0.3))
                            )
                    }
                }
                
                // Баннер превью
                VStack(spacing: 12) {
                    if let bannerImage = bannerImage {
                        Image(uiImage: bannerImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 100)
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
                                    .overlay(
                                        Image(systemName: "photo.fill")
                                            .font(.system(size: 30))
                                            .foregroundColor(.white.opacity(0.3))
                                    )
                            }
                        }
                        .frame(height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.themeBlockBackgroundSecondary)
                            .frame(height: 100)
                            .overlay(
                                Image(systemName: "photo.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(.white.opacity(0.3))
                            )
                    }
                }
            }
            
            // Кнопки внизу
            VStack(spacing: 12) {
                if #available(iOS 26.0, *) {
                    PhotosPicker(
                        selection: $selectedAvatarItem,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        Label("Изменить аватар", systemImage: "photo")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.glass)
                    .buttonBorderShape(.roundedRectangle(radius: 12))
                    
                    PhotosPicker(
                        selection: $selectedBannerItem,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        Label("Изменить баннер", systemImage: "photo.on.rectangle")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.glass)
                    .buttonBorderShape(.roundedRectangle(radius: 12))
                } else {
                    PhotosPicker(
                        selection: $selectedAvatarItem,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        Label("Изменить аватар", systemImage: "photo")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(appAccent)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    PhotosPicker(
                        selection: $selectedBannerItem,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        Label("Изменить баннер", systemImage: "photo.on.rectangle")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(appAccent)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(20)
        .glassEffect(GlassEffectStyle.regular, in: RoundedRectangle(cornerRadius: 20))
    }
    
    @ViewBuilder
    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Имя")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white)
            
            TextField("Введите имя", text: $name)
                .font(.system(size: 16))
                .foregroundColor(.white)
                .focused($focusedField, equals: .name)
                .padding(14)
                .glassEffect(GlassEffectStyle.regular, in: RoundedRectangle(cornerRadius: 12))
        }
        .padding(20)
        .glassEffect(GlassEffectStyle.regular, in: RoundedRectangle(cornerRadius: 20))
    }
    
    @ViewBuilder
    private var usernameSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Юзернейм")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white)
            
            TextField("Введите юзернейм", text: $username)
                .font(.system(size: 16))
                .foregroundColor(.white)
                .focused($focusedField, equals: .username)
                .padding(14)
                .glassEffect(GlassEffectStyle.regular, in: RoundedRectangle(cornerRadius: 12))
        }
        .padding(20)
        .glassEffect(GlassEffectStyle.regular, in: RoundedRectangle(cornerRadius: 20))
    }
    
    @ViewBuilder
    private var profileStyleSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Стиль профиля")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
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
        .padding(20)
        .glassEffect(GlassEffectStyle.regular, in: RoundedRectangle(cornerRadius: 20))
    }
    
    @ViewBuilder
    private var saveButton: some View {
        if #available(iOS 26.0, *) {
            Button(action: {
                Task {
                    await saveChanges()
                }
            }) {
                HStack(spacing: 10) {
                    if isUploading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18))
                    }
                    Text(isUploading ? "Сохранение..." : "Сохранить изменения")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }
            .buttonStyle(.glass)
            .buttonBorderShape(.roundedRectangle(radius: 14))
            .disabled(isUploading || !hasChanges)
            .opacity(hasChanges && !isUploading ? 1.0 : 0.5)
        } else {
            Button(action: {
                Task {
                    await saveChanges()
                }
            }) {
                HStack(spacing: 10) {
                    if isUploading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18))
                    }
                    Text(isUploading ? "Сохранение..." : "Сохранить изменения")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(hasChanges && !isUploading ? Color.appAccent : Color(red: 0.5, green: 0.5, blue: 0.5))
                )
            }
            .disabled(isUploading || !hasChanges)
        }
    }
    
    @available(iOS 26.0, *)
    @ViewBuilder
    private var liquidGlassEditProfile: some View {
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
                VStack(spacing: 20) {
                    if let errorMessage = errorMessage {
                        errorBanner(message: errorMessage)
                    }
                    
                    if let successMessage = successMessage {
                        successBanner(message: successMessage)
                    }
                    
                    mediaSection
                    nameSection
                    usernameSection
                    profileStyleSection
                    
                    saveButton
                }
                .padding(16)
            }
        }
    }
    
    @ViewBuilder
    private var fallbackEditProfile: some View {
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
                        errorBanner(message: errorMessage)
                    }
                    
                    if let successMessage = successMessage {
                        successBanner(message: successMessage)
                    }
                    
                    mediaSection
                    nameSection
                    usernameSection
                    profileStyleSection
                    
                    saveButton
                }
                .padding(16)
            }
        }
    }
    
    @ViewBuilder
    private func errorBanner(message: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
                .font(.system(size: 16))
            
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(.red)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .glassEffect(GlassEffectStyle.regular, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.red.opacity(0.3), lineWidth: 1)
        )
    }
    
    @ViewBuilder
    private func successBanner(message: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.system(size: 16))
            
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(.green)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .glassEffect(GlassEffectStyle.regular, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.green.opacity(0.3), lineWidth: 1)
        )
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
        if #available(iOS 26.0, *) {
            Button(action: action) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(title)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                        }
                    }
                    
                    Text(description)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.7))
                }
                .frame(width: 160)
                .padding(16)
            }
            .buttonStyle(.glass)
            .buttonBorderShape(.roundedRectangle(radius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        isSelected ? Color.appAccent : Color.clear,
                        lineWidth: isSelected ? 2 : 0
                    )
            )
        } else {
            Button(action: action) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(title)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                        }
                    }
                    
                    Text(description)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.7))
                }
                .frame(width: 160)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(isSelected ? Color.appAccent.opacity(0.3) : Color(red: 0.13, green: 0.13, blue: 0.13).opacity(0.6))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(
                            isSelected ? Color.appAccent : Color.appAccent.opacity(0.15),
                            lineWidth: isSelected ? 2 : 1
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

