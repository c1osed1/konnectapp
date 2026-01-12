import SwiftUI
import UIKit

struct AboutAppView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [
                        Color.themeBackgroundStart,
                        Color.themeBackgroundEnd
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 24) {
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
                                .frame(width: 120, height: 120)
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
                    .shadow(color: Color.appAccent.opacity(0.3), radius: 20, x: 0, y: 10)
                    .padding(.top, 40)
                    
                    Text("KonnectApp")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Color.themeTextPrimary)
                    
                    VStack(spacing: 12) {
                        InfoRow(
                            title: "Версия приложения",
                            value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.2.5"
                        )
                        InfoRow(title: "Разработчик", value: "qsoul")
                        InfoRow(title: "Правообладателям", value: "verif@k-connect.ru")
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    Spacer()
                }
            }
            .navigationTitle("О приложении")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") {
                        dismiss()
                    }
                    .foregroundColor(Color.themeTextPrimary)
                }
            }
        }
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 16))
                .foregroundColor(Color.themeTextSecondary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color.themeTextPrimary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.themeBlockBackground)
        )
    }
}

