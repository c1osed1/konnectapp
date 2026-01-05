import SwiftUI

struct LoginView: View {
    @StateObject private var authManager = AuthManager.shared
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var showPassword: Bool = false
    @State private var errorMessage: String?
    @FocusState private var focusedField: Field?
    
    enum Field {
        case username, password
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.06, green: 0.06, blue: 0.06),
                        Color(red: 0.1, green: 0.1, blue: 0.1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        Spacer().frame(height: geometry.size.height * 0.08)
                        logoSection.padding(.bottom, 40)
                        loginForm.padding(.horizontal, 24).padding(.bottom, 40)
                        Spacer()
                    }
                }
            }
        }
        .onAppear {
            errorMessage = nil
        }
        .onSubmit {
            if focusedField == .username {
                focusedField = .password
            } else if focusedField == .password {
                Task { await performLogin() }
            }
        }
    }
    
    private var logoSection: some View {
        VStack(spacing: 16) {
            Group {
                if let svgPath = Bundle.main.path(forResource: "newlogo2025", ofType: "svg"),
                   let svgString = try? String(contentsOfFile: svgPath, encoding: .utf8) {
                    SVGView(svgString: svgString)
                        .frame(width: 120, height: 120)
                } else if let svgPath = Bundle.main.path(forResource: "newlogo2025", ofType: "svg", inDirectory: nil),
                          let svgString = try? String(contentsOfFile: svgPath, encoding: .utf8) {
                    SVGView(svgString: svgString)
                        .frame(width: 120, height: 120)
                } else if let image = UIImage(named: "newlogo2025") {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else {
                    SVGView(svgString: """
                    <svg width="417" height="413" viewBox="0 0 417 413" fill="none" xmlns="http://www.w3.org/2000/svg">
                    <g clip-path="url(#clip0_2685_294)">
                    <path fill-rule="evenodd" clip-rule="evenodd" d="M5.64939 332.325L3.04267 373.644C1.60174 396.495 18.9574 414.333 41.8118 413.49L83.1876 412.017C86.0662 366.373 51.3549 330.698 5.64939 332.325ZM16.0743 167.047L10.8618 249.686C102.128 246.408 171.715 317.928 165.966 409.098L248.716 406.151C257.383 269.189 153.222 162.135 16.0743 167.047ZM370.296 401.794L331.496 403.176C343.01 220.601 204.138 77.8714 21.2887 84.352L23.7331 45.6042C25.2958 20.8246 48.3051 0.795403 72.8278 2.66311C262.876 17.2094 405.258 163.546 414.593 353.922C415.789 378.487 395.109 400.91 370.296 401.794Z" fill="#B69DF8"/>
                    </g>
                    <defs>
                    <clipPath id="clip0_2685_294">
                    <rect width="417" height="413" fill="white"/>
                    </clipPath>
                    </defs>
                    </svg>
                    """)
                        .frame(width: 120, height: 120)
                }
            }
            .frame(maxWidth: 120, maxHeight: 120)
            .shadow(color: Color(red: 0.82, green: 0.74, blue: 1.0).opacity(0.3), radius: 20, x: 0, y: 10)
            
            Text("Коннект")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text("Будущее за нами")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(red: 0.83, green: 0.83, blue: 0.83))
        }
    }
    
    private var loginForm: some View {
        VStack(spacing: 20) {
            VStack(spacing: 24) {
                usernameField
                passwordField
                if let error = errorMessage {
                    errorView(message: error)
                }
                loginButton
            }
            .padding(28)
            .background(
                RoundedRectangle(cornerRadius: 23)
                    .fill(Color(red: 0.13, green: 0.13, blue: 0.13))
                    .background(
                        RoundedRectangle(cornerRadius: 23)
                            .fill(.ultraThinMaterial)
                    )
            )
            .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
        }
    }
    
    private var usernameField: some View {
        HStack {
            Image(systemName: "person.fill")
                .foregroundColor(Color(red: 0.82, green: 0.74, blue: 1.0))
                .frame(width: 20)
            
            TextField("", text: $username, prompt: Text("Имя пользователя или email").foregroundColor(Color(red: 0.47, green: 0.47, blue: 0.47)))
                .textContentType(.username)
                .autocapitalization(.none)
                .autocorrectionDisabled()
                .keyboardType(.emailAddress)
                .focused($focusedField, equals: .username)
                .foregroundColor(.white)
                .font(.system(size: 16))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(red: 0.2, green: 0.2, blue: 0.2))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(focusedField == .username ? Color(red: 0.82, green: 0.74, blue: 1.0) : Color.clear, lineWidth: 2)
        )
    }
    
    private var passwordField: some View {
        HStack {
            Image(systemName: "lock.fill")
                .foregroundColor(Color(red: 0.82, green: 0.74, blue: 1.0))
                .frame(width: 20)
            
            if showPassword {
                EnglishPasswordField(text: $password, placeholder: "Пароль")
            } else {
                EnglishSecureField(text: $password, placeholder: "Пароль")
            }
            
            Button(action: { showPassword.toggle() }) {
                Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                    .foregroundColor(Color(red: 0.82, green: 0.74, blue: 1.0))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(red: 0.2, green: 0.2, blue: 0.2))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(focusedField == .password ? Color(red: 0.82, green: 0.74, blue: 1.0) : Color.clear, lineWidth: 2)
        )
    }
    
    private func errorView(message: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(Color(red: 0.96, green: 0.26, blue: 0.21))
                .font(.system(size: 18))
            
            Text(message)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(red: 0.96, green: 0.26, blue: 0.21))
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(red: 0.96, green: 0.26, blue: 0.21).opacity(0.1))
        )
    }
    
    private var loginButton: some View {
        Button(action: {
            Task { await performLogin() }
        }) {
            HStack {
                if authManager.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Войти")
                        .font(.system(size: 18, weight: .semibold))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.82, green: 0.74, blue: 1.0),
                        Color(red: 0.75, green: 0.65, blue: 0.95)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.black)
            .cornerRadius(23)
            .shadow(color: Color(red: 0.82, green: 0.74, blue: 1.0).opacity(0.4), radius: 15, x: 0, y: 8)
        }
        .disabled(authManager.isLoading || username.isEmpty || password.isEmpty)
        .opacity((authManager.isLoading || username.isEmpty || password.isEmpty) ? 0.6 : 1.0)
        .buttonStyle(PlainButtonStyle())
    }
    
    private func performLogin() async {
        errorMessage = nil
        focusedField = nil
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        
        guard !username.isEmpty, !password.isEmpty else {
            errorMessage = "Заполните все поля"
            return
        }
        
        do {
            try await authManager.login(
                username: username.trimmingCharacters(in: .whitespacesAndNewlines),
                password: password
            )
        } catch {
            print("❌ Login error caught in view: \(error)")
            if let authError = error as? AuthError {
                errorMessage = authError.errorDescription
            } else {
                let errorDesc = error.localizedDescription
                print("Error description: \(errorDesc)")
                errorMessage = "Ошибка входа: \(errorDesc)"
            }
        }
    }
}

#Preview {
    LoginView()
}

