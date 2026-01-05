import Foundation

func cleanStatusText(_ text: String) -> String {
    var cleaned = text
    let pattern = "\\{[^}]*\\}"
    if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
        cleaned = regex.stringByReplacingMatches(in: cleaned, options: [], range: NSRange(location: 0, length: cleaned.utf16.count), withTemplate: "")
    }
    return cleaned.trimmingCharacters(in: .whitespaces)
}

