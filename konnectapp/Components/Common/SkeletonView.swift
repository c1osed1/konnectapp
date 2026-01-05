import SwiftUI

struct SkeletonView: View {
    @State private var isAnimating = false
    
    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.2, green: 0.2, blue: 0.2),
                        Color(red: 0.25, green: 0.25, blue: 0.25),
                        Color(red: 0.2, green: 0.2, blue: 0.2)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .opacity(isAnimating ? 0.5 : 0.8)
            .onAppear {
                withAnimation(
                    Animation
                        .linear(duration: 1.5)
                        .repeatForever(autoreverses: false)
                ) {
                    isAnimating = true
                }
            }
    }
}

struct SkeletonCircle: View {
    @State private var isAnimating = false
    let size: CGFloat
    
    init(size: CGFloat = 44) {
        self.size = size
    }
    
    var body: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.2, green: 0.2, blue: 0.2),
                        Color(red: 0.25, green: 0.25, blue: 0.25),
                        Color(red: 0.2, green: 0.2, blue: 0.2)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .opacity(isAnimating ? 0.5 : 0.8)
            .frame(width: size, height: size)
            .onAppear {
                withAnimation(
                    Animation
                        .linear(duration: 1.5)
                        .repeatForever(autoreverses: false)
                ) {
                    isAnimating = true
                }
            }
    }
}

