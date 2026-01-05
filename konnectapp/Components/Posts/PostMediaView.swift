import SwiftUI

struct PostMediaView: View {
    let mediaURLs: [String]
    let isNsfw: Bool
    @State private var showNsfw: Bool = false
    
    var body: some View {
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
    
    @ViewBuilder
    private func singleImageView(url: String) -> some View {
        ZStack {
            AsyncImage(url: URL(string: url)) { phase in
                switch phase {
                case .empty:
                    Rectangle()
                        .fill(Color(red: 0.13, green: 0.13, blue: 0.13))
                        .frame(minHeight: 200)
                        .aspectRatio(16/9, contentMode: .fit)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .blur(radius: (isNsfw && !showNsfw) ? 20 : 0)
                        .clipped()
                case .failure:
                    Rectangle()
                        .fill(Color(red: 0.13, green: 0.13, blue: 0.13))
                        .frame(minHeight: 200)
                        .aspectRatio(16/9, contentMode: .fit)
                @unknown default:
                    EmptyView()
                }
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
    }
    
    @ViewBuilder
    private func twoImagesView(urls: [String]) -> some View {
        HStack(spacing: 2) {
            ForEach(urls, id: \.self) { mediaURL in
                ZStack {
                    AsyncImage(url: URL(string: mediaURL)) { phase in
                        switch phase {
                        case .empty:
                            Rectangle()
                                .fill(Color(red: 0.13, green: 0.13, blue: 0.13))
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
                                .fill(Color(red: 0.13, green: 0.13, blue: 0.13))
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
                            .fill(Color(red: 0.13, green: 0.13, blue: 0.13))
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
                            .fill(Color(red: 0.13, green: 0.13, blue: 0.13))
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
            
            HStack(spacing: 2) {
                ForEach(Array(urls[1...2]), id: \.self) { mediaURL in
                    ZStack {
                        AsyncImage(url: URL(string: mediaURL)) { phase in
                            switch phase {
                            case .empty:
                                Rectangle()
                                    .fill(Color(red: 0.13, green: 0.13, blue: 0.13))
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
                                    .fill(Color(red: 0.13, green: 0.13, blue: 0.13))
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
                }
            }
        }
    }
    
    @ViewBuilder
    private func gridImagesView(urls: [String]) -> some View {
        VStack(spacing: 2) {
            HStack(spacing: 2) {
                ForEach(Array(urls.prefix(2)), id: \.self) { mediaURL in
                    ZStack {
                        AsyncImage(url: URL(string: mediaURL)) { phase in
                            switch phase {
                            case .empty:
                                Rectangle()
                                    .fill(Color(red: 0.13, green: 0.13, blue: 0.13))
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
                                    .fill(Color(red: 0.13, green: 0.13, blue: 0.13))
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
                }
            }
            
            HStack(spacing: 2) {
                ForEach(Array(urls[2..<min(5, urls.count)]), id: \.self) { mediaURL in
                    ZStack {
                        AsyncImage(url: URL(string: mediaURL)) { phase in
                            switch phase {
                            case .empty:
                                ZStack {
                                    Rectangle()
                                        .fill(Color(red: 0.13, green: 0.13, blue: 0.13))
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
                                        .fill(Color(red: 0.13, green: 0.13, blue: 0.13))
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
                }
            }
        }
    }
}

