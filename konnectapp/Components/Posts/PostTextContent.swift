import SwiftUI
import UIKit

struct PostTextContent: View {
    let content: String
    var navigationPath: Binding<NavigationPath>? = nil
    @State private var isExpanded: Bool = false
    
    private var shouldTruncate: Bool {
        content.count > 200
    }
    
    private var displayContent: String {
        isExpanded || !shouldTruncate ? content : truncatedContent
    }
    
    private var truncatedContent: String {
        let truncateLength = Int(Double(content.count) * 0.2)
        return String(content.prefix(content.count - truncateLength))
    }
    
    var body: some View {
        if !content.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                ClickableTextWithMentions(
                    text: displayContent,
                    onMentionTap: { username in
                        navigationPath?.wrappedValue.append(username)
                    }
                )
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                
                if shouldTruncate {
                    Button(action: {
                        isExpanded.toggle()
                    }) {
                        Text(isExpanded ? "Скрыть" : "Показать полностью")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color.appAccent)
                    }
                }
            }
        }
    }
}

// MARK: - ClickableTextWithMentions

struct ClickableTextWithMentions: UIViewRepresentable {
    let text: String
    let onMentionTap: (String) -> Void
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainer.widthTracksTextView = true
        textView.textContainer.maximumNumberOfLines = 0
        textView.textContainer.lineBreakMode = .byWordWrapping
        textView.delegate = context.coordinator
        textView.font = .systemFont(ofSize: 15)
        textView.textColor = UIColor(Color.themeTextPrimary)
        textView.linkTextAttributes = [:]
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        return textView
    }
    
    func updateUIView(_ textView: UITextView, context: Context) {
        let attributedString = createAttributedString(from: text)
        textView.attributedText = attributedString
        textView.textContainer.widthTracksTextView = true
    }
    
    static func dismantleUIView(_ uiView: UITextView, coordinator: Coordinator) {
        // Очистка при необходимости
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onMentionTap: onMentionTap)
    }
    
    private func createAttributedString(from text: String) -> NSMutableAttributedString {
        let attributedString = NSMutableAttributedString(string: text)
        let fullRange = NSRange(location: 0, length: text.utf16.count)
        
        // Базовые атрибуты
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 4
        attributedString.addAttribute(.font, value: UIFont.systemFont(ofSize: 15), range: fullRange)
        attributedString.addAttribute(.paragraphStyle, value: paragraphStyle, range: fullRange)
        
        // Используем цвет из темы
        let themeTextColor = UIColor(Color.themeTextPrimary)
        attributedString.addAttribute(.foregroundColor, value: themeTextColor, range: fullRange)
        
        // Находим упоминания
        let regex = try? NSRegularExpression(pattern: "@(\\w+)", options: [])
        let matches = regex?.matches(in: text, options: [], range: fullRange) ?? []
        
        for match in matches {
            // Выделяем упоминание акцентным цветом
            let accentColor = UIColor(Color.appAccent)
            attributedString.addAttribute(.foregroundColor, value: accentColor, range: match.range)
            
            // Добавляем кастомный атрибут для идентификации упоминания
            let username = (text as NSString).substring(with: match.range(at: 1))
            attributedString.addAttribute(.link, value: "mention://\(username)", range: match.range)
        }
        
        return attributedString
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        let onMentionTap: (String) -> Void
        
        init(onMentionTap: @escaping (String) -> Void) {
            self.onMentionTap = onMentionTap
        }
        
        func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
            if URL.scheme == "mention", let username = URL.host {
                onMentionTap(username)
                return false // Предотвращаем открытие URL
            }
            return true
        }
    }
}
