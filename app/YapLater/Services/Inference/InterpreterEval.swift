#if DEBUG
import Foundation

/// Debug tool: runs fixed utterances through an interpreter and the validator, and reports what happened.
/// A report only describes the model and device it ran on.
enum InterpreterEval {
    enum Expected: Equatable {
        case expense(cents: Int, category: Category)
        case budget(cents: Int, category: Category)
        /// An expense with no amount said: the proposal's amount must be nil and the app must ask.
        case missingAmount
        /// A reminder request: recognized as one (a draft, or a question about its time).
        case reminder
        case unsupported
    }

    struct Case {
        let utterance: String
        let expected: Expected
        var merchant: String? = nil
        var yesterday = false
    }

    static let cases: [Case] = [
        Case(utterance: "Just spent like fifty bucks on groceries at Walmart",
             expected: .expense(cents: 5000, category: .groceries), merchant: "Walmart"),
        Case(utterance: "Spent 12 dollars on lunch", expected: .expense(cents: 1200, category: .dining)),
        Case(utterance: "I paid $45.99 for a shirt at Target",
             expected: .expense(cents: 4599, category: .shopping), merchant: "Target"),
        Case(utterance: "Coffee was six fifty", expected: .expense(cents: 650, category: .coffee)),
        Case(utterance: "Dinner at Chipotle was thirteen forty five",
             expected: .expense(cents: 1345, category: .dining), merchant: "Chipotle"),
        Case(utterance: "Uber home yesterday was twenty two dollars",
             expected: .expense(cents: 2200, category: .transport), merchant: "Uber", yesterday: true),
        Case(utterance: "Yesterday I spent 30 dollars on movie tickets",
             expected: .expense(cents: 3000, category: .fun), yesterday: true),
        Case(utterance: "Paid the electric bill, eighty four dollars",
             expected: .expense(cents: 8400, category: .bills)),
        Case(utterance: "Dropped 15 bucks at the pharmacy", expected: .expense(cents: 1500, category: .health)),
        Case(utterance: "Spent a hundred and twenty on new shoes",
             expected: .expense(cents: 12000, category: .shopping)),
        Case(utterance: "Filled up the tank for 40 dollars", expected: .expense(cents: 4000, category: .transport)),
        Case(utterance: "Grabbed a coffee", expected: .missingAmount),
        Case(utterance: "Bought some groceries at Trader Joe's", expected: .missingAmount),
        Case(utterance: "Grabbed a coffee. Six fifty", expected: .expense(cents: 650, category: .coffee)),
        Case(utterance: "Got lunch with Sam. 18 dollars", expected: .expense(cents: 1800, category: .dining)),
        Case(utterance: "Set my coffee budget to 25 a week", expected: .budget(cents: 2500, category: .coffee)),
        Case(utterance: "Set my fun budget to forty a week", expected: .budget(cents: 4000, category: .fun)),
        Case(utterance: "Make my groceries budget one hundred fifty dollars a week",
             expected: .budget(cents: 15000, category: .groceries)),
        Case(utterance: "What's the weather like", expected: .unsupported),
        Case(utterance: "Remind me to call mom tomorrow at six pm", expected: .reminder),
        Case(utterance: "Remind me in twenty minutes to check the laundry", expected: .reminder),
        Case(utterance: "My electric bill is due on the fifth, ninety dollars", expected: .reminder),
        Case(utterance: "Tell me a joke", expected: .unsupported),
    ]

    struct CaseResult {
        let passed: Bool
        let got: String
        let milliseconds: Int
    }

    static func run(_ interpreter: any MoneyInterpreter) async -> String {
        let validator = ProposalValidator()
        var lines: [String] = []
        var latencies: [Int] = []
        var passes = 0

        for (index, testCase) in cases.enumerated() {
            let result = await evaluate(testCase, interpreter: interpreter, validator: validator)
            latencies.append(result.milliseconds)
            if result.passed { passes += 1 }
            lines.append("\(result.passed ? "PASS" : "FAIL") \(String(format: "%2d", index + 1)). "
                + "\"\(testCase.utterance)\" | expected \(describe(testCase)) | got \(result.got) | "
                + "\(result.milliseconds) ms")
        }

        let sorted = latencies.sorted()
        let median = sorted.isEmpty ? 0 : sorted[sorted.count / 2]
        let header = "Interpreter eval (\(interpreter.isMock ? "MOCK" : String(describing: type(of: interpreter))))"
        let totals = "Passed \(passes)/\(cases.count). Latency ms: median \(median), "
            + "min \(sorted.first ?? 0), max \(sorted.last ?? 0), first \(latencies.first ?? 0)."
        return ([header] + lines + [totals]).joined(separator: "\n")
    }

    static func evaluate(_ testCase: Case, interpreter: any MoneyInterpreter,
                         validator: ProposalValidator) async -> CaseResult {
        let request = InterpretationRequest(transcript: testCase.utterance)
        let clock = ContinuousClock()
        let start = clock.now
        let proposal: MoneyProposal
        do {
            proposal = try await interpreter.interpret(request)
        } catch {
            return CaseResult(passed: false, got: "error: \(error)", milliseconds: milliseconds(clock.now - start))
        }
        let elapsed = milliseconds(clock.now - start)
        let outcome = validator.validate(proposal, request: request)
        return CaseResult(passed: matches(testCase, proposal: proposal, outcome: outcome, request: request),
                          got: describe(outcome, proposal: proposal, request: request),
                          milliseconds: elapsed)
    }

    static func matches(_ testCase: Case, proposal: MoneyProposal, outcome: ValidationOutcome,
                        request: InterpretationRequest) -> Bool {
        switch (testCase.expected, outcome) {
        case (.expense(let cents, let category), .expense(let entry)):
            guard entry.amountCents == cents, entry.category == category else { return false }
            if let merchant = testCase.merchant,
               entry.merchant?.lowercased().contains(merchant.lowercased()) != true { return false }
            return isYesterday(entry.date, request: request) == testCase.yesterday
        case (.budget(let cents, let category), .budgetSet(let budget)):
            return budget.weeklyLimitCents == cents && budget.category == category
        case (.missingAmount, .askBack):
            return proposal.kind == .expense && proposal.amount == nil
        case (.reminder, .reminder):
            return true
        case (.reminder, .askBack):
            return proposal.kind == .reminder
        case (.unsupported, .unsupported):
            return true
        default:
            return false
        }
    }

    private static func isYesterday(_ date: Date, request: InterpretationRequest) -> Bool {
        date < request.referenceInstant.addingTimeInterval(-3600)
    }

    private static func milliseconds(_ duration: Duration) -> Int {
        let parts = duration.components
        return Int(parts.seconds) * 1000 + Int(parts.attoseconds / 1_000_000_000_000_000)
    }

    private static func dollars(_ cents: Int) -> String { String(format: "$%.2f", Double(cents) / 100) }

    private static func describe(_ testCase: Case) -> String {
        var text: String
        switch testCase.expected {
        case .expense(let cents, let category): text = "expense \(dollars(cents)) \(category.rawValue)"
        case .budget(let cents, let category): text = "budget \(dollars(cents)) \(category.rawValue)"
        case .missingAmount: text = "ask-back, nil amount"
        case .reminder: text = "reminder"
        case .unsupported: text = "unsupported"
        }
        if let merchant = testCase.merchant { text += " @\(merchant)" }
        if testCase.yesterday { text += " yesterday" }
        return text
    }

    private static func describe(_ outcome: ValidationOutcome, proposal: MoneyProposal,
                                 request: InterpretationRequest) -> String {
        switch outcome {
        case .expense(let entry):
            var text = "expense \(dollars(entry.amountCents)) \(entry.category.rawValue)"
            if let merchant = entry.merchant { text += " @\(merchant)" }
            if isYesterday(entry.date, request: request) { text += " yesterday" }
            return text
        case .budgetSet(let budget):
            return "budget \(dollars(budget.weeklyLimitCents)) \(budget.category.rawValue)"
        case .reminder(let draft):
            return "reminder \"\(draft.title)\" \(draft.whenText())"
        case .askBack(let question):
            let amount = proposal.amount.map { String($0) } ?? "nil"
            return "ask-back \"\(question)\" (\(proposal.kind.rawValue), amount \(amount), "
                + "category \(proposal.category ?? "nil"))"
        case .unsupported:
            return "unsupported"
        }
    }
}
#endif
