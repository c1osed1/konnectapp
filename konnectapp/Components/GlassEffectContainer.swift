import SwiftUI

@available(iOS 26.0, *)
struct GlassEffectContainer<Content: View>: View {
    let spacing: CGFloat
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        content()
    }
}

