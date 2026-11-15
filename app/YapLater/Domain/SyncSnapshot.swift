import Foundation

/// A device's ledger in a form that can be handed to the user's other device. Plain values only.
struct SyncSnapshot: Codable, Equatable, Sendable {
    struct Item: Codable, Equatable, Sendable {
        var id: UUID
        var amountCents: Int
        var merchant: String?
        var category: String
        var date: Date
        var transcript: String
    }

    struct Limit: Codable, Equatable, Sendable {
        var category: String
        var weeklyLimitCents: Int
    }

    var entries: [Item] = []
    var budgets: [Limit] = []

    init(entries: [Entry], budgets: [Budget]) {
        self.entries = entries.map {
            Item(id: $0.id, amountCents: $0.amountCents, merchant: $0.merchant,
                 category: $0.category.rawValue, date: $0.date, transcript: $0.transcript)
        }
        self.budgets = budgets.map { Limit(category: $0.category.rawValue, weeklyLimitCents: $0.weeklyLimitCents) }
    }

    func encoded() -> Data { (try? JSONEncoder().encode(self)) ?? Data() }

    static func decode(_ data: Data) -> SyncSnapshot? { try? JSONDecoder().decode(SyncSnapshot.self, from: data) }

    /// What arrives from the other device is checked like anything else that did not come from this app's own
    /// validator: a known category, a positive amount within the app's limit. Anything else is dropped.
    var validEntries: [Entry] {
        entries.compactMap { item in
            guard let category = Category(rawValue: item.category),
                  item.amountCents > 0, item.amountCents <= ProposalValidator.maxAmountCents else { return nil }
            return Entry(id: item.id, amountCents: item.amountCents, merchant: item.merchant,
                         category: category, date: item.date, transcript: item.transcript)
        }
    }

    var validBudgets: [Budget] {
        budgets.compactMap { limit in
            guard let category = Category(rawValue: limit.category), limit.weeklyLimitCents > 0 else { return nil }
            return Budget(category: category, weeklyLimitCents: limit.weeklyLimitCents)
        }
    }
}
