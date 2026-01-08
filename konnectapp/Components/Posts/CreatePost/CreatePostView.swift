import SwiftUI
import PhotosUI
import AVKit
import UniformTypeIdentifiers

enum PostMediaItem {
    case image(UIImage)
    case video(Data, thumbnail: UIImage?)
    
    var thumbnail: UIImage? {
        switch self {
        case .image(let image):
            return image
        case .video(_, let thumbnail):
            return thumbnail
        }
    }
}

struct CreatePostView: View {
    @StateObject private var themeManager = ThemeManager.shared
    @State private var text: String = ""
    @State private var mediaItems: [PostMediaItem] = []
    @State private var selectedVideoData: Data? = nil
    @State private var selectedTrack: MusicTrack? = nil
    @State private var isNsfw: Bool = false
    @State private var isPublishing: Bool = false
    @State private var showImagePicker: Bool = false
    @State private var showMusicModal: Bool = false
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var errorMessage: String?
    
    let onPostCreated: (Post?) -> Void
    var postType: String? = nil
    var recipientId: Int64? = nil
    
    var body: some View {
        // Используем fallback версию для всех, чтобы иметь контроль над затемнением
        fallbackCreatePost
    }
    
    @available(iOS 26.0, *)
    @ViewBuilder
    private var liquidGlassCreatePost: some View {
        VStack(alignment: .leading, spacing: 0) {
            CreatePostTextField(text: $text)
                .padding(12)
                .onTapGesture {
                    // Prevent tap from propagating
                }
            
            CreatePostMediaPreview(mediaItems: mediaItems) { index in
                mediaItems.remove(at: index)
                if mediaItems.isEmpty {
                    selectedVideoData = nil
                }
            }
            
            if let track = selectedTrack {
                HStack(spacing: 12) {
                    AsyncImage(url: URL(string: track.cover_path ?? "")) { phase in
                        switch phase {
                        case .empty:
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.themeBlockBackground)
                                .frame(width: 50, height: 50)
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 50, height: 50)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        case .failure:
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.themeBlockBackground)
                                .frame(width: 50, height: 50)
                        @unknown default:
                            EmptyView()
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(track.title)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color.themeTextPrimary)
                        if let artist = track.artist {
                            Text(artist)
                                .font(.system(size: 12))
                                .foregroundColor(Color.themeTextSecondary)
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        selectedTrack = nil
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Color.themeTextSecondary.opacity(0.6))
                            .font(.system(size: 20))
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(.system(size: 13))
                    .foregroundColor(.red)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)
            }
            
            CreatePostActions(
                isNsfw: $isNsfw,
                hasMedia: !mediaItems.isEmpty,
                hasMusic: selectedTrack != nil,
                canPublish: !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !mediaItems.isEmpty || selectedTrack != nil,
                onAddGallery: {
                    showImagePicker = true
                },
                onAddMusic: {
                    showMusicModal = true
                },
                onPublish: {
                    Task {
                        await publishPost()
                    }
                },
                isPublishing: isPublishing
            )
        }
        .glassEffect(.regularInteractive, in: RoundedRectangle(cornerRadius: 20))
        .photosPicker(
            isPresented: $showImagePicker,
            selection: $selectedItems,
            maxSelectionCount: 10,
            matching: .any(of: [.images, .videos])
        )
        .sheet(isPresented: $showMusicModal) {
            MusicSelectionModal(isPresented: $showMusicModal, selectedTrack: $selectedTrack)
        }
        .onChange(of: selectedItems) { oldValue, newValue in
            Task { @MainActor in
                await loadImages(from: newValue)
            }
        }
    }
    
    @ViewBuilder
    private var fallbackCreatePost: some View {
        VStack(alignment: .leading, spacing: 0) {
            CreatePostTextField(text: $text)
                .padding(12)
            
            CreatePostMediaPreview(mediaItems: mediaItems) { index in
                mediaItems.remove(at: index)
                if mediaItems.isEmpty {
                    selectedVideoData = nil
                }
            }
            
            if let track = selectedTrack {
                HStack(spacing: 12) {
                    AsyncImage(url: URL(string: track.cover_path ?? "")) { phase in
                        switch phase {
                        case .empty:
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(red: 0.13, green: 0.13, blue: 0.13))
                                .frame(width: 50, height: 50)
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 50, height: 50)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        case .failure:
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(red: 0.13, green: 0.13, blue: 0.13))
                                .frame(width: 50, height: 50)
                        @unknown default:
                            EmptyView()
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(track.title)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color.themeTextPrimary)
                        if let artist = track.artist {
                            Text(artist)
                                .font(.system(size: 12))
                                .foregroundColor(Color.themeTextSecondary)
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        selectedTrack = nil
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Color.themeTextSecondary.opacity(0.6))
                            .font(.system(size: 20))
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(.system(size: 13))
                    .foregroundColor(.red)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)
            }
            
            CreatePostActions(
                isNsfw: $isNsfw,
                hasMedia: !mediaItems.isEmpty,
                hasMusic: selectedTrack != nil,
                canPublish: !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !mediaItems.isEmpty || selectedTrack != nil,
                onAddGallery: {
                    showImagePicker = true
                },
                onAddMusic: {
                    showMusicModal = true
                },
                onPublish: {
                    Task {
                        await publishPost()
                    }
                },
                isPublishing: isPublishing
            )
        }
        .background(
            ZStack {
                // Более темный фоновый слой
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.themeBlockBackground.opacity(0.95))
                
                // Блюр эффект с затемнением
                RoundedRectangle(cornerRadius: 20)
                    .fill(.thinMaterial.opacity(0.3))
            }
        )
        .photosPicker(
            isPresented: $showImagePicker,
            selection: $selectedItems,
            maxSelectionCount: 10,
            matching: .any(of: [.images, .videos])
        )
        .sheet(isPresented: $showMusicModal) {
            MusicSelectionModal(isPresented: $showMusicModal, selectedTrack: $selectedTrack)
        }
        .onChange(of: selectedItems) { oldValue, newValue in
            Task { @MainActor in
                await loadImages(from: newValue)
            }
        }
    }
    
    private func loadImages(from items: [PhotosPickerItem]) async {
        var loadedMedia: [PostMediaItem] = []
        
        for item in items {
            // Проверяем тип контента - является ли это видео
            let isVideo = item.supportedContentTypes.contains { contentType in
                contentType.conforms(to: UTType.movie) || 
                contentType.conforms(to: UTType.quickTimeMovie) || 
                contentType.conforms(to: UTType.mpeg4Movie) ||
                contentType.identifier.hasPrefix("public.movie") ||
                contentType.identifier.hasPrefix("public.video")
            }
            
            if isVideo {
                // Загружаем видео
                if let videoData = try? await item.loadTransferable(type: Data.self) {
                    // Генерируем thumbnail для видео
                    let thumbnail = await generateVideoThumbnail(from: videoData)
                    loadedMedia.append(.video(videoData, thumbnail: thumbnail))
                    await MainActor.run {
                        if selectedVideoData == nil {
                            selectedVideoData = videoData // Сохраняем первое видео для отправки
                        }
                    }
                }
            } else {
                // Загружаем изображение
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    loadedMedia.append(.image(image))
                }
            }
        }
        
        await MainActor.run {
            mediaItems.append(contentsOf: loadedMedia)
            selectedItems = []
        }
    }
    
    private func generateVideoThumbnail(from videoData: Data) async -> UIImage? {
        return await withCheckedContinuation { continuation in
            // Создаем временный файл для видео
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mp4")
            
            do {
                try videoData.write(to: tempURL)
                
                let asset = AVURLAsset(url: tempURL)
                let imageGenerator = AVAssetImageGenerator(asset: asset)
                imageGenerator.appliesPreferredTrackTransform = true
                
                let time = CMTime(seconds: 0.0, preferredTimescale: 1)
                
                Task {
                    do {
                        let cgImage = try await imageGenerator.image(at: time).image
                        let uiImage = UIImage(cgImage: cgImage)
                        
                        // Удаляем временный файл
                        try? FileManager.default.removeItem(at: tempURL)
                        
                        continuation.resume(returning: uiImage)
                    } catch {
                        try? FileManager.default.removeItem(at: tempURL)
                        continuation.resume(returning: nil)
                    }
                }
            } catch {
                continuation.resume(returning: nil)
            }
        }
    }
    
    private func publishPost() async {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !mediaItems.isEmpty || selectedTrack != nil else {
            await MainActor.run {
                errorMessage = "Добавьте текст, изображение или музыку"
            }
            return
        }
        
        isPublishing = true
        errorMessage = nil
        
        defer {
            Task { @MainActor in
                isPublishing = false
            }
        }
        
        do {
            // Разделяем изображения и видео
            var images: [UIImage] = []
            var videoData: Data? = selectedVideoData
            
            for item in mediaItems {
                switch item {
                case .image(let image):
                    images.append(image)
                case .video(let data, _):
                    if videoData == nil {
                        videoData = data
                    }
                }
            }
            
            let createdPost = try await PostService.shared.createPost(
                content: text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : text,
                images: images,
                video: videoData,
                isNsfw: isNsfw,
                music: selectedTrack,
                postType: postType,
                recipientId: recipientId
            )
            
            await MainActor.run {
                text = ""
                mediaItems = []
                selectedVideoData = nil
                selectedTrack = nil
                isNsfw = false
                errorMessage = nil
                onPostCreated(createdPost)
            }
        } catch {
            await MainActor.run {
                if case PostError.rateLimit = error {
                    errorMessage = "Превышен лимит создания постов. Попробуйте позже."
                } else {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

