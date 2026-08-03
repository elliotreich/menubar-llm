import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var viewModel: ChatViewModel

    @State private var apiKey: String = ""
    @State private var baseURL: String = ""
    @State private var fastModel: String = ""
    @State private var reasoningModel: String = ""
    @State private var tavilyApiKey: String = ""
    @State private var enableWebSearch: Bool = false

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Settings")
                    .font(.headline)
                Spacer()
                Button("Done") {
                    viewModel.showSettings = false
                }
                .buttonStyle(.borderless)
            }

            Form {
                Section(header: Text("LLM Configuration").font(.caption).foregroundColor(.secondary)) {
                    TextField("API Key", text: $apiKey)
                        .textFieldStyle(.roundedBorder)
                    TextField("Base URL", text: $baseURL)
                        .textFieldStyle(.roundedBorder)
                    TextField("Fast Model", text: $fastModel)
                        .textFieldStyle(.roundedBorder)
                    TextField("Reasoning Model", text: $reasoningModel)
                        .textFieldStyle(.roundedBorder)
                }

                Section(header: Text("Web Search").font(.caption).foregroundColor(.secondary)) {
                    Toggle("Enable Web Search", isOn: $enableWebSearch)
                    TextField("Tavily API Key", text: $tavilyApiKey)
                        .textFieldStyle(.roundedBorder)
                }
            }

            HStack {
                Button("Cancel") {
                    viewModel.showSettings = false
                }
                .buttonStyle(.borderless)

                Spacer()

                Button("Save") {
                    save()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding()
        .onAppear {
            apiKey = viewModel.config.apiKey
            baseURL = viewModel.config.baseURL
            fastModel = viewModel.config.fastModel
            reasoningModel = viewModel.config.reasoningModel
            tavilyApiKey = viewModel.config.tavilyApiKey
            enableWebSearch = viewModel.config.enableWebSearch
        }
    }

    private func save() {
        viewModel.config.apiKey = apiKey
        viewModel.config.baseURL = baseURL
        viewModel.config.fastModel = fastModel
        viewModel.config.reasoningModel = reasoningModel
        viewModel.config.tavilyApiKey = tavilyApiKey
        viewModel.config.enableWebSearch = enableWebSearch
        viewModel.saveConfig()
        viewModel.showSettings = false
    }
}
