import Foundation
import EventKit

class EventKitReminderService: ReminderService {
    private let store = EKEventStore()

    func createReminder(title: String, notes: String?, dueDate: Date?) async throws {
        let granted = try await requestAccess()
        guard granted else {
            throw NSError(domain: "ReminderService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Access to Reminders not granted"])
        }

        // Operations on EKEventStore must be efficient, but creating one object is fast.
        let reminder = EKReminder(eventStore: store)
        reminder.title = title
        reminder.notes = notes
        reminder.calendar = store.defaultCalendarForNewReminders()

        if let dueDate = dueDate {
            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: dueDate)
            reminder.dueDateComponents = components
            reminder.addAlarm(EKAlarm(absoluteDate: dueDate))
        }

        try store.save(reminder, commit: true)
    }

    private func requestAccess() async throws -> Bool {
        if #available(macOS 14.0, *) {
            return try await store.requestFullAccessToReminders()
        } else {
            return try await store.requestAccess(to: .reminder)
        }
    }
}
