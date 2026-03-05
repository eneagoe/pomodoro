import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func sendSessionEndNotification(for sessionType: SessionType) {
        let content = UNMutableNotificationContent()
        switch sessionType {
        case .work:
            content.title = "Pomodoro Complete!"
            content.body = "Time for a break. Well done!"
        case .shortBreak:
            content.title = "Break Over"
            content.body = "Ready to focus again?"
        case .longBreak:
            content.title = "Long Break Over"
            content.body = "Time to get back to it!"
        }
        content.sound = Preferences.shared.soundEnabled ? .default : nil

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }
}
