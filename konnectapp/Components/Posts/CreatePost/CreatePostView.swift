import SwiftUI
import PhotosUI

struct CreatePostView: View {
    @StateObject private var themeManager = ThemeManager.shared
    @State private var text: String = ""
    @State private var images: [UIImage] = []
    @State private var selectedTrack: MusicTrack? = nil
    @State private var isNsfw: Bool = false
    @State private var isPublishing: Bool = false
    @State private var showImagePicker: Bool = false
    @State private var showMusicModal: Bool = false
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var errorMessage: String?
    
    let onPostCreated: () -> Void
    
    var body: some View {
        Group {
            if #available(iOS 26.0, *) {
                liquidGlassCreatePost
            } else {
                fallbackCreatePost
            }
        }
    }
    
    @available(iOS 26.0, *)
    @ViewBuilder
    private var liquidGlassCreatePost: some View {
        GlassEffectContainer(spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                CreatePostTextField(text: $text)
                    .padding(12)
                    .onTapGesture {
                        // Prevent tap from propagating
                    }
                
                CreatePostMediaPreview(images: images) { index in
                    images.remove(at: index)
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
                                .foregroundColor(.white)
                            if let artist = track.artist {
                                Text(artist)
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.6))
                            }
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            selectedTrack = nil
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.white.opacity(0.6))
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
                    hasMedia: !images.isEmpty,
                    hasMusic: selectedTrack != nil,
                    canPublish: !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !images.isEmpty || selectedTrack != nil,
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
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial.opacity(0.1))
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(red: 0.1, green: 0.1, blue: 0.1).opacity(0.5))
                        )
                }
            )
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
        }
        .contentShape(Rectangle())
        .onTapGesture {
            // Prevent dismissing keyboard when tapping inside
        }
        .photosPicker(
            isPresented: $showImagePicker,
            selection: $selectedItems,
            maxSelectionCount: 10,
            matching: .images
        )
        .sheet(isPresented: $showMusicModal) {
            MusicSelectionModal(isPresented: $showMusicModal, selectedTrack: $selectedTrack)
        }
        .onChange(of: selectedItems) { oldValue, newValue in
            Task {
                await loadImages(from: newValue)
            }
        }
        .simultaneousGesture(
            TapGesture()
                .onEnded { _ in
                    // This will be handled by parent
                }
        )
    }
    
    @ViewBuilder
    private var fallbackCreatePost: some View {
        VStack(alignment: .leading, spacing: 0) {
            CreatePostTextField(text: $text)
                .padding(12)
                .onTapGesture {
                    // Prevent tap from propagating
                }
            
            CreatePostMediaPreview(images: images) { index in
                images.remove(at: index)
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
                            .foregroundColor(.white)
                        if let artist = track.artist {
                            Text(artist)
                                .font(.system(size: 12))
                                .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.6))
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        selectedTrack = nil
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(0.6))
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
                hasMedia: !images.isEmpty,
                hasMusic: selectedTrack != nil,
                canPublish: !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !images.isEmpty || selectedTrack != nil,
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
        .contentShape(Rectangle())
        .onTapGesture {
            // Prevent dismissing keyboard when tapping inside
        }
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial.opacity(0.1))
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(red: 0.1, green: 0.1, blue: 0.1).opacity(0.5))
                    )
                
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        Color.appAccent.opacity(0.3),
                        lineWidth: 1
                    )
            }
        )
        .photosPicker(
            isPresented: $showImagePicker,
            selection: $selectedItems,
            maxSelectionCount: 10,
            matching: .images
        )
        .sheet(isPresented: $showMusicModal) {
            MusicSelectionModal(isPresented: $showMusicModal, selectedTrack: $selectedTrack)
        }
        .onChange(of: selectedItems) { oldValue, newValue in
            Task {
                await loadImages(from: newValue)
            }
        }
    }
    
    private func loadImages(from items: [PhotosPickerItem]) async {
        var loadedImages: [UIImage] = []
        
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                loadedImages.append(image)
            }
        }
        
        await MainActor.run {
            images.append(contentsOf: loadedImages)
            selectedItems = []
        }
    }
    
    private func publishPost() async {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !images.isEmpty || selectedTrack != nil else {
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
            let _ = try await PostService.shared.createPost(
                content: text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : text,
                images: images,
                isNsfw: isNsfw,
                music: selectedTrack
            )
            
            await MainActor.run {
                text = ""
                images = []
                selectedTrack = nil
                isNsfw = false
                errorMessage = nil
                onPostCreated()
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

