import SwiftUI
import UIKit

struct PostTextContent: View {
    let content: String
    var navigationPath: Binding<NavigationPath>? = nil
    @State private var isExpanded: Bool = false
    
    // Обрезаем только действительно длинные тексты (больше 500 символов)
    private var shouldTruncate: Bool {
        content.count > 500
    }
    
    private var displayContent: String {
        if isExpanded || !shouldTruncate {
            return content
        } else {
            return truncatedContent
        }
    }
    
    // Обрезаем до примерно 450 символов, стараясь не обрезать в середине слова
    private var truncatedContent: String {
        let maxLength = 450
        guard content.count > maxLength else {
            return content
        }
        
        // Обрезаем до maxLength и ищем последний пробел, чтобы не обрезать слово
        let truncated = String(content.prefix(maxLength))
        if let lastSpaceIndex = truncated.lastIndex(of: " ") {
            return String(truncated[..<lastSpaceIndex]) + "..."
        } else {
            return truncated + "..."
        }
    }
    
    private var extractedURLs: [String] {
        let urls = extractURLs(from: content)
        return groupUrlsByDomain(urls)
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
                
                // Кнопка "Показать полностью" / "Скрыть"
                if shouldTruncate {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isExpanded.toggle()
                        }
                    }) {
                        HStack(spacing: 4) {
                            Text(isExpanded ? "Скрыть" : "Показать полностью")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color.appAccent)
                            
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color.appAccent)
                        }
                    }
                    .padding(.top, 4)
                }
                
                // Превью ссылок
                if !extractedURLs.isEmpty {
                    GroupedLinkPreviews(urls: extractedURLs, maxCount: 3)
                        .padding(.top, 4)
                }
            }
        }
    }
}

// MARK: - ClickableTextWithMentions

// Кастомный UITextView с правильным расчетом размера
class AutoSizingTextView: UITextView {
    override var intrinsicContentSize: CGSize {
        let size = sizeThatFits(CGSize(width: bounds.width, height: .greatestFiniteMagnitude))
        // Убеждаемся, что высота рассчитывается правильно
        if size.height > 0 {
            return CGSize(width: UIView.noIntrinsicMetric, height: size.height)
        }
        return super.intrinsicContentSize
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        invalidateIntrinsicContentSize()
    }
}

struct ClickableTextWithMentions: UIViewRepresentable {
    let text: String
    let onMentionTap: (String) -> Void
    
    func makeUIView(context: Context) -> AutoSizingTextView {
        let textView = AutoSizingTextView()
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainer.widthTracksTextView = true
        textView.textContainer.heightTracksTextView = false
        textView.textContainer.maximumNumberOfLines = 0
        textView.textContainer.lineBreakMode = .byWordWrapping
        textView.delegate = context.coordinator
        textView.font = .systemFont(ofSize: 15)
        textView.textColor = UIColor(Color.themeTextPrimary)
        textView.linkTextAttributes = [:]
        // Устанавливаем приоритеты для правильного расчета размера
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        textView.setContentCompressionResistancePriority(.required, for: .vertical)
        textView.setContentHuggingPriority(.defaultHigh, for: .vertical)
        return textView
    }
    
    func updateUIView(_ textView: AutoSizingTextView, context: Context) {
        let attributedString = createAttributedString(from: text)
        
        // Логируем длину текста для отладки
        if text.count > 200 {
            print("📝 PostTextContent: text length = \(text.count), first 100 chars: \(text.prefix(100))")
        }
        
        let oldText = textView.attributedText
        textView.attributedText = attributedString
        
        // Обновляем размер только если текст изменился
        if oldText?.string != attributedString.string {
            textView.textContainer.widthTracksTextView = true
            textView.textContainer.heightTracksTextView = false
            textView.textContainer.maximumNumberOfLines = 0
            textView.textContainer.lineBreakMode = .byWordWrapping
            
            // Принудительно обновляем размер после установки текста
            DispatchQueue.main.async {
                textView.invalidateIntrinsicContentSize()
                textView.setNeedsLayout()
                textView.layoutIfNeeded()
            }
        }
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
        let mentionRegex = try? NSRegularExpression(pattern: "@(\\w+)", options: [])
        let mentionMatches = mentionRegex?.matches(in: text, options: [], range: fullRange) ?? []
        
        for match in mentionMatches {
            // Выделяем упоминание акцентным цветом
            let accentColor = UIColor(Color.appAccent)
            attributedString.addAttribute(.foregroundColor, value: accentColor, range: match.range)
            
            // Добавляем кастомный атрибут для идентификации упоминания
            let username = (text as NSString).substring(with: match.range(at: 1))
            attributedString.addAttribute(.link, value: "mention://\(username)", range: match.range)
        }
        
        // Находим URL и выделяем их акцентным цветом
        let urlRegex = try? NSRegularExpression(pattern: "(https?://[^\\s]+)", options: [])
        let urlMatches = urlRegex?.matches(in: text, options: [], range: fullRange) ?? []
        
        for match in urlMatches {
            // Проверяем, не пересекается ли с упоминанием
            var overlapsWithMention = false
            for mentionMatch in mentionMatches {
                if NSIntersectionRange(match.range, mentionMatch.range).length > 0 {
                    overlapsWithMention = true
                    break
                }
            }
            
            if !overlapsWithMention {
                // Выделяем ссылку акцентным цветом
                let accentColor = UIColor(Color.appAccent)
                attributedString.addAttribute(.foregroundColor, value: accentColor, range: match.range)
                
                // Добавляем обычную ссылку
                let urlString = (text as NSString).substring(with: match.range)
                if let url = URL(string: urlString) {
                    attributedString.addAttribute(.link, value: url, range: match.range)
                }
            }
        }
        
        return attributedString
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        let onMentionTap: (String) -> Void
        
        init(onMentionTap: @escaping (String) -> Void) {
            self.onMentionTap = onMentionTap
        }
        
        @available(iOS, introduced: 10.0, deprecated: 17.0, message: "Use textView(_:primaryActionFor:defaultAction:) instead")
        func textView(_ textView: UITextView, shouldInteractWith url: URL, in characterRange: NSRange) -> Bool {
            if url.scheme == "mention", let username = url.host {
                onMentionTap(username)
                return false // Предотвращаем открытие URL
            }
            return true
        }
        
        @available(iOS 17.0, *)
        func textView(_ textView: UITextView, primaryActionFor textItem: UITextItem, defaultAction: UIAction) -> UIAction? {
            if case .link(let url) = textItem.content {
                if url.scheme == "mention", let username = url.host {
                    onMentionTap(username)
                    return UIAction { _ in } // Предотвращаем открытие URL
                }
            }
            return nil // Используем дефолтное поведение для обычных ссылок
        }
    }
}
