import Testing
import Foundation
@testable import YapLater

struct RambleSplitterTests {
    @Test func severalExpensesBecomeOnePieceEach() {
        let pieces = RambleSplitter.pieces(of: "I spent fifty on groceries, twelve dollars on lunch and six fifty on coffee.")
        #expect(pieces.count == 3)
        #expect(pieces.first?.contains("groceries") == true)
        #expect(pieces.last?.contains("coffee") == true)
    }

    @Test func aSingleExpenseIsNotSplit() {
        #expect(RambleSplitter.pieces(of: "Just spent like fifty bucks on groceries at Walmart").isEmpty)
        #expect(RambleSplitter.pieces(of: "Paid the electric bill, eighty four dollars").isEmpty)
        #expect(RambleSplitter.pieces(of: "Grabbed a coffee. Six fifty").isEmpty)
        #expect(RambleSplitter.pieces(of: "Got coffee and a bagel for nine dollars").isEmpty)
    }

    @Test func andInsideAnAmountDoesNotSplit() {
        #expect(RambleSplitter.pieces(of: "Spent a hundred and twenty on new shoes").isEmpty)
        #expect(RambleSplitter.pieces(of: "Lunch was five dollars and fifty cents").isEmpty)
    }

    @Test func remindersAndBudgetsStayWhole() {
        #expect(RambleSplitter.pieces(of: "Remind me at 6 to pay 40 dollars and call mom at 7").isEmpty)
        #expect(RambleSplitter.pieces(of: "Set my coffee budget to 25 and my fun budget to 40").isEmpty)
    }

    @Test func wordsWithoutAnAmountStayWithTheirExpense() {
        let pieces = RambleSplitter.pieces(of: "Went to Target, spent 30 on a shirt, then 8 on lunch, it was good")
        #expect(pieces.count == 2)
        #expect(pieces[0].contains("Target") && pieces[0].contains("30"))
        #expect(pieces[1].hasPrefix("8 on lunch"))
        #expect(RambleSplitter.pieces(of: "Thirty on movies, and 15 at the pharmacy").last == "15 at the pharmacy")
        #expect(RambleSplitter.pieces(of: "Got an Uber for 22 bucks and then dinner was 13") == ["Got an Uber for 22 bucks", "dinner was 13"])
    }
}

@MainActor
struct RambleFlowTests {
    private func makeModel(budgets: [Budget] = []) -> AppModel {
        AppModel(transcriber: MockTranscriber(), interpreter: MockMoneyInterpreter(delay: .zero),
                 store: InMemoryLedgerStore(entries: [], budgets: budgets),
                 speaker: SilentSpeaker(), undoWindow: .seconds(60))
    }

    @Test func aRambleSavesEveryExpenseAndUndoRemovesThemAll() async {
        let model = makeModel(budgets: [Budget(category: .groceries, weeklyLimitCents: 20_000)])
        await model.handle(text: "Spent 50 on groceries, 12 on lunch and 6 on coffee", generation: 0)
        #expect(model.entries.count == 3)
        #expect(model.weekTotalCents == 6800)
        #expect(model.lastSavedGroup.count == 3)
        #expect(model.budgetStatuses.first?.spentCents == 5000)
        model.undoLast()
        #expect(model.entries.isEmpty)
        #expect(model.lastSaved == nil)
        #expect(model.budgetStatuses.first?.spentCents == 0)
    }

    @Test func aRambleWithAPartThatIsNotAnExpenseSavesNothingExtra() async {
        let model = makeModel()
        // The second part has an amount but nothing the mock can place; the whole yap falls back to one request.
        await model.handle(text: "Spent 50 on groceries", generation: 0)
        #expect(model.entries.count == 1)
        #expect(model.lastSavedGroup.count == 1)
    }
}
