import Testing
import Foundation
@testable import YapLater

struct WeekInsightsTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York")!
        calendar.firstWeekday = 1
        return calendar
    }

    /// Wednesday, November 18, 2026, noon.
    private var wednesday: Date {
        calendar.date(from: DateComponents(year: 2026, month: 11, day: 18, hour: 12))!
    }

    private func entry(_ cents: Int, _ category: YapLater.Category, daysAgo: Int = 0, merchant: String? = nil) -> Entry {
        Entry(amountCents: cents, merchant: merchant, category: category,
              date: calendar.date(byAdding: .day, value: -daysAgo, to: wednesday)!, transcript: "")
    }

    @Test func daysAndSharesAddUpToTheTotal() {
        let entries = [entry(5000, .groceries, merchant: "Walmart"), entry(1200, .dining, daysAgo: 1), entry(800, .coffee, daysAgo: 3)]
        let insights = WeekInsights.make(entries: entries, statuses: [], now: wednesday, calendar: calendar)
        #expect(insights.totalCents == 7000)
        #expect(insights.days.count == 7)
        #expect(insights.days.map(\.cents) == [800, 0, 1200, 5000, 0, 0, 0]) // Sunday first
        #expect(insights.days[3].isToday)
        #expect(insights.days[4].isFuture && !insights.days[3].isFuture)
        #expect(insights.slices.map(\.category) == [.groceries, .dining, .coffee])
        #expect(abs(insights.slices.reduce(0) { $0 + $1.share } - 1) < 0.0001)
        #expect(insights.averagePerDayCents == 7000 / 4) // Sunday through Wednesday
    }

    @Test func tipsNameTheBudgetsThatNeedAttentionUsingStoredNumbers() {
        let entries = [entry(3000, .coffee), entry(5000, .groceries, merchant: "Walmart")]
        let statuses = [BudgetStatus(category: .coffee, limitCents: 2500, spentCents: 3000),
                        BudgetStatus(category: .groceries, limitCents: 6000, spentCents: 5000)]
        let tips = WeekInsights.make(entries: entries, statuses: statuses, now: wednesday, calendar: calendar).tips
        #expect(tips.first?.title == "Over on Coffee")
        #expect(tips.first?.detail.contains("$5") == true)
        #expect(tips.contains { $0.title == "Groceries is nearly used up" && $0.detail.contains("$10 left of $60") && $0.detail.contains("3 days") })
        #expect(tips.contains { $0.title == "Biggest single expense" && $0.detail.contains("Walmart") })
        #expect(!tips.contains { $0.tone == .good })
    }

    @Test func aQuietWeekSaysSo() {
        let empty = WeekInsights.make(entries: [], statuses: [], now: wednesday, calendar: calendar)
        #expect(empty.tips.map(\.id) == ["empty"])
        #expect(empty.totalCents == 0 && empty.slices.isEmpty)

        let fine = WeekInsights.make(entries: [entry(500, .coffee)],
                                     statuses: [BudgetStatus(category: .coffee, limitCents: 2500, spentCents: 500)],
                                     now: wednesday, calendar: calendar)
        #expect(fine.tips.first?.title == "On track")
    }
}
