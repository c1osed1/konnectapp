import SwiftUI

struct ToastView: View {
    let message: String
    @Binding var isPresented: Bool
    
    var body: some View {
        if isPresented {
            VStack {
                Spacer()
                
                Text(message)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(red: 0.2, green: 0.2, blue: 0.2).opacity(0.95))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        Color.appAccent.opacity(0.3),
                                        lineWidth: 0.5
                                    )
                            )
                    )
                    .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPresented)
        }
    }
}

struct ToastModifier: ViewModifier {
    @Binding var toastMessage: String?
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if let message = toastMessage {
                ToastView(message: message, isPresented: .constant(true))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            toastMessage = nil
                        }
                    }
            }
        }
    }
}

extension View {
    func toast(message: Binding<String?>) -> some View {
        modifier(ToastModifier(toastMessage: message))
    }
}

