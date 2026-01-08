import SwiftUI
import UIKit

class TabBarMenuCoordinator: NSObject, UIGestureRecognizerDelegate {
    var onShowMenu: (() -> Void)?
    
    @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        print("🟡 TabBarLongPressHandler: Gesture state: \(gesture.state.rawValue)")
        guard gesture.state == .began else { return }
        print("🟢 TabBarLongPressHandler: Long press detected!")
        onShowMenu?()
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
}

struct TabBarLongPressHandler: UIViewRepresentable {
    let onShowMenu: () -> Void
    private let coordinator = TabBarMenuCoordinator()
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        coordinator.onShowMenu = onShowMenu
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let tabBarController = findTabBarController(in: window) {
                setupLongPressGesture(on: tabBarController)
            }
        }
    }
    
    private func findTabBarController(in view: UIView) -> UITabBarController? {
        if let tabBarController = view.next(UIViewController.self) as? UITabBarController {
            return tabBarController
        }
        
        for subview in view.subviews {
            if let found = findTabBarController(in: subview) {
                return found
            }
        }
        
        return nil
    }
    
    private func setupLongPressGesture(on tabBarController: UITabBarController) {
        let tabBar = tabBarController.tabBar
        print("🟡 TabBarLongPressHandler: Setting up gesture on tab bar with \(tabBar.subviews.count) subviews, items: \(tabBar.items?.count ?? 0)")
        
        // Find the profile tab view (4th tab, index 3)
        var profileView: UIView?
        
        for subview in tabBar.subviews {
            print("🟡 TabBarLongPressHandler: Checking subview type: \(type(of: subview)), subviews: \(subview.subviews.count)")
            if subview.subviews.count >= 4 {
                profileView = subview.subviews[safe: 3]
                print("🟢 TabBarLongPressHandler: Found profile view at index 3")
                break
            }
        }
        
        guard let targetView = profileView else {
            print("⚠️ TabBarLongPressHandler: Could not find profile view")
            return
        }
        
        print("🟢 TabBarLongPressHandler: Found profile view, type: \(type(of: targetView))")
        
        // Remove existing gestures
        targetView.gestureRecognizers?.removeAll { $0 is UILongPressGestureRecognizer }
        
        // Create gesture
        let longPress = UILongPressGestureRecognizer(target: coordinator, action: #selector(TabBarMenuCoordinator.handleLongPress(_:)))
        longPress.minimumPressDuration = 0.6
        longPress.numberOfTouchesRequired = 1
        longPress.cancelsTouchesInView = false
        longPress.delaysTouchesBegan = false
        longPress.delaysTouchesEnded = false
        longPress.delegate = coordinator
        
        targetView.addGestureRecognizer(longPress)
        targetView.isUserInteractionEnabled = true
        
        print("🟢 TabBarLongPressHandler: Long press gesture added successfully")
    }
}

extension UIView {
    func next<T>(_ type: T.Type) -> T? {
        var responder: UIResponder? = self
        while responder != nil {
            if let result = responder as? T {
                return result
            }
            responder = responder?.next
        }
        return nil
    }
}

extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
