import Foundation
import FoundationModels

/// Why an interpreter could not produce a proposal. The app decides what to say.
enum InterpreterError: Error, Equatable, LocalizedError {
    enum UnavailableReason: String, Sendable {
        case deviceNotEligible
        case appleIntelligenceNotEnabled
        case modelNotReady
        case unknown
    }

    /// The on-device model cannot run right now.
    case modelUnavailable(UnavailableReason)
    /// The model's safety guardrails declined the sentence.
    case refused
    /// The model ran but nothing usable came back.
    case generationFailed(String)

    var errorDescription: String? {
        switch self {
        case .modelUnavailable(.deviceNotEligible):
            "This device can't run the on-device model."
        case .modelUnavailable(.appleIntelligenceNotEnabled):
            "Turn on Apple Intelligence in Settings to use the on-device model."
        case .modelUnavailable(.modelNotReady):
            "The on-device model is still downloading. Try again in a bit."
        case .modelUnavailable(.unknown):
            "The on-device model isn't available right now."
        case .refused:
            "The on-device model declined that one."
        case .generationFailed(let detail):
            "The on-device model couldn't read that. \(detail)"
        }
    }
}

/// What the model is asked to fill in. Guided generation constrains it to exactly this shape.
@Generable(description: "A reading of one spoken sentence about money")
struct GeneratedMoneyProposal: Equatable {
    @Generable(description: "What the person wants")
    enum Kind: String, CaseIterable {
        case expense
        case budgetSet
        case unsupported
    }

    @Generable(description: "Spending category")
    enum Category: String, CaseIterable {
        case groceries, dining, coffee, transport, shopping, bills, fun, health, other
    }

    @Guide(description: "expense when the person spent or paid money, even if no amount was said. budgetSet when they set or change a budget. unsupported for anything else.")
    var kind: Kind

    @Guide(description: "The dollar amount that was said, as a number: 'fifty bucks' is 50, 'six fifty' is 6.5, 'thirteen forty five' is 13.45. null when the sentence has no amount. Never invent one.")
    var amount: Double?

    @Guide(description: "The shop, restaurant, or company name exactly as said, such as Walmart or Uber. null when no name was said.")
    var merchant: String?

    @Guide(description: "Best fit for what the money was for; for a budget, the category the budget is for. other if unsure.")
    var category: Category

    @Guide(description: "The words about when it happened, copied from the sentence, such as yesterday or last night. null when none were said.")
    var datePhrase: String?
}

extension GeneratedMoneyProposal {
    /// Maps the model's answer to the app's untrusted proposal. The transcript is used to drop an
    /// amount when no number was said at all, so an invented amount never leaves the interpreter.
    func proposal(for transcript: String) -> MoneyProposal {
        let kind: MoneyProposal.Kind = switch self.kind {
        case .expense: .expense
        case .budgetSet: .budgetSet
        case .unsupported: .unsupported
        }
        guard kind != .unsupported else { return MoneyProposal(kind: .unsupported) }

        var amount = self.amount
        if let value = amount {
            let cents = Int((value * 100).rounded(.toNearestOrAwayFromZero))
            if !value.isFinite || value <= 0 || !AmountEvidence.supports(cents: cents, in: transcript) {
                amount = nil
            }
        }
        return MoneyProposal(
            kind: kind,
            amount: amount,
            merchant: Self.clean(merchant),
            category: category.rawValue,
            datePhrase: Self.clean(datePhrase),
            period: kind == .budgetSet ? "week" : nil)
    }

    private static func clean(_ text: String?) -> String? {
        guard let trimmed = text?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else { return nil }
        return ["null", "none", "n/a", "unknown"].contains(trimmed.lowercased()) ? nil : trimmed
    }
}

/// Interprets a transcript with Apple's on-device system language model. Runs fully on the phone.
struct FoundationModelsInterpreter: MoneyInterpreter {
    let isMock = false
    var name: String { "Apple on-device model (fallback)" }

    /// Instructions for guided generation. The shape comes from `GeneratedMoneyProposal`, so no JSON here.
    static let instructions = """
    You read one spoken sentence about money and fill in a form. The sentence came from speech \
    recognition, so amounts are often spelled out as words.

    Rules:
    - kind is expense when the person spent, paid, bought, or grabbed something, even if they did not \
    say how much. kind is budgetSet when they set or change a budget. Anything else is unsupported \
    (questions, reminders, chit-chat).
    - amount is the dollars that were said. "fifty bucks" is 50. "six fifty" is 6.5. "thirteen forty \
    five" is 13.45. "a hundred and twenty" is 120. "$45.99" is 45.99. If the sentence has no amount, \
    amount is null. Never guess or make up an amount.
    - A later short sentence that is only a number is the amount for the earlier one: \
    "Grabbed a coffee. Six fifty" is a coffee expense of 6.5.
    - merchant is the shop or company name if one was said, otherwise null.
    - category is one of: \(InterpreterPrompt.categories). lunch, dinner, restaurants and takeout are \
    dining. Uber, gas, bus and parking are transport. clothes, shoes and gadgets are shopping. rent, \
    electric, phone and internet are bills. movies, games and concerts are fun. pharmacy, doctor and \
    gym are health. Use other if unsure.
    - datePhrase is the words about when it happened ("yesterday", "last night"), otherwise null.

    Examples:
    "Just spent like fifty bucks on groceries at Walmart" -> expense, amount 50, merchant Walmart, category groceries, datePhrase null
    "Grabbed a coffee" -> expense, amount null, merchant null, category coffee, datePhrase null
    "Grabbed a coffee. Six fifty" -> expense, amount 6.5, merchant null, category coffee, datePhrase null
    "Uber home yesterday was twenty two dollars" -> expense, amount 22, merchant Uber, category transport, datePhrase yesterday
    "Set my fun budget to forty a week" -> budgetSet, amount 40, merchant null, category fun, datePhrase null
    "What's the weather like" -> unsupported, amount null, merchant null, category other, datePhrase null
    """

    /// Greedy sampling so the same sentence always gives the same proposal.
    static let options = GenerationOptions(sampling: .greedy, temperature: 0, maximumResponseTokens: 200)

    /// `nil` when the system model can run now; otherwise the reason it cannot.
    static var unavailableReason: InterpreterError.UnavailableReason? {
        switch SystemLanguageModel.default.availability {
        case .available: nil
        case .unavailable(.deviceNotEligible): .deviceNotEligible
        case .unavailable(.appleIntelligenceNotEnabled): .appleIntelligenceNotEnabled
        case .unavailable(.modelNotReady): .modelNotReady
        case .unavailable: .unknown
        @unknown default: .unknown
        }
    }

    static var isAvailable: Bool { unavailableReason == nil }

    /// Loads the model ahead of the first yap. Safe to call at launch; does nothing when unavailable.
    func prewarm() {
        guard Self.isAvailable else { return }
        let session = LanguageModelSession(instructions: Self.instructions)
        session.prewarm()
        // Keep the session alive briefly so the load is not cancelled when this function returns.
        Task.detached(priority: .utility) {
            try? await Task.sleep(for: .seconds(20))
            _ = session
        }
    }

    func interpret(_ request: InterpretationRequest) async throws -> MoneyProposal {
        try Task.checkCancellation()
        if let reason = Self.unavailableReason { throw InterpreterError.modelUnavailable(reason) }

        let prompt = InterpreterPrompt.user(for: request)
        do {
            // A fresh session per request: yaps are independent and must not see each other.
            let session = LanguageModelSession(instructions: Self.instructions)
            let response = try await session.respond(
                to: prompt, generating: GeneratedMoneyProposal.self, options: Self.options)
            try Task.checkCancellation()
            return response.content.proposal(for: request.transcript)
        } catch let error as LanguageModelSession.GenerationError {
            try Task.checkCancellation()
            switch error {
            case .decodingFailure, .unsupportedGuide:
                return try await interpretAsText(request)
            case .guardrailViolation, .refusal:
                throw InterpreterError.refused
            case .assetsUnavailable:
                throw InterpreterError.modelUnavailable(Self.unavailableReason ?? .modelNotReady)
            default:
                throw InterpreterError.generationFailed(error.localizedDescription)
            }
        } catch let error as InterpreterError {
            throw error
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            try Task.checkCancellation()
            throw InterpreterError.generationFailed(error.localizedDescription)
        }
    }

    /// Fallback when guided generation cannot be used: plain text out, parsed as JSON.
    private func interpretAsText(_ request: InterpretationRequest) async throws -> MoneyProposal {
        let session = LanguageModelSession(instructions: InterpreterPrompt.system)
        do {
            let response = try await session.respond(to: InterpreterPrompt.user(for: request), options: Self.options)
            try Task.checkCancellation()
            return try ProposalParser.parse(response.content)
        } catch is CancellationError {
            throw CancellationError()
        } catch let error as LanguageModelSession.GenerationError {
            try Task.checkCancellation()
            switch error {
            case .guardrailViolation, .refusal: throw InterpreterError.refused
            default: throw InterpreterError.generationFailed(error.localizedDescription)
            }
        } catch {
            try Task.checkCancellation()
            throw InterpreterError.generationFailed("\(error)")
        }
    }
}
