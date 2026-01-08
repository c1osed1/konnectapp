import SwiftUI

struct RepostedPostView: View {
    let originalPost: OriginalPost
    @Binding var navigationPath: NavigationPath
    @StateObject private var themeManager = ThemeManager.shared
    
    private var uniqueMedia: [String] {
        var allMedia: [String] = []
        if let media = originalPost.media {
            allMedia.append(contentsOf: media)
        }
        if let images = originalPost.images {
            allMedia.append(contentsOf: images)
        }
        if let image = originalPost.image, !allMedia.contains(image) {
            allMedia.append(image)
        }
        return Array(Set(allMedia))
    }
    
    var body: some View {
        Group {
            if #available(iOS 26.0, *), themeManager.isGlassEffectEnabled {
                liquidGlassRepostedPost
            } else {
                fallbackRepostedPost
            }
        }
    }
    
    @available(iOS 26.0, *)
    @ViewBuilder
    private var liquidGlassRepostedPost: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                if let user = originalPost.user {
                    PostHeader(
                        user: user,
                        timestamp: originalPost.created_at ?? originalPost.timestamp,
                        navigationPath: $navigationPath
                    )
                }
                
                if let content = originalPost.content, !content.isEmpty {
                    PostTextContent(content: content, navigationPath: $navigationPath)
                }
            }
            .padding(12)
            
            if !uniqueMedia.isEmpty {
                PostMediaView(mediaURLs: uniqueMedia, isNsfw: originalPost.is_nsfw ?? false)
            }
            
            if let music = originalPost.music, !music.isEmpty {
                PostMusicView(tracks: music)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 8)
            }
        }
        .glassEffect(in: RoundedRectangle(cornerRadius: 16))
    }
    
    @ViewBuilder
    private var fallbackRepostedPost: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                if let user = originalPost.user {
                    PostHeader(
                        user: user,
                        timestamp: originalPost.created_at ?? originalPost.timestamp,
                        navigationPath: $navigationPath
                    )
                }
                
                if let content = originalPost.content, !content.isEmpty {
                    PostTextContent(content: content, navigationPath: $navigationPath)
                }
            }
            .padding(12)
            
            if !uniqueMedia.isEmpty {
                PostMediaView(mediaURLs: uniqueMedia, isNsfw: originalPost.is_nsfw ?? false)
            }
            
            if let music = originalPost.music, !music.isEmpty {
                PostMusicView(tracks: music)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 8)
            }
        }
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial.opacity(0.3))
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.themeBlockBackground.opacity(0.9))
                    )
                
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        Color.appAccent.opacity(0.1),
                        lineWidth: 0.5
                    )
            }
        )
    }
}

