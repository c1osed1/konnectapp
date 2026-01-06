import SwiftUI

struct CreatePostTextField: View {
    @Binding var text: String
    @FocusState private var isFocused: Bool
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $text)
                .font(.system(size: 15))
                .foregroundColor(.white)
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
                    .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.6))
                    .padding(.leading, 8)
                    .padding(.top, 10)
                    .allowsHitTesting(false)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(red: 0.13, green: 0.13, blue: 0.13).opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            Color.appAccent.opacity(0.2),
                            lineWidth: 1
                        )
                )
        )
    }
}

