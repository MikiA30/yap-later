import Foundation
import Observation

/// Drives one yap: listen → interpret → entry. T009 replaces the mock services and adds validation and storage.
@MainActor
@Observable
final class YapModel {
    enum Phase: Equatable {
        case idle
        case listening
        case thinking(transcript: String)
        case failed(message: String)
    }

    private(set) var phase: Phase = .idle
    private(set) var entries: [Entry] = []
    private(set) var lastAddedID: UUID?

    let usesMocks: Bool
    private let transcriber: any SpeechTranscriber
    private let interpreter: any MoneyInterpreter
    private var generation = 0
    private var task: Task<Void, Never>?

    init(transcriber: any SpeechTranscriber, interpreter: any MoneyInterpreter) {
        self.transcriber = transcriber
        self.interpreter = interpreter
        self.usesMocks = transcriber.isMock || interpreter.isMock
    }

    var isBusy: Bool { phase == .listening || { if case .thinking = phase { true } else { false } }() }

    var weekTotalCents: Int { entries.reduce(0) { $0 + $1.amountCents } }

    func startYap() {
        guard !isBusy else { return }
        generation += 1
        let mine = generation
        phase = .listening
        task = Task { [weak self] in await self?.run(generation: mine) }
    }

    func cancel() {
        generation += 1
        task?.cancel()
        phase = .idle
    }

    func undoLast() {
        guard let id = lastAddedID else { return }
        entries.removeAll { $0.id == id }
        lastAddedID = nil
    }

    /// Runs one yap to completion. Exposed for tests.
    func run(generation mine: Int) async {
        do {
            let transcript = try await transcriber.transcribe()
            guard mine == generation else { return }
            phase = .thinking(transcript: transcript)

            let proposal = try await interpreter.interpret(InterpretationRequest(transcript: transcript))
            guard mine == generation else { return }

            guard proposal.kind == .expense, let amount = proposal.amount, amount > 0 else {
                phase = .failed(message: proposal.question ?? "I couldn't turn that into an expense.")
                return
            }
            let entry = Entry(
                amountCents: Int((amount * 100).rounded()),
                merchant: proposal.merchant,
                category: proposal.category.flatMap(Category.init(rawValue:)) ?? .other,
                transcript: transcript
            )
            entries.insert(entry, at: 0)
            lastAddedID = entry.id
            phase = .idle
        } catch is CancellationError {
            if mine == generation { phase = .idle }
        } catch {
            if mine == generation { phase = .failed(message: "Something went wrong. Try again.") }
        }
    }
}
