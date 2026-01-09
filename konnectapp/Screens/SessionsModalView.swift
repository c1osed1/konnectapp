//
//  SessionsModalView.swift
//  konnectapp
//
//  Modal view for managing user sessions
//

import SwiftUI

struct SessionsModalView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authManager = AuthManager.shared
    @State private var sessions: [Session] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var deletingSessionId: Int64?
    
    var body: some View {
        NavigationView {
            ZStack {
                AppBackgroundView(backgroundURL: authManager.currentUser?.profile_background_url)
                
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color.appAccent))
                } else if let error = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundColor(.orange)
                        
                        Text("Ошибка загрузки")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(Color.themeTextPrimary)
                        
                        Text(error)
                            .font(.system(size: 14))
                            .foregroundColor(Color.themeTextSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                        
                        Button {
                            loadSessions()
                        } label: {
                            Text("Повторить")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(Color.appAccent)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal, 32)
                        .padding(.top, 8)
                    }
                } else if sessions.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "desktopcomputer")
                            .font(.system(size: 48))
                            .foregroundColor(Color.themeTextSecondary)
                        
                        Text("Нет активных сессий")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color.themeTextPrimary)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(sessions) { session in
                                SessionRow(
                                    session: session,
                                    isDeleting: deletingSessionId == session.id,
                                    onDelete: {
                                        deleteSession(sessionId: session.id)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle("Подключенные устройства")
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
        .task {
            loadSessions()
        }
    }
    
    private func loadSessions() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let loadedSessions = try await SessionService.shared.getSessions()
                await MainActor.run {
                    self.sessions = loadedSessions
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    private func deleteSession(sessionId: Int64) {
        deletingSessionId = sessionId
        
        Task {
            do {
                try await SessionService.shared.deleteSession(sessionId: sessionId)
                await MainActor.run {
                    sessions.removeAll { $0.id == sessionId }
                    deletingSessionId = nil
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    deletingSessionId = nil
                }
            }
        }
    }
}

struct SessionRow: View {
    let session: Session
    let isDeleting: Bool
    let onDelete: () -> Void
    
    @State private var showDeleteConfirmation = false
    
    private var deviceIcon: String {
        let device = session.device.lowercased()
        if device.contains("iphone") || device.contains("ios") {
            return "iphone"
        } else if device.contains("ipad") {
            return "ipad"
        } else if device.contains("mac") || device.contains("macos") {
            return "desktopcomputer"
        } else {
            return "desktopcomputer"
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Иконка устройства
            ZStack {
                Circle()
                    .fill(session.is_current ? Color.appAccent.opacity(0.2) : Color.themeBlockBackground)
                    .frame(width: 48, height: 48)
                
                Image(systemName: deviceIcon)
                    .font(.system(size: 22))
                    .foregroundColor(session.is_current ? Color.appAccent : Color.themeTextSecondary)
            }
            
            // Информация о сессии
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(session.device)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color.themeTextPrimary)
                    
                    if session.is_current {
                        Text("• Активная")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color.appAccent)
                    }
                }
                
                Text(session.browser)
                    .font(.system(size: 14))
                    .foregroundColor(Color.themeTextSecondary)
                
                HStack(spacing: 8) {
                    Text(session.ip_address)
                        .font(.system(size: 13))
                        .foregroundColor(Color.themeTextSecondary)
                    
                    Text("•")
                        .font(.system(size: 13))
                        .foregroundColor(Color.themeTextSecondary)
                    
                    Text(formatLastActivity(session.last_activity))
                        .font(.system(size: 13))
                        .foregroundColor(Color.themeTextSecondary)
                }
            }
            
            Spacer()
            
            // Кнопка удаления
            if !session.is_current {
                Button {
                    showDeleteConfirmation = true
                } label: {
                    if isDeleting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Color.themeTextSecondary))
                            .frame(width: 24, height: 24)
                    } else {
                        Image(systemName: "trash")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color.themeTextSecondary)
                    }
                }
                .frame(width: 40, height: 40)
                .disabled(isDeleting)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(session.is_current ? Color.appAccent.opacity(0.1) : Color.themeBlockBackground)
        )
        .alert("Завершить сессию?", isPresented: $showDeleteConfirmation) {
            Button("Отмена", role: .cancel) { }
            Button("Завершить", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("Сессия на устройстве \"\(session.device)\" будет завершена. Вы не сможете использовать это устройство для входа.")
        }
    }
    
    private func formatLastActivity(_ dateString: String) -> String {
        // Парсим дату в формате "09.01.2026 13:16"
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy HH:mm"
        formatter.locale = Locale(identifier: "ru_RU")
        
        if let date = formatter.date(from: dateString) {
            let now = Date()
            let timeInterval = now.timeIntervalSince(date)
            
            if timeInterval < 60 {
                return "только что"
            } else if timeInterval < 3600 {
                let minutes = Int(timeInterval / 60)
                return "\(minutes) мин. назад"
            } else if timeInterval < 86400 {
                let hours = Int(timeInterval / 3600)
                return "\(hours) ч. назад"
            } else {
                let days = Int(timeInterval / 86400)
                if days == 1 {
                    return "вчера"
                } else if days < 7 {
                    return "\(days) дн. назад"
                } else {
                    formatter.dateFormat = "dd MMM"
                    return formatter.string(from: date)
                }
            }
        }
        
        return dateString
    }
}

