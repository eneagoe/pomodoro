import Foundation

enum SessionType: String, CaseIterable {
    case work = "work"
    case shortBreak = "short_break"
    case longBreak = "long_break"

    var displayName: String {
        switch self {
        case .work: return "Work"
        case .shortBreak: return "Short Break"
        case .longBreak: return "Long Break"
        }
    }

    var emoji: String {
        switch self {
        case .work: return "🍅"
        case .shortBreak: return "☕"
        case .longBreak: return "🌿"
        }
    }
}
