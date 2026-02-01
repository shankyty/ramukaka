import Foundation
import Combine

class AssistantInteractor: ObservableObject {
    @Published var state: AppState = .idle
    @Published var currentAnalysis: EmailAnalysis?

    private let mailService: MailService
    private let reminderService: ReminderService
    private var llmService: LLMService

    enum AppState {
        case idle
        case processing(String)
        case result
        case error(String)
    }

    init(mailService: MailService, reminderService: ReminderService, llmService: LLMService) {
        self.mailService = mailService
        self.reminderService = reminderService
        self.llmService = llmService
    }

    func updateLLMService(_ service: LLMService) {
        self.llmService = service
    }

    @MainActor
    func processMail() async {
        state = .processing("Fetching emails...")

        do {
            // 1. Fetch
            let emails = try await mailService.fetchUnreadEmails(limit: 10)

            if emails.isEmpty {
                state = .error("No unread emails found.")
                return
            }

            // 2. Analyze
            state = .processing("Analyzing \(emails.count) emails...")
            let analysis = try await llmService.processEmails(emails)
            self.currentAnalysis = analysis

            // 3. Act (Create Reminders)
            if !analysis.actionItems.isEmpty {
                state = .processing("Creating \(analysis.actionItems.count) reminders...")
                for item in analysis.actionItems {
                    try await reminderService.createReminder(
                        title: item.title,
                        notes: item.description,
                        dueDate: item.suggestedDueDate
                    )
                }
            }

            state = .result
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    @MainActor
    func reset() {
        state = .idle
        currentAnalysis = nil
    }
}
