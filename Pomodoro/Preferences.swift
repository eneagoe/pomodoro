import Foundation
import Combine

final class Preferences: ObservableObject {
    static let shared = Preferences()

    @Published var workDuration: Int {
        didSet { UserDefaults.standard.set(workDuration, forKey: Keys.workDuration) }
    }
    @Published var shortBreakDuration: Int {
        didSet { UserDefaults.standard.set(shortBreakDuration, forKey: Keys.shortBreakDuration) }
    }
    @Published var longBreakDuration: Int {
        didSet { UserDefaults.standard.set(longBreakDuration, forKey: Keys.longBreakDuration) }
    }
    @Published var pomodorosBeforeLongBreak: Int {
        didSet { UserDefaults.standard.set(pomodorosBeforeLongBreak, forKey: Keys.pomodorosBeforeLongBreak) }
    }
    @Published var soundEnabled: Bool {
        didSet { UserDefaults.standard.set(soundEnabled, forKey: Keys.soundEnabled) }
    }
    @Published var hotkeyStart: HotkeyConfig {
        didSet { saveHotkey(hotkeyStart, forKey: Keys.hotkeyStart) }
    }
    @Published var hotkeyPause: HotkeyConfig {
        didSet { saveHotkey(hotkeyPause, forKey: Keys.hotkeyPause) }
    }
    @Published var hotkeyResume: HotkeyConfig {
        didSet { saveHotkey(hotkeyResume, forKey: Keys.hotkeyResume) }
    }

    private enum Keys {
        static let workDuration = "workDuration"
        static let shortBreakDuration = "shortBreakDuration"
        static let longBreakDuration = "longBreakDuration"
        static let pomodorosBeforeLongBreak = "pomodorosBeforeLongBreak"
        static let soundEnabled = "soundEnabled"
        static let hotkeyStart = "hotkeyStart"
        static let hotkeyPause = "hotkeyPause"
        static let hotkeyResume = "hotkeyResume"
    }

    private init() {
        let d = UserDefaults.standard
        workDuration = d.integer(forKey: Keys.workDuration).nonZero ?? 25
        shortBreakDuration = d.integer(forKey: Keys.shortBreakDuration).nonZero ?? 5
        longBreakDuration = d.integer(forKey: Keys.longBreakDuration).nonZero ?? 15
        pomodorosBeforeLongBreak = d.integer(forKey: Keys.pomodorosBeforeLongBreak).nonZero ?? 4
        soundEnabled = d.object(forKey: Keys.soundEnabled) as? Bool ?? true
        hotkeyStart  = Preferences.loadHotkey(forKey: Keys.hotkeyStart,  default: .defaultStart)
        hotkeyPause  = Preferences.loadHotkey(forKey: Keys.hotkeyPause,  default: .defaultPause)
        hotkeyResume = Preferences.loadHotkey(forKey: Keys.hotkeyResume, default: .defaultResume)
    }

    private func saveHotkey(_ config: HotkeyConfig, forKey key: String) {
        let data = try? JSONEncoder().encode(config)
        UserDefaults.standard.set(data, forKey: key)
    }

    private static func loadHotkey(forKey key: String, default fallback: HotkeyConfig) -> HotkeyConfig {
        guard let data = UserDefaults.standard.data(forKey: key),
              let config = try? JSONDecoder().decode(HotkeyConfig.self, from: data)
        else { return fallback }
        return config
    }
}

private extension Int {
    var nonZero: Int? { self == 0 ? nil : self }
}
