import Foundation

/// Local persistence for entries and budgets. Nothing here touches the network.
@MainActor
protocol LedgerStore: AnyObject {
    /// Entries whose date falls in `interval`, newest first.
    func entries(in interval: DateInterval) throws -> [Entry]
    /// Inserts, or replaces the entry with the same `id`. Saving the same entry twice never duplicates it.
    func upsert(_ entry: Entry) throws
    func delete(entryID: UUID) throws
    func budgets() throws -> [Budget]
    /// Creates or replaces the budget for its category.
    func setBudget(_ budget: Budget) throws
    func removeBudget(for category: Category) throws
}

/// Keeps everything in memory. Used by tests, previews, and mock mode.
@MainActor
final class InMemoryLedgerStore: LedgerStore {
    private var entriesByID: [UUID: Entry] = [:]
    private var budgetsByCategory: [Category: Budget] = [:]

    init(entries: [Entry] = [], budgets: [Budget] = []) {
        entries.forEach { entriesByID[$0.id] = $0 }
        budgets.forEach { budgetsByCategory[$0.category] = $0 }
    }

    func entries(in interval: DateInterval) throws -> [Entry] {
        entriesByID.values.filter { interval.contains($0.date) }.sorted { $0.date > $1.date }
    }

    func upsert(_ entry: Entry) throws { entriesByID[entry.id] = entry }
    func delete(entryID: UUID) throws { entriesByID[entryID] = nil }
    func budgets() throws -> [Budget] { Array(budgetsByCategory.values) }
    func setBudget(_ budget: Budget) throws { budgetsByCategory[budget.category] = budget }
    func removeBudget(for category: Category) throws { budgetsByCategory[category] = nil }
}
