import SwiftUI
import Charts

struct StatsView: View {
    @State private var todaySessions: [PomodoroSession] = []
    @State private var weekSessions: [PomodoroSession] = []
    @State private var allSessions: [PomodoroSession] = []

    private var db: DatabaseManager { .shared }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {

                // Daily
                GroupBox {
                    HStack(spacing: 0) {
                        StatItem(label: "Completed", value: "\(todayCompleted)")
                        Divider().frame(height: 36)
                        StatItem(label: "Cancelled", value: "\(todayCancelled)")
                        Divider().frame(height: 36)
                        StatItem(label: "Focus time", value: "\(todayMinutes) min")
                    }
                } label: {
                    Label("Today", systemImage: "sun.max")
                }

                // Weekly chart
                GroupBox {
                    let data = db.dailyStats(for: weekSessions)
                    if data.isEmpty {
                        Text("No sessions this week yet.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .frame(height: 80)
                    } else {
                        Chart {
                            ForEach(data) { item in
                                BarMark(
                                    x: .value("Day", item.date, unit: .day),
                                    y: .value("Pomodoros", item.completedPomodoros)
                                )
                                .foregroundStyle(.red)
                                BarMark(
                                    x: .value("Day", item.date, unit: .day),
                                    y: .value("Pomodoros", item.cancelledPomodoros)
                                )
                                .foregroundStyle(.gray.opacity(0.4))
                            }
                        }
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .day)) {
                                AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                            }
                        }
                        .chartYAxis {
                            AxisMarks(position: .leading)
                        }
                        .frame(height: 80)
                    }
                } label: {
                    Label("Last 7 Days", systemImage: "chart.bar")
                }

                // All-time
                GroupBox {
                    VStack(spacing: 8) {
                        HStack(spacing: 0) {
                            StatItem(label: "Completed", value: "\(allCompleted)")
                            Divider().frame(height: 36)
                            StatItem(label: "Cancelled", value: "\(allCancelled)")
                            Divider().frame(height: 36)
                            StatItem(label: "Hours", value: String(format: "%.1f", Double(allFocusSeconds) / 3600))
                        }
                        Divider()
                        HStack(spacing: 0) {
                            StatItem(label: "Streak", value: "\(currentStreak)d")
                            Divider().frame(height: 36)
                            StatItem(label: "Best streak", value: "\(bestStreak)d")
                        }
                    }
                } label: {
                    Label("All Time", systemImage: "infinity")
                }

                // Export
                Button(action: exportCSV) {
                    Label("Export CSV…", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            .padding(12)
        }
        .onAppear(perform: loadData)
    }

    // MARK: - Actions

    private func loadData() {
        todaySessions = (try? db.todaySessions()) ?? []
        weekSessions = (try? db.weekSessions()) ?? []
        allSessions = (try? db.allSessions()) ?? []
    }

    private func exportCSV() {
        CSVExporter.export(sessions: allSessions)
    }

    // MARK: - Computed

    private var todayCompleted: Int {
        todaySessions.filter { $0.sessionType == SessionType.work.rawValue && $0.completed }.count
    }

    private var todayCancelled: Int {
        todaySessions.filter { $0.sessionType == SessionType.work.rawValue && !$0.completed }.count
    }

    private var todayMinutes: Int {
        todaySessions
            .filter { $0.sessionType == SessionType.work.rawValue && $0.completed }
            .reduce(0) { $0 + $1.durationSeconds } / 60
    }

    private var allCompleted: Int {
        allSessions.filter { $0.sessionType == SessionType.work.rawValue && $0.completed }.count
    }

    private var allCancelled: Int {
        allSessions.filter { $0.sessionType == SessionType.work.rawValue && !$0.completed }.count
    }

    private var allFocusSeconds: Int {
        allSessions
            .filter { $0.sessionType == SessionType.work.rawValue && $0.completed }
            .reduce(0) { $0 + $1.durationSeconds }
    }

    private var currentStreak: Int {
        db.currentStreak(from: allSessions)
    }

    private var bestStreak: Int {
        db.bestStreak(from: allSessions)
    }
}

private struct StatItem: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title3).bold()
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
