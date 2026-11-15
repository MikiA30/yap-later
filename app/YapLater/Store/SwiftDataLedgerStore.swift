import Foundation
import SwiftData

@Model
final class EntryRecord {
    @Attribute(.unique) var id: UUID
    var amountCents: Int
    var merchant: String?
    var categoryRaw: String
    var date: Date
    var transcript: String

    init(_ entry: Entry) {
        id = entry.id
        amountCents = entry.amountCents
        merchant = entry.merchant
        categoryRaw = entry.category.rawValue
        date = entry.date
        transcript = entry.transcript
    }

    func apply(_ entry: Entry) {
        amountCents = entry.amountCents
        merchant = entry.merchant
        categoryRaw = entry.category.rawValue
        date = entry.date
        transcript = entry.transcript
    }

    var entry: Entry {
        Entry(id: id, amountCents: amountCents, merchant: merchant,
              category: Category(rawValue: categoryRaw) ?? .other, date: date, transcript: transcript)
    }
}

@Model
final class BudgetRecord {
    @Attribute(.unique) var categoryRaw: String
    var weeklyLimitCents: Int

    init(_ budget: Budget) {
        categoryRaw = budget.category.rawValue
        weeklyLimitCents = budget.weeklyLimitCents
    }
}

/// Entries and budgets in a SwiftData file on this phone. No iCloud, no network.
@MainActor
final class SwiftDataLedgerStore: LedgerStore {
    private let container: ModelContainer
    private var context: ModelContext { container.mainContext }

    init(inMemory: Bool = false) throws {
        if !inMemory, let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            try? FileManager.default.createDirectory(at: support, withIntermediateDirectories: true)
        }
        let configuration = ModelConfiguration("YapLater", isStoredInMemoryOnly: inMemory, cloudKitDatabase: .none)
        container = try ModelContainer(for: EntryRecord.self, BudgetRecord.self, configurations: configuration)
    }

    func entries(in interval: DateInterval) throws -> [Entry] {
        let start = interval.start, end = interval.end
        let descriptor = FetchDescriptor<EntryRecord>(
            predicate: #Predicate { $0.date >= start && $0.date <= end },
            sortBy: [SortDescriptor(\.date, order: .reverse)])
        return try context.fetch(descriptor).map(\.entry)
    }

    func upsert(_ entry: Entry) throws {
        if let existing = try record(for: entry.id) {
            existing.apply(entry)
        } else {
            context.insert(EntryRecord(entry))
        }
        try context.save()
    }

    func delete(entryID: UUID) throws {
        guard let existing = try record(for: entryID) else { return }
        context.delete(existing)
        try context.save()
    }

    func budgets() throws -> [Budget] {
        try context.fetch(FetchDescriptor<BudgetRecord>()).compactMap { record in
            Category(rawValue: record.categoryRaw).map { Budget(category: $0, weeklyLimitCents: record.weeklyLimitCents) }
        }
    }

    func setBudget(_ budget: Budget) throws {
        if let existing = try budgetRecord(for: budget.category) {
            existing.weeklyLimitCents = budget.weeklyLimitCents
        } else {
            context.insert(BudgetRecord(budget))
        }
        try context.save()
    }

    func removeBudget(for category: Category) throws {
        guard let existing = try budgetRecord(for: category) else { return }
        context.delete(existing)
        try context.save()
    }

    private func record(for id: UUID) throws -> EntryRecord? {
        try context.fetch(FetchDescriptor<EntryRecord>(predicate: #Predicate { $0.id == id })).first
    }

    private func budgetRecord(for category: Category) throws -> BudgetRecord? {
        let raw = category.rawValue
        return try context.fetch(FetchDescriptor<BudgetRecord>(predicate: #Predicate { $0.categoryRaw == raw })).first
    }
}
