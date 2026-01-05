import SwiftUI
import UIKit

extension UITextField {
    func setEnglishKeyboard() {
        keyboardType = .asciiCapable
        autocapitalizationType = .none
        autocorrectionType = .no
    }
}

struct EnglishPasswordField: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String
    
    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.isSecureTextEntry = false
        textField.placeholder = placeholder
        textField.textColor = .white
        textField.setEnglishKeyboard()
        textField.returnKeyType = .done
        textField.textContentType = .password
        
        let placeholderColor = UIColor(red: 0.47, green: 0.47, blue: 0.47, alpha: 1.0)
        textField.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [NSAttributedString.Key.foregroundColor: placeholderColor]
        )
        
        textField.addTarget(context.coordinator, action: #selector(Coordinator.textChanged), for: .editingChanged)
        textField.delegate = context.coordinator
        
        context.coordinator.textField = textField
        
        return textField
    }
    
    func updateUIView(_ uiView: UITextField, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
        uiView.setEnglishKeyboard()
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }
    
    class Coordinator: NSObject, UITextFieldDelegate {
        @Binding var text: String
        weak var textField: UITextField?
        
        init(text: Binding<String>) {
            _text = text
        }
        
        @objc func textChanged(_ sender: UITextField) {
            text = sender.text ?? ""
        }
        
        func textFieldDidBeginEditing(_ textField: UITextField) {
            textField.setEnglishKeyboard()
        }
    }
}

struct EnglishSecureField: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String
    
    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.isSecureTextEntry = true
        textField.placeholder = placeholder
        textField.textColor = .white
        textField.setEnglishKeyboard()
        textField.returnKeyType = .done
        textField.textContentType = .password
        
        let placeholderColor = UIColor(red: 0.47, green: 0.47, blue: 0.47, alpha: 1.0)
        textField.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [NSAttributedString.Key.foregroundColor: placeholderColor]
        )
        
        textField.addTarget(context.coordinator, action: #selector(Coordinator.textChanged), for: .editingChanged)
        textField.delegate = context.coordinator
        
        context.coordinator.textField = textField
        
        return textField
    }
    
    func updateUIView(_ uiView: UITextField, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
        uiView.setEnglishKeyboard()
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }
    
    class Coordinator: NSObject, UITextFieldDelegate {
        @Binding var text: String
        weak var textField: UITextField?
        
        init(text: Binding<String>) {
            _text = text
        }
        
        @objc func textChanged(_ sender: UITextField) {
            text = sender.text ?? ""
        }
        
        func textFieldDidBeginEditing(_ textField: UITextField) {
            textField.setEnglishKeyboard()
        }
    }
}
