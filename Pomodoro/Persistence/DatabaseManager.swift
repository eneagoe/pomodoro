import Foundation
import GRDB

final class DatabaseManager {
    static let shared = DatabaseManager()

    private var dbQueue: DatabaseQueue!

    private init() {
        setupDatabase()
    }

    private func setupDatabase() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("Pomodoro")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let path = dir.appendingPathComponent("pomodoro.db").path

        do {
            dbQueue = try DatabaseQueue(path: path)
            try runMigrations()
        } catch {
            print("DB setup error: \(error)")
        }
    }

    private func runMigrations() throws {
        var migrator = DatabaseMigrator()
        migrator.registerMigration("v1") { db in
            try db.create(table: "sessions") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("sessionType", .text).notNull()
                t.column("startedAt", .datetime).notNull()
                t.column("endedAt", .datetime).notNull()
                t.column("durationSeconds", .integer).notNull()
                t.column("completed", .boolean).notNull()
            }
        }
        migrator.registerMigration("v2") { db in
            try db.alter(table: "sessions") { t in
                t.add(column: "note", .text).notNull().defaults(to: "")
            }
        }
        try migrator.migrate(dbQueue)
    }

    // MARK: - Writes

    func insert(session: PomodoroSession) throws {
        var s = session
        try dbQueue.write { db in
            try s.insert(db)
        }
    }

    // MARK: - Reads

    func todaySessions() throws -> [PomodoroSession] {
        let cal = Calendar.current
        let start = cal.startOfDay(for: Date())
        let end = cal.date(byAdding: .day, value: 1, to: start)!
        return try dbQueue.read { db in
            try PomodoroSession
                .filter(Column("startedAt") >= start && Column("startedAt") < end)
                .order(Column("startedAt"))
                .fetchAll(db)
        }
    }

    func weekSessions() throws -> [PomodoroSession] {
        let cal = Calendar.current
        let start = cal.startOfDay(for: cal.date(byAdding: .day, value: -6, to: Date())!)
        return try dbQueue.read { db in
            try PomodoroSession
                .filter(Column("startedAt") >= start)
                .order(Column("startedAt"))
                .fetchAll(db)
        }
    }

    func allSessions() throws -> [PomodoroSession] {
        try dbQueue.read { db in
            try PomodoroSession.order(Column("startedAt")).fetchAll(db)
        }
    }

    func lastWorkNote() throws -> String {
        try dbQueue.read { db in
            try PomodoroSession
                .filter(Column("sessionType") == SessionType.work.rawValue && Column("completed") == true)
                .order(Column("startedAt").desc)
                .fetchOne(db)?
                .note ?? ""
        }
    }

    // MARK: - Aggregates

    struct DailyStats: Identifiable {
        let id: Date
        var date: Date { id }
        let completedPomodoros: Int
        let cancelledPomodoros: Int
        let totalFocusMinutes: Int
    }

    func dailyStats(for sessions: [PomodoroSession]) -> [DailyStats] {
        let cal = Calendar.current
        let workSessions = sessions.filter { $0.sessionType == SessionType.work.rawValue }
        let grouped = Dictionary(grouping: workSessions) { cal.startOfDay(for: $0.startedAt) }
        return grouped.map { date, items in
            let completed = items.filter { $0.completed }
            let cancelled = items.filter { !$0.completed }
            return DailyStats(
                id: date,
                completedPomodoros: completed.count,
                cancelledPomodoros: cancelled.count,
                totalFocusMinutes: completed.reduce(0) { $0 + $1.durationSeconds } / 60
            )
        }.sorted { $0.date < $1.date }
    }

    func currentStreak(from sessions: [PomodoroSession]) -> Int {
        let cal = Calendar.current
        let days = Set(
            sessions
                .filter { $0.sessionType == SessionType.work.rawValue && $0.completed }
                .map { cal.startOfDay(for: $0.startedAt) }
        )
        var streak = 0
        var day = cal.startOfDay(for: Date())
        while days.contains(day) {
            streak += 1
            day = cal.date(byAdding: .day, value: -1, to: day)!
        }
        return streak
    }

    func bestStreak(from sessions: [PomodoroSession]) -> Int {
        let cal = Calendar.current
        let days = Set(
            sessions
                .filter { $0.sessionType == SessionType.work.rawValue && $0.completed }
                .map { cal.startOfDay(for: $0.startedAt) }
        ).sorted()

        guard !days.isEmpty else { return 0 }
        var best = 1
        var current = 1
        for i in 1..<days.count {
            let diff = cal.dateComponents([.day], from: days[i - 1], to: days[i]).day ?? 0
            if diff == 1 {
                current += 1
                best = max(best, current)
            } else {
                current = 1
            }
        }
        return best
    }
}
