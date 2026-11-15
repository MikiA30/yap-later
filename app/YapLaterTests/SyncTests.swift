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

    private func makeProfile() -> ProfileStore {
        let suite = "sync-tests-\(UUID().uuidString)"
        let file = FileManager.default.temporaryDirectory.appendingPathComponent("\(suite).jpg")
        return ProfileStore(defaults: UserDefaults(suiteName: suite)!, photoFile: file)
    }

    @Test func aNameSetOnOneDeviceReachesTheOtherAndTheNewerOneWins() {
        let phone = AppModel(transcriber: MockTranscriber(), interpreter: MockMoneyInterpreter(delay: .zero),
                             store: InMemoryLedgerStore(), speaker: SilentSpeaker(), profile: makeProfile())
        let mac = AppModel(transcriber: MockTranscriber(), interpreter: MockMoneyInterpreter(delay: .zero),
                           store: InMemoryLedgerStore(), speaker: SilentSpeaker(), profile: makeProfile())
        phone.profile.name = "Miki A"

        // An empty device takes what arrives, and survives the trip through JSON.
        var snapshot = phone.syncSnapshot()
        snapshot.profile = phone.profile.forSync
        #expect(mac.mergeProfile(SyncSnapshot.decode(snapshot.encoded())?.profile))
        #expect(mac.profile.name == "Miki A")
        #expect(mac.profile.changedAt == phone.profile.changedAt)

        // The same profile coming back changes nothing, and neither does an empty one.
        #expect(!phone.mergeProfile(mac.profile.forSync))
        #expect(!mac.mergeProfile(SyncSnapshot.Profile(name: "", photo: nil, changedAt: .distantFuture)))
        #expect(!mac.mergeProfile(nil))

        // An older change loses; a newer one wins.
        #expect(!mac.mergeProfile(SyncSnapshot.Profile(name: "Old", photo: nil, changedAt: .distantPast)))
        #expect(mac.mergeProfile(SyncSnapshot.Profile(name: "New Name", photo: nil, changedAt: .distantFuture)))
        #expect(mac.profile.name == "New Name")
    }

    @Test func aLedgerSavedBeforeProfilesExistedStillDecodes() {
        let old = Data(#"{"entries":[],"budgets":[]}"#.utf8)
        #expect(SyncSnapshot.decode(old)?.profile == nil)
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
