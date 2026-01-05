import SwiftUI

struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style = .systemUltraThinMaterialDark
    var intensity: CGFloat = 1.0
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        let view = UIVisualEffectView(effect: nil)
        return view
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        let effect = UIBlurEffect(style: style)
        let animator = UIViewPropertyAnimator(duration: 0.1, curve: .linear) {
            uiView.effect = effect
        }
        animator.fractionComplete = intensity
        animator.pausesOnCompletion = true
    }
}

