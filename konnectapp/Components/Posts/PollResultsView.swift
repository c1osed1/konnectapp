import SwiftUI

struct PollResultsView: View {
    let poll: Poll
    @Environment(\.dismiss) var dismiss
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
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
                    // Header
                    HStack {
                        Text("Результаты опроса")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(Color.themeTextPrimary)
                        
                        Spacer()
                        
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 18))
                                .foregroundColor(Color.themeTextPrimary)
                                .frame(width: 32, height: 32)
                                .background(
                                    Circle()
                                        .fill(Color.themeBlockBackground.opacity(0.5))
                                )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // Question
                    Text(poll.question)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color.themeTextPrimary)
                        .padding(.horizontal)
                    
                    // Total votes
                    if let totalVotes = poll.total_votes {
                        Text("Всего голосов: \(totalVotes)")
                            .font(.system(size: 14))
                            .foregroundColor(Color.themeTextSecondary)
                            .padding(.horizontal)
                    }
                    
                    // Options with voters
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(poll.options) { option in
                            PollResultOptionView(option: option, totalVotes: poll.total_votes ?? 0)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
        }
        .onAppear {
            print("📊 PollResultsView appeared with poll ID: \(poll.id), question: '\(poll.question)', options count: \(poll.options.count)")
        }
    }
}

struct PollResultOptionView: View {
    let option: PollOption
    let totalVotes: Int
    @StateObject private var themeManager = ThemeManager.shared
    
    private var percentage: Double {
        option.percentage ?? 0.0
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Option header
            HStack {
                Text(option.text)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color.themeTextPrimary)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Int(percentage))%")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color.appAccent)
                    
                    if let votesCount = option.votes_count {
                        Text("\(votesCount) \(pluralizeVotes(votesCount))")
                            .font(.system(size: 12))
                            .foregroundColor(Color.themeTextSecondary)
                    }
                }
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.themeBlockBackground.opacity(0.5))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.appAccent)
                        .frame(width: geometry.size.width * (percentage / 100.0), height: 8)
                }
            }
            .frame(height: 8)
            
            // Voters list
            if let voters = option.voters, !voters.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Проголосовали:")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color.themeTextSecondary)
                    
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(voters) { voter in
                            HStack(spacing: 10) {
                                AsyncImage(url: URL(string: voter.avatar_url ?? "")) { phase in
                                    switch phase {
                                    case .empty:
                                        Circle()
                                            .fill(Color.themeBlockBackground)
                                            .frame(width: 32, height: 32)
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 32, height: 32)
                                            .clipShape(Circle())
                                    case .failure:
                                        Circle()
                                            .fill(Color.themeBlockBackground)
                                            .frame(width: 32, height: 32)
                                    @unknown default:
                                        Circle()
                                            .fill(Color.themeBlockBackground)
                                            .frame(width: 32, height: 32)
                                    }
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(voter.name ?? voter.username)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(Color.themeTextPrimary)
                                    
                                    if let votedAt = voter.voted_at {
                                        Text(formatVoteDate(votedAt))
                                            .font(.system(size: 12))
                                            .foregroundColor(Color.themeTextSecondary)
                                    }
                                }
                                
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.themeBlockBackground.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.appAccent.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    private func pluralizeVotes(_ count: Int) -> String {
        let remainder = count % 10
        let remainder100 = count % 100
        
        if remainder100 >= 11 && remainder100 <= 19 {
            return "голосов"
        } else if remainder == 1 {
            return "голос"
        } else if remainder >= 2 && remainder <= 4 {
            return "голоса"
        } else {
            return "голосов"
        }
    }
    
    private func formatVoteDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let date = formatter.date(from: dateString) else {
            return dateString
        }
        
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.minute, .hour, .day], from: date, to: now)
        
        if let minutes = components.minute, minutes < 1 {
            return "только что"
        } else if let minutes = components.minute, minutes < 60 {
            return "\(minutes) мин назад"
        } else if let hours = components.hour, hours < 24 {
            return "\(hours) ч назад"
        } else if let days = components.day, days < 7 {
            return "\(days) дн назад"
        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "d MMM yyyy"
            dateFormatter.locale = Locale(identifier: "ru_RU")
            return dateFormatter.string(from: date)
        }
    }
}
