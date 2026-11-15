import Testing
import Foundation
@testable import YapLater

struct ReminderResolverTests {
    /// Sunday, November 15, 2026, 10:00 in New York.
    private let now = Date(timeIntervalSince1970: 1_794_754_800)
    private func request(_ text: String) -> InterpretationRequest {
        InterpretationRequest(transcript: text, referenceInstant: now,
                              timeZone: TimeZone(identifier: "America/New_York")!, locale: Locale(identifier: "en_US"))
    }
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York")!
        return calendar
    }
    private func parts(_ outcome: ValidationOutcome) -> DateComponents? {
        guard case .reminder(let draft) = outcome else { return nil }
        return calendar.dateComponents([.year, .month, .day, .hour, .minute], from: draft.dueAt)
    }

    @Test func tomorrowAtSixPM() {
        var proposal = MoneyProposal(kind: .reminder)
        proposal.title = "call mom"; proposal.day = "tomorrow"; proposal.hour = 18; proposal.minute = 0
        let outcome = ReminderResolver.resolve(proposal, request: request("Remind me to call mom tomorrow at six pm"))
        #expect(parts(outcome) == DateComponents(year: 2026, month: 11, day: 16, hour: 18, minute: 0))
        if case .reminder(let draft) = outcome { #expect(draft.title == "Call mom") }
    }

    @Test func anHourWithoutMorningOrEveningAsks() {
        var proposal = MoneyProposal(kind: .reminder)
        proposal.title = "Email Professor Lee"; proposal.hour = 6; proposal.minute = 0
        #expect(ReminderResolver.resolve(proposal, request: request("Remind me to email Professor Lee at six"))
                == .askBack(question: "At 6, morning or evening?"))
    }

    @Test func eveningWordsMoveTheHourEvenIfTheModelDidNot() {
        var proposal = MoneyProposal(kind: .reminder)
        proposal.title = "Email Professor Lee"; proposal.hour = 6; proposal.minute = 0
        let outcome = ReminderResolver.resolve(proposal, request: request("Remind me to email Professor Lee at six. Evening"))
        #expect(parts(outcome) == DateComponents(year: 2026, month: 11, day: 15, hour: 18, minute: 0))
    }

    @Test func inMinutesIsRelativeToTheRequest() {
        var proposal = MoneyProposal(kind: .reminder)
        proposal.title = "Check the oven"; proposal.inMinutes = 10
        guard case .reminder(let draft) = ReminderResolver.resolve(proposal, request: request("in ten minutes")) else {
            Issue.record("expected a reminder"); return
        }
        #expect(draft.dueAt == now.addingTimeInterval(600))
    }

    @Test func aBillOnTheFirstDefaultsToNineAndKeepsItsAmount() {
        var proposal = MoneyProposal(kind: .reminder, amount: 1200)
        proposal.title = "Pay rent"; proposal.day = "date"; proposal.dayOfMonth = 1
        let outcome = ReminderResolver.resolve(proposal, request: request("Rent is due on the first, twelve hundred dollars"))
        #expect(parts(outcome) == DateComponents(year: 2026, month: 12, day: 1, hour: 9, minute: 0))
        if case .reminder(let draft) = outcome { #expect(draft.amountCents == 120_000) }
    }

    @Test func aWeekdayMeansTheNextOne() {
        var proposal = MoneyProposal(kind: .reminder)
        proposal.title = "Take out the trash"; proposal.day = "thursday"; proposal.hour = 7; proposal.minute = 30
        let outcome = ReminderResolver.resolve(proposal, request: request("on Thursday at seven thirty in the morning"))
        #expect(parts(outcome) == DateComponents(year: 2026, month: 11, day: 19, hour: 7, minute: 30))
    }

    @Test func noTitleOrNoTimeAsks() {
        #expect(ReminderResolver.resolve(MoneyProposal(kind: .reminder), request: request("remind me"))
                == .askBack(question: "What should I remind you about?"))
        var proposal = MoneyProposal(kind: .reminder)
        proposal.title = "Water the plants"
        #expect(ReminderResolver.resolve(proposal, request: request("Remind me to water the plants"))
                == .askBack(question: "When should I remind you?"))
    }
}

@MainActor
struct ReminderFlowTests {
    @Test func aReminderIsOnlySavedAfterConfirming() async {
        let saver = RecordingReminderSaver()
        let model = AppModel(transcriber: MockTranscriber(), interpreter: MockMoneyInterpreter(delay: .zero),
                             store: InMemoryLedgerStore(), speaker: SilentSpeaker(), reminders: saver)
        await model.handle(text: "Remind me to check the oven in 10 minutes", generation: 0)
        #expect(model.pendingReminder?.title == "Check the oven")
        #expect(saver.saved.isEmpty)
        #expect(model.entries.isEmpty)

        model.confirmReminder()
        model.confirmReminder() // a second tap must not save twice
        for _ in 0..<50 where model.isSavingReminder { await Task.yield() }
        #expect(saver.saved.count == 1)
        #expect(model.pendingReminder == nil)
        #expect(model.upcomingReminders.count == 1)
    }

    @Test func cancellingSavesNothing() async {
        let saver = RecordingReminderSaver()
        let model = AppModel(transcriber: MockTranscriber(), interpreter: MockMoneyInterpreter(delay: .zero),
                             store: InMemoryLedgerStore(), speaker: SilentSpeaker(), reminders: saver)
        await model.handle(text: "Remind me to check the oven in 10 minutes", generation: 0)
        model.cancelReminder()
        #expect(model.pendingReminder == nil)
        #expect(saver.saved.isEmpty)
    }
}
