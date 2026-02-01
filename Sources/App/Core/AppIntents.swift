import AppIntents
import SwiftUI

@available(macOS 13.0, *)
struct CheckMailIntent: AppIntent {
    static var title: LocalizedStringResource = "Check Mail and Summarize"
    static var description = IntentDescription("Checks unread emails, summarizes them, and creates reminders.")

    // AppIntents run in the background, so we need to instantiate our services.
    // In a production app, use a dependency injection container singleton.
    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let mailService = AppleMailService()
        let reminderService = EventKitReminderService()
        let llmService = MockLLMService()

        let interactor = AssistantInteractor(
            mailService: mailService,
            reminderService: reminderService,
            llmService: llmService
        )

        // Trigger the process
        await interactor.processMail()

        // Inspect state to determine result
        switch interactor.state {
        case .result:
            if let analysis = interactor.currentAnalysis {
                let count = analysis.actionItems.count
                return .result(value: "Found \(count) action items. Summary: \(analysis.summary)")
            } else {
                return .result(value: "Processed mail but got no analysis.")
            }
        case .error(let message):
             return .result(value: "Error: \(message)")
        default:
             return .result(value: "Finished without definite result.")
        }
    }
}

@available(macOS 13.0, *)
struct MacAssistantShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CheckMailIntent(),
            phrases: [
                "Check my mail with \(.applicationName)",
                "Summarize emails with \(.applicationName)"
            ],
            shortTitle: "Check Mail"
        )
    }
}
