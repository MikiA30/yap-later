import Foundation

/// Turns a transcript into an untrusted `MoneyProposal`. Implementations never touch storage.
protocol MoneyInterpreter: Sendable {
    /// `true` when this is a stand-in, so the UI can label it.
    var isMock: Bool { get }
    func interpret(_ request: InterpretationRequest) async throws -> MoneyProposal
}

/// MOCK: fixed answers for the mock transcriber's script. No model runs.
struct MockMoneyInterpreter: MoneyInterpreter {
    let isMock = true

    func interpret(_ request: InterpretationRequest) async throws -> MoneyProposal {
        try await Task.sleep(for: .milliseconds(600))
        let text = request.transcript.lowercased()
        if text.contains("groceries") {
            return MoneyProposal(kind: .expense, amount: 50, merchant: "Walmart", category: "groceries")
        }
        if text.contains("coffee") {
            return MoneyProposal(kind: .expense, amount: 6.5, merchant: nil, category: "coffee")
        }
        if text.contains("uber") {
            return MoneyProposal(kind: .expense, amount: 22, merchant: "Uber", category: "transport")
        }
        return MoneyProposal(kind: .unsupported, question: "I didn't catch that. What did you spend?")
    }
}
