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
    @AppStorage("openai_api_key") private var apiKey: String = ""

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
                    configureService()
                }
                .onChange(of: apiKey) { newValue in
                    configureService()
                }
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            // Add custom commands if needed
        }
    }

    private func configureService() {
        if apiKey.isEmpty {
            interactor.updateLLMService(MockLLMService())
            print("Using MockLLMService")
        } else {
            interactor.updateLLMService(OpenAILLMService(apiKey: apiKey))
            print("Using OpenAILLMService")
        }
    }
}
