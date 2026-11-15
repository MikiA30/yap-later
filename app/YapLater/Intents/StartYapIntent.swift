import AppIntents
import Observation

/// Counts requests to start listening that came from outside the app (Action Button, Shortcuts, Siri).
@MainActor
@Observable
final class YapTrigger {
    static let shared = YapTrigger()
    var requests = 0
}

/// "Start a Yap": opens Yap Later already listening. Assign it to the Action Button in Settings.
struct StartYapIntent: AppIntent {
    static let title: LocalizedStringResource = "Start a Yap"
    static let description = IntentDescription("Opens Yap Later already listening, so you can say what you spent.")
    static let openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        YapTrigger.shared.requests += 1
        return .result()
    }
}

struct YapShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: StartYapIntent(),
                    phrases: ["Start a yap in \(.applicationName)", "Yap in \(.applicationName)"],
                    shortTitle: "Start a Yap",
                    systemImageName: "mic.fill")
    }
}
