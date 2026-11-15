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
        guard let object = try JSONSerialization.jsonObject(with: Data(json.utf8)) as? [String: Any] else {
            throw ParseError.notAnObject
        }
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
        return trimmed.isEmpty || trimmed.lowercased() == "null" ? nil : trimmed
    }

    private static func number(_ value: Any?) -> Double? {
        if let number = value as? NSNumber, !(value is Bool) { return number.doubleValue }
        if let text = value as? String {
            let cleaned = text.filter { $0.isNumber || $0 == "." }
            return Double(cleaned)
        }
        return nil
    }
}
