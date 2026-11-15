import SwiftUI

@main
struct YapLaterApp: App {
    @State private var model = AppEnvironment.makeModel()

    var body: some Scene {
        WindowGroup {
            RootView(model: model)
                .task {
                    await model.prepare()
                    #if DEBUG
                    if let scenario = AppEnvironment.scenario {
                        await DebugScenarios.run(scenario, model: model)
                    }
                    #endif
                }
        }
    }
}

/// Chooses the real or mock services. The only place that knows which is which.
@MainActor
enum AppEnvironment {
    /// `-scenario <name>` on the command line (debug builds only).
    static var scenario: String? {
        #if DEBUG
        UserDefaults.standard.string(forKey: "scenario")
        #else
        nil
        #endif
    }

    static func makeModel() -> AppModel {
        #if DEBUG
        if let scenario {
            let seed = DebugScenarios.seed(for: scenario)
            return AppModel(transcriber: MockTranscriber(),
                            interpreter: MockMoneyInterpreter(),
                            store: InMemoryLedgerStore(entries: seed.entries, budgets: seed.budgets),
                            speaker: SilentSpeaker())
        }
        #endif
        return AppModel(transcriber: MockTranscriber(),
                        interpreter: MockMoneyInterpreter(),
                        store: InMemoryLedgerStore(),
                        speaker: SystemSpeaker())
    }
}
