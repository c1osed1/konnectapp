import SwiftUI

struct PostTextContent: View {
    let content: String
    @State private var isExpanded: Bool = false
    
    private var shouldTruncate: Bool {
        content.count > 200
    }
    
    private var truncatedContent: String {
        let truncateLength = Int(Double(content.count) * 0.2)
        return String(content.prefix(content.count - truncateLength))
    }
    
    var body: some View {
        if !content.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text(isExpanded || !shouldTruncate ? content : truncatedContent)
                    .font(.system(size: 15))
                    .foregroundColor(Color.themeTextPrimary)
                    .lineSpacing(4)
                
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

