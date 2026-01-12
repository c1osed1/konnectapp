import SwiftUI

struct CreatePollData {
    var question: String = ""
    var options: [String] = ["", ""]
    var isMultipleChoice: Bool = false
    var isAnonymous: Bool = false
    var isTemporary: Bool = false
    var expiresInDays: Int = 7
}

struct CreatePollView: View {
    @Binding var isPresented: Bool
    @Binding var pollData: CreatePollData?
    @StateObject private var themeManager = ThemeManager.shared
    @State private var poll: CreatePollData = CreatePollData()
    
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
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Question field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Вопрос опроса")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color.themeTextPrimary)
                            
                            TextField("Введите вопрос", text: $poll.question)
                                .font(.system(size: 15))
                                .foregroundColor(Color.themeTextPrimary)
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.themeBlockBackground.opacity(0.5))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.themeBorder.opacity(0.6), lineWidth: 0.5)
                                        )
                                )
                        }
                        
                        // Options
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Варианты ответа")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(Color.themeTextPrimary)
                                
                                Spacer()
                                
                                if poll.options.count < 10 {
                                    Button(action: {
                                        poll.options.append("")
                                    }) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 20))
                                            .foregroundColor(Color.appAccent)
                                    }
                                }
                            }
                            
                            ForEach(0..<poll.options.count, id: \.self) { index in
                                HStack(spacing: 8) {
                                    TextField("Вариант \(index + 1)", text: $poll.options[index])
                                        .font(.system(size: 15))
                                        .foregroundColor(Color.themeTextPrimary)
                                        .padding(12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color.themeBlockBackground.opacity(0.5))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .stroke(Color.themeBorder.opacity(0.6), lineWidth: 0.5)
                                                )
                                        )
                                    
                                    if poll.options.count > 2 {
                                        Button(action: {
                                            poll.options.remove(at: index)
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.system(size: 20))
                                                .foregroundColor(Color.themeTextSecondary.opacity(0.6))
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Settings
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Настройки")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color.themeTextPrimary)
                            
                            // Multiple choice
                            Toggle(isOn: $poll.isMultipleChoice) {
                                Text("Множественный выбор")
                                    .font(.system(size: 15))
                                    .foregroundColor(Color.themeTextPrimary)
                            }
                            .tint(Color.appAccent)
                            
                            // Anonymous
                            Toggle(isOn: $poll.isAnonymous) {
                                Text("Анонимный опрос")
                                    .font(.system(size: 15))
                                    .foregroundColor(Color.themeTextPrimary)
                            }
                            .tint(Color.appAccent)
                            
                            // Temporary poll
                            Toggle(isOn: $poll.isTemporary) {
                                Text("Временный опрос")
                                    .font(.system(size: 15))
                                    .foregroundColor(Color.themeTextPrimary)
                            }
                            .tint(Color.appAccent)
                            
                            // Expiration (only if temporary)
                            if poll.isTemporary {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Срок действия: \(poll.expiresInDays) дней")
                                        .font(.system(size: 15))
                                        .foregroundColor(Color.themeTextPrimary)
                                    
                                    Slider(value: Binding(
                                        get: { Double(poll.expiresInDays) },
                                        set: { poll.expiresInDays = Int($0) }
                                    ), in: 1...30, step: 1)
                                    .tint(Color.appAccent)
                                }
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.themeBlockBackground.opacity(0.5))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.themeBorder.opacity(0.6), lineWidth: 0.5)
                                )
                        )
                    }
                    .padding()
                }
            }
            .navigationTitle("Создать опрос")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") {
                        isPresented = false
                    }
                    .foregroundColor(Color.themeTextPrimary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") {
                        if isValidPoll() {
                            // Filter out empty options before saving
                            var cleanedPoll = poll
                            let allOptions = poll.options
                            cleanedPoll.options = allOptions.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                            
                            print("📋 CREATE POLL DEBUG:")
                            print("  Original options count: \(allOptions.count)")
                            print("  Original options: \(allOptions)")
                            print("  Cleaned options count: \(cleanedPoll.options.count)")
                            print("  Cleaned options: \(cleanedPoll.options)")
                            print("  Question: '\(cleanedPoll.question)'")
                            print("  isMultipleChoice: \(cleanedPoll.isMultipleChoice)")
                            print("  isAnonymous: \(cleanedPoll.isAnonymous)")
                            print("  isTemporary: \(cleanedPoll.isTemporary)")
                            if cleanedPoll.isTemporary {
                                print("  expiresInDays: \(cleanedPoll.expiresInDays)")
                            }
                            
                            pollData = cleanedPoll
                            isPresented = false
                        } else {
                            print("❌ Poll validation failed:")
                            print("  Question empty: \(poll.question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)")
                            let validOptions = poll.options.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                            print("  Valid options count: \(validOptions.count)")
                            print("  All options: \(poll.options)")
                        }
                    }
                    .foregroundColor(isValidPoll() ? Color.appAccent : Color.themeTextSecondary)
                    .disabled(!isValidPoll())
                }
            }
        }
    }
    
    private func isValidPoll() -> Bool {
        guard !poll.question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return false
        }
        
        let validOptions = poll.options.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        return validOptions.count >= 2
    }
}
