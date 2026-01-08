import SwiftUI

struct CreatePostMediaPreview: View {
    let mediaItems: [PostMediaItem]
    let onRemove: (Int) -> Void
    
    var body: some View {
        if !mediaItems.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(mediaItems.enumerated()), id: \.offset) { index, item in
                        ZStack(alignment: .topTrailing) {
                            if let thumbnail = item.thumbnail {
                                Image(uiImage: thumbnail)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 100, height: 100)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            
                            // Иконка видео
                            if case .video = item {
                                ZStack {
                                    Circle()
                                        .fill(Color.black.opacity(0.6))
                                        .frame(width: 32, height: 32)
                                    Image(systemName: "play.fill")
                                        .foregroundColor(.white)
                                        .font(.system(size: 12))
                                }
                                .padding(8)
                            }
                            
                            // Кнопка удаления
                            Button(action: {
                                onRemove(index)
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                                    .background(Circle().fill(Color.black.opacity(0.5)))
                                    .padding(4)
                            }
                        }
                    }
                }
                .padding(.horizontal, 8)
            }
            .padding(.vertical, 8)
        }
    }
}

