import SwiftUI

struct PostRepostButton: View {
    var body: some View {
        if #available(iOS 26.0, *) {
            Button(action: {}) {
                Image(systemName: "arrow.2.squarepath")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.glass)
            .buttonBorderShape(.roundedRectangle(radius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        Color(red: 0.82, green: 0.74, blue: 1.0).opacity(0.15),
                        lineWidth: 0.5
                    )
            )
            .disabled(true)
        } else {
            Button(action: {}) {
                Image(systemName: "arrow.2.squarepath")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.ultraThinMaterial.opacity(0.2))
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color(red: 0.1, green: 0.1, blue: 0.1).opacity(0.8))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(
                                        Color(red: 0.82, green: 0.74, blue: 1.0).opacity(0.15),
                                        lineWidth: 0.5
                                    )
                            )
                    )
            }
            .disabled(true)
        }
    }
}

