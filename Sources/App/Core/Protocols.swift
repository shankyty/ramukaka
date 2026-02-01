import Foundation

protocol MailService {
    /// Fetches unread emails from the inbox.
    func fetchUnreadEmails(limit: Int) async throws -> [Email]
}

protocol ReminderService {
    /// Creates a new reminder in the default list.
    func createReminder(title: String, notes: String?, dueDate: Date?) async throws
}

protocol LLMService {
    /// Generates a summary and action items from a list of emails.
    func processEmails(_ emails: [Email]) async throws -> EmailAnalysis
}
