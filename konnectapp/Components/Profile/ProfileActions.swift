import SwiftUI

struct ProfileActions: View {
    let isFollowing: Bool
    let isOwnProfile: Bool
    let onFollowToggle: () -> Void
    let onEdit: () -> Void
    let onMessage: () -> Void
    
    var body: some View {
        Group {
            if #available(iOS 26.0, *) {
                liquidGlassActions
            } else {
                fallbackActions
            }
        }
    }
    
    @available(iOS 26.0, *)
    @ViewBuilder
    private var liquidGlassActions: some View {
        HStack(spacing: 10) {
            if isOwnProfile {
                Button(action: onEdit) {
                    Text("Редактировать")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.ultraThinMaterial.opacity(0.1))
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color(red: 0.13, green: 0.13, blue: 0.13).opacity(0.6))
                                    )
                            }
                        )
                        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12))
                }
            } else {
                Button(action: onFollowToggle) {
                    Text(isFollowing ? "Отписаться" : "Подписаться")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.ultraThinMaterial.opacity(0.1))
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(isFollowing ? Color(red: 0.13, green: 0.13, blue: 0.13).opacity(0.6) : Color.appAccent)
                                    )
                            }
                        )
                        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12))
                }
                
                Button(action: onMessage) {
                    Image(systemName: "message.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.ultraThinMaterial.opacity(0.1))
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color(red: 0.13, green: 0.13, blue: 0.13).opacity(0.6))
                                    )
                            }
                        )
                        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }
    
    @ViewBuilder
    private var fallbackActions: some View {
        HStack(spacing: 10) {
            if isOwnProfile {
                Button(action: onEdit) {
                    Text("Редактировать")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.ultraThinMaterial.opacity(0.1))
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color(red: 0.13, green: 0.13, blue: 0.13).opacity(0.6))
                                    )
                                
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        Color.appAccent.opacity(0.15),
                                        lineWidth: 0.5
                                    )
                            }
                        )
                }
            } else {
                Button(action: onFollowToggle) {
                    Text(isFollowing ? "Отписаться" : "Подписаться")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.ultraThinMaterial.opacity(0.1))
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(isFollowing ? Color(red: 0.13, green: 0.13, blue: 0.13).opacity(0.6) : Color.appAccent)
                                    )
                                
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        Color.appAccent.opacity(0.15),
                                        lineWidth: 0.5
                                    )
                            }
                        )
                }
                
                Button(action: onMessage) {
                    Image(systemName: "message.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.ultraThinMaterial.opacity(0.1))
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color(red: 0.13, green: 0.13, blue: 0.13).opacity(0.6))
                                    )
                                
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        Color.appAccent.opacity(0.15),
                                        lineWidth: 0.5
                                    )
                            }
                        )
                }
            }
        }
    }
}

