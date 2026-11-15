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
