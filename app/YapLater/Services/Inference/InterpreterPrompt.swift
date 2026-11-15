import Foundation

/// The instructions every on-device model gets, whichever runtime runs it.
enum InterpreterPrompt {
    static let categories = Category.allCases.map(\.rawValue).joined(separator: ", ")

    static let system = """
    You turn one spoken sentence about money into JSON. Reply with one JSON object and nothing else.

    Fields:
    - "kind": "expense" when the person spent money, "budget_set" when they set a weekly budget, otherwise "unsupported".
    - "amount": the number of dollars that was said, as a number (6.5, 50, 1200). null if no amount was said. Never guess an amount.
    - "merchant": the shop or company name if one was said, otherwise null.
    - "category": one of: \(categories). Pick the best fit; use "other" if unsure. For "budget_set" it is the category of the budget.
    - "date_phrase": the words about when it happened ("yesterday", "on Monday"), or null if none.
    - "period": "week" for "budget_set", otherwise null.

    Examples:
    Sentence: "Just spent like fifty bucks on groceries at Walmart"
    {"kind":"expense","amount":50,"merchant":"Walmart","category":"groceries","date_phrase":null,"period":null}
    Sentence: "Grabbed a coffee"
    {"kind":"expense","amount":null,"merchant":null,"category":"coffee","date_phrase":null,"period":null}
    Sentence: "Grabbed a coffee. Six fifty"
    {"kind":"expense","amount":6.5,"merchant":null,"category":"coffee","date_phrase":null,"period":null}
    Sentence: "Set my fun budget to forty a week"
    {"kind":"budget_set","amount":40,"merchant":null,"category":"fun","date_phrase":null,"period":"week"}
    Sentence: "Uber home yesterday was twenty two dollars"
    {"kind":"expense","amount":22,"merchant":"Uber","category":"transport","date_phrase":"yesterday","period":null}
    Sentence: "What's the weather like"
    {"kind":"unsupported","amount":null,"merchant":null,"category":null,"date_phrase":null,"period":null}
    """

    /// Short rules for chat-style prompting, where the examples are given as earlier turns (`chatExamples`).
    /// Small models follow example turns far better than examples buried in the instructions.
    static let chatSystem = """
    You turn one spoken sentence about money into one JSON object. Read the sentence carefully and answer only about that sentence.
    - "kind": "expense" if the person spent, paid, or bought something (even with no amount). "budget_set" if they set or change a budget. Otherwise "unsupported".
    - "amount": the dollars that were said, as a number. "six fifty" is 6.5, "thirteen forty five" is 13.45, "a hundred and twenty" is 120. null if no amount was said. Never make one up.
    - "merchant": the shop or company name if one was said, otherwise null.
    - "category": one of \(categories). Food shopping is groceries. Lunch, dinner, restaurants are dining. Uber, gas, bus, parking are transport. Clothes, shoes, gadgets are shopping. Rent, electric, phone, internet are bills. Movies, games, concerts are fun. Pharmacy, doctor, gym are health. Otherwise other.
    - "date_phrase": the words about when it happened, like "yesterday", otherwise null.
    - "period": "week" for budget_set, otherwise null.
    """

    /// Example turns: (sentence, answer). Kept different from the eval sentences where possible.
    static let chatExamples: [(sentence: String, answer: String)] = [
        ("Just spent like fifty bucks on groceries at Walmart",
         #"{"kind":"expense","amount":50,"merchant":"Walmart","category":"groceries","date_phrase":null,"period":null}"#),
        ("Grabbed a coffee",
         #"{"kind":"expense","amount":null,"merchant":null,"category":"coffee","date_phrase":null,"period":null}"#),
        ("Lunch was eleven dollars",
         #"{"kind":"expense","amount":11,"merchant":null,"category":"dining","date_phrase":null,"period":null}"#),
        ("Change my dining budget to eighty dollars a week",
         #"{"kind":"budget_set","amount":80,"merchant":null,"category":"dining","date_phrase":null,"period":"week"}"#),
        ("Took a Lyft last night, seventeen fifty",
         #"{"kind":"expense","amount":17.5,"merchant":"Lyft","category":"transport","date_phrase":"last night","period":null}"#),
        ("Remind me to water the plants",
         #"{"kind":"unsupported","amount":null,"merchant":null,"category":null,"date_phrase":null,"period":null}"#),
        ("Got headphones for two hundred at Best Buy",
         #"{"kind":"expense","amount":200,"merchant":"Best Buy","category":"shopping","date_phrase":null,"period":null}"#),
        ("Concert tickets, sixty five bucks",
         #"{"kind":"expense","amount":65,"merchant":null,"category":"fun","date_phrase":null,"period":null}"#),
        ("Set my coffee budget to twenty a week",
         #"{"kind":"budget_set","amount":20,"merchant":null,"category":"coffee","date_phrase":null,"period":"week"}"#),
        ("Doctor copay was thirty five dollars. Grabbed a sandwich after",
         #"{"kind":"expense","amount":35,"merchant":null,"category":"health","date_phrase":null,"period":null}"#),
        ("How much did I spend this week",
         #"{"kind":"unsupported","amount":null,"merchant":null,"category":null,"date_phrase":null,"period":null}"#),
        ("Paid the internet bill, sixty dollars",
         #"{"kind":"expense","amount":60,"merchant":null,"category":"bills","date_phrase":null,"period":null}"#),
    ]

    static func sentenceLine(_ sentence: String) -> String {
        "Sentence: \"\(sentence.replacingOccurrences(of: "\"", with: "'"))\""
    }

    static func user(for request: InterpretationRequest) -> String {
        let sentence = request.transcript.replacingOccurrences(of: "\"", with: "'")
        return "Sentence: \"\(sentence)\""
    }
}

/// Pulls a `MoneyProposal` out of whatever text a model produced. Tolerant of extra prose and loose types.
enum ProposalParser {
    enum ParseError: Error, Equatable { case noJSON, notAnObject }

    static func parse(_ text: String) throws -> MoneyProposal {
        guard let json = firstJSONObject(in: text) else { throw ParseError.noJSON }
        guard let object = try jsonObject(json) as? [String: Any] else { throw ParseError.notAnObject }
        let kind = (object["kind"] as? String).flatMap { MoneyProposal.Kind(rawValue: $0.lowercased()) } ?? .unsupported
        return MoneyProposal(
            kind: kind,
            amount: number(object["amount"]),
            merchant: string(object["merchant"]),
            category: string(object["category"])?.lowercased(),
            datePhrase: string(object["date_phrase"]),
            period: string(object["period"])?.lowercased(),
            question: string(object["question"]))
    }

    /// Strict JSON first; then the lenient reader, which accepts trailing commas, single quotes, and bare keys.
    private static func jsonObject(_ json: String) throws -> Any {
        let data = Data(json.utf8)
        if let strict = try? JSONSerialization.jsonObject(with: data) { return strict }
        return try JSONSerialization.jsonObject(with: data, options: [.json5Allowed])
    }

    /// The first balanced `{ ... }` in the text, ignoring braces inside strings.
    static func firstJSONObject(in text: String) -> String? {
        guard let start = text.firstIndex(of: "{") else { return nil }
        var depth = 0, inString = false, escaped = false
        for index in text[start...].indices {
            let character = text[index]
            if inString {
                if escaped { escaped = false }
                else if character == "\\" { escaped = true }
                else if character == "\"" { inString = false }
                continue
            }
            switch character {
            case "\"": inString = true
            case "{": depth += 1
            case "}":
                depth -= 1
                if depth == 0 { return String(text[start...index]) }
            default: break
            }
        }
        return nil
    }

    private static func string(_ value: Any?) -> String? {
        guard let text = value as? String else { return nil }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty || ["null", "none", "unknown", "n/a"].contains(trimmed.lowercased()) ? nil : trimmed
    }

    private static func number(_ value: Any?) -> Double? {
        if let number = value as? NSNumber, !(value is Bool) { return number.doubleValue }
        if let text = value as? String {
            // "$6.50", "1,200", "50 dollars": keep the first run of digits and one decimal point.
            let cleaned = text.replacingOccurrences(of: ",", with: "")
            guard let match = cleaned.firstMatch(of: /\d+(?:\.\d+)?|\.\d+/) else { return nil }
            return Double(match.0.hasPrefix(".") ? "0" + match.0 : String(match.0))
        }
        return nil
    }
}
