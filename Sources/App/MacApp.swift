import SwiftUI

@main
struct MacApp: App {
    // In a real app, use Dependency Injection container
    @StateObject var interactor = AssistantInteractor(
        mailService: AppleMailService(),
        reminderService: EventKitReminderService(),
        llmService: MockLLMService()
    )

    var body: some Scene {
        WindowGroup {
            SpotlightView(interactor: interactor)
                .onAppear {
                    // Transparent window setup would go here via NSWindow accessor
                }
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            // Add custom commands if needed
        }
    }
}
