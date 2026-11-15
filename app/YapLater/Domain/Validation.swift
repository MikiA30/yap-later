import Foundation

/// What app code decided to do with an untrusted proposal.
enum ValidationOutcome: Equatable, Sendable {
    case expense(Entry)
    case budgetSet(Budget)
    /// A reminder to show for confirmation. Not saved until the user taps Save.
    case reminder(ReminderDraft)
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
        case .reminder:
            return ReminderResolver.resolve(proposal, request: request)

        case .unsupported:
            return .unsupported(message: proposal.question
                ?? "I can log spending, set weekly budgets, and set reminders. Try “spent 12 dollars on lunch”.")

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
    /// True when `cents` is one of the amounts the transcript could mean.
    static func supports(cents: Int, in transcript: String) -> Bool {
        candidates(in: transcript).contains(cents)
    }

    /// Every amount, in cents, that the words or digits in the transcript could reasonably mean.
    /// Spoken prices are ambiguous ("six fifty" is $6.50 or $650), so both readings are allowed;
    /// what is not allowed is an amount with no basis in what was said.
    static func candidates(in transcript: String) -> Set<Int> {
        let numbers = spokenNumbers(in: transcript)
        var result: Set<Int> = []
        for (index, number) in numbers.enumerated() {
            if number.isCents {
                result.insert(number.cents / 100) // "twenty cents" alone
            } else {
                result.insert(number.cents)
                // Bare three- or four-digit numbers from speech recognition: "650" may be "six fifty".
                if number.fromDigits, !number.hadDecimal, (100...9_999).contains(number.cents / 100) {
                    result.insert(number.cents / 100)
                }
            }
            guard index > 0 else { continue }
            let previous = numbers[index - 1]
            guard !previous.isCents, previous.cents % 100 == 0, number.cents % 100 == 0 else { continue }
            let dollars = previous.cents / 100, tail = number.cents / 100
            guard tail < 100, number.adjacentToPrevious else { continue }
            result.insert(dollars * 100 + tail)                      // "six fifty" -> $6.50
            if !number.isCents, dollars < 100 { result.insert((dollars * 100 + tail) * 100) } // -> $650
        }
        return result.filter { $0 > 0 }
    }

    private struct Spoken {
        var cents: Int
        var fromDigits = false
        var hadDecimal = false
        /// Followed by the word "cents".
        var isCents = false
        /// Nothing but filler ("dollars", "bucks", "and") sits between this and the previous number.
        var adjacentToPrevious = false
    }

    private static let units: [String: Int] = [
        "zero": 0, "one": 1, "two": 2, "three": 3, "four": 4, "five": 5, "six": 6, "seven": 7, "eight": 8,
        "nine": 9, "ten": 10, "eleven": 11, "twelve": 12, "thirteen": 13, "fourteen": 14, "fifteen": 15,
        "sixteen": 16, "seventeen": 17, "eighteen": 18, "nineteen": 19]
    private static let tens: [String: Int] = [
        "twenty": 20, "thirty": 30, "forty": 40, "fifty": 50, "sixty": 60, "seventy": 70, "eighty": 80, "ninety": 90]
    private static let filler: Set<String> = ["dollar", "dollars", "buck", "bucks", "and"]

    private static func spokenNumbers(in transcript: String) -> [Spoken] {
        let words = transcript.lowercased()
            .replacingOccurrences(of: "-", with: " ")
            .split { !($0.isLetter || $0.isNumber || $0 == "." || $0 == ",") }
            .map { $0.trimmingCharacters(in: CharacterSet(charactersIn: ".,")) }
            .filter { !$0.isEmpty }

        var numbers: [Spoken] = []
        var value = 0          // the number being built, in whole dollars
        var group = 0          // the part below one hundred/thousand
        var building = false
        var lastWasTens = false, lastWasUnit = false
        var gapIsFiller = true // only filler words since the previous number ended

        func finish() {
            guard building else { return }
            numbers.append(Spoken(cents: (value + group) * 100, adjacentToPrevious: !numbers.isEmpty && gapIsFiller))
            value = 0; group = 0; building = false; lastWasTens = false; lastWasUnit = false
            gapIsFiller = true
        }

        for (index, word) in words.enumerated() {
            if let digits = Double(word.replacingOccurrences(of: ",", with: "")), word.first?.isNumber == true {
                finish()
                numbers.append(Spoken(cents: Int((digits * 100).rounded()), fromDigits: true,
                                      hadDecimal: word.contains("."),
                                      adjacentToPrevious: !numbers.isEmpty && gapIsFiller))
                gapIsFiller = true
            } else if let unit = units[word] {
                if building, lastWasUnit || (lastWasTens && unit >= 10) { finish() } // "six" "five", "twenty" "twelve"
                group += unit; building = true; lastWasUnit = true; lastWasTens = false
            } else if let ten = tens[word] {
                if building, lastWasUnit || lastWasTens { finish() }                 // "six" "fifty"
                group += ten; building = true; lastWasTens = true; lastWasUnit = false
            } else if word == "hundred" {
                group = max(group, 1) * 100; building = true; lastWasTens = false; lastWasUnit = false
            } else if word == "thousand" || word == "grand" {
                value += max(group, 1) * 1000; group = 0; building = true; lastWasTens = false; lastWasUnit = false
            } else if word == "a" || word == "an" {
                // "a hundred", "a grand", "a buck": counts as one only when such a word follows.
                let next = index + 1 < words.count ? words[index + 1] : ""
                if ["hundred", "thousand", "grand", "buck", "dollar"].contains(next) {
                    finish(); group = 1; building = true; lastWasUnit = false; lastWasTens = false
                } else { finish(); gapIsFiller = false }
            } else if word == "cents" || word == "cent" {
                finish()
                if !numbers.isEmpty { numbers[numbers.count - 1].isCents = true }
            } else if word == "and", building {
                continue // "a hundred and twenty"
            } else if filler.contains(word) {
                finish()
            } else {
                finish()
                gapIsFiller = false
            }
        }
        finish()
        return numbers
    }
}

/// Resolves simple relative day phrases in code, against the request's own clock.
enum DatePhrase {
    static func resolve(_ phrase: String?, request: InterpretationRequest) -> Date {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(identifier: request.timeZoneID) ?? .current
        let now = request.referenceInstant
        // Look in what was actually said too, in case the model left the date words out.
        let phrase = "\(phrase ?? "") \(request.transcript)".lowercased()
        if phrase.contains("yesterday") || phrase.contains("last night") {
            return calendar.date(byAdding: .day, value: -1, to: now) ?? now
        }
        if let match = phrase.firstMatch(of: /(\d+|one|two|three|four|five|six) days? ago/) {
            let words = ["one": 1, "two": 2, "three": 3, "four": 4, "five": 5, "six": 6]
            if let days = Int(match.1) ?? words[String(match.1)], (1...6).contains(days) {
                return calendar.date(byAdding: .day, value: -days, to: now) ?? now
            }
        }
        // "on Monday", "last Friday": the most recent such day before today.
        for (index, name) in ReminderResolver.weekdays.enumerated()
        where phrase.contains("on \(name)") || phrase.contains("last \(name)") {
            let today = calendar.component(.weekday, from: now)
            let back = (today - (index + 1) + 7) % 7
            return calendar.date(byAdding: .day, value: -(back == 0 ? 7 : back), to: now) ?? now
        }
        return now
    }
}
