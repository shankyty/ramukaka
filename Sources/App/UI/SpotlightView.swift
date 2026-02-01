import SwiftUI

struct SpotlightView: View {
    @ObservedObject var interactor: AssistantInteractor
    @State private var inputText: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Input Bar Area
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundColor(.purple)

                TextField("Ask Assistant (e.g., 'Check my mail')", text: $inputText)
                    .font(.title2)
                    .textFieldStyle(.plain)
                    .onSubmit {
                        if inputText.localizedCaseInsensitiveContains("mail") {
                            Task { await interactor.processMail() }
                        }
                    }

                if case .processing = interactor.state {
                    ProgressView()
                        .controlSize(.small)
                }
            }
            .padding(16)

            Divider()

            // Content Area
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    switch interactor.state {
                    case .idle:
                        Text("Type 'Check my mail' and press Enter.")
                            .foregroundColor(.secondary)

                    case .processing(let message):
                        Text(message)
                            .foregroundColor(.secondary)

                    case .error(let message):
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                            Text(message)
                        }
                        .foregroundColor(.red)

                    case .result:
                        if let analysis = interactor.currentAnalysis {
                            VStack(alignment: .leading, spacing: 12) {
                                Label("Summary", systemImage: "text.alignleft")
                                    .font(.headline)
                                Text(analysis.summary)
                                    .fixedSize(horizontal: false, vertical: true)

                                Divider()

                                Label("Reminders Created", systemImage: "checklist")
                                    .font(.headline)

                                ForEach(analysis.actionItems) { item in
                                    HStack(alignment: .top) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                        VStack(alignment: .leading) {
                                            Text(item.title)
                                                .fontWeight(.medium)
                                            if let desc = item.description {
                                                Text(desc)
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                    }
                }
                .padding(16)
            }
            .frame(maxHeight: 400) // Limit height
        }
        .frame(width: 650)
        .background(EffectView(material: .sidebar, blendingMode: .behindWindow))
    }
}

// Helper for NSVisualEffectView in SwiftUI
struct EffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
