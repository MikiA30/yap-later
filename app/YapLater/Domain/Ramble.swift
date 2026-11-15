import Foundation

/// Splits one yap that names several expenses ("fifty on groceries, twelve on lunch and six on coffee")
/// into one piece per amount, so each piece goes through the same single-expense path.
/// This is plain text handling; the model still interprets every piece and the validator still checks it.
enum RambleSplitter {
    private static let joiners: Set<String> = ["and", "then", "plus", "also"]
    private static let numberJoinBefore: Set<String> = ["hundred", "thousand", "grand"]
    private static let moneyWords: Set<String> = ["dollar", "dollars", "buck", "bucks"]
    /// Requests that are not a list of expenses stay whole.
    private static let singleOnly = ["remind", "budget", " due "]

    /// Two or more pieces when the transcript clearly holds several amounts; otherwise empty.
    static func pieces(of transcript: String) -> [String] {
        let lowered = " " + transcript.lowercased() + " "
        guard !singleOnly.contains(where: { lowered.contains($0) }) else { return [] }

        // 1. Cut at sentence punctuation, commas, and joining words.
        let words = transcript.split(whereSeparator: \.isWhitespace).map(String.init)
        var fragments: [[String]] = [[]]
        for (index, word) in words.enumerated() {
            let bare = word.lowercased().trimmingCharacters(in: .punctuationCharacters)
            if joiners.contains(bare), index + 1 < words.count {
                if fragments[fragments.count - 1].isEmpty {
                    // A joining word right after a cut ("…, and 15 at the pharmacy") is dropped.
                } else if bare == "and", isInsideNumber(words, at: index) {
                    fragments[fragments.count - 1].append(word)
                } else {
                    fragments.append([])
                }
                continue
            }
            fragments[fragments.count - 1].append(word)
            if let last = word.last, ".,;!?".contains(last) { fragments.append([]) }
        }

        // 2. Glue fragments back together so that each piece holds exactly one amount.
        var pieces: [String] = []
        var current: [String] = []
        var currentHasAmount = false
        for fragment in fragments where !fragment.isEmpty {
            let text = fragment.joined(separator: " ")
            let fragmentHasAmount = hasAmount(text)
            if fragmentHasAmount, currentHasAmount {
                pieces.append(clean(current))
                current = []
                currentHasAmount = false
            }
            current.append(text)
            currentHasAmount = currentHasAmount || fragmentHasAmount
        }
        if !current.isEmpty {
            if currentHasAmount || pieces.isEmpty {
                pieces.append(clean(current))
            } else {
                pieces[pieces.count - 1] += " " + clean(current)
            }
        }
        return pieces.count >= 2 ? pieces : []
    }

    /// "a hundred and twenty", "five dollars and fifty cents": this "and" belongs to one amount.
    private static func isInsideNumber(_ words: [String], at index: Int) -> Bool {
        guard index > 0 else { return false }
        let before = words[index - 1].lowercased().trimmingCharacters(in: .punctuationCharacters)
        if numberJoinBefore.contains(before) { return true }
        if moneyWords.contains(before) {
            let after = words[(index + 1)..<min(words.count, index + 4)]
            return after.contains { $0.lowercased().hasPrefix("cent") }
        }
        return false
    }

    /// A fragment counts as holding an amount when a number was said in it. A lone "one" ("one coffee")
    /// only counts next to a money word.
    private static func hasAmount(_ text: String) -> Bool {
        let amounts = AmountEvidence.candidates(in: text)
        if amounts.isEmpty { return false }
        if amounts == [100] {
            let lowered = text.lowercased()
            return lowered.contains("$") || moneyWords.contains { lowered.contains($0) }
        }
        return true
    }

    private static func clean(_ fragments: [String]) -> String {
        fragments.joined(separator: " ")
            .trimmingCharacters(in: CharacterSet(charactersIn: ",;").union(.whitespaces))
    }
}
