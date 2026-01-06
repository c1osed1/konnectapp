import SwiftUI

@available(iOS 26.0, *)
struct GlassEffectContainer<Content: View>: View {
    let spacing: CGFloat
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        content()
    }
}

enum GlassEffectStyle {
    case regular
    case regularInteractive
}

extension GlassEffectStyle {
    static var glass: GlassEffectStyle { .regular }
    
    var isInteractive: Bool {
        switch self {
        case .regular: return false
        case .regularInteractive: return true
        }
    }
}

extension View {
    @available(iOS 26.0, *)
    @ViewBuilder
    func glassEffect(in shape: some Shape) -> some View {
        self.glassEffect(GlassEffectStyle.regular, in: shape)
    }
    
    @ViewBuilder
    func glassEffect(_ style: GlassEffectStyle, in shape: some Shape) -> some View {
        if #available(iOS 26.0, *) {
            self.background(
                shape.fill(.ultraThinMaterial)
            )
        } else {
            self.background(
                shape.fill(.ultraThinMaterial.opacity(0.1))
                    .background(
                        shape.fill(Color(red: 0.1, green: 0.1, blue: 0.1).opacity(0.5))
                    )
            )
        }
    }
}

extension GlassEffectStyle {
    func interactive() -> GlassEffectStyle {
        .regularInteractive
    }
}
