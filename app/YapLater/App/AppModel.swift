import Foundation
import Observation

/// The one place where a yap becomes money: speech → interpreter → validator → store → budgets → nudge.
/// Views read its state and call its actions; they never talk to services directly.
@MainActor
@Observable
final class AppModel {
    enum Phase: Equatable {
        case idle
        /// The button is held and audio is being captured.
        case listening
        /// The button was released; speech is being turned into text.
        case transcribing
        /// The model is interpreting `transcript`.
        case thinking
        /// The app asked a question (also spoken) and is waiting for a held-to-talk or typed answer.
        case asking(question: String)
        case failed(message: String)
    }

    // MARK: State for views

    private(set) var phase: Phase = .idle
    /// The most recent thing the user said or typed.
    private(set) var transcript = ""
    /// Input level 0...1 while listening, for the waveform.
    private(set) var audioLevel: Float = 0
    /// This week's entries, newest first.
    private(set) var entries: [Entry] = []
    /// One per budget, in category order.
    private(set) var budgetStatuses: [BudgetStatus] = []
    /// The entry that can still be undone; nil once the undo window closes.
    private(set) var lastSaved: Entry?
    /// Everything the last yap saved (several when it named several expenses). Undo removes all of them.
    private(set) var lastSavedGroup: [Entry] = []
    /// The nudge to show now; nil when dismissed.
    private(set) var nudge: Nudge?
    /// Set briefly when a budget was just created or changed by voice.
    private(set) var lastBudgetSet: Budget?
    /// A reminder waiting for the user's Save or Cancel. Nothing is written until Save.
    private(set) var pendingReminder: ReminderDraft?
    /// Set after a reminder was saved, for the confirmation toast.
    private(set) var savedReminder: ReminderDraft?
    /// Reminders this app created that are still ahead, soonest first.
    private(set) var upcomingReminders: [ReminderDraft] = []
    private(set) var isSavingReminder = false
    /// What the Mac-and-iPhone sync is doing, while it runs and briefly after; nil otherwise.
    private(set) var syncStatus: String?
    var isSyncing: Bool { sync != nil }
    /// True when speech or interpretation is a stand-in. Views must show this.
    let usesMocks: Bool
    /// Which model interprets yaps, for display: the sponsor model, the fallback, or the mock.
    let interpreterName: String

    var weekTotalCents: Int { entries.reduce(0) { $0 + $1.amountCents } }
    /// The week summarized for the insights page, from stored entries and budgets.
    var insights: WeekInsights { WeekInsights.make(entries: entries, statuses: budgetStatuses, now: now()) }
    var isBusy: Bool {
        switch phase {
        case .listening, .transcribing, .thinking: true
        case .idle, .asking, .failed: false
        }
    }

    // MARK: Dependencies

    private let transcriber: any SpeechTranscriber
    private let interpreter: any MoneyInterpreter
    private let validator: any ProposalValidating
    private let store: any LedgerStore
    private let speaker: any Speaker
    private let notifier: any NudgeNotifier
    private let reminders: any ReminderSaving
    private let reminderLog: ReminderLog
    private let now: @Sendable () -> Date
    private let undoWindow: Duration

    // MARK: Private state

    private var generation = 0
    private var startTask: Task<Void, Never>?
    private var workTask: Task<Void, Never>?
    private var undoTask: Task<Void, Never>?
    /// What was said before an ask-back, so the answer is interpreted together with it.
    private var pendingContext: String?
    private var sync: (any PeerSyncing)?
    private var syncTimeout: Task<Void, Never>?
    private var askCount = 0
    static let maxAsks = 2

    init(transcriber: any SpeechTranscriber,
         interpreter: any MoneyInterpreter,
         validator: any ProposalValidating = ProposalValidator(),
         store: any LedgerStore,
         speaker: any Speaker,
         notifier: any NudgeNotifier = NoopNudgeNotifier(),
         reminders: (any ReminderSaving)? = nil,
         reminderLog: ReminderLog? = nil,
         undoWindow: Duration = .seconds(6),
         now: @escaping @Sendable () -> Date = { .now }) {
        self.transcriber = transcriber
        self.interpreter = interpreter
        self.validator = validator
        self.store = store
        self.speaker = speaker
        self.notifier = notifier
        self.reminders = reminders ?? RecordingReminderSaver()
        self.reminderLog = reminderLog ?? ReminderLog(defaults: nil)
        self.undoWindow = undoWindow
        self.now = now
        self.usesMocks = transcriber.isMock || interpreter.isMock
        self.interpreterName = interpreter.name
        refresh()
    }

    // MARK: Actions

    /// Call once at launch: warms up speech so the first yap is quick.
    func prepare() async {
        try? await transcriber.prepare()
        _ = await notifier.requestPermission()
    }

    /// Button pressed down: start listening.
    func beginYap() {
        guard !isBusy else { return }
        speaker.stop()
        generation += 1
        pendingReminder = nil // a new yap replaces an unconfirmed reminder
        savedReminder = nil
        let mine = generation
        phase = .listening
        audioLevel = 0
        startTask = Task { [weak self, transcriber] in
            do {
                try await transcriber.start { level in
                    Task { @MainActor [weak self] in
                        guard let self, self.generation == mine, self.phase == .listening else { return }
                        self.audioLevel = level
                    }
                }
            } catch {
                await MainActor.run { [weak self] in
                    guard let self, self.generation == mine else { return }
                    self.phase = .failed(message: Self.message(for: error))
                }
            }
        }
    }

    /// Button released: transcribe what was said and act on it.
    func endYap() {
        guard phase == .listening else { return }
        let mine = generation
        phase = .transcribing
        audioLevel = 0
        workTask = Task { [weak self, transcriber, startTask] in
            await startTask?.value
            do {
                let text = try await transcriber.stop()
                await self?.handle(text: text, generation: mine)
            } catch {
                await MainActor.run { [weak self] in
                    guard let self, self.generation == mine else { return }
                    self.phase = .failed(message: Self.message(for: error))
                }
            }
        }
    }

    /// Stop listening or thinking and throw the result away.
    func cancelYap() {
        generation += 1
        workTask?.cancel()
        audioLevel = 0
        pendingContext = nil
        askCount = 0
        phase = .idle
        Task { [transcriber] in await transcriber.cancel() }
    }

    /// Typed input: same path as a spoken yap.
    func submit(text: String) {
        guard !isBusy else { return }
        generation += 1
        let mine = generation
        workTask = Task { [weak self] in await self?.handle(text: text, generation: mine) }
    }

    func undoLast() {
        guard lastSaved != nil else { return }
        let group = lastSavedGroup
        clearUndo()
        for entry in group { delete(entry) }
    }

    func update(_ entry: Entry) {
        let before = budgetStatuses
        try? store.upsert(entry)
        if lastSaved?.id == entry.id { lastSaved = entry }
        if let index = lastSavedGroup.firstIndex(where: { $0.id == entry.id }) { lastSavedGroup[index] = entry }
        refresh()
        raiseNudgeIfNeeded(before: before, category: entry.category)
    }

    func delete(_ entry: Entry) {
        try? store.delete(entryID: entry.id)
        if lastSaved?.id == entry.id { clearUndo() }
        lastSavedGroup.removeAll { $0.id == entry.id }
        if nudge?.category == entry.category { nudge = nil }
        refresh()
    }

    func setBudget(category: Category, weeklyLimitCents: Int) {
        guard weeklyLimitCents > 0 else { return }
        try? store.setBudget(Budget(category: category, weeklyLimitCents: weeklyLimitCents))
        refresh()
    }

    func removeBudget(category: Category) {
        try? store.removeBudget(for: category)
        if nudge?.category == category { nudge = nil }
        refresh()
    }

    func dismissNudge() { nudge = nil }

    /// The user tapped Save on the reminder card: write it to Apple Reminders, once.
    func confirmReminder() {
        guard let draft = pendingReminder, !isSavingReminder else { return }
        isSavingReminder = true
        Task { [weak self, reminders] in
            do {
                _ = try await reminders.save(draft)
                guard let self else { return }
                self.reminderLog.add(draft)
                self.pendingReminder = nil
                self.savedReminder = draft
                self.refresh()
                self.speaker.speak("Saved. I'll remind you \(draft.whenText(now: self.now()).lowercased()).")
            } catch {
                guard let self else { return }
                self.phase = .failed(message: error as? ReminderError == .permissionDenied
                    ? "Yap Later needs access to Reminders. Turn it on in Settings."
                    : "That reminder didn't save. Try again.")
            }
            self?.isSavingReminder = false
        }
    }

    func cancelReminder() {
        guard !isSavingReminder else { return }
        pendingReminder = nil
        speaker.stop()
    }

    func dismissSavedReminder() { savedReminder = nil }

    // MARK: Sync between the user's own devices

    /// Everything in this device's ledger, for the user's other device.
    func syncSnapshot() -> SyncSnapshot {
        let everything = DateInterval(start: .distantPast, end: .distantFuture)
        return SyncSnapshot(entries: (try? store.entries(in: everything)) ?? [], budgets: (try? store.budgets()) ?? [])
    }

    /// Adds the entries and budgets this device does not have yet. Nothing here is changed or removed,
    /// and no nudge is raised. Returns how many entries were added.
    @discardableResult
    func merge(_ snapshot: SyncSnapshot) -> Int {
        let known = Set(syncSnapshot().entries.map(\.id))
        var added = 0
        for entry in snapshot.validEntries where !known.contains(entry.id) {
            if (try? store.upsert(entry)) != nil { added += 1 }
        }
        let budgeted = Set(((try? store.budgets()) ?? []).map(\.category))
        for budget in snapshot.validBudgets where !budgeted.contains(budget.category) {
            try? store.setBudget(budget)
        }
        refresh()
        return added
    }

    /// The user tapped Sync: look for the other device over Bluetooth and exchange ledgers once.
    func startSync() {
        guard sync == nil else { return stopSync() }
        var added = 0
        let session = BluetoothSync.make(
            snapshot: { [weak self] in self?.syncSnapshot().encoded() ?? Data() },
            receive: { [weak self] data in
                guard let self, let snapshot = SyncSnapshot.decode(data) else { return }
                added = self.merge(snapshot)
            },
            status: { [weak self] message, finished in
                guard let self else { return }
                if finished {
                    let detail = message.hasPrefix("Synced") ? " \(added) new here." : ""
                    self.finishSync(message + detail)
                } else {
                    self.syncStatus = message
                }
            })
        sync = session
        syncStatus = "Starting Bluetooth…"
        session.start()
        syncTimeout = Task { [weak self] in
            try? await Task.sleep(for: .seconds(45))
            guard !Task.isCancelled else { return }
            self?.finishSync("No other device found. Open Yap Later there and tap Sync.")
        }
    }

    func stopSync() { finishSync(nil) }

    private func finishSync(_ message: String?) {
        syncTimeout?.cancel()
        sync?.stop()
        sync = nil
        syncStatus = message
        guard let message else { return }
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(6))
            if self?.syncStatus == message { self?.syncStatus = nil }
        }
    }

    #if DEBUG
    // MARK: Demo week (debug builds only)

    /// Where the ledger is saved before the demo week replaces it.
    private static var demoBackupFile: URL? { LocalAssets.root?.appendingPathComponent("ledger-before-demo.json") }
    private var everything: DateInterval { DateInterval(start: .distantPast, end: .distantFuture) }

    /// Shows the fixed demo week (see `DemoWeek`) and its budgets. With `replacing`, what was stored before is
    /// first saved to a file and then taken out of the ledger, so today starts empty; `restoreAfterDemoWeek`
    /// brings it back. Running this twice changes nothing more.
    func loadDemoWeek(replacing: Bool) {
        if replacing {
            // Keep the first backup: it is the user's own ledger, not a later mix.
            if let file = Self.demoBackupFile, !FileManager.default.fileExists(atPath: file.path) {
                var mine = syncSnapshot()
                mine.entries.removeAll { DemoWeek.ids.contains($0.id) }
                try? FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
                try? mine.encoded().write(to: file, options: .atomic)
            }
            for entry in (try? store.entries(in: everything)) ?? [] where !DemoWeek.ids.contains(entry.id) {
                try? store.delete(entryID: entry.id)
            }
            for budget in (try? store.budgets()) ?? [] { try? store.removeBudget(for: budget.category) }
        }
        for entry in DemoWeek.entries(now: now()) { try? store.upsert(entry) }
        for budget in DemoWeek.budgets { try? store.setBudget(budget) }
        clearUndo()
        nudge = nil
        refresh()
    }

    /// Removes the demo entries. Budgets and everything the user logged stay.
    func clearDemoWeek() {
        for id in DemoWeek.ids { try? store.delete(entryID: id) }
        nudge = nil
        refresh()
    }

    /// Takes the demo week out and puts back the ledger saved by `loadDemoWeek(replacing: true)`.
    func restoreAfterDemoWeek() {
        guard let file = Self.demoBackupFile, let data = try? Data(contentsOf: file),
              let saved = SyncSnapshot.decode(data) else { return }
        clearDemoWeek()
        for budget in (try? store.budgets()) ?? [] { try? store.removeBudget(for: budget.category) }
        for budget in saved.validBudgets { try? store.setBudget(budget) }
        merge(saved)
        try? FileManager.default.removeItem(at: file)
    }

    /// Everything stored, for a debug printout.
    func debugDump() -> String {
        let all = (try? store.entries(in: DateInterval(start: .distantPast, end: .distantFuture))) ?? []
        let lines = all.map { "\($0.date.formatted(date: .abbreviated, time: .shortened)) | \(Money.format(cents: $0.amountCents)) | \($0.category.rawValue) | \($0.merchant ?? "-") | \(DemoWeek.ids.contains($0.id) ? "demo" : "user")" }
        let budgets = ((try? store.budgets()) ?? []).map { "budget \($0.category.rawValue) \(Money.format(cents: $0.weeklyLimitCents))" }
        return (lines + budgets + ["week total \(Money.format(cents: weekTotalCents)), \(entries.count) entries this week"]).joined(separator: "\n")
    }
    #endif

    func dismissFailure() {
        if case .failed = phase { phase = .idle }
    }

    // MARK: The loop

    /// Interprets and applies one utterance. Internal so tests can await it.
    func handle(text rawText: String, generation mine: Int) async {
        guard mine == generation else { return }
        let text = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            phase = .failed(message: "I didn't catch anything. Hold the button and try again.")
            return
        }
        transcript = text
        phase = .thinking
        // Several expenses in one yap: each part goes through the same checks; all or nothing.
        if pendingContext == nil, await handleRamble(text, generation: mine) { return }
        guard mine == generation else { return }
        let combined = pendingContext.map {
            "\($0.trimmingCharacters(in: .punctuationCharacters.union(.whitespaces))). \(text)"
        } ?? text
        let request = InterpretationRequest(transcript: combined, referenceInstant: now())

        let proposal: MoneyProposal
        let started = Date()
        do {
            proposal = try await interpreter.interpret(request)
            #if DEBUG
            print("YAP heard: \"\(combined)\" -> \(proposal.kind.rawValue) amount=\(proposal.amount.map { String($0) } ?? "nil") category=\(proposal.category ?? "nil") merchant=\(proposal.merchant ?? "nil") in \(Int(Date().timeIntervalSince(started) * 1000)) ms")
            #endif
        } catch is CancellationError {
            return
        } catch {
            guard mine == generation else { return }
            phase = .failed(message: "I couldn't work that one out. Try saying it again.")
            return
        }
        guard mine == generation else { return }

        switch validator.validate(proposal, request: request) {
        case .expense(let entry):
            resetConversation()
            let before = budgetStatuses
            do { try store.upsert(entry) } catch {
                phase = .failed(message: "That didn't save. Try again.")
                return
            }
            refresh()
            lastSaved = entry
            lastSavedGroup = [entry]
            startUndoWindow(for: entry.id)
            phase = .idle
            raiseNudgeIfNeeded(before: before, category: entry.category)

        case .budgetSet(let budget):
            resetConversation()
            do { try store.setBudget(budget) } catch {
                phase = .failed(message: "That budget didn't save. Try again.")
                return
            }
            refresh()
            lastBudgetSet = budget
            phase = .idle
            speaker.speak("Done. \(budget.category.displayName) budget is \(Money.format(cents: budget.weeklyLimitCents)) a week.")

        case .reminder(let draft):
            resetConversation()
            savedReminder = nil
            pendingReminder = draft
            phase = .idle
            speaker.speak("\(draft.title), \(draft.whenText(now: now()).lowercased()). Save it?")

        case .askBack(let question):
            askCount += 1
            guard askCount <= Self.maxAsks else {
                resetConversation()
                phase = .failed(message: "I still couldn't get that. Try saying the whole thing again.")
                return
            }
            pendingContext = combined
            phase = .asking(question: question)
            speaker.speak(question)

        case .unsupported(let message):
            resetConversation()
            phase = .failed(message: message)
        }
    }

    /// Tries to read the yap as a list of expenses. Returns false, having saved nothing, unless every part
    /// is a valid expense; the caller then treats the yap as a single request.
    private func handleRamble(_ text: String, generation mine: Int) async -> Bool {
        let pieces = RambleSplitter.pieces(of: text)
        guard pieces.count >= 2, pieces.count <= 6 else { return false }
        let instant = now()
        var found: [Entry] = []
        for piece in pieces {
            let request = InterpretationRequest(transcript: piece, referenceInstant: instant)
            guard let proposal = try? await interpreter.interpret(request), mine == generation,
                  case .expense(let entry) = validator.validate(proposal, request: request) else { return false }
            #if DEBUG
            print("YAP ramble part: \"\(piece)\" -> \(Money.format(cents: entry.amountCents)) \(entry.category.rawValue)")
            #endif
            found.append(entry)
        }
        resetConversation()
        let before = budgetStatuses
        var saved: [Entry] = []
        for entry in found {
            do { try store.upsert(entry); saved.append(entry) } catch {
                for entry in saved { try? store.delete(entryID: entry.id) }
                refresh()
                phase = .failed(message: "That didn't save. Try again.")
                return true
            }
        }
        refresh()
        lastSaved = found.last
        lastSavedGroup = found
        if let last = found.last { startUndoWindow(for: last.id) }
        phase = .idle
        var seen: Set<Category> = []
        for entry in found where seen.insert(entry.category).inserted {
            raiseNudgeIfNeeded(before: before, category: entry.category)
        }
        return true
    }

    // MARK: Helpers

    private func resetConversation() {
        pendingContext = nil
        askCount = 0
    }

    private func refresh() {
        let week = BudgetMath.weekInterval(containing: now())
        entries = (try? store.entries(in: week)) ?? []
        budgetStatuses = BudgetMath.statuses(entries: entries, budgets: (try? store.budgets()) ?? [])
        upcomingReminders = reminderLog.upcoming(after: now())
    }

    private func raiseNudgeIfNeeded(before: [BudgetStatus], category: Category) {
        guard let after = budgetStatuses.first(where: { $0.category == category }),
              let newNudge = BudgetMath.nudge(before: before.first { $0.category == category }, after: after)
        else { return }
        nudge = newNudge
        speaker.speak(newNudge.message)
        Task { [notifier] in await notifier.post(newNudge) }
    }

    private func startUndoWindow(for id: UUID) {
        undoTask?.cancel()
        undoTask = Task { [weak self, undoWindow] in
            try? await Task.sleep(for: undoWindow)
            guard !Task.isCancelled else { return }
            await MainActor.run { [weak self] in
                if self?.lastSaved?.id == id { self?.clearUndo() }
            }
        }
    }

    private func clearUndo() {
        undoTask?.cancel()
        lastSaved = nil
        lastSavedGroup = []
    }

    private static func message(for error: Error) -> String {
        switch error as? SpeechError {
        case .microphoneDenied: "Yap Later needs the microphone. Turn it on in Settings, or type instead."
        case .notReady: "Speech is still getting ready. Give it a second."
        default: "I couldn't hear that. Try again."
        }
    }
}
