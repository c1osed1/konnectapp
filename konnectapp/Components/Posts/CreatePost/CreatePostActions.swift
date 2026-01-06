import SwiftUI

struct CreatePostActions: View {
    @Binding var isNsfw: Bool
    let hasMedia: Bool
    let hasMusic: Bool
    let canPublish: Bool
    let onAddGallery: () -> Void
    let onAddMusic: () -> Void
    let onPublish: () -> Void
    let isPublishing: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            Button(action: onAddGallery) {
                HStack(spacing: 6) {
                    Image(systemName: "photo")
                        .font(.system(size: 16))
                    Text("Галерея")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(red: 0.13, green: 0.13, blue: 0.13).opacity(0.5))
                )
            }
            
            Button(action: onAddMusic) {
                HStack(spacing: 6) {
                    Image(systemName: "music.note")
                        .font(.system(size: 16))
                    Text("Музыка")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(red: 0.13, green: 0.13, blue: 0.13).opacity(0.5))
                )
            }
            
            if hasMedia {
                Button(action: {
                    isNsfw.toggle()
                }) {
                    Image(systemName: isNsfw ? "eye.slash.fill" : "eye.slash")
                        .font(.system(size: 18))
                        .foregroundColor(isNsfw ? Color.appAccent : .white)
                        .frame(width: 40, height: 40)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(red: 0.13, green: 0.13, blue: 0.13).opacity(0.5))
                        )
                }
            }
            
            Spacer()
            
            Button(action: onPublish) {
                Group {
                    if isPublishing {
                        ProgressView()
                            .tint(.white)
                            .frame(width: 16, height: 16)
                    } else {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.appAccent,
                                    Color(red: 0.7, green: 0.6, blue: 0.95)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
            }
            .disabled(isPublishing || !canPublish)
            .opacity(isPublishing || !canPublish ? 0.5 : 1.0)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
    }
}

