import Testing
import Foundation
@testable import YapLater

/// Fails the first `failures` requests, then behaves like the mock.
private actor FlakyInterpreter: MoneyInterpreter {
    nonisolated let isMock = true
    private var failures: Int
    private let inner = MockMoneyInterpreter(delay: .zero)

    init(failures: Int) { self.failures = failures }

    func interpret(_ request: InterpretationRequest) async throws -> MoneyProposal {
        if failures > 0 {
            failures -= 1
            throw InterpreterError.generationFailed("test failure")
        }
        return try await inner.interpret(request)
    }
}

@MainActor
struct ReliabilityTests {
    private func makeModel(interpreter: any MoneyInterpreter = MockMoneyInterpreter(delay: .zero),
                           undoWindow: Duration = .seconds(60)) -> AppModel {
        AppModel(transcriber: MockTranscriber(), interpreter: interpreter,
                 store: InMemoryLedgerStore(entries: [], budgets: []),
                 speaker: SilentSpeaker(), undoWindow: undoWindow)
    }

    @Test func aFailedInterpretationSavesNothingAndTheNextYapWorks() async {
        let model = makeModel(interpreter: FlakyInterpreter(failures: 1))
        await model.handle(text: "spent 50 on groceries", generation: 0)
        #expect(model.entries.isEmpty)
        guard case .failed = model.phase else { Issue.record("expected a failure message"); return }
        model.dismissFailure()
        #expect(model.phase == .idle)
        await model.handle(text: "spent 50 on groceries", generation: 0)
        #expect(model.entries.count == 1)
    }

    @Test func tappingSendTwiceSavesOneEntry() async {
        let model = makeModel()
        model.submit(text: "spent 50 on groceries")
        model.submit(text: "spent 50 on groceries")
        try? await Task.sleep(for: .milliseconds(300))
        #expect(model.entries.count == 1)
    }

    @Test func emptySpeechFailsGentlyAndRecovers() async {
        let model = makeModel()
        await model.handle(text: "   ", generation: 0)
        guard case .failed = model.phase else { Issue.record("expected a failure message"); return }
        #expect(model.entries.isEmpty)
        #expect(!model.isBusy)
    }

    @Test func undoDoesNothingAfterItsWindowCloses() async {
        let model = makeModel(undoWindow: .milliseconds(20))
        await model.handle(text: "spent 50 on groceries", generation: 0)
        try? await Task.sleep(for: .milliseconds(200))
        #expect(model.lastSaved == nil)
        model.undoLast()
        #expect(model.entries.count == 1)
    }

    @Test func undoTwiceRemovesOnlyTheLastEntry() async {
        let model = makeModel()
        await model.handle(text: "spent 12 on lunch", generation: 0)
        await model.handle(text: "spent 50 on groceries", generation: 0)
        model.undoLast()
        model.undoLast()
        #expect(model.entries.count == 1)
        #expect(model.entries.first?.category == .dining)
    }
}

#if canImport(TTSKit)
struct SpokenFormTests {
    @Test func moneyIsWrittenTheWayItIsSaid() {
        #expect(ArgmaxSpeaker.spokenForm(of: "Only $10 left for Groceries this week.") == "Only 10 dollars left for Groceries this week.")
        #expect(ArgmaxSpeaker.spokenForm(of: "Coffee budget is $6.50 a week.") == "Coffee budget is 6 dollars and 50 cents a week.")
        #expect(ArgmaxSpeaker.spokenForm(of: "$1,200 over") == "1200 dollars over")
        #expect(ArgmaxSpeaker.spokenForm(of: "How much was it?") == "How much was it?")
    }
}
#endif
