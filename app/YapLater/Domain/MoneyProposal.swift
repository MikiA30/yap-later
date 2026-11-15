import Foundation

/// What the app sends to an interpreter. The app owns the clock; the model never supplies "now".
struct InterpretationRequest: Sendable {
    let id: UUID
    let transcript: String
    let referenceInstant: Date
    let timeZoneID: String
    let localeID: String

    init(transcript: String, referenceInstant: Date = .now,
         timeZone: TimeZone = .current, locale: Locale = .current) {
        self.id = UUID()
        self.transcript = transcript
        self.referenceInstant = referenceInstant
        self.timeZoneID = timeZone.identifier
        self.localeID = locale.identifier
    }
}

/// Untrusted output of an interpreter. Validation happens in app code before anything is stored.
struct MoneyProposal: Codable, Equatable, Sendable {
    enum Kind: String, Codable, Sendable {
        case expense
        case budgetSet = "budget_set"
        /// A request to be reminded of something, or a bill that is due.
        case reminder
        case unsupported
    }

    var kind: Kind
    var amount: Double?
    var merchant: String?
    var category: String?
    var datePhrase: String?
    var period: String?
    var question: String?

    // Reminder details (only for `.reminder`). The model normalizes words to numbers; app code builds the date.
    var title: String?
    /// "today", "tomorrow", a weekday name, or "date" when `dayOfMonth` (and maybe `month`) is given.
    var day: String?
    var dayOfMonth: Int?
    var month: Int?
    /// 0...23 as said; app code applies morning/evening words and asks when it is unclear.
    var hour: Int?
    var minute: Int?
    var inMinutes: Int?

    enum CodingKeys: String, CodingKey {
        case kind, amount, merchant, category, period, question, title, day, month, hour, minute
        case datePhrase = "date_phrase"
        case dayOfMonth = "day_of_month"
        case inMinutes = "in_minutes"
    }
}
