import XCTest
@testable import MacAssistant

final class AssistantInteractorTests: XCTestCase {

    // Mocks
    class MockMailService: MailService {
        var emailsToReturn: [Email] = []
        var lastLimit: Int?
        func fetchUnreadEmails(limit: Int) async throws -> [Email] {
            lastLimit = limit
            return emailsToReturn
        }
    }

    class MockReminderService: ReminderService {
        var createdReminders: [(title: String, notes: String?)] = []
        func createReminder(title: String, notes: String?, dueDate: Date?) async throws {
            createdReminders.append((title, notes))
        }
    }

    class MockLLMService: LLMService {
        var analysisToReturn: EmailAnalysis?
        func processEmails(_ emails: [Email]) async throws -> EmailAnalysis {
            if let analysis = analysisToReturn {
                return analysis
            }
            throw NSError(domain: "Mock", code: 1)
        }
    }

    // Tests

    func testProcessMailFlow() async throws {
        // Setup
        let mailService = MockMailService()
        let reminderService = MockReminderService()
        let llmService = MockLLMService()
        let interactor = AssistantInteractor(
            mailService: mailService,
            reminderService: reminderService,
            llmService: llmService
        )

        // Data
        let testEmail = Email(
            id: "1", sender: "boss@company.com", subject: "Urgent", body: "Do this.", date: Date()
        )
        mailService.emailsToReturn = [testEmail]

        let testAction = ActionItem(title: "Do work", description: "From boss", suggestedDueDate: nil)
        llmService.analysisToReturn = EmailAnalysis(
            summary: "Got mail",
            actionItems: [testAction]
        )

        // Execute
        await interactor.processMail()

        // Verify
        if case .result = interactor.state {
            XCTAssertNotNil(interactor.currentAnalysis)
            XCTAssertEqual(interactor.currentAnalysis?.summary, "Got mail")
            XCTAssertEqual(reminderService.createdReminders.count, 1)
            XCTAssertEqual(reminderService.createdReminders.first?.title, "Do work")
            XCTAssertEqual(mailService.lastLimit, 5)
        } else {
            XCTFail("State should be .result")
        }
    }

    func testProcessMailEmpty() async throws {
        // Setup
        let interactor = AssistantInteractor(
            mailService: MockMailService(),
            reminderService: MockReminderService(),
            llmService: MockLLMService()
        )

        // Execute
        await interactor.processMail() // Returns empty list by default in mock

        // Verify
        if case .error(let msg) = interactor.state {
            XCTAssertEqual(msg, "No unread emails found.")
        } else {
            XCTFail("State should be .error")
        }
    }
}
