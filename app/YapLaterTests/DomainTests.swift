import Testing
import Foundation
@testable import YapLater

struct AmountEvidenceTests {
    @Test(arguments: [
        ("Just spent fifty bucks on groceries", 5_000),
        ("Coffee was six fifty", 650),
        ("Coffee was six fifty", 65_000),
        ("Dinner was thirteen forty five", 1_345),
        ("Nineteen ninety nine for a shirt", 1_999),
        ("I paid $45.99 for a shirt", 4_599),
        ("Spent a hundred and twenty on shoes", 12_000),
        ("Rent is twelve hundred dollars", 120_000),
        ("one hundred fifty dollars a week", 15_000),
        ("Uber was twenty two dollars", 2_200),
        ("twenty-two dollars", 2_200),
        ("five dollars and twenty cents", 520),
        ("six dollars and fifty cents", 650),
        ("a buck fifty", 150),
        ("two grand for the laptop", 200_000),
        ("Grab the coffee. Uh, 650.", 650),
        ("paid 1,200 for rent", 120_000),
        ("6 50 for a latte", 650),
    ])
    func saidAmountsAreSupported(transcript: String, cents: Int) {
        #expect(AmountEvidence.supports(cents: cents, in: transcript))
    }

    @Test(arguments: [
        ("Grabbed a coffee", 500),
        ("Bought some groceries at Trader Joe's", 5_000),
        ("Spent twelve on lunch", 2_000),
        ("fifty bucks on groceries", 15_000),
        ("I have one question about lunch", 1_200),
    ])
    func inventedAmountsAreNot(transcript: String, cents: Int) {
        #expect(!AmountEvidence.supports(cents: cents, in: transcript))
    }
}

struct BudgetMathTests {
    private func status(limit: Int, spent: Int) -> BudgetStatus {
        BudgetStatus(category: .groceries, limitCents: limit, spentCents: spent)
    }

    @Test func levelsFollowTheRule() {
        #expect(BudgetMath.level(of: status(limit: 10_000, spent: 7_400)) == .fine)
        #expect(BudgetMath.level(of: status(limit: 10_000, spent: 7_500)) == .low)   // 25% left
        #expect(BudgetMath.level(of: status(limit: 40_000, spent: 34_000)) == .fine) // $60 left of $400
        #expect(BudgetMath.level(of: status(limit: 40_000, spent: 35_000)) == .low)  // $50 left
        #expect(BudgetMath.level(of: status(limit: 10_000, spent: 10_000)) == .spent)
        #expect(BudgetMath.level(of: status(limit: 10_000, spent: 10_001)) == .over)
    }

    @Test func aNudgeFiresOnlyWhenTheLevelGetsWorse() {
        let fine = status(limit: 20_000, spent: 10_000), low = status(limit: 20_000, spent: 15_000)
        let lower = status(limit: 20_000, spent: 16_000), over = status(limit: 20_000, spent: 21_200)
        #expect(BudgetMath.nudge(before: fine, after: low)?.message == "Only $50 left for Groceries this week.")
        #expect(BudgetMath.nudge(before: low, after: lower) == nil)
        #expect(BudgetMath.nudge(before: lower, after: over)?.message == "You're $12 over your Groceries budget this week.")
        #expect(BudgetMath.nudge(before: over, after: fine) == nil)
        #expect(BudgetMath.nudge(before: nil, after: fine) == nil)
    }

    @Test func totalsOnlyCountTheirOwnCategory() {
        let entries = [Entry(amountCents: 500, category: .coffee, transcript: ""),
                       Entry(amountCents: 700, category: .coffee, transcript: ""),
                       Entry(amountCents: 4_000, category: .groceries, transcript: "")]
        let statuses = BudgetMath.statuses(entries: entries, budgets: [Budget(category: .coffee, weeklyLimitCents: 2_500),
                                                                       Budget(category: .fun, weeklyLimitCents: 4_000)])
        #expect(statuses == [BudgetStatus(category: .coffee, limitCents: 2_500, spentCents: 1_200),
                             BudgetStatus(category: .fun, limitCents: 4_000, spentCents: 0)])
    }

    @Test func theWeekStartsOnTheCalendarsFirstWeekday() {
        var sundayFirst = Calendar(identifier: .gregorian)
        sundayFirst.timeZone = TimeZone(identifier: "America/New_York")!
        sundayFirst.firstWeekday = 1
        var mondayFirst = sundayFirst
        mondayFirst.firstWeekday = 2
        let wednesday = Date(timeIntervalSince1970: 1_795_000_000) // Wed Nov 18, 2026
        #expect(sundayFirst.component(.weekday, from: BudgetMath.weekInterval(containing: wednesday, calendar: sundayFirst).start) == 1)
        #expect(mondayFirst.component(.weekday, from: BudgetMath.weekInterval(containing: wednesday, calendar: mondayFirst).start) == 2)
    }
}

struct DatePhraseTests {
    private let now = Date(timeIntervalSince1970: 1_794_754_800) // Sunday Nov 15, 2026, 10:00 New York
    private func request(_ text: String) -> InterpretationRequest {
        InterpretationRequest(transcript: text, referenceInstant: now, timeZone: TimeZone(identifier: "America/New_York")!)
    }
    private func daysBack(_ date: Date) -> Int { Int((now.timeIntervalSince(date) / 86_400).rounded()) }

    @Test func relativeDaysResolveAgainstTheRequestClock() {
        #expect(DatePhrase.resolve(nil, request: request("lunch was twelve dollars")) == now)
        #expect(daysBack(DatePhrase.resolve("yesterday", request: request("x"))) == 1)
        #expect(daysBack(DatePhrase.resolve(nil, request: request("took an Uber last night"))) == 1)
        #expect(daysBack(DatePhrase.resolve("two days ago", request: request("x"))) == 2)
        #expect(daysBack(DatePhrase.resolve("on Friday", request: request("x"))) == 2)
        #expect(daysBack(DatePhrase.resolve("last Sunday", request: request("x"))) == 7)
    }
}

@MainActor
struct SwiftDataLedgerStoreTests {
    private let week = DateInterval(start: Date(timeIntervalSince1970: 1_794_700_000), duration: 7 * 86_400)
    private func entry(_ cents: Int, offset: TimeInterval, id: UUID = UUID()) -> Entry {
        Entry(id: id, amountCents: cents, merchant: "Shop", category: .groceries,
              date: week.start.addingTimeInterval(offset), transcript: "t")
    }

    @Test func savingTwiceReplacesAndDeleteRemoves() throws {
        let store = try SwiftDataLedgerStore(inMemory: true)
        let id = UUID()
        try store.upsert(entry(500, offset: 100, id: id))
        try store.upsert(entry(900, offset: 100, id: id))
        #expect(try store.entries(in: week).map(\.amountCents) == [900])
        try store.delete(entryID: id)
        #expect(try store.entries(in: week).isEmpty)
    }

    @Test func entriesAreLimitedToTheWeekAndNewestFirst() throws {
        let store = try SwiftDataLedgerStore(inMemory: true)
        try store.upsert(entry(100, offset: 100))
        try store.upsert(entry(200, offset: 5_000))
        try store.upsert(entry(300, offset: -5_000))          // before the week
        try store.upsert(entry(400, offset: 8 * 86_400))      // after the week
        #expect(try store.entries(in: week).map(\.amountCents) == [200, 100])
    }

    @Test func budgetsReplacePerCategoryAndCanBeRemoved() throws {
        let store = try SwiftDataLedgerStore(inMemory: true)
        try store.setBudget(Budget(category: .coffee, weeklyLimitCents: 2_000))
        try store.setBudget(Budget(category: .coffee, weeklyLimitCents: 2_500))
        try store.setBudget(Budget(category: .fun, weeklyLimitCents: 4_000))
        #expect(Set(try store.budgets()) == [Budget(category: .coffee, weeklyLimitCents: 2_500),
                                              Budget(category: .fun, weeklyLimitCents: 4_000)])
        try store.removeBudget(for: .coffee)
        #expect(try store.budgets() == [Budget(category: .fun, weeklyLimitCents: 4_000)])
    }
}
