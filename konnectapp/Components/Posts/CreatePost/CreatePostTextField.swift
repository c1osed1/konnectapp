import SwiftUI

struct CreatePostTextField: View {
    @Binding var text: String
    @StateObject private var themeManager = ThemeManager.shared
    @FocusState private var isFocused: Bool
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $text)
                .font(.system(size: 15))
                .foregroundColor(Color.themeTextPrimary)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .focused($isFocused)
                .frame(minHeight: 40, maxHeight: 120)
                .padding(.top, 8)
                .padding(.bottom, 2)
                .padding(.horizontal, 4)
            
            if text.isEmpty && !isFocused {
                Text("что сегодня тут напишешь?")
                    .font(.system(size: 15))
                    .foregroundColor(Color.themeTextSecondary)
                    .padding(.leading, 8)
                    .padding(.top, 10)
                    .allowsHitTesting(false)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.themeBlockBackground.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            Color.themeBorder.opacity(0.6),
                            lineWidth: 0.5
                        )
                )
        )
    }
}

