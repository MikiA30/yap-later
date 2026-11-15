#if DEBUG
import Foundation

/// A made-up but ordinary five days of spending, used to show the charts and budgets with some history
/// before a live demo. It is demo data: the entries carry fixed ids, are marked in their transcript,
/// and can be removed again without touching anything the user logged.
enum DemoWeek {
    private struct Row {
        let daysAgo: Int
        let hour: Int
        let minute: Int
        let cents: Int
        let category: Category
        let merchant: String?
    }

    private static let rows: [Row] = [
        Row(daysAgo: 5, hour: 8, minute: 10, cents: 525, category: .coffee, merchant: "Starbucks"),
        Row(daysAgo: 5, hour: 12, minute: 35, cents: 1345, category: .dining, merchant: "Chipotle"),
        Row(daysAgo: 5, hour: 22, minute: 15, cents: 1400, category: .transport, merchant: "Uber"),
        Row(daysAgo: 4, hour: 9, minute: 5, cents: 475, category: .coffee, merchant: nil),
        Row(daysAgo: 4, hour: 18, minute: 5, cents: 4680, category: .groceries, merchant: "Trader Joe's"),
        Row(daysAgo: 3, hour: 8, minute: 40, cents: 525, category: .coffee, merchant: "Starbucks"),
        Row(daysAgo: 3, hour: 19, minute: 30, cents: 1860, category: .dining, merchant: "Thai Basil"),
        Row(daysAgo: 3, hour: 21, minute: 0, cents: 1600, category: .fun, merchant: nil),
        Row(daysAgo: 2, hour: 13, minute: 10, cents: 1150, category: .dining, merchant: nil),
        Row(daysAgo: 2, hour: 17, minute: 20, cents: 3200, category: .transport, merchant: "Shell"),
        Row(daysAgo: 2, hour: 18, minute: 0, cents: 3820, category: .groceries, merchant: "Wegmans"),
        Row(daysAgo: 2, hour: 21, minute: 30, cents: 1200, category: .fun, merchant: nil),
        Row(daysAgo: 1, hour: 10, minute: 45, cents: 1500, category: .groceries, merchant: "Farmers market"),
        Row(daysAgo: 1, hour: 14, minute: 20, cents: 2799, category: .shopping, merchant: "Target"),
        Row(daysAgo: 1, hour: 16, minute: 5, cents: 949, category: .health, merchant: "CVS"),
    ]

    static let ids: [UUID] = rows.indices.map { UUID(uuidString: String(format: "DE300000-0000-4000-8000-%012d", $0))! }

    /// Groceries stands at $100 of $200, so a live $50 grocery yap leaves exactly the $50 that raises the nudge.
    static let budgets: [Budget] = [
        Budget(category: .groceries, weeklyLimitCents: 20_000),
        Budget(category: .coffee, weeklyLimitCents: 2_500),
        Budget(category: .dining, weeklyLimitCents: 8_000),
        Budget(category: .transport, weeklyLimitCents: 6_000),
        Budget(category: .fun, weeklyLimitCents: 4_000),
    ]

    static func entries(now: Date, calendar: Calendar = BudgetMath.calendar) -> [Entry] {
        let today = calendar.startOfDay(for: now)
        return rows.enumerated().compactMap { index, row in
            guard let day = calendar.date(byAdding: .day, value: -row.daysAgo, to: today),
                  let date = calendar.date(bySettingHour: row.hour, minute: row.minute, second: 0, of: day) else { return nil }
            return Entry(id: ids[index], amountCents: row.cents, merchant: row.merchant, category: row.category,
                         date: date, transcript: "Demo entry")
        }
    }
}
#endif
