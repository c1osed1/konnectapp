import SwiftUI

struct AppBackgroundView: View {
    let backgroundURL: String?
    
    var body: some View {
        ZStack {
            Group {
                if let backgroundURL = backgroundURL, !backgroundURL.isEmpty, let url = URL(string: backgroundURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            defaultGradient
                                .onAppear {
                                    print("🟡 AppBackgroundView: Loading image from \(backgroundURL)")
                                }
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .clipped()
                                .overlay(
                                    // Затемнение для лучшей читаемости
                                    LinearGradient(
                                        colors: [
                                            Color.black.opacity(0.3),
                                            Color.black.opacity(0.5)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .onAppear {
                                    print("🟢 AppBackgroundView: Image loaded successfully from \(backgroundURL)")
                                }
                        case .failure(let error):
                            defaultGradient
                                .onAppear {
                                    print("❌ AppBackgroundView: Failed to load image from \(backgroundURL), error: \(error.localizedDescription)")
                                }
                        @unknown default:
                            defaultGradient
                                .onAppear {
                                    print("⚠️ AppBackgroundView: Unknown state for image loading")
                                }
                        }
                    }
                } else {
                    defaultGradient
                }
            }
        }
        .ignoresSafeArea(.all)
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
    
    private var defaultGradient: some View {
        LinearGradient(
            colors: [
                Color(red: 0.06, green: 0.06, blue: 0.06),
                Color(red: 0.1, green: 0.1, blue: 0.1)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea(.all)
    }
}

