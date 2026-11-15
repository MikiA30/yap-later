import Foundation

/// A reminder the user has not confirmed yet. Nothing is written to Apple Reminders until they tap Save.
struct ReminderDraft: Identifiable, Equatable, Codable, Sendable {
    let id: UUID
    var title: String
    var dueAt: Date
    /// A bill amount, when one was said.
    var amountCents: Int?
    var transcript: String

    /// "Today at 6:00 PM", "Tomorrow at 9:00 AM", "Friday, Nov 20 at 7:30 AM".
    func whenText(now: Date = .now, calendar: Calendar = .current) -> String {
        let time = dueAt.formatted(date: .omitted, time: .shortened)
        if calendar.isDate(dueAt, inSameDayAs: now) { return "Today at \(time)" }
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now), calendar.isDate(dueAt, inSameDayAs: tomorrow) {
            return "Tomorrow at \(time)"
        }
        return "\(dueAt.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())) at \(time)"
    }
}

/// Builds the reminder's date in app code from the model's normalized pieces. Asks instead of guessing.
enum ReminderResolver {
    static let weekdays = ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"]
    private static let eveningCues = ["pm", "p.m", "evening", "tonight", "afternoon", "night"]
    private static let morningCues = ["am", "a.m", "morning"]
    /// Used when a day was given without a time (typical for bills). Shown on the card before saving.
    static let defaultHour = 9

    static func resolve(_ proposal: MoneyProposal, request: InterpretationRequest) -> ValidationOutcome {
        guard let title = proposal.title?.trimmingCharacters(in: .whitespacesAndNewlines), !title.isEmpty else {
            return .askBack(question: "What should I remind you about?")
        }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: request.timeZoneID) ?? .current
        let now = request.referenceInstant
        var amount = ProposalValidator.cents(proposal.amount)
        if let cents = amount, !AmountEvidence.supports(cents: cents, in: request.transcript) { amount = nil }
        func draft(_ due: Date) -> ValidationOutcome {
            .reminder(ReminderDraft(id: request.id, title: title.prefix(1).uppercased() + title.dropFirst(),
                                    dueAt: due, amountCents: amount, transcript: request.transcript))
        }

        if let minutes = proposal.inMinutes, (1...(14 * 24 * 60)).contains(minutes) {
            return draft(now.addingTimeInterval(Double(minutes) * 60))
        }

        let dayWord = proposal.day?.lowercased()
        guard dayWord != nil || proposal.hour != nil else {
            return .askBack(question: "When should I remind you?")
        }

        // Time of day.
        var hour = proposal.hour ?? defaultHour
        guard (0...23).contains(hour) else { return .askBack(question: "What time should I remind you?") }
        let minute = min(max(proposal.minute ?? 0, 0), 59)
        if proposal.hour != nil, (1...11).contains(hour) {
            let words = cueWords(in: request.transcript)
            if words.contains(where: eveningCues.contains) {
                hour += 12
            } else if !words.contains(where: morningCues.contains) {
                return .askBack(question: "At \(hour), morning or evening?")
            }
        }

        // Day.
        let today = calendar.startOfDay(for: now)
        let justBeforeToday = today.addingTimeInterval(-1)
        let day: Date
        var stepIfPast: DateComponents?
        switch dayWord {
        case nil:
            day = today
            stepIfPast = DateComponents(day: 1) // "at six pm" after 6 pm means tomorrow
        case "today":
            day = today
        case "tomorrow":
            day = calendar.date(byAdding: .day, value: 1, to: today) ?? today
        case "date":
            guard let dayOfMonth = proposal.dayOfMonth, (1...31).contains(dayOfMonth) else {
                return .askBack(question: "Which day should I remind you?")
            }
            var components = DateComponents(day: dayOfMonth)
            if let month = proposal.month, (1...12).contains(month) { components.month = month }
            guard let match = calendar.nextDate(after: justBeforeToday, matching: components, matchingPolicy: .nextTime) else {
                return .askBack(question: "Which day should I remind you?")
            }
            day = calendar.startOfDay(for: match)
            stepIfPast = components.month == nil ? DateComponents(month: 1) : DateComponents(year: 1)
        case let name?:
            guard let index = weekdays.firstIndex(of: name),
                  let match = calendar.nextDate(after: justBeforeToday, matching: DateComponents(weekday: index + 1),
                                                matchingPolicy: .nextTime) else {
                return .askBack(question: "Which day should I remind you?")
            }
            day = calendar.startOfDay(for: match)
            stepIfPast = DateComponents(day: 7)
        }

        guard var due = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day) else {
            return .askBack(question: "What time should I remind you?")
        }
        if due <= now, let step = stepIfPast, let later = calendar.date(byAdding: step, to: due) { due = later }
        guard due > now else {
            return .unsupported(message: "That time has already passed. Try a later time.")
        }
        return draft(due)
    }

    /// Lowercased words with dots kept, so "p.m." and "pm" can both be matched whole.
    private static func cueWords(in transcript: String) -> [String] {
        transcript.lowercased()
            .split { !($0.isLetter || $0 == ".") }
            .map { $0.trimmingCharacters(in: CharacterSet(charactersIn: ".")) }
            .map { $0 == "p.m" || $0 == "a.m" ? $0 : $0.replacingOccurrences(of: ".", with: "") }
    }
}
