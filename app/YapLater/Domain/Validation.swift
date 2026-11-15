import Foundation

/// What app code decided to do with an untrusted proposal.
enum ValidationOutcome: Equatable, Sendable {
    case expense(Entry)
    case budgetSet(Budget)
    /// Something essential is missing; ask the user this short question (spoken) and wait for the answer.
    case askBack(question: String)
    case unsupported(message: String)
}

protocol ProposalValidating: Sendable {
    func validate(_ proposal: MoneyProposal, request: InterpretationRequest) -> ValidationOutcome
}

/// Deterministic checks on a model proposal. The model proposes; this decides.
struct ProposalValidator: ProposalValidating {
    static let maxAmountCents = 10_000_000 // $100,000: anything above is treated as a mishearing

    func validate(_ proposal: MoneyProposal, request: InterpretationRequest) -> ValidationOutcome {
        switch proposal.kind {
        case .unsupported:
            return .unsupported(message: proposal.question
                ?? "I can log spending and set weekly budgets. Try “spent 12 dollars on lunch”.")

        case .expense:
            guard let cents = Self.cents(proposal.amount),
                  AmountEvidence.supports(cents: cents, in: request.transcript) else {
                return .askBack(question: "How much was it?")
            }
            let category = proposal.category.flatMap { Category(rawValue: $0.lowercased()) } ?? .other
            let merchant = proposal.merchant?.trimmingCharacters(in: .whitespacesAndNewlines)
            return .expense(Entry(
                id: request.id,
                amountCents: cents,
                merchant: (merchant?.isEmpty ?? true) ? nil : merchant,
                category: category,
                date: DatePhrase.resolve(proposal.datePhrase, request: request),
                transcript: request.transcript))

        case .budgetSet:
            guard let category = proposal.category.flatMap({ Category(rawValue: $0.lowercased()) }) else {
                return .askBack(question: "Which category is that budget for?")
            }
            guard let cents = Self.cents(proposal.amount),
                  AmountEvidence.supports(cents: cents, in: request.transcript) else {
                return .askBack(question: "How much per week for \(category.displayName)?")
            }
            return .budgetSet(Budget(category: category, weeklyLimitCents: cents))
        }
    }

    static func cents(_ amount: Double?) -> Int? {
        guard let amount, amount.isFinite, amount > 0 else { return nil }
        let cents = Int((amount * 100).rounded())
        return (1...maxAmountCents).contains(cents) ? cents : nil
    }
}

/// Checks that an amount the model proposed was actually said. Guards against invented numbers.
enum AmountEvidence {
    /// First pass: the transcript must contain a digit or a number word. T006 tightens this to match the value.
    static func supports(cents: Int, in transcript: String) -> Bool {
        let text = transcript.lowercased()
        if text.contains(where: \.isNumber) { return true }
        return numberWords.contains { text.contains($0) }
    }

    static let numberWords = ["one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten",
                              "eleven", "twelve", "thirteen", "fourteen", "fifteen", "sixteen", "seventeen",
                              "eighteen", "nineteen", "twenty", "thirty", "forty", "fifty", "sixty", "seventy",
                              "eighty", "ninety", "hundred", "thousand", "buck", "dollar", "grand"]
}

/// Resolves simple relative day phrases in code, against the request's own clock.
enum DatePhrase {
    static func resolve(_ phrase: String?, request: InterpretationRequest) -> Date {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(identifier: request.timeZoneID) ?? .current
        let now = request.referenceInstant
        guard let phrase = phrase?.lowercased(), !phrase.isEmpty else { return now }
        if phrase.contains("yesterday") {
            return calendar.date(byAdding: .day, value: -1, to: now) ?? now
        }
        return now
    }
}
