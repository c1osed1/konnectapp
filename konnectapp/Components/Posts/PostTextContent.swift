import SwiftUI

struct PostTextContent: View {
    let content: String
    
    var body: some View {
        if !content.isEmpty {
            Text(content)
                .font(.system(size: 15))
                .foregroundColor(.white)
                .lineSpacing(4)
        }
    }
}

