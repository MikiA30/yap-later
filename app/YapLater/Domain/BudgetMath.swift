import Foundation

/// Pure budget arithmetic. No storage, no clock of its own.
enum BudgetMath {
    /// The app's week runs Monday through Sunday, so a weekend's spending counts against the week it ends.
    static let calendar: Calendar = {
        var calendar = Calendar.current
        calendar.firstWeekday = 2
        return calendar
    }()

    /// The week containing `date`: Monday to Sunday unless another calendar is given.
    static func weekInterval(containing date: Date, calendar: Calendar = BudgetMath.calendar) -> DateInterval {
        calendar.dateInterval(of: .weekOfYear, for: date) ?? DateInterval(start: date, duration: 7 * 86_400)
    }

    static func spentByCategory(_ entries: [Entry]) -> [Category: Int] {
        entries.reduce(into: [:]) { $0[$1.category, default: 0] += $1.amountCents }
    }

    /// One status per budget, in `Category.allCases` order. `entries` must already be limited to the week.
    static func statuses(entries: [Entry], budgets: [Budget]) -> [BudgetStatus] {
        let spent = spentByCategory(entries)
        let order = Dictionary(uniqueKeysWithValues: Category.allCases.enumerated().map { ($1, $0) })
        return budgets
            .sorted { order[$0.category, default: 0] < order[$1.category, default: 0] }
            .map { BudgetStatus(category: $0.category, limitCents: $0.weeklyLimitCents,
                                spentCents: spent[$0.category, default: 0]) }
    }

    /// At or below this remaining amount, a budget counts as "low": 25% of the limit, or $50 for limits over $200.
    static func lowThresholdCents(limitCents: Int) -> Int {
        limitCents > 20_000 ? 5_000 : limitCents / 4
    }

    static func level(of status: BudgetStatus) -> Nudge.Level {
        if status.remainingCents < 0 { return .over }
        if status.remainingCents == 0 { return .spent }
        if status.remainingCents <= lowThresholdCents(limitCents: status.limitCents) { return .low }
        return .fine
    }

    /// A nudge when a change moved a budget into a worse level than before; otherwise nil.
    static func nudge(before: BudgetStatus?, after: BudgetStatus) -> Nudge? {
        let old = before.map(level(of:)) ?? .fine
        let new = level(of: after)
        guard new > old, new != .fine else { return nil }
        return Nudge(category: after.category, level: new,
                     remainingCents: after.remainingCents, limitCents: after.limitCents)
    }
}
