import Foundation

/// Turns a transcript into an untrusted `MoneyProposal`. Implementations never touch storage.
protocol MoneyInterpreter: Sendable {
    /// `true` when this is a stand-in, so the UI can label it.
    var isMock: Bool { get }
    /// Short label for the UI and reports, e.g. "Bonsai 2 · …".
    var name: String { get }
    func interpret(_ request: InterpretationRequest) async throws -> MoneyProposal
}

extension MoneyInterpreter {
    var name: String { isMock ? "Mock" : String(describing: Self.self) }
}

/// MOCK: keyword and digit matching so the UI has something to show. No model runs.
struct MockMoneyInterpreter: MoneyInterpreter {
    let isMock = true
    var delay: Duration = .milliseconds(500)

    func interpret(_ request: InterpretationRequest) async throws -> MoneyProposal {
        try await Task.sleep(for: delay)
        let text = request.transcript.lowercased()
        let amount = Self.amount(in: text)
        let category = Self.keywords.first { pair in pair.words.contains { text.contains($0) } }?.category

        if text.contains("remind") {
            // Just enough for tests and previews: "remind me to <title> [tomorrow] [at <n> [pm]] [in <n> minutes]".
            var proposal = MoneyProposal(kind: .reminder)
            if let match = text.firstMatch(of: /remind me (?:to )?([a-z ]+?)(?: tomorrow| today| at | in |\.|$)/) {
                proposal.title = String(match.1).trimmingCharacters(in: .whitespaces)
            }
            if text.contains("tomorrow") { proposal.day = "tomorrow" }
            if let match = text.firstMatch(of: /in (\d+) minutes?/) { proposal.inMinutes = Int(match.1) }
            if let match = text.firstMatch(of: /at (\d{1,2})/), let hour = Int(match.1) {
                proposal.hour = hour
                proposal.minute = 0
            }
            return proposal
        }
        if text.contains("budget") {
            return MoneyProposal(kind: .budgetSet, amount: amount, category: category?.rawValue, period: "week")
        }
        guard amount != nil || category != nil else {
            return MoneyProposal(kind: .unsupported, question: nil)
        }
        let merchant = ["walmart": "Walmart", "uber": "Uber", "starbucks": "Starbucks", "target": "Target"]
            .first { text.contains($0.key) }?.value
        return MoneyProposal(kind: .expense, amount: amount, merchant: merchant,
                             category: category?.rawValue,
                             datePhrase: text.contains("yesterday") ? "yesterday" : nil)
    }

    private static let keywords: [(category: Category, words: [String])] = [
        (.groceries, ["grocer", "walmart", "supermarket"]),
        (.coffee, ["coffee", "starbucks", "latte"]),
        (.transport, ["uber", "gas", "bus", "train", "lyft"]),
        (.dining, ["lunch", "dinner", "restaurant", "pizza"]),
        (.fun, ["fun", "movie", "game", "concert"]),
        (.shopping, ["shopping", "clothes", "target", "amazon"]),
        (.bills, ["rent", "bill", "electric"]),
        (.health, ["pharmacy", "doctor", "gym"]),
    ]

    private static let words: [(String, Double)] = [
        ("six fifty", 6.5), ("twenty two", 22), ("fifty", 50), ("forty", 40), ("twenty", 20),
        ("twelve", 12), ("ten", 10), ("five", 5),
    ]

    static func amount(in text: String) -> Double? {
        if let match = text.firstMatch(of: /\$?(\d+(?:\.\d{1,2})?)/), let value = Double(match.1) {
            return value
        }
        return words.first { text.contains($0.0) }?.1
    }
}
