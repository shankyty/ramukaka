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
    @AppStorage("llm_provider") private var provider: LLMProvider = .mock
    @AppStorage("ollama_host") private var ollamaHost: String = "http://localhost:11434"
    @AppStorage("ollama_model") private var ollamaModel: String = "llama3"

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
                .onChange(of: apiKey) { _ in configureService() }
                .onChange(of: provider) { _ in configureService() }
                .onChange(of: ollamaHost) { _ in configureService() }
                .onChange(of: ollamaModel) { _ in configureService() }
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            // Add custom commands if needed
        }
    }

    private func configureService() {
        switch provider {
        case .mock:
            interactor.updateLLMService(MockLLMService())
            print("Using MockLLMService")
        case .openai:
            interactor.updateLLMService(OpenAILLMService(apiKey: apiKey))
            print("Using OpenAILLMService")
        case .ollama:
            interactor.updateLLMService(OllamaLLMService(host: ollamaHost, model: ollamaModel))
            print("Using OllamaLLMService")
        }
    }
}
