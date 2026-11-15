import EventKit
import Foundation

enum ReminderError: Error, Equatable {
    case permissionDenied
    case noList
    case failed(String)
}

/// Writes a confirmed reminder into the user's reminders. Only ever called after an explicit Save.
@MainActor
protocol ReminderSaving: AnyObject {
    /// Returns the saved reminder's identifier.
    func save(_ draft: ReminderDraft) async throws -> String
}

/// Saves into Apple Reminders with a due date and an explicit alarm, so the system alerts at that time.
@MainActor
final class EventKitReminderSaver: ReminderSaving {
    private let store = EKEventStore()

    func save(_ draft: ReminderDraft) async throws -> String {
        let granted = (try? await store.requestFullAccessToReminders()) ?? false
        guard granted else { throw ReminderError.permissionDenied }
        guard let list = store.defaultCalendarForNewReminders() else { throw ReminderError.noList }

        let reminder = EKReminder(eventStore: store)
        reminder.title = draft.amountCents.map { "\(draft.title) (\(Money.format(cents: $0)))" } ?? draft.title
        reminder.calendar = list
        reminder.dueDateComponents = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute], from: draft.dueAt)
        reminder.addAlarm(EKAlarm(absoluteDate: draft.dueAt)) // a due date alone does not alert
        do {
            try store.save(reminder, commit: true)
        } catch {
            throw ReminderError.failed(error.localizedDescription)
        }
        return reminder.calendarItemIdentifier
    }
}

/// Records what would have been saved. For tests, previews, and mock mode.
@MainActor
final class RecordingReminderSaver: ReminderSaving {
    private(set) var saved: [ReminderDraft] = []
    var error: ReminderError?

    func save(_ draft: ReminderDraft) async throws -> String {
        if let error { throw error }
        saved.append(draft)
        return draft.id.uuidString
    }
}

/// The reminders this app created, kept on the phone so the home screen can show what is coming up.
@MainActor
final class ReminderLog {
    private let defaults: UserDefaults?
    private var items: [ReminderDraft]
    private static let key = "savedReminders"

    /// Pass `nil` to keep the log in memory only.
    init(defaults: UserDefaults? = .standard) {
        self.defaults = defaults
        items = defaults?.data(forKey: Self.key).flatMap { try? JSONDecoder().decode([ReminderDraft].self, from: $0) } ?? []
    }

    func add(_ draft: ReminderDraft) {
        items.removeAll { $0.id == draft.id }
        items.append(draft)
        if let data = try? JSONEncoder().encode(items) { defaults?.set(data, forKey: Self.key) }
    }

    func upcoming(after now: Date) -> [ReminderDraft] {
        items.filter { $0.dueAt > now }.sorted { $0.dueAt < $1.dueAt }
    }
}
