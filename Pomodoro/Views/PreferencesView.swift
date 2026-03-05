import SwiftUI

struct PreferencesView: View {
    @ObservedObject private var prefs = Preferences.shared

    var body: some View {
        Form {
            Section("Durations (minutes)") {
                Stepper("Work: \(prefs.workDuration)", value: $prefs.workDuration, in: 1...60)
                Stepper("Short Break: \(prefs.shortBreakDuration)", value: $prefs.shortBreakDuration, in: 1...30)
                Stepper("Long Break: \(prefs.longBreakDuration)", value: $prefs.longBreakDuration, in: 1...60)
            }

            Section("Session") {
                Stepper(
                    "Pomodoros before long break: \(prefs.pomodorosBeforeLongBreak)",
                    value: $prefs.pomodorosBeforeLongBreak,
                    in: 1...10
                )
            }

            Section("Notifications") {
                Toggle("Sound enabled", isOn: $prefs.soundEnabled)
            }

            Section("Keyboard Shortcuts") {
                LabeledContent("Start") {
                    KeyRecorderButton(config: $prefs.hotkeyStart)
                }
                LabeledContent("Interrupt") {
                    KeyRecorderButton(config: $prefs.hotkeyPause)
                }
                LabeledContent("Resume") {
                    KeyRecorderButton(config: $prefs.hotkeyResume)
                }
            }
        }
        .formStyle(.grouped)
    }
}
