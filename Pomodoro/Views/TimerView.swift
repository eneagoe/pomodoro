import SwiftUI

struct TimerView: View {
    @EnvironmentObject var timer: PomodoroTimer
    @State private var todayCount: Int = 0

    var body: some View {
        VStack(spacing: 16) {
            // Session label
            Text("\(timer.currentSession.emoji)  \(timer.currentSession.displayName)")
                .font(.headline)
                .foregroundColor(.secondary)

            // Progress ring + countdown
            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.15), lineWidth: 10)

                Circle()
                    .trim(from: 0, to: timer.progress)
                    .stroke(sessionColor, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: timer.progress)

                Text(timeString)
                    .font(.system(size: 40, weight: .bold, design: .monospaced))
            }
            .frame(width: 150, height: 150)

            // Note field (work sessions only)
            if timer.currentSession == .work {
                TextField("What are you working on?", text: $timer.currentNote)
                    .textFieldStyle(.roundedBorder)
                    .font(.callout)
                    .disabled(timer.state == .running)
                    .opacity(timer.state == .running ? 0.6 : 1)
            }

            // Pomodoro dots
            HStack(spacing: 8) {
                let total = Preferences.shared.pomodorosBeforeLongBreak
                let filled = timer.pomodoroCount % max(1, total)
                ForEach(0..<total, id: \.self) { i in
                    Circle()
                        .fill(i < filled ? Color.red : Color.secondary.opacity(0.25))
                        .frame(width: 9, height: 9)
                }
            }

            // Controls
            HStack(spacing: 20) {
                Button(action: timer.reset) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.title2)
                }
                .buttonStyle(.plain)
                .help("Reset")

                Button(action: toggleTimer) {
                    Image(systemName: timer.state == .running ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)

                Button(action: timer.skip) {
                    Image(systemName: "forward.end")
                        .font(.title2)
                }
                .buttonStyle(.plain)
                .help("Skip")
            }

            Text("Today: \(todayCount) pomodoro\(todayCount == 1 ? "" : "s")")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .onAppear { refreshTodayCount() }
        .onReceive(timer.$state) { newState in
            if newState == .idle { refreshTodayCount() }
        }
    }

    private func toggleTimer() {
        timer.state == .running ? timer.pause() : timer.start()
    }

    private var timeString: String {
        let m = timer.remainingSeconds / 60
        let s = timer.remainingSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }

    private var sessionColor: Color {
        switch timer.currentSession {
        case .work: return .red
        case .shortBreak: return .green
        case .longBreak: return .blue
        }
    }

    private func refreshTodayCount() {
        let sessions = (try? DatabaseManager.shared.todaySessions()) ?? []
        todayCount = sessions.filter { $0.sessionType == SessionType.work.rawValue && $0.completed }.count
    }
}
