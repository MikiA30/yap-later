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
                    if UserDefaults.standard.bool(forKey: "eval") || ProcessInfo.processInfo.environment["YAP_EVAL"] != nil {
                        // Score the active on-device model on the built-in utterances and print the report.
                        let interpreter = AppEnvironment.makeInterpreter()
                        print("YAPLATER-EVAL-BEGIN \(interpreter.name)\n" + (await InterpreterEval.run(interpreter)) + "\nYAPLATER-EVAL-END")
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
        // Real services. Anything that cannot run for real falls back to a mock, and the UI says MOCK.
        #if targetEnvironment(simulator)
        let transcriber: any SpeechTranscriber = MockTranscriber()
        #else
        let transcriber: any SpeechTranscriber = WhisperKitTranscriber()
        #endif
        let interpreter = makeInterpreter()
        let store: any LedgerStore = (try? SwiftDataLedgerStore()) ?? InMemoryLedgerStore()
        return AppModel(transcriber: transcriber, interpreter: interpreter, store: store,
                        speaker: SystemSpeaker(), notifier: SystemNudgeNotifier())
    }

    /// Sponsor model first (Bonsai 2 via llama.cpp, when its file is on the phone), then Apple's on-device
    /// model as a labeled fallback, then the mock (which makes the UI say MOCK).
    static func makeInterpreter() -> any MoneyInterpreter {
        #if canImport(llama)
        if let url = BonsaiInterpreter.provisionedModel(), !UserDefaults.standard.bool(forKey: "noBonsai") {
            let bonsai = BonsaiInterpreter(modelURL: url)
            Task.detached(priority: .userInitiated) { await bonsai.prewarm() }
            return bonsai
        }
        #endif
        if FoundationModelsInterpreter.isAvailable {
            let onDevice = FoundationModelsInterpreter()
            onDevice.prewarm()
            return onDevice
        }
        return MockMoneyInterpreter()
    }
}
