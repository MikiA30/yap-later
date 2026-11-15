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
        case unsupported
    }

    var kind: Kind
    var amount: Double?
    var merchant: String?
    var category: String?
    var datePhrase: String?
    var period: String?
    var question: String?

    enum CodingKeys: String, CodingKey {
        case kind, amount, merchant, category, period, question
        case datePhrase = "date_phrase"
    }
}
