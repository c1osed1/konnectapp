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
}

extension GlassEffectStyle {
    static var glass: GlassEffectStyle { .regular }
}

extension View {
    @ViewBuilder
    func glassEffect(_ style: GlassEffectStyle, in shape: some Shape) -> some View {
        if #available(iOS 26.0, *) {
            // Liquid glass эффект - используем ultraThinMaterial как у .buttonStyle(.glass)
            // Без opacity для настоящего liquid glass эффекта
            self.background(
                shape.fill(.ultraThinMaterial)
            )
        } else {
            // Fallback для старых версий
            self.background(
                shape.fill(.ultraThinMaterial.opacity(0.1))
                    .background(
                        shape.fill(Color(red: 0.1, green: 0.1, blue: 0.1).opacity(0.5))
                    )
            )
        }
    }
}
