import Foundation
import GRDB

struct PomodoroSession: Codable, FetchableRecord, MutablePersistableRecord {
    var id: Int64?
    var sessionType: String
    var startedAt: Date
    var endedAt: Date
    var durationSeconds: Int
    var completed: Bool
    var note: String

    static let databaseTableName = "sessions"

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
