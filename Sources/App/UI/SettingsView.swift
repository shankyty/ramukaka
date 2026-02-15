import SwiftUI

enum LLMProvider: String, CaseIterable, Identifiable {
    case mock = "mock"
    case openai = "openai"
    case ollama = "ollama"

    var id: String { self.rawValue }
    var displayName: String {
        switch self {
        case .mock: return "Mock (Testing)"
        case .openai: return "OpenAI"
        case .ollama: return "Ollama"
        }
    }
}

struct SettingsView: View {
    @AppStorage("openai_api_key") private var apiKey: String = ""
    @AppStorage("llm_provider") private var provider: LLMProvider = .mock
    @AppStorage("ollama_host") private var ollamaHost: String = "http://localhost:11434"
    @AppStorage("ollama_model") private var ollamaModel: String = "llama3"

    @State private var availableModels: [String] = []
    @State private var isLoadingModels: Bool = false
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Text("Settings")
                .font(.headline)

            Form {
                Section(header: Text("General")) {
                    Picker("AI Provider", selection: $provider) {
                        ForEach(LLMProvider.allCases) { provider in
                            Text(provider.displayName).tag(provider)
                        }
                    }
                }

                if provider == .openai {
                    Section(header: Text("OpenAI Configuration")) {
                        SecureField("API Key", text: $apiKey)
                            .textFieldStyle(.roundedBorder)
                    }
                } else if provider == .ollama {
                    Section(header: Text("Ollama Configuration")) {
                        TextField("Host URL", text: $ollamaHost)
                            .textFieldStyle(.roundedBorder)

                        HStack {
                            Picker("Model", selection: $ollamaModel) {
                                ForEach(availableModels, id: \.self) { model in
                                    Text(model).tag(model)
                                }
                                if !availableModels.contains(ollamaModel) && !ollamaModel.isEmpty {
                                    Text(ollamaModel).tag(ollamaModel)
                                }
                            }

                            Button(action: {
                                Task {
                                    await fetchOllamaModels()
                                }
                            }) {
                                Image(systemName: "arrow.clockwise")
                            }
                            .disabled(isLoadingModels)
                        }

                        if isLoadingModels {
                            ProgressView()
                                .controlSize(.small)
                        }
                    }
                } else {
                    Section {
                         Text("Mock service uses hardcoded responses for testing UI.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .formStyle(.grouped)

            HStack {
                Spacer()
                Button("Done") {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
        .frame(width: 400, height: 350)
        .padding()
        .onAppear {
            if provider == .ollama {
                Task {
                    await fetchOllamaModels()
                }
            }
        }
    }

    private func fetchOllamaModels() async {
        isLoadingModels = true
        defer { isLoadingModels = false }

        // Normalize Host
        var urlString = ollamaHost
        if !urlString.lowercased().hasPrefix("http://") && !urlString.lowercased().hasPrefix("https://") {
            urlString = "http://" + urlString
        }
        if urlString.hasSuffix("/") {
            urlString.removeLast()
        }

        guard let url = URL(string: urlString + "/api/tags") else { return }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)

            struct OllamaTagsResponse: Decodable {
                struct Model: Decodable {
                    let name: String
                }
                let models: [Model]
            }

            let response = try JSONDecoder().decode(OllamaTagsResponse.self, from: data)
            let models = response.models.map { $0.name }

            await MainActor.run {
                self.availableModels = models
                // If current model is not in list, or empty, select first available
                if !models.isEmpty && (ollamaModel.isEmpty || !models.contains(ollamaModel)) {
                    ollamaModel = models.first!
                }
            }
        } catch {
            print("Failed to fetch models: \(error)")
        }
    }
}
