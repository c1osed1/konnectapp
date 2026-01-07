import SwiftUI

struct PostHeader: View {
    let user: PostUser
    let timestamp: String?
    @Binding var navigationPath: NavigationPath
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: {
                navigationPath.append(user.username)
            }) {
                Group {
                    let avatarURLString: String? = {
                        if let avatarURL = user.avatar_url {
                            return avatarURL
                        } else if let photo = user.photo {
                            if photo.hasPrefix("http") {
                                return photo
                            } else {
                                return "https://s3.k-connect.ru/static/uploads/avatar/\(user.id)/\(photo)"
                            }
                        }
                        return nil
                    }()
                    
                    if let avatarURLString = avatarURLString, let url = URL(string: avatarURLString) {
                        CachedAsyncImage(url: url, cacheType: .avatar)
                        .aspectRatio(contentMode: .fill)
                    } else {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.appAccent,
                                    Color(red: 0.75, green: 0.65, blue: 0.95)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    .overlay(
                        Text(String((user.name ?? user.username).prefix(1)))
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.black)
                    )
                    }
                }
                .frame(width: 44, height: 44)
                .clipShape(Circle())
            }
            
            Button(action: {
                navigationPath.append(user.username)
            }) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(user.name ?? user.username)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Color.themeTextPrimary)
                        
                        if user.is_verified == true {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 12))
                                .foregroundColor(Color.appAccent)
                        }
                    }
                    
                    Text("@\(user.username)")
                        .font(.system(size: 13))
                        .foregroundColor(Color.themeTextSecondary)
                }
            }
            
            Spacer()
            
            if let timestamp = timestamp {
                Text(formatDate(timestamp))
                    .font(.system(size: 12))
                    .foregroundColor(Color.themeTextSecondary)
            }
        }
    }
    
    private func formatDate(_ dateString: String) -> String {
        var date: Date?
        
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let parsedDate = isoFormatter.date(from: dateString) {
            date = parsedDate
        } else {
            isoFormatter.formatOptions = [.withInternetDateTime]
            if let parsedDate = isoFormatter.date(from: dateString) {
                date = parsedDate
            } else {
                let customFormatter = DateFormatter()
                customFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'"
                customFormatter.timeZone = TimeZone(secondsFromGMT: 0)
                if let parsedDate = customFormatter.date(from: dateString) {
                    date = parsedDate
                } else {
                    customFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
                    date = customFormatter.date(from: dateString)
                }
            }
        }
        
        guard let date = date else {
            print("⚠️ Failed to parse date: \(dateString)")
            return dateString
        }
        
        let calendar = Calendar.current
        let now = Date()
        let diff = now.timeIntervalSince(date)
        
        if diff < 60 {
            return "только что"
        } else if diff < 3600 {
            let minutes = Int(diff / 60)
            return "\(minutes) \(minutes == 1 ? "минуту" : minutes < 5 ? "минуты" : "минут") назад"
        } else if diff < 86400 {
            let hours = Int(diff / 3600)
            if hours == 1 {
                return "1 час назад"
            } else if hours < 5 {
                return "\(hours) часа назад"
            } else {
                return "\(hours) часов назад"
            }
        } else if calendar.isDateInYesterday(date) {
            return "вчера"
        } else {
            let days = Int(diff / 86400)
            if days < 7 {
                return "\(days) \(days == 1 ? "день" : days < 5 ? "дня" : "дней") назад"
            } else {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "d MMM"
                dateFormatter.locale = Locale(identifier: "ru_RU")
                return dateFormatter.string(from: date)
            }
        }
    }
}