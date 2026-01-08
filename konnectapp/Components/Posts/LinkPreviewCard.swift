import SwiftUI

struct LinkPreviewCard: View {
    let preview: LinkPreviewData
    let url: String
    @State private var isLoading = true
    
    var body: some View {
        Button(action: {
            if let url = URL(string: url) {
                UIApplication.shared.open(url)
            }
        }) {
            HStack(spacing: 10) {
                // Изображение превью
                if let imageURLString = preview.image {
                    if let imageURL = URL(string: imageURLString) {
                        CachedAsyncImage(url: imageURL, cacheType: .post)
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 60, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.themeBlockBackground.opacity(0.1), lineWidth: 1)
                            )
                            .onAppear {
                                print("🖼️ LinkPreviewCard: Loading image from \(imageURLString)")
                            }
                    } else {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.themeBlockBackground)
                            .frame(width: 60, height: 60)
                            .onAppear {
                                print("⚠️ LinkPreviewCard: Invalid image URL: \(imageURLString)")
                            }
                    }
                } else {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.themeBlockBackground)
                        .frame(width: 60, height: 60)
                }
                
                // Контент
                VStack(alignment: .leading, spacing: 3) {
                    // Заголовок
                    Text(preview.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color.themeTextPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    // Описание
                    if let description = preview.description, !description.isEmpty {
                        Text(description)
                            .font(.system(size: 12))
                            .foregroundColor(Color.themeTextSecondary)
                            .lineLimit(1)
                            .multilineTextAlignment(.leading)
                    }
                    
                    // Домен
                    if let domain = URL(string: url)?.host {
                        HStack(spacing: 3) {
                            Image(systemName: "link")
                                .font(.system(size: 9))
                                .foregroundColor(Color.themeTextSecondary)
                            Text(domain)
                                .font(.system(size: 11))
                                .foregroundColor(Color.themeTextSecondary)
                                .lineLimit(1)
                        }
                        .padding(.top, 2)
                    }
                }
                
                Spacer()
            }
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.themeBlockBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.appAccent.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Grouped Link Previews

struct GroupedLinkPreviews: View {
    let urls: [String]
    let maxCount: Int
    
    init(urls: [String], maxCount: Int = 3) {
        self.urls = groupUrlsByDomain(urls)
        self.maxCount = maxCount
    }
    
    var body: some View {
        VStack(spacing: 8) {
            ForEach(Array(urls.prefix(maxCount)), id: \.self) { url in
                LinkPreviewCardView(url: url)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Link Preview Card View (with loading state)

struct LinkPreviewCardView: View {
    let url: String
    @State private var preview: LinkPreviewData?
    @State private var isLoading = true
    @State private var hasError = false
    
    var body: some View {
        Group {
            if isLoading {
                // Placeholder во время загрузки
                HStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.themeBlockBackground)
                        .frame(width: 60, height: 60)
                    
                    VStack(alignment: .leading, spacing: 3) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.themeBlockBackground)
                            .frame(height: 14)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.themeBlockBackground)
                            .frame(height: 11)
                            .frame(width: 120)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.themeBlockBackground)
                            .frame(height: 10)
                            .frame(width: 80)
                            .padding(.top, 2)
                    }
                    
                    Spacer()
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.themeBlockBackground)
                )
            } else if let preview = preview {
                LinkPreviewCard(preview: preview, url: url)
            }
            // Если ошибка - не показываем ничего
        }
        .task {
            await loadPreview()
        }
    }
    
    private func loadPreview() async {
        isLoading = true
        hasError = false
        
        do {
            if let previewData = try await LinkPreviewService.shared.getLinkPreview(url: url) {
                print("✅ LinkPreviewCardView: Successfully loaded preview for \(url)")
                print("   Title: \(previewData.title)")
                print("   Image: \(previewData.image ?? "nil")")
                await MainActor.run {
                    self.preview = previewData
                    self.isLoading = false
                }
            } else {
                print("⚠️ LinkPreviewCardView: Preview data is nil for \(url)")
                await MainActor.run {
                    self.hasError = true
                    self.isLoading = false
                }
            }
        } catch {
            print("❌ LinkPreviewCardView: Error loading link preview for \(url): \(error.localizedDescription)")
            await MainActor.run {
                self.hasError = true
                self.isLoading = false
            }
        }
    }
}

// MARK: - Helper Functions

func extractURLs(from text: String) -> [String] {
    let pattern = "(https?://[^\\s]+)"
    let regex = try? NSRegularExpression(pattern: pattern, options: [])
    let nsString = text as NSString
    let matches = regex?.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length)) ?? []
    
    var urls: [String] = []
    for match in matches {
        let urlString = nsString.substring(with: match.range)
        if let url = URL(string: urlString), url.scheme == "http" || url.scheme == "https" {
            urls.append(urlString)
        }
    }
    
    return urls
}

func groupUrlsByDomain(_ urls: [String]) -> [String] {
    var seenDomains: Set<String> = []
    var result: [String] = []
    
    for urlString in urls {
        guard let url = URL(string: urlString),
              let host = url.host else {
            continue
        }
        
        let domain = host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
        
        if !seenDomains.contains(domain) {
            seenDomains.insert(domain)
            result.append(urlString)
        }
    }
    
    return result
}
