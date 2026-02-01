import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Force the app to become active and frontmost
        NSApp.activate(ignoringOtherApps: true)
    }
}

@main
struct MacApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

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
