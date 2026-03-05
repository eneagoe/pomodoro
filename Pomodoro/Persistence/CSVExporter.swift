import Foundation
import AppKit
import UniformTypeIdentifiers

enum CSVExporter {
    static func export(sessions: [PomodoroSession]) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [UTType.commaSeparatedText]
        panel.nameFieldStringValue = "pomodoro_log.csv"
        panel.title = "Export Pomodoro Log"

        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            try buildCSV(from: sessions).write(to: url, atomically: true, encoding: .utf8)
        } catch {
            let alert = NSAlert()
            alert.messageText = "Export Failed"
            alert.informativeText = error.localizedDescription
            alert.runModal()
        }
    }

    private static func buildCSV(from sessions: [PomodoroSession]) -> String {
        let fmt = ISO8601DateFormatter()
        var lines = ["id,session_type,started_at,ended_at,duration_seconds,completed,note"]
        for s in sessions {
            let id = s.id.map(String.init) ?? ""
            let note = s.note.contains(",") || s.note.contains("\"") || s.note.contains("\n")
                ? "\"\(s.note.replacingOccurrences(of: "\"", with: "\"\""))\""
                : s.note
            lines.append("\(id),\(s.sessionType),\(fmt.string(from: s.startedAt)),\(fmt.string(from: s.endedAt)),\(s.durationSeconds),\(s.completed),\(note)")
        }
        return lines.joined(separator: "\n")
    }
}
