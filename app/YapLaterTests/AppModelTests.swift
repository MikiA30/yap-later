import Testing
import Foundation
@testable import YapLater

@MainActor
struct AppModelTests {
    private func makeModel(budgets: [Budget] = [], entries: [Entry] = [],
                           speaker: SilentSpeaker? = nil) -> AppModel {
        AppModel(transcriber: MockTranscriber(),
                 interpreter: MockMoneyInterpreter(delay: .zero),
                 store: InMemoryLedgerStore(entries: entries, budgets: budgets),
                 speaker: speaker ?? SilentSpeaker(),
                 undoWindow: .seconds(60))
    }

    @Test func aSpokenExpenseIsSavedAndCategorized() async {
        let model = makeModel()
        #expect(model.usesMocks)
        await model.handle(text: "Just spent like fifty bucks on groceries at Walmart", generation: 0)
        #expect(model.entries.count == 1)
        #expect(model.entries.first?.amountCents == 5000)
        #expect(model.entries.first?.category == .groceries)
        #expect(model.entries.first?.merchant == "Walmart")
        #expect(model.phase == .idle)
        #expect(model.lastSaved != nil)
    }

    @Test func undoRemovesTheEntryAndItsSpending() async {
        let model = makeModel(budgets: [Budget(category: .groceries, weeklyLimitCents: 20_000)])
        await model.handle(text: "spent 50 on groceries", generation: 0)
        #expect(model.budgetStatuses.first?.spentCents == 5000)
        model.undoLast()
        #expect(model.entries.isEmpty)
        #expect(model.budgetStatuses.first?.spentCents == 0)
        #expect(model.lastSaved == nil)
    }

    @Test func aMissingAmountAsksBackAndTheAnswerCompletesTheEntry() async {
        let speaker = SilentSpeaker()
        let model = makeModel(speaker: speaker)
        await model.handle(text: "Grabbed a coffee", generation: 0)
        #expect(model.phase == .asking(question: "How much was it?"))
        #expect(speaker.spoken == ["How much was it?"])
        #expect(model.entries.isEmpty)

        await model.handle(text: "Six fifty", generation: 0)
        #expect(model.entries.count == 1)
        #expect(model.entries.first?.amountCents == 650)
        #expect(model.entries.first?.category == .coffee)
        #expect(model.phase == .idle)
    }

    @Test func crossingTheLowThresholdRaisesOneSpokenNudge() async {
        let speaker = SilentSpeaker()
        let earlier = Entry(amountCents: 10_000, category: .groceries, transcript: "earlier this week")
        let model = makeModel(budgets: [Budget(category: .groceries, weeklyLimitCents: 20_000)],
                              entries: [earlier], speaker: speaker)
        await model.handle(text: "spent 50 on groceries", generation: 0)
        #expect(model.nudge?.level == .low)
        #expect(model.nudge?.message == "Only $50 left for Groceries this week.")
        #expect(speaker.spoken == ["Only $50 left for Groceries this week."])

        model.dismissNudge()
        await model.handle(text: "spent 5 on groceries", generation: 0)
        #expect(model.nudge == nil) // still low, not a new level
    }

    @Test func aBudgetCanBeSetByVoice() async {
        let model = makeModel()
        await model.handle(text: "Set my fun budget to forty a week", generation: 0)
        #expect(model.budgetStatuses == [BudgetStatus(category: .fun, limitCents: 4000, spentCents: 0)])
        #expect(model.lastBudgetSet?.category == .fun)
    }

    @Test func staleResultsAreIgnoredAfterCancel() async {
        let model = makeModel()
        model.cancelYap() // generation is now 1
        await model.handle(text: "spent 50 on groceries", generation: 0)
        #expect(model.entries.isEmpty)
    }

    @Test func proposalDecodesSnakeCase() throws {
        let json = #"{"kind":"budget_set","amount":25,"category":"coffee","period":"week","date_phrase":null}"#
        let proposal = try JSONDecoder().decode(MoneyProposal.self, from: Data(json.utf8))
        #expect(proposal.kind == .budgetSet)
        #expect(proposal.amount == 25)
    }

    @Test func moneyFormatsWholeAndFractionalDollars() {
        #expect(Money.format(cents: 5000) == "$50")
        #expect(Money.format(cents: 650) == "$6.50")
    }
}

struct ProposalParserTests {
    @Test func parsesJSONSurroundedByProse() throws {
        let text = "Sure! Here you go:\n{\"kind\":\"expense\",\"amount\":\"$50\",\"merchant\":\"Walmart\",\"category\":\"Groceries\",\"date_phrase\":null,\"period\":null}\nHope that helps."
        let proposal = try ProposalParser.parse(text)
        #expect(proposal == MoneyProposal(kind: .expense, amount: 50, merchant: "Walmart", category: "groceries"))
    }

    @Test func unknownKindBecomesUnsupportedAndMissingJSONThrows() throws {
        #expect(try ProposalParser.parse(#"{"kind":"transfer","amount":5}"#).kind == .unsupported)
        #expect(throws: ProposalParser.ParseError.noJSON) { try ProposalParser.parse("no json here") }
    }
}
