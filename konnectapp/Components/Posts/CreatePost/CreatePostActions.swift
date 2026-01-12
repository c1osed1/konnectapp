import SwiftUI

struct CreatePostActions: View {
    @Binding var isNsfw: Bool
    let hasMedia: Bool
    let hasMusic: Bool
    let hasPoll: Bool
    let canPublish: Bool
    let onAddGallery: () -> Void
    let onAddMusic: () -> Void
    let onAddPoll: () -> Void
    let onPublish: () -> Void
    let isPublishing: Bool
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        let borderColor = Color.themeBorder.opacity(0.6)
        HStack(spacing: 8) {
            Button(action: onAddGallery) {
                Image(systemName: "photo")
                    .font(.system(size: 18))
                    .foregroundColor(Color.themeTextPrimary)
                    .frame(width: 40, height: 40)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.themeBlockBackground.opacity(0.5))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(borderColor, lineWidth: 0.5)
                            )
                    )
            }
            
            Button(action: onAddMusic) {
                Image(systemName: "music.note")
                    .font(.system(size: 18))
                    .foregroundColor(Color.themeTextPrimary)
                    .frame(width: 40, height: 40)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.themeBlockBackground.opacity(0.5))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(borderColor, lineWidth: 0.5)
                            )
                    )
            }
            
            Button(action: onAddPoll) {
                Image(systemName: "chart.bar")
                    .font(.system(size: 18))
                    .foregroundColor(hasPoll ? Color.appAccent : Color.themeTextPrimary)
                    .frame(width: 40, height: 40)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(hasPoll ? Color.appAccent.opacity(0.2) : Color.themeBlockBackground.opacity(0.5))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(hasPoll ? Color.appAccent : borderColor, lineWidth: 0.5)
                            )
                    )
            }
            
            if hasMedia {
                Button(action: {
                    isNsfw.toggle()
                }) {
                    Image(systemName: isNsfw ? "eye.slash.fill" : "eye.slash")
                        .font(.system(size: 18))
                        .foregroundColor(isNsfw ? Color.appAccent : Color.themeTextPrimary)
                        .frame(width: 40, height: 40)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.themeBlockBackground.opacity(0.5))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(borderColor, lineWidth: 0.5)
                                )
                        )
                }
            }
            
            Spacer()
            
            Button(action: onPublish) {
                Group {
                    if isPublishing {
                        ProgressView()
                            .tint(Color.themeTextPrimary)
                            .frame(width: 16, height: 16)
                    } else {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 16))
                            .foregroundColor(Color.themeTextPrimary)
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

