import SwiftUI

struct SettingsView: View {
    @AppStorage("openai_api_key") private var apiKey: String = ""
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Text("Settings")
                .font(.headline)

            Form {
                Section(header: Text("Configuration")) {
                    SecureField("OpenAI API Key", text: $apiKey)
                        .textFieldStyle(.roundedBorder)

                    Text("Leave empty to use Mock Service (Testing)")
                        .font(.caption)
                        .foregroundColor(.secondary)
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
        .frame(width: 350, height: 200)
        .padding()
    }
}
