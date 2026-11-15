import SwiftUI

@main
struct YapLaterApp: App {
    init() {
        #if DEBUG
        setvbuf(stdout, nil, _IONBF, 0) // show print output immediately when launched from the Mac
        #endif
    }

    @State private var model = AppEnvironment.makeModel()

    var body: some Scene {
        WindowGroup {
            RootView(model: model)
                #if os(macOS)
                .frame(width: 430, height: 860) // the phone layout, in a fixed window
                .buttonStyle(.plain) // no default Mac bezels behind the icon buttons
                #endif
                .task {
                    #if DEBUG
                    if let scenario = AppEnvironment.scenario {
                        await DebugScenarios.run(scenario, model: model)
                    }
                    if let sentences = ProcessInfo.processInfo.environment["YAP_TRY"] {
                        // Debug: run "a|b|c" through the active interpreter and print what it proposes.
                        for whole in sentences.split(separator: "|").map(String.init) {
                          let parts = RambleSplitter.pieces(of: whole)
                          for sentence in (parts.isEmpty ? [whole] : parts) {
                            let result = try? await AppEnvironment.sharedInterpreter.interpret(InterpretationRequest(transcript: sentence))
                            print("YAPTRY \(sentence) => \(result.map { "\($0.kind.rawValue) amount=\($0.amount.map { String($0) } ?? "nil") category=\($0.category ?? "nil")" } ?? "error")")
                          }
                        }
                        print("YAPTRY-END")
                    }
                    if ProcessInfo.processInfo.environment["YAP_SYNC"] != nil {
                        // Debug: start a sync as if the user tapped Sync, and print what it reports.
                        model.startSync()
                        var last = ""
                        for _ in 0..<120 {
                            try? await Task.sleep(for: .milliseconds(500))
                            let now = model.syncStatus ?? "(idle)"
                            if now != last { print("YAPSYNC \(now) | entries \(model.entries.count)"); last = now }
                            if !model.isSyncing { break }
                        }
                        print("YAPSYNC-END")
                    }
                    if let typed = ProcessInfo.processInfo.environment["YAP_SUBMIT"] {
                        // Debug: send "a|b" through the whole app as typed yaps (this saves real entries).
                        for sentence in typed.split(separator: "|").map(String.init) {
                            model.submit(text: sentence)
                            try? await Task.sleep(for: .seconds(6))
                            print("YAPSUBMIT \(sentence) => phase \(model.phase), entries \(model.entries.count), total \(model.weekTotalCents)")
                        }
                        print("YAPSUBMIT-END")
                    }
                    #if canImport(TTSKit)
                    if let line = ProcessInfo.processInfo.environment["YAP_TTS"] {
                        // Debug: load the Argmax voice (downloading it once if needed) and speak a line.
                        let speaker = ArgmaxSpeaker()
                        speaker.prepare(download: true)
                        while !speaker.isReady { try? await Task.sleep(for: .milliseconds(300)) }
                        if line == "download-only" { print("YAPTTS-END"); exit(0) }
                        speaker.speak(line)
                        try? await Task.sleep(for: .seconds(12))
                        speaker.speak("Only fifty dollars left for groceries this week.")
                        try? await Task.sleep(for: .seconds(12))
                        // The microphone must still work right after the voice has played.
                        speaker.stop()
                        if ProcessInfo.processInfo.environment["YAP_TTS_MIC"] != nil { do {
                            try await AppEnvironment.sharedWhisper.prepare()
                            try await AppEnvironment.sharedWhisper.start { _ in }
                            try? await Task.sleep(for: .seconds(2))
                            let heard = try await AppEnvironment.sharedWhisper.stop()
                            print("YAPTTS microphone after voice: ok, heard \"\(heard)\"")
                        } catch { print("YAPTTS microphone after voice: FAILED \(error)") } }
                        print("YAPTTS-END")
                    }
                    #endif
                    if ProcessInfo.processInfo.environment["YAP_SPEECH_EVAL"] != nil {
                        print("YAPLATER-SPEECH-BEGIN\n" + (await SpeechEval.run(AppEnvironment.sharedWhisper)) + "\nYAPLATER-SPEECH-END")
                    }
                    if UserDefaults.standard.bool(forKey: "eval") || ProcessInfo.processInfo.environment["YAP_EVAL"] != nil {
                        // Score the active on-device model on the built-in utterances and print the report.
                        let interpreter = AppEnvironment.sharedInterpreter
                        print("YAPLATER-EVAL-BEGIN \(interpreter.name)\n" + (await InterpreterEval.run(interpreter)) + "\nYAPLATER-EVAL-END")
                    }
                    #endif
                    await model.prepare()
                }
        }
        #if os(macOS)
        .windowResizability(.contentSize)
        #endif
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
        let transcriber: any SpeechTranscriber = sharedWhisper
        #endif
        let interpreter = sharedInterpreter
        let store: any LedgerStore = (try? SwiftDataLedgerStore()) ?? InMemoryLedgerStore()
        return AppModel(transcriber: transcriber, interpreter: interpreter, store: store,
                        speaker: makeSpeaker(), notifier: SystemNudgeNotifier(),
                        reminders: EventKitReminderSaver(), reminderLog: ReminderLog())
    }

    /// The Argmax voice when its model is on the device (and `YAP_VOICE=system` is not set); otherwise the system voice.
    static func makeSpeaker() -> any Speaker {
        #if canImport(TTSKit)
        if ArgmaxSpeaker.isEnabled, ProcessInfo.processInfo.environment["YAP_VOICE"] != "system" {
            let speaker = ArgmaxSpeaker()
            speaker.prepare()
            return speaker
        }
        #endif
        return SystemSpeaker()
    }

    /// Sponsor model first (Bonsai 2 via llama.cpp, when its file is on the phone), then Apple's on-device
    /// model as a labeled fallback, then the mock (which makes the UI say MOCK).
    /// One speech recognizer for the whole app, so its model is loaded once.
    static let sharedWhisper = WhisperKitTranscriber()

    /// One interpreter for the whole app, so the model is loaded once.
    static let sharedInterpreter: any MoneyInterpreter = makeInterpreter()

    private static func makeInterpreter() -> any MoneyInterpreter {
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
