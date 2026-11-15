import Testing
import Foundation
@testable import YapLater

@MainActor
struct MockFlowTests {
    private func makeModel() -> YapModel {
        YapModel(transcriber: MockTranscriber(), interpreter: MockMoneyInterpreter())
    }

    @Test func mockYapAddsAGroceriesEntry() async {
        let model = makeModel()
        #expect(model.usesMocks)
        await model.run(generation: 0)
        #expect(model.entries.count == 1)
        #expect(model.entries.first?.amountCents == 5000)
        #expect(model.entries.first?.category == .groceries)
        #expect(model.entries.first?.merchant == "Walmart")
        #expect(model.phase == .idle)
    }

    @Test func undoRemovesTheLastEntry() async {
        let model = makeModel()
        await model.run(generation: 0)
        model.undoLast()
        #expect(model.entries.isEmpty)
        #expect(model.weekTotalCents == 0)
    }

    @Test func staleResultsAreIgnoredAfterCancel() async {
        let model = makeModel()
        model.cancel() // generation is now 1
        await model.run(generation: 0)
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
