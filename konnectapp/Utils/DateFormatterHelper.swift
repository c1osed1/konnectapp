import Foundation

struct DateFormatterHelper {
    static func formatRelativeTime(_ dateString: String) -> String {
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
            return "\(minutes) м."
        } else if diff < 86400 {
            let hours = Int(diff / 3600)
            return "\(hours) ч."
        } else if calendar.isDateInYesterday(date) {
            return "вчера"
        } else {
            let days = Int(diff / 86400)
            if days < 7 {
                return "\(days) д."
            } else {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "d MMM"
                dateFormatter.locale = Locale(identifier: "ru_RU")
                return dateFormatter.string(from: date)
            }
        }
    }
    
    static func formatTimeUntil(_ dateString: String) -> String {
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
        
        let now = Date()
        let diff = date.timeIntervalSince(now)
        
        if diff < 0 {
            return "истек"
        } else if diff < 3600 {
            let minutes = Int(diff / 60)
            if minutes < 1 {
                return "менее минуты"
            }
            return "еще \(minutes) \(pluralizeMinutes(minutes))"
        } else if diff < 86400 {
            let hours = Int(diff / 3600)
            return "еще \(hours) \(pluralizeHours(hours))"
        } else {
            let days = Int(diff / 86400)
            return "еще \(days) \(pluralizeDays(days))"
        }
    }
    
    private static func pluralizeMinutes(_ count: Int) -> String {
        let remainder = count % 10
        let remainder100 = count % 100
        
        if remainder100 >= 11 && remainder100 <= 19 {
            return "минут"
        } else if remainder == 1 {
            return "минута"
        } else if remainder >= 2 && remainder <= 4 {
            return "минуты"
        } else {
            return "минут"
        }
    }
    
    private static func pluralizeHours(_ count: Int) -> String {
        let remainder = count % 10
        let remainder100 = count % 100
        
        if remainder100 >= 11 && remainder100 <= 19 {
            return "часов"
        } else if remainder == 1 {
            return "час"
        } else if remainder >= 2 && remainder <= 4 {
            return "часа"
        } else {
            return "часов"
        }
    }
    
    private static func pluralizeDays(_ count: Int) -> String {
        let remainder = count % 10
        let remainder100 = count % 100
        
        if remainder100 >= 11 && remainder100 <= 19 {
            return "дней"
        } else if remainder == 1 {
            return "день"
        } else if remainder >= 2 && remainder <= 4 {
            return "дня"
        } else {
            return "дней"
        }
    }
}

