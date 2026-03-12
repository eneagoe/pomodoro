import Foundation
import Combine

enum TimerState: Equatable {
    case idle, running, paused, finished
}

final class PomodoroTimer: ObservableObject {
    static let shared = PomodoroTimer()

    @Published var state: TimerState = .idle
    @Published var currentSession: SessionType = .work
    @Published var remainingSeconds: Int = 0
    @Published var pomodoroCount: Int = 0
    @Published var currentNote: String = ""

    private var countdownTimer: Timer?
    private var interruptionTimer: Timer?
    private var sessionStartTime: Date?
    private var interruptionCount: Int = 0
    private var completedPomodoroDates: [Date] = []
    private var prefs: Preferences { .shared }

    private static let maxInterruptionSeconds: TimeInterval = 45
    private static let maxInterruptions: Int = 2
    private static let pomodoroSessionWindowBuffer: TimeInterval = 30 * 60

    /// Time to complete a full cycle back-to-back, plus a 30-minute buffer.
    private var pomodoroSessionWindow: TimeInterval {
        let n = prefs.pomodorosBeforeLongBreak
        let work = n * prefs.workDuration * 60
        let breaks = (n - 1) * prefs.shortBreakDuration * 60
        return TimeInterval(work + breaks) + Self.pomodoroSessionWindowBuffer
    }

    private init() {
        remainingSeconds = prefs.workDuration * 60
        loadLastWorkNote()
    }

    var totalSecondsForCurrentSession: Int {
        durationFor(session: currentSession)
    }

    var progress: Double {
        let total = totalSecondsForCurrentSession
        guard total > 0 else { return 0 }
        return 1.0 - Double(remainingSeconds) / Double(total)
    }

    func start() {
        guard state != .running else { return }
        if state == .idle || state == .finished {
            sessionStartTime = Date()
            interruptionCount = 0
        }
        interruptionTimer?.invalidate()
        interruptionTimer = nil
        state = .running
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    func pause() {
        guard state == .running else { return }
        interruptionCount += 1
        if interruptionCount > Self.maxInterruptions {
            cancelSession()
            return
        }
        state = .paused
        invalidateTimer()
        interruptionTimer = Timer.scheduledTimer(withTimeInterval: Self.maxInterruptionSeconds, repeats: false) { [weak self] _ in
            self?.cancelDueToLongInterruption()
        }
    }

    func reset() {
        cancelSession()
    }

    private func cancelDueToLongInterruption() {
        guard state == .paused else { return }
        cancelSession()
    }

    private func cancelSession() {
        if state == .running || state == .paused {
            logSession(completed: false)
        }
        invalidateTimer()
        interruptionTimer?.invalidate()
        interruptionTimer = nil
        interruptionCount = 0
        state = .idle
        sessionStartTime = nil
        remainingSeconds = totalSecondsForCurrentSession
    }

    func skip() {
        if state == .running || state == .paused {
            logSession(completed: false)
        }
        invalidateTimer()
        interruptionTimer?.invalidate()
        interruptionTimer = nil
        interruptionCount = 0
        advance()
    }

    private func tick() {
        if remainingSeconds > 0 {
            remainingSeconds -= 1
        } else {
            sessionCompleted()
        }
    }

    private func sessionCompleted() {
        invalidateTimer()
        state = .finished
        logSession(completed: true)

        let completedSession = currentSession
        if completedSession == .work {
            completedPomodoroDates.append(Date())
        }

        NotificationManager.shared.sendSessionEndNotification(for: completedSession)
        advance()

        // Auto-start break after a completed work session
        if completedSession == .work {
            start()
        }
    }

    private func recomputePomodoroCount() {
        let cutoff = Date().addingTimeInterval(-pomodoroSessionWindow)
        completedPomodoroDates = completedPomodoroDates.filter { $0 > cutoff }
        pomodoroCount = completedPomodoroDates.count
    }

    private func advance() {
        recomputePomodoroCount()
        let next = nextSessionType()
        currentSession = next
        remainingSeconds = durationFor(session: next)
        state = .idle
        sessionStartTime = nil
        if next == .work {
            loadLastWorkNote()
        }
    }

    private func nextSessionType() -> SessionType {
        switch currentSession {
        case .work:
            let longBreakEvery = prefs.pomodorosBeforeLongBreak
            if longBreakEvery > 0 && pomodoroCount > 0 && pomodoroCount % longBreakEvery == 0 {
                return .longBreak
            }
            return .shortBreak
        case .shortBreak, .longBreak:
            return .work
        }
    }

    private func durationFor(session: SessionType) -> Int {
        switch session {
        case .work: return prefs.workDuration * 60
        case .shortBreak: return prefs.shortBreakDuration * 60
        case .longBreak: return prefs.longBreakDuration * 60
        }
    }

    private func invalidateTimer() {
        countdownTimer?.invalidate()
        countdownTimer = nil
    }

    private func logSession(completed: Bool) {
        guard let start = sessionStartTime else { return }
        let end = Date()
        let duration = max(1, Int(end.timeIntervalSince(start)))
        let note = currentSession == .work ? currentNote : ""
        let session = PomodoroSession(
            id: nil,
            sessionType: currentSession.rawValue,
            startedAt: start,
            endedAt: end,
            durationSeconds: duration,
            completed: completed,
            note: note
        )
        DispatchQueue.global(qos: .utility).async {
            try? DatabaseManager.shared.insert(session: session)
        }
    }

    private func loadLastWorkNote() {
        DispatchQueue.global(qos: .utility).async {
            let note = (try? DatabaseManager.shared.lastWorkNote()) ?? ""
            DispatchQueue.main.async { self.currentNote = note }
        }
    }
}
