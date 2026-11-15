import Foundation

/// A weekly spending limit for one category.
struct Budget: Identifiable, Equatable, Sendable {
    let category: Category
    var weeklyLimitCents: Int
    var id: Category { category }
}

/// A budget plus what has been spent against it in the current week.
struct BudgetStatus: Identifiable, Equatable, Sendable {
    let category: Category
    let limitCents: Int
    let spentCents: Int
    var id: Category { category }
    var remainingCents: Int { limitCents - spentCents }
    /// 0...1, how much of the limit is used (clamped).
    var fractionUsed: Double {
        guard limitCents > 0 else { return 1 }
        return min(max(Double(spentCents) / Double(limitCents), 0), 1)
    }
}

/// A heads-up that a weekly budget is running low or has been exceeded. Built only from stored numbers.
struct Nudge: Identifiable, Equatable, Sendable {
    enum Level: Int, Comparable, Sendable {
        case fine = 0, low, spent, over
        static func < (a: Level, b: Level) -> Bool { a.rawValue < b.rawValue }
    }

    let id: UUID
    let category: Category
    let level: Level
    let remainingCents: Int
    let limitCents: Int

    init(id: UUID = UUID(), category: Category, level: Level, remainingCents: Int, limitCents: Int) {
        self.id = id
        self.category = category
        self.level = level
        self.remainingCents = remainingCents
        self.limitCents = limitCents
    }

    var message: String {
        switch level {
        case .fine: "You're on track with \(category.displayName) this week."
        case .low: "Only \(Money.format(cents: remainingCents)) left for \(category.displayName) this week."
        case .spent: "That's your whole \(category.displayName) budget for this week."
        case .over: "You're \(Money.format(cents: -remainingCents)) over your \(category.displayName) budget this week."
        }
    }
}
