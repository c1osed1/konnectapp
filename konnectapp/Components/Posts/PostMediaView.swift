import SwiftUI

struct PostMediaView: View {
    let mediaURLs: [String]
    let isNsfw: Bool
    @State private var showNsfw: Bool = false
    @State private var showImageViewer: Bool = false
    @State private var selectedImageIndex: Int = 0
    
    var body: some View {
        Group {
            if mediaURLs.isEmpty {
                EmptyView()
            } else if mediaURLs.count == 1 {
                singleImageView(url: mediaURLs[0])
            } else if mediaURLs.count == 2 {
                twoImagesView(urls: mediaURLs)
            } else if mediaURLs.count == 3 {
                threeImagesView(urls: mediaURLs)
            } else {
                gridImagesView(urls: mediaURLs)
            }
        }
        .fullScreenCover(isPresented: $showImageViewer) {
            ImageViewer(imageURLs: mediaURLs, initialIndex: selectedImageIndex)
        }
    }
    
    @ViewBuilder
    private func singleImageView(url: String) -> some View {
        ZStack {
            if let imageURL = URL(string: url) {
                CachedAsyncImage(url: imageURL, cacheType: .post)
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 200)
                    .blur(radius: (isNsfw && !showNsfw) ? 20 : 0)
                    .clipped()
            } else {
                Rectangle()
                    .fill(Color.themeBlockBackground)
                    .frame(minHeight: 200)
                    .aspectRatio(16/9, contentMode: .fit)
            }
            
            if isNsfw && !showNsfw {
                Button(action: {
                    showNsfw = true
                }) {
                    VStack {
                        Image(systemName: "eye.slash.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                        Text("NSFW")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.black.opacity(0.5))
                    )
                }
            }
        }
        .onTapGesture {
            if showNsfw || !isNsfw {
                selectedImageIndex = 0
                showImageViewer = true
            }
        }
    }
    
    @ViewBuilder
    private func twoImagesView(urls: [String]) -> some View {
        HStack(spacing: 2) {
            ForEach(Array(urls.enumerated()), id: \.element) { index, mediaURL in
                ZStack {
                    if let imageURL = URL(string: mediaURL) {
                        CachedAsyncImage(url: imageURL, cacheType: .post)
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 200)
                            .frame(maxWidth: .infinity)
                            .blur(radius: (isNsfw && !showNsfw) ? 20 : 0)
                            .clipped()
                    } else {
                        Rectangle()
                            .fill(Color.themeBlockBackground)
                            .frame(height: 200)
                    }
                    
                    if isNsfw && !showNsfw {
                        Button(action: {
                            showNsfw = true
                        }) {
                            Image(systemName: "eye.slash.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                                .padding(8)
                                .background(
                                    Circle()
                                        .fill(Color.black.opacity(0.5))
                                )
                        }
                    }
                }
                .onTapGesture {
                    if showNsfw || !isNsfw {
                        selectedImageIndex = index
                        showImageViewer = true
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func threeImagesView(urls: [String]) -> some View {
        VStack(spacing: 2) {
            ZStack {
                AsyncImage(url: URL(string: urls[0])) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .fill(Color.themeBlockBackground)
                            .frame(height: 200)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 200)
                            .frame(maxWidth: .infinity)
                            .blur(radius: (isNsfw && !showNsfw) ? 20 : 0)
                            .clipped()
                    case .failure:
                        Rectangle()
                            .fill(Color.themeBlockBackground)
                            .frame(height: 200)
                    @unknown default:
                        EmptyView()
                    }
                }
                
                if isNsfw && !showNsfw {
                    Button(action: {
                        showNsfw = true
                    }) {
                        Image(systemName: "eye.slash.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .padding(8)
                            .background(
                                Circle()
                                    .fill(Color.black.opacity(0.5))
                            )
                    }
                }
            }
            .onTapGesture {
                if showNsfw || !isNsfw {
                    selectedImageIndex = 0
                    showImageViewer = true
                }
            }
            
            HStack(spacing: 2) {
                ForEach(Array(urls[1...2].enumerated()), id: \.element) { subIndex, mediaURL in
                    ZStack {
                        AsyncImage(url: URL(string: mediaURL)) { phase in
                            switch phase {
                            case .empty:
                                Rectangle()
                                    .fill(Color.themeBlockBackground)
                                    .frame(height: 200)
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(height: 200)
                                    .frame(maxWidth: .infinity)
                                    .blur(radius: (isNsfw && !showNsfw) ? 20 : 0)
                                    .clipped()
                            case .failure:
                                Rectangle()
                                    .fill(Color.themeBlockBackground)
                                    .frame(height: 200)
                            @unknown default:
                                EmptyView()
                            }
                        }
                        
                        if isNsfw && !showNsfw {
                            Button(action: {
                                showNsfw = true
                            }) {
                                Image(systemName: "eye.slash.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                                    .padding(6)
                                    .background(
                                        Circle()
                                            .fill(Color.black.opacity(0.5))
                                    )
                            }
                        }
                    }
                    .onTapGesture {
                        if showNsfw || !isNsfw {
                            selectedImageIndex = subIndex + 1
                            showImageViewer = true
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func gridImagesView(urls: [String]) -> some View {
        VStack(spacing: 2) {
            HStack(spacing: 2) {
                ForEach(Array(urls.prefix(2).enumerated()), id: \.element) { index, mediaURL in
                    ZStack {
                        AsyncImage(url: URL(string: mediaURL)) { phase in
                            switch phase {
                            case .empty:
                                Rectangle()
                                    .fill(Color.themeBlockBackground)
                                    .frame(height: 150)
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(height: 150)
                                    .frame(maxWidth: .infinity)
                                    .blur(radius: (isNsfw && !showNsfw) ? 20 : 0)
                                    .clipped()
                            case .failure:
                                Rectangle()
                                    .fill(Color.themeBlockBackground)
                                    .frame(height: 150)
                            @unknown default:
                                EmptyView()
                            }
                        }
                        
                        if isNsfw && !showNsfw {
                            Button(action: {
                                showNsfw = true
                            }) {
                                Image(systemName: "eye.slash.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(.white)
                                    .padding(6)
                                    .background(
                                        Circle()
                                            .fill(Color.black.opacity(0.5))
                                    )
                            }
                        }
                    }
                    .onTapGesture {
                        if showNsfw || !isNsfw {
                            selectedImageIndex = index
                            showImageViewer = true
                        }
                    }
                }
            }
            
            HStack(spacing: 2) {
                ForEach(Array(urls[2..<min(5, urls.count)].enumerated()), id: \.element) { subIndex, mediaURL in
                    ZStack {
                        AsyncImage(url: URL(string: mediaURL)) { phase in
                            switch phase {
                            case .empty:
                                ZStack {
                                    Rectangle()
                                        .fill(Color.themeBlockBackground)
                                        .frame(height: 150)
                                    
                                    if urls.count > 5 && mediaURL == urls[4] {
                                        Rectangle()
                                            .fill(Color.black.opacity(0.6))
                                            .frame(height: 150)
                                        
                                        Text("+\(urls.count - 5)")
                                            .font(.system(size: 24, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                }
                            case .success(let image):
                                ZStack {
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(height: 150)
                                        .frame(maxWidth: .infinity)
                                        .blur(radius: (isNsfw && !showNsfw) ? 20 : 0)
                                        .clipped()
                                    
                                    if urls.count > 5 && mediaURL == urls[4] {
                                        Rectangle()
                                            .fill(Color.black.opacity(0.6))
                                        
                                        Text("+\(urls.count - 5)")
                                            .font(.system(size: 24, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                }
                            case .failure:
                                ZStack {
                                    Rectangle()
                                        .fill(Color.themeBlockBackground)
                                        .frame(height: 150)
                                    
                                    if urls.count > 5 && mediaURL == urls[4] {
                                        Rectangle()
                                            .fill(Color.black.opacity(0.6))
                                            .frame(height: 150)
                                        
                                        Text("+\(urls.count - 5)")
                                            .font(.system(size: 24, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                }
                            @unknown default:
                                EmptyView()
                            }
                        }
                        
                        if isNsfw && !showNsfw {
                            Button(action: {
                                showNsfw = true
                            }) {
                                Image(systemName: "eye.slash.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(.white)
                                    .padding(6)
                                    .background(
                                        Circle()
                                            .fill(Color.black.opacity(0.5))
                                    )
                            }
                        }
                    }
                    .onTapGesture {
                        if showNsfw || !isNsfw {
                            selectedImageIndex = subIndex + 2
                            showImageViewer = true
                        }
                    }
                }
            }
        }
    }
}

