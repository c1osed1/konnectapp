import UIKit
import SwiftUI

class ToastHelper {
    static func showToast(message: String) {
        DispatchQueue.main.async {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first else { return }
            
            let toastLabel = UILabel()
            toastLabel.text = message
            toastLabel.font = .systemFont(ofSize: 14, weight: .medium)
            toastLabel.textColor = .white
            toastLabel.textAlignment = .center
            toastLabel.backgroundColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 0.95)
            toastLabel.layer.cornerRadius = 12
            toastLabel.clipsToBounds = true
            toastLabel.numberOfLines = 0
            
            let padding: CGFloat = 16
            let maxWidth = window.bounds.width - 40
            let size = toastLabel.sizeThatFits(CGSize(width: maxWidth - padding * 2, height: CGFloat.greatestFiniteMagnitude))
            toastLabel.frame = CGRect(
                x: 0,
                y: 0,
                width: min(size.width + padding * 2, maxWidth),
                height: size.height + padding
            )
            
            toastLabel.center = CGPoint(
                x: window.bounds.width / 2,
                y: window.bounds.height - 150
            )
            
            toastLabel.alpha = 0
            window.addSubview(toastLabel)
            
            UIView.animate(withDuration: 0.3, animations: {
                toastLabel.alpha = 1
            }) { _ in
                UIView.animate(withDuration: 0.3, delay: 1.5, options: .curveEaseOut, animations: {
                    toastLabel.alpha = 0
                }) { _ in
                    toastLabel.removeFromSuperview()
                }
            }
        }
    }
}

