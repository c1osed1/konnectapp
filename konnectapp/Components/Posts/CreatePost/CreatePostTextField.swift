import SwiftUI

struct CreatePostTextField: View {
    @Binding var text: String
    @FocusState private var isFocused: Bool
    
    var body: some View {
        TextEditor(text: $text)
            .font(.system(size: 15))
            .foregroundColor(.white)
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .focused($isFocused)
            .frame(minHeight: 40, maxHeight: 120)
            .padding(.top, 8)
            .padding(.bottom, 4)
            .padding(.horizontal, 4)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(red: 0.13, green: 0.13, blue: 0.13).opacity(0.5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                Color(red: 0.82, green: 0.74, blue: 1.0).opacity(0.2),
                                lineWidth: 1
                            )
                    )
            )
            .overlay(
                Group {
                    if text.isEmpty && !isFocused {
                        Text("Газ полный")
                            .font(.system(size: 15))
                            .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.6))
                            .padding(.leading, 12)
                            .padding(.top, 12)
                            .allowsHitTesting(false)
                    }
                },
                alignment: .topLeading
            )
    }
}

