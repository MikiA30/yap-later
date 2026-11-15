import Foundation

/// Posts a nudge as a system notification so it is seen when the app is not in front.
protocol NudgeNotifier: Sendable {
    func requestPermission() async -> Bool
    func post(_ nudge: Nudge) async
}

/// Does nothing. For tests, previews, and until T003 adds the real one.
struct NoopNudgeNotifier: NudgeNotifier {
    func requestPermission() async -> Bool { false }
    func post(_ nudge: Nudge) async {}
}

import UserNotifications

/// Posts nudges through the system. iOS shows them when the app is not in front; in the app the banner covers it.
struct SystemNudgeNotifier: NudgeNotifier {
    func requestPermission() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])) ?? false
    }

    func post(_ nudge: Nudge) async {
        let content = UNMutableNotificationContent()
        content.title = "\(nudge.category.displayName) budget"
        content.body = nudge.message
        content.sound = .default
        let request = UNNotificationRequest(identifier: nudge.id.uuidString, content: content, trigger: nil)
        try? await UNUserNotificationCenter.current().add(request)
    }
}
