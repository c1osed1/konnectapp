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
    @ViewBuilder
    func glassEffect(in shape: some Shape) -> some View {
        self.glassEffect(GlassEffectStyle.regular, in: shape)
    }
    
    @ViewBuilder
    func glassEffect(_ style: GlassEffectStyle, in shape: some Shape) -> some View {
        if #available(iOS 26.0, *) {
            self.modifier(NativeGlassEffectModifier(style: style, shape: shape))
        } else {
            self.background(
                ZStack {
                    // Более темный фоновый слой
                    shape.fill(Color.themeBlockBackground.opacity(0.95))
                    
                    // Блюр эффект с затемнением
                    shape.fill(.thinMaterial.opacity(0.3))
                    
                    shape.stroke(
                        Color.appAccent.opacity(0.15),
                        lineWidth: 0.5
                    )
                }
            )
        }
    }
}

extension GlassEffectStyle {
    func interactive() -> GlassEffectStyle {
        .regularInteractive
    }
}

@available(iOS 26.0, *)
struct NativeGlassEffectModifier<S: Shape>: ViewModifier {
    let style: GlassEffectStyle
    let shape: S
    
    func body(content: Content) -> some View {
        content.background(
            shape.fill(.ultraThinMaterial)
        )
    }
}
