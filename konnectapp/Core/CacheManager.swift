import Foundation
import UIKit

class CacheManager {
    static let shared = CacheManager()
    
    private let fileManager = FileManager.default
    private var cacheDirectory: URL {
        let urls = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        return urls[0].appendingPathComponent("KonnectAppCache")
    }
    
    private var postsImagesCacheDirectory: URL {
        cacheDirectory.appendingPathComponent("PostsImages")
    }
    
    private var avatarsCacheDirectory: URL {
        cacheDirectory.appendingPathComponent("Avatars")
    }
    
    private var bannersCacheDirectory: URL {
        cacheDirectory.appendingPathComponent("Banners")
    }
    
    private var tracksCacheDirectory: URL {
        cacheDirectory.appendingPathComponent("Tracks")
    }
    
    private init() {
        createDirectoriesIfNeeded()
    }
    
    private func createDirectoriesIfNeeded() {
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        try? fileManager.createDirectory(at: postsImagesCacheDirectory, withIntermediateDirectories: true)
        try? fileManager.createDirectory(at: avatarsCacheDirectory, withIntermediateDirectories: true)
        try? fileManager.createDirectory(at: bannersCacheDirectory, withIntermediateDirectories: true)
        try? fileManager.createDirectory(at: tracksCacheDirectory, withIntermediateDirectories: true)
    }
    
    func cachePostImage(url: URL, data: Data) {
        let fileName = url.lastPathComponent
        let fileURL = postsImagesCacheDirectory.appendingPathComponent(fileName)
        try? data.write(to: fileURL)
    }
    
    func getCachedPostImage(url: URL) -> Data? {
        let fileName = url.lastPathComponent
        let fileURL = postsImagesCacheDirectory.appendingPathComponent(fileName)
        return try? Data(contentsOf: fileURL)
    }
    
    func cacheAvatar(url: URL, data: Data) {
        let fileName = url.lastPathComponent
        let fileURL = avatarsCacheDirectory.appendingPathComponent(fileName)
        try? data.write(to: fileURL)
    }
    
    func getCachedAvatar(url: URL) -> Data? {
        let fileName = url.lastPathComponent
        let fileURL = avatarsCacheDirectory.appendingPathComponent(fileName)
        return try? Data(contentsOf: fileURL)
    }
    
    func cacheBanner(url: URL, data: Data) {
        let fileName = url.lastPathComponent
        let fileURL = bannersCacheDirectory.appendingPathComponent(fileName)
        try? data.write(to: fileURL)
    }
    
    func getCachedBanner(url: URL) -> Data? {
        let fileName = url.lastPathComponent
        let fileURL = bannersCacheDirectory.appendingPathComponent(fileName)
        return try? Data(contentsOf: fileURL)
    }
    
    func cacheTrack(url: URL, data: Data) {
        let fileName = url.lastPathComponent
        let fileURL = tracksCacheDirectory.appendingPathComponent(fileName)
        try? data.write(to: fileURL)
    }
    
    func getCachedTrack(url: URL) -> URL? {
        let fileName = url.lastPathComponent
        let fileURL = tracksCacheDirectory.appendingPathComponent(fileName)
        return fileManager.fileExists(atPath: fileURL.path) ? fileURL : nil
    }
    
    func getCacheSize() -> CacheSize {
        let postsImagesSize = getDirectorySize(url: postsImagesCacheDirectory)
        let avatarsSize = getDirectorySize(url: avatarsCacheDirectory)
        let bannersSize = getDirectorySize(url: bannersCacheDirectory)
        let tracksSize = getDirectorySize(url: tracksCacheDirectory)
        let totalSize = postsImagesSize + avatarsSize + bannersSize + tracksSize
        return CacheSize(postsImages: postsImagesSize, avatars: avatarsSize, banners: bannersSize, tracks: tracksSize, total: totalSize)
    }
    
    private func getDirectorySize(url: URL) -> Int64 {
        guard let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey]) else {
            return 0
        }
        var totalSize: Int64 = 0
        for case let fileURL as URL in enumerator {
            if let attributes = try? fileURL.resourceValues(forKeys: [.fileSizeKey]),
               let size = attributes.fileSize {
                totalSize += Int64(size)
            }
        }
        return totalSize
    }
    
    func clearPostsImagesCache() {
        try? fileManager.removeItem(at: postsImagesCacheDirectory)
        createDirectoriesIfNeeded()
    }
    
    func clearAvatarsCache() {
        try? fileManager.removeItem(at: avatarsCacheDirectory)
        createDirectoriesIfNeeded()
    }
    
    func clearBannersCache() {
        try? fileManager.removeItem(at: bannersCacheDirectory)
        createDirectoriesIfNeeded()
    }
    
    func clearTracksCache() {
        try? fileManager.removeItem(at: tracksCacheDirectory)
        createDirectoriesIfNeeded()
    }
    
    func clearAllCache() {
        clearPostsImagesCache()
        clearAvatarsCache()
        clearBannersCache()
        clearTracksCache()
    }
}

struct CacheSize {
    let postsImages: Int64
    let avatars: Int64
    let banners: Int64
    let tracks: Int64
    let total: Int64
    
    func formatted() -> String {
        return ByteCountFormatter.string(fromByteCount: total, countStyle: .file)
    }
    
    func formattedPostsImages() -> String {
        return ByteCountFormatter.string(fromByteCount: postsImages, countStyle: .file)
    }
    
    func formattedAvatars() -> String {
        return ByteCountFormatter.string(fromByteCount: avatars, countStyle: .file)
    }
    
    func formattedBanners() -> String {
        return ByteCountFormatter.string(fromByteCount: banners, countStyle: .file)
    }
    
    func formattedTracks() -> String {
        return ByteCountFormatter.string(fromByteCount: tracks, countStyle: .file)
    }
}

