import SwiftUI

struct AppBackgroundView: View {
    let backgroundURL: String?
    
    var body: some View {
        GeometryReader { geometry in
            Group {
                if let backgroundURL = backgroundURL, !backgroundURL.isEmpty, let url = URL(string: backgroundURL) {
                    CachedAsyncImage(url: url, cacheType: .banner)
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                        .overlay(
                            LinearGradient(
                                colors: [
                                    Color.black.opacity(0.3),
                                    Color.black.opacity(0.5)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                } else {
                    defaultGradient
                        .frame(width: geometry.size.width, height: geometry.size.height)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            .onAppear {
                if let backgroundURL = backgroundURL, !backgroundURL.isEmpty {
                    print("🟡 AppBackgroundView: Initialized with backgroundURL: \(backgroundURL)")
                } else {
                    print("🔵 AppBackgroundView: Initialized without valid backgroundURL, received: \(backgroundURL ?? "nil")")
                }
            }
            .onChange(of: backgroundURL) { oldValue, newValue in
                print("🔄 AppBackgroundView: backgroundURL changed from \(oldValue ?? "nil") to \(newValue ?? "nil")")
            }
        }
        .ignoresSafeArea(.all)
        .allowsHitTesting(false) // Фон не должен перехватывать нажатия
    }
    
    @StateObject private var themeManager = ThemeManager.shared
    
    private var defaultGradient: some View {
        LinearGradient(
            colors: [
                Color.themeBackgroundStart,
                Color.themeBackgroundEnd
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

