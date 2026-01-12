import SwiftUI

struct PollView: View {
    let poll: Poll
    let postId: Int64
    @StateObject private var themeManager = ThemeManager.shared
    @State private var localPoll: Poll
    @State private var isVoting: Bool = false
    @State private var selectedOptionIds: Set<Int64> = []
    
    init(poll: Poll, postId: Int64) {
        self.poll = poll
        self.postId = postId
        _localPoll = State(initialValue: poll)
        if let userVoteIds = poll.user_vote_option_ids {
            _selectedOptionIds = State(initialValue: Set(userVoteIds))
        }
    }
    
    @State private var pollResults: Poll?
    @State private var isLoadingResults: Bool = false
    @State private var isRemovingVote: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Question
            Text(poll.question)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Color.themeTextPrimary)
            
            // Options
            VStack(alignment: .leading, spacing: 6) {
                ForEach(localPoll.options) { option in
                    PollOptionView(
                        option: option,
                        isSelected: selectedOptionIds.contains(option.id),
                        isVoted: localPoll.user_voted ?? false,
                        isExpired: localPoll.is_expired ?? false,
                        isMultipleChoice: localPoll.is_multiple_choice ?? false,
                        onTap: {
                            handleOptionTap(optionId: option.id)
                        }
                    )
                }
            }
            
            // Footer info
            HStack {
                if let totalVotes = localPoll.total_votes {
                    Button(action: {
                        if !(localPoll.is_anonymous ?? true) {
                            Task {
                                await loadPollResults()
                            }
                        }
                    }) {
                        Text("\(totalVotes) \(pluralizeVotes(totalVotes))")
                            .font(.system(size: 12))
                            .foregroundColor(localPoll.is_anonymous ?? true ? Color.themeTextSecondary : Color.appAccent)
                    }
                    .disabled(localPoll.is_anonymous ?? true)
                }
                
                Spacer()
                
                if let expiresAt = poll.expires_at, !(localPoll.is_expired ?? false) {
                    Text(DateFormatterHelper.formatTimeUntil(expiresAt))
                        .font(.system(size: 12))
                        .foregroundColor(Color.themeTextSecondary)
                } else if localPoll.is_expired ?? false {
                    Text("Опрос завершен")
                        .font(.system(size: 12))
                        .foregroundColor(Color.themeTextSecondary)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.themeBlockBackground.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.appAccent.opacity(0.3), lineWidth: 1)
                )
        )
        .sheet(item: $pollResults) { results in
            PollResultsView(poll: results)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("PollVoteChanged"))) { notification in
            if let userInfo = notification.userInfo,
               let postId = userInfo["postId"] as? Int64,
               postId == self.postId,
               let updatedPoll = userInfo["poll"] as? Poll {
                localPoll = updatedPoll
                if let userVoteIds = updatedPoll.user_vote_option_ids {
                    selectedOptionIds = Set(userVoteIds)
                } else {
                    selectedOptionIds = []
                }
            }
        }
    }
    
    private func loadPollResults() async {
        guard !isLoadingResults else { return }
        guard !(localPoll.is_anonymous ?? true) else { return }
        
        isLoadingResults = true
        
        do {
            print("📊 Loading poll results for poll ID: \(poll.id)")
            let results = try await PollService.shared.getPollResults(pollId: poll.id)
            print("✅ Poll results loaded: question='\(results.question)', options count=\(results.options.count)")
            
            await MainActor.run {
                pollResults = results
                isLoadingResults = false
                print("✅ pollResults set, should show modal now")
            }
        } catch {
            print("❌ Error loading poll results: \(error.localizedDescription)")
            await MainActor.run {
                isLoadingResults = false
            }
        }
    }
    
    private func handleOptionTap(optionId: Int64) {
        guard !isVoting else { return }
        guard !(localPoll.is_expired ?? false) else { return }
        guard !(localPoll.user_voted ?? false) else { return }
        
        let isMultipleChoice = localPoll.is_multiple_choice ?? false
        
        if isMultipleChoice {
            if selectedOptionIds.contains(optionId) {
                selectedOptionIds.remove(optionId)
            } else {
                selectedOptionIds.insert(optionId)
            }
        } else {
            selectedOptionIds = [optionId]
        }
        
        // Vote immediately
        Task {
            await vote(optionIds: Array(selectedOptionIds))
        }
    }
    
    private func vote(optionIds: [Int64]) async {
        guard !isVoting else { return }
        guard !optionIds.isEmpty else { return }
        
        isVoting = true
        defer { isVoting = false }
        
        do {
            let updatedPoll = try await PollService.shared.vote(
                pollId: poll.id,
                optionIds: optionIds
            )
            
            await MainActor.run {
                localPoll = updatedPoll
                if let userVoteIds = updatedPoll.user_vote_option_ids {
                    selectedOptionIds = Set(userVoteIds)
                }
            }
        } catch {
            print("❌ Vote error: \(error.localizedDescription)")
            // Revert selection on error
            await MainActor.run {
                if let userVoteIds = poll.user_vote_option_ids {
                    selectedOptionIds = Set(userVoteIds)
                } else {
                    selectedOptionIds = []
                }
            }
        }
    }
    
    private func removeVote() async {
        guard !isRemovingVote else { return }
        guard !(localPoll.is_expired ?? false) else { return }
        
        isRemovingVote = true
        defer { isRemovingVote = false }
        
        do {
            let updatedPoll = try await PollService.shared.removeVote(pollId: poll.id)
            
            await MainActor.run {
                localPoll = updatedPoll
                selectedOptionIds = []
            }
        } catch {
            print("❌ Remove vote error: \(error.localizedDescription)")
        }
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
    
}

struct PollOptionView: View {
    let option: PollOption
    let isSelected: Bool
    let isVoted: Bool
    let isExpired: Bool
    let isMultipleChoice: Bool
    let onTap: () -> Void
    
    @StateObject private var themeManager = ThemeManager.shared
    
    private var percentage: Double {
        option.percentage ?? 0.0
    }
    
    private var canInteract: Bool {
        !isVoted && !isExpired
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                // Selection indicator
                ZStack {
                    if isMultipleChoice {
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(isSelected ? Color.appAccent : Color.themeBorder.opacity(0.6), lineWidth: 2)
                            .frame(width: 18, height: 18)
                        
                        if isSelected {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Color.appAccent)
                        }
                    } else {
                        Circle()
                            .stroke(isSelected ? Color.appAccent : Color.themeBorder.opacity(0.6), lineWidth: 2)
                            .frame(width: 18, height: 18)
                        
                        if isSelected {
                            Circle()
                                .fill(Color.appAccent)
                                .frame(width: 10, height: 10)
                        }
                    }
                }
                
                // Option text and progress
                VStack(alignment: .leading, spacing: 4) {
                    Text(option.text)
                        .font(.system(size: 14))
                        .foregroundColor(Color.themeTextPrimary)
                        .multilineTextAlignment(.leading)
                    
                    if isVoted || isExpired {
                        HStack(spacing: 6) {
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Color.themeBlockBackground.opacity(0.5))
                                        .frame(height: 5)
                                    
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Color.appAccent)
                                        .frame(width: geometry.size.width * (percentage / 100.0), height: 5)
                                }
                            }
                            .frame(height: 5)
                            
                            Text("\(Int(percentage))%")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Color.themeTextSecondary)
                                .frame(width: 35, alignment: .trailing)
                            
                            if let votesCount = option.votes_count {
                                Text("(\(votesCount))")
                                    .font(.system(size: 11))
                                    .foregroundColor(Color.themeTextSecondary.opacity(0.7))
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected && canInteract ? Color.appAccent.opacity(0.1) : Color.themeBlockBackground.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(
                                isSelected && canInteract ? Color.appAccent.opacity(0.5) : Color.themeBorder.opacity(0.3),
                                lineWidth: isSelected && canInteract ? 1.5 : 0.5
                            )
                    )
            )
        }
        .disabled(!canInteract)
        .opacity(canInteract ? 1.0 : 0.8)
    }
}
