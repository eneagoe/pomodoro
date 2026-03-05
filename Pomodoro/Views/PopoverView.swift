import SwiftUI

enum PopoverTab: String, CaseIterable {
    case timer = "Timer"
    case stats = "Stats"
    case preferences = "Prefs"
}

struct PopoverView: View {
    @EnvironmentObject var pomodoroTimer: PomodoroTimer
    @State private var selectedTab: PopoverTab = .timer

    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $selectedTab) {
                ForEach(PopoverTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 12)
            .padding(.top, 12)
            .padding(.bottom, 8)

            Divider()

            Group {
                switch selectedTab {
                case .timer:
                    TimerView()
                case .stats:
                    StatsView()
                case .preferences:
                    PreferencesView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 300, height: 420)
    }
}
