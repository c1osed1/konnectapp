import SwiftUI

struct CreatePostMediaPreview: View {
    let images: [UIImage]
    let onRemove: (Int) -> Void
    
    var body: some View {
        if !images.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(images.enumerated()), id: \.offset) { index, image in
                        ZStack(alignment: .topTrailing) {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 100, height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            
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

