import Foundation

/// What the insights page shows about the current week. Every number here is computed from stored
/// entries and budgets; nothing is estimated by a model.
struct WeekInsights: Equatable, Sendable {
    struct Day: Identifiable, Equatable, Sendable {
        /// 0...6, position in the week.
        let id: Int
        let label: String
        let cents: Int
        let isToday: Bool
        let isFuture: Bool
    }

    struct Slice: Identifiable, Equatable, Sendable {
        let category: Category
        let cents: Int
        /// 0...1 of the week's total.
        let share: Double
        var id: Category { category }
    }

    struct Tip: Identifiable, Equatable, Sendable {
        enum Tone: Sendable { case good, watch, alert, neutral }
        let id: String
        let symbol: String
        let tone: Tone
        let title: String
        let detail: String
    }

    let totalCents: Int
    let entryCount: Int
    let days: [Day]
    let slices: [Slice]
    let tips: [Tip]
    /// Spending so far divided by the days of the week that have started.
    let averagePerDayCents: Int

    static func make(entries: [Entry], statuses: [BudgetStatus], now: Date,
                     calendar: Calendar = .current) -> WeekInsights {
        let week = BudgetMath.weekInterval(containing: now, calendar: calendar)
        let total = entries.reduce(0) { $0 + $1.amountCents }
        let todayStart = calendar.startOfDay(for: now)

        var days: [Day] = []
        var daysStarted = 0
        for index in 0..<7 {
            guard let start = calendar.date(byAdding: .day, value: index, to: week.start),
                  let end = calendar.date(byAdding: .day, value: 1, to: start) else { continue }
            let spent = entries.filter { $0.date >= start && $0.date < end }.reduce(0) { $0 + $1.amountCents }
            let weekday = calendar.component(.weekday, from: start)
            let isFuture = start > todayStart
            if !isFuture { daysStarted += 1 }
            days.append(Day(id: index, label: calendar.veryShortWeekdaySymbols[weekday - 1], cents: spent,
                            isToday: start == todayStart, isFuture: isFuture))
        }
        daysStarted = max(daysStarted, 1)

        let byCategory = BudgetMath.spentByCategory(entries)
        let slices = byCategory
            .filter { $0.value > 0 }
            .sorted { $0.value != $1.value ? $0.value > $1.value : $0.key.rawValue < $1.key.rawValue }
            .map { Slice(category: $0.key, cents: $0.value, share: total > 0 ? Double($0.value) / Double(total) : 0) }

        let average = total / daysStarted
        return WeekInsights(totalCents: total, entryCount: entries.count, days: days, slices: slices,
                            tips: tips(entries: entries, statuses: statuses, slices: slices, total: total,
                                       average: average, daysStarted: daysStarted),
                            averagePerDayCents: average)
    }

    private static func tips(entries: [Entry], statuses: [BudgetStatus], slices: [Slice], total: Int,
                             average: Int, daysStarted: Int) -> [Tip] {
        guard !entries.isEmpty else {
            return [Tip(id: "empty", symbol: "waveform", tone: .neutral, title: "Nothing logged yet",
                        detail: "Hold the button and say what you spent.")]
        }
        var tips: [Tip] = []
        let daysLeft = 7 - daysStarted

        for status in statuses where BudgetMath.level(of: status) == .over {
            tips.append(Tip(id: "over-\(status.category.rawValue)", symbol: "exclamationmark.triangle.fill", tone: .alert,
                            title: "Over on \(status.category.displayName)",
                            detail: "\(Money.format(cents: -status.remainingCents)) past your \(Money.format(cents: status.limitCents)) weekly budget."))
        }
        for status in statuses where [.low, .spent].contains(BudgetMath.level(of: status)) {
            let time = daysLeft == 0 ? "on the last day of the week" : "with \(daysLeft) \(daysLeft == 1 ? "day" : "days") to go"
            tips.append(Tip(id: "low-\(status.category.rawValue)", symbol: "gauge.with.dots.needle.67percent", tone: .watch,
                            title: "\(status.category.displayName) is nearly used up",
                            detail: "\(Money.format(cents: max(status.remainingCents, 0))) left of \(Money.format(cents: status.limitCents)), \(time)."))
        }
        let budgeted = Set(statuses.map(\.category))
        if let top = slices.first(where: { !budgeted.contains($0.category) }), top.cents >= 2000 {
            tips.append(Tip(id: "nobudget-\(top.category.rawValue)", symbol: "target", tone: .watch,
                            title: "No budget for \(top.category.displayName)",
                            detail: "\(Money.format(cents: top.cents)) there this week. Say “set my \(top.category.displayName.lowercased()) budget to…” to keep an eye on it."))
        }
        if let top = slices.first, slices.count > 1 {
            tips.append(Tip(id: "top", symbol: "chart.pie.fill", tone: .neutral,
                            title: "\(top.category.displayName) leads the week",
                            detail: "\(Int((top.share * 100).rounded()))% of what you spent, \(Money.format(cents: top.cents))."))
        }
        if entries.count > 1, let biggest = entries.max(by: { $0.amountCents < $1.amountCents }) {
            let place = biggest.merchant.map { "at \($0)" } ?? "on \(biggest.category.displayName.lowercased())"
            tips.append(Tip(id: "biggest", symbol: "arrow.up.right.circle.fill", tone: .neutral,
                            title: "Biggest single expense",
                            detail: "\(Money.format(cents: biggest.amountCents)) \(place)."))
        }
        if daysStarted >= 2, daysLeft > 0 {
            tips.append(Tip(id: "pace", symbol: "speedometer", tone: .neutral, title: "At this pace",
                            detail: "About \(Money.format(cents: average * 7)) by the end of the week: \(Money.format(cents: average)) a day so far, times seven."))
        }
        if !statuses.isEmpty, !tips.contains(where: { $0.tone == .alert || $0.tone == .watch }) {
            tips.insert(Tip(id: "ontrack", symbol: "checkmark.seal.fill", tone: .good, title: "On track",
                            detail: "Every budget still has room."), at: 0)
        }
        return Array(tips.prefix(5))
    }
}
