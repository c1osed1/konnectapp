import SwiftUI

struct CommentView: View {
    let comment: Comment
    @Binding var navigationPath: NavigationPath
    @State private var isLiked: Bool
    @State private var likesCount: Int
    @State private var isLiking: Bool = false
    @State private var showReplies: Bool = false
    
    init(comment: Comment, navigationPath: Binding<NavigationPath>) {
        self.comment = comment
        self._navigationPath = navigationPath
        _isLiked = State(initialValue: comment.user_liked ?? false)
        _likesCount = State(initialValue: comment.likes_count ?? 0)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                if let user = comment.user {
                    Button {
                        navigationPath.append(user.username)
                    } label: {
                        AsyncImage(url: URL(string: user.avatar_url ?? "")) { phase in
                            switch phase {
                            case .empty:
                                Circle()
                                    .fill(Color(red: 0.2, green: 0.2, blue: 0.2))
                                    .frame(width: 40, height: 40)
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 40, height: 40)
                                    .clipShape(Circle())
                            case .failure:
                                Circle()
                                    .fill(Color(red: 0.2, green: 0.2, blue: 0.2))
                                    .frame(width: 40, height: 40)
                            @unknown default:
                                Circle()
                                    .fill(Color(red: 0.2, green: 0.2, blue: 0.2))
                                    .frame(width: 40, height: 40)
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    if let user = comment.user {
                        HStack(spacing: 6) {
                            Button {
                                navigationPath.append(user.username)
                            } label: {
                                Text(user.name ?? user.username)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Text("@\(user.username)")
                                .font(.system(size: 13))
                                .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.6))
                            
                            if let timestamp = comment.timestamp {
                                Text(formatRelativeTime(timestamp))
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                            }
                        }
                    }
                    
                    if let content = comment.content, !content.isEmpty {
                        Text(content)
                            .font(.system(size: 15))
                            .foregroundColor(.white)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    if let image = comment.image, let imageURL = URL(string: image) {
                        AsyncImage(url: imageURL) { phase in
                            switch phase {
                            case .empty:
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(red: 0.2, green: 0.2, blue: 0.2))
                                    .frame(height: 200)
                            case .success(let img):
                                img
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(maxHeight: 300)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            case .failure:
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(red: 0.2, green: 0.2, blue: 0.2))
                                    .frame(height: 200)
                            @unknown default:
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(red: 0.2, green: 0.2, blue: 0.2))
                                    .frame(height: 200)
                            }
                        }
                        .padding(.top, 4)
                    }
                    
                    HStack(spacing: 16) {
                        Button {
                            Task {
                                await toggleLike()
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: isLiked ? "heart.fill" : "heart")
                                    .font(.system(size: 14))
                                    .foregroundColor(isLiked ? .red : Color(red: 0.6, green: 0.6, blue: 0.6))
                                
                                if likesCount > 0 {
                                    Text("\(likesCount)")
                                        .font(.system(size: 13))
                                        .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.6))
                                }
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(isLiking)
                        
                        if let repliesCount = comment.replies_count, repliesCount > 0 {
                            Button {
                                showReplies.toggle()
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrowshape.turn.up.right")
                                        .font(.system(size: 14))
                                        .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.6))
                                    
                                    Text("\(repliesCount) ответ\(repliesCount == 1 ? "" : repliesCount < 5 ? "а" : "ов")")
                                        .font(.system(size: 13))
                                        .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.6))
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.top, 4)
                }
            }
            
            if showReplies, let replies = comment.replies, !replies.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(replies) { reply in
                        ReplyView(reply: reply, navigationPath: $navigationPath)
                            .padding(.leading, 52)
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding(.vertical, 8)
    }
    
    private func toggleLike() async {
        guard !isLiking else { return }
        
        isLiking = true
        defer { isLiking = false }
        
        let previousLiked = isLiked
        let previousCount = likesCount
        
        isLiked.toggle()
        if isLiked {
            likesCount += 1
        } else {
            likesCount = max(0, likesCount - 1)
        }
        
        do {
            let response = try await CommentService.shared.likeComment(commentId: comment.id)
            await MainActor.run {
                isLiked = response.liked
                likesCount = response.likesCount
            }
        } catch {
            await MainActor.run {
                isLiked = previousLiked
                likesCount = previousCount
            }
            print("❌ Comment like error: \(error.localizedDescription)")
        }
    }
    
    private func formatRelativeTime(_ timestamp: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: timestamp) else {
            return timestamp
        }
        
        let now = Date()
        let timeInterval = now.timeIntervalSince(date)
        
        if timeInterval < 60 {
            return "только что"
        } else if timeInterval < 3600 {
            let minutes = Int(timeInterval / 60)
            return "\(minutes) мин. назад"
        } else if timeInterval < 86400 {
            let hours = Int(timeInterval / 3600)
            return "\(hours) \(hours == 1 ? "час" : hours < 5 ? "часа" : "часов") назад"
        } else if timeInterval < 604800 {
            let days = Int(timeInterval / 86400)
            return "\(days) \(days == 1 ? "день" : days < 5 ? "дня" : "дней") назад"
        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "d MMM"
            dateFormatter.locale = Locale(identifier: "ru_RU")
            return dateFormatter.string(from: date)
        }
    }
}

struct ReplyView: View {
    let reply: Reply
    @Binding var navigationPath: NavigationPath
    @State private var isLiked: Bool
    @State private var likesCount: Int
    @State private var isLiking: Bool = false
    
    init(reply: Reply, navigationPath: Binding<NavigationPath>) {
        self.reply = reply
        self._navigationPath = navigationPath
        _isLiked = State(initialValue: reply.user_liked ?? false)
        _likesCount = State(initialValue: reply.likes_count ?? 0)
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if let user = reply.user {
                Button {
                    navigationPath.append(user.username)
                } label: {
                    AsyncImage(url: URL(string: user.avatar_url ?? "")) { phase in
                        switch phase {
                        case .empty:
                            Circle()
                                .fill(Color(red: 0.2, green: 0.2, blue: 0.2))
                                .frame(width: 32, height: 32)
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 32, height: 32)
                                .clipShape(Circle())
                        case .failure:
                            Circle()
                                .fill(Color(red: 0.2, green: 0.2, blue: 0.2))
                                .frame(width: 32, height: 32)
                        @unknown default:
                            Circle()
                                .fill(Color(red: 0.2, green: 0.2, blue: 0.2))
                                .frame(width: 32, height: 32)
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            VStack(alignment: .leading, spacing: 4) {
                if let user = reply.user {
                    HStack(spacing: 6) {
                        Button {
                            navigationPath.append(user.username)
                        } label: {
                            Text(user.name ?? user.username)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Text("@\(user.username)")
                            .font(.system(size: 12))
                            .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.6))
                        
                        if let timestamp = reply.timestamp {
                            Text(formatRelativeTime(timestamp))
                                .font(.system(size: 11))
                                .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                        }
                    }
                }
                
                if let content = reply.content, !content.isEmpty {
                    Text(content)
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                if let image = reply.image, let imageURL = URL(string: image) {
                    AsyncImage(url: imageURL) { phase in
                        switch phase {
                        case .empty:
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(red: 0.2, green: 0.2, blue: 0.2))
                                .frame(height: 150)
                        case .success(let img):
                            img
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        case .failure:
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(red: 0.2, green: 0.2, blue: 0.2))
                                .frame(height: 150)
                        @unknown default:
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(red: 0.2, green: 0.2, blue: 0.2))
                                .frame(height: 150)
                        }
                    }
                    .padding(.top, 4)
                }
                
                Button {
                    Task {
                        await toggleLike()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .font(.system(size: 13))
                            .foregroundColor(isLiked ? .red : Color(red: 0.6, green: 0.6, blue: 0.6))
                        
                        if likesCount > 0 {
                            Text("\(likesCount)")
                                .font(.system(size: 12))
                                .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.6))
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(isLiking)
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func toggleLike() async {
        guard !isLiking else { return }
        
        isLiking = true
        defer { isLiking = false }
        
        let previousLiked = isLiked
        let previousCount = likesCount
        
        isLiked.toggle()
        if isLiked {
            likesCount += 1
        } else {
            likesCount = max(0, likesCount - 1)
        }
        
        do {
            let response = try await CommentService.shared.likeComment(commentId: reply.id)
            await MainActor.run {
                isLiked = response.liked
                likesCount = response.likesCount
            }
        } catch {
            await MainActor.run {
                isLiked = previousLiked
                likesCount = previousCount
            }
            print("❌ Reply like error: \(error.localizedDescription)")
        }
    }
    
    private func formatRelativeTime(_ timestamp: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: timestamp) else {
            return timestamp
        }
        
        let now = Date()
        let timeInterval = now.timeIntervalSince(date)
        
        if timeInterval < 60 {
            return "только что"
        } else if timeInterval < 3600 {
            let minutes = Int(timeInterval / 60)
            return "\(minutes) мин. назад"
        } else if timeInterval < 86400 {
            let hours = Int(timeInterval / 3600)
            return "\(hours) \(hours == 1 ? "час" : hours < 5 ? "часа" : "часов") назад"
        } else if timeInterval < 604800 {
            let days = Int(timeInterval / 86400)
            return "\(days) \(days == 1 ? "день" : days < 5 ? "дня" : "дней") назад"
        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "d MMM"
            dateFormatter.locale = Locale(identifier: "ru_RU")
            return dateFormatter.string(from: date)
        }
    }
}

