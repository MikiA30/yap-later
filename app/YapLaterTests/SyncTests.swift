import Testing
import Foundation
@testable import YapLater

@MainActor
struct SyncTests {
    private func makeModel(entries: [Entry] = [], budgets: [Budget] = []) -> AppModel {
        AppModel(transcriber: MockTranscriber(), interpreter: MockMoneyInterpreter(delay: .zero),
                 store: InMemoryLedgerStore(entries: entries, budgets: budgets), speaker: SilentSpeaker())
    }

    @Test func twoDevicesEndUpWithTheSameEntriesAndNoDuplicates() {
        let lunch = Entry(amountCents: 1200, category: .dining, transcript: "lunch")
        let coffee = Entry(amountCents: 650, category: .coffee, transcript: "coffee")
        let phone = makeModel(entries: [lunch], budgets: [Budget(category: .coffee, weeklyLimitCents: 2500)])
        let mac = makeModel(entries: [coffee])

        // The same exchange the Bluetooth link carries: phone to Mac, then the Mac's merged ledger back.
        let fromPhone = SyncSnapshot.decode(phone.syncSnapshot().encoded())
        #expect(mac.merge(fromPhone!) == 1)
        #expect(phone.merge(SyncSnapshot.decode(mac.syncSnapshot().encoded())!) == 1)

        #expect(Set(phone.entries.map(\.id)) == [lunch.id, coffee.id])
        #expect(Set(mac.entries.map(\.id)) == [lunch.id, coffee.id])
        #expect(mac.budgetStatuses.first?.limitCents == 2500)
        #expect(mac.merge(phone.syncSnapshot()) == 0) // syncing again adds nothing
        #expect(mac.entries.count == 2)
    }

    @Test func aBudgetAlreadySetHereIsNotOverwritten() {
        let mac = makeModel(budgets: [Budget(category: .coffee, weeklyLimitCents: 4000)])
        mac.merge(SyncSnapshot(entries: [], budgets: [Budget(category: .coffee, weeklyLimitCents: 2500)]))
        #expect(mac.budgetStatuses.first?.limitCents == 4000)
    }

    @Test func badDataFromTheOtherDeviceIsDropped() {
        var snapshot = SyncSnapshot(entries: [Entry(amountCents: 500, category: .fun, transcript: "ok")], budgets: [])
        snapshot.entries.append(.init(id: UUID(), amountCents: -5, merchant: nil, category: "fun", date: .now, transcript: ""))
        snapshot.entries.append(.init(id: UUID(), amountCents: 500, merchant: nil, category: "yachts", date: .now, transcript: ""))
        snapshot.budgets.append(.init(category: "yachts", weeklyLimitCents: 100))
        let model = makeModel()
        #expect(model.merge(snapshot) == 1)
        #expect(model.budgetStatuses.isEmpty)
    }

    @Test func aLedgerSurvivesBeingCutIntoBluetoothSizedPieces() {
        let entries = (0..<40).map { Entry(amountCents: 100 + $0, category: .other, transcript: "entry \($0)") }
        let data = SyncSnapshot(entries: entries, budgets: []).encoded()
        let pieces = BluetoothSync.pieces(of: data, size: 182)
        #expect(pieces.last == BluetoothSync.end)
        #expect(pieces.dropLast().allSatisfy { $0.count <= 182 && $0 != BluetoothSync.end })
        let joined = pieces.dropLast().reduce(Data(), +)
        #expect(SyncSnapshot.decode(joined)?.entries.count == 40)
    }
}
