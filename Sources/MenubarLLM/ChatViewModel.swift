import Foundation
import Combine
import SwiftUI

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var inputText: String = ""
    @Published var isLoading: Bool = false
    @Published var currentMode: String = "fast"
    @Published var config: AppConfig = AppConfig.defaultConfig
    @Published var showSettings: Bool = false
    @Published var errorMessage: String?
    @Published var lastSearchCount: Int = 0

    private let tavilyService = TavilyService()
    private let llmService = LLMService()

    init() {
        loadConfig()
    }

    /// Sends the current user message, optionally searches the web, and streams the LLM response.
    func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        let userMessage = Message(id: UUID(), role: "user", content: text, timestamp: Date())
        messages.append(userMessage)
        inputText = ""
        isLoading = true
        errorMessage = nil
        lastSearchCount = 0

        Task {
            do {
                var searchResults: [SearchResult] = []
                var tavilyAnswer: String? = nil
                if config.enableWebSearch && !config.tavilyApiKey.isEmpty {
                    (searchResults, tavilyAnswer) = try await tavilyService.search(query: text, apiKey: config.tavilyApiKey)
                    lastSearchCount = searchResults.count
                }

                let stream = await llmService.streamChat(
                    messages: messages,
                    config: config,
                    searchResults: searchResults,
                    tavilyAnswer: tavilyAnswer
                )
                var assistantContent = ""
                let assistantId = UUID()
                let assistantMessage = Message(id: assistantId, role: "assistant", content: "", timestamp: Date())
                messages.append(assistantMessage)

                for try await chunk in stream {
                    assistantContent += chunk
                    if let index = messages.firstIndex(where: { $0.id == assistantId }) {
                        messages[index].content = assistantContent
                    }
                }
            } catch {
                errorMessage = "Error: \(error.localizedDescription)"
            }
            isLoading = false
        }
    }

    func clearChat() {
        messages.removeAll()
        errorMessage = nil
    }

    func saveConfig() {
        config.currentMode = currentMode
        if let data = try? JSONEncoder().encode(config) {
            UserDefaults.standard.set(data, forKey: "appConfig")
        }
    }

    func loadConfig() {
        guard let data = UserDefaults.standard.data(forKey: "appConfig"),
              let loaded = try? JSONDecoder().decode(AppConfig.self, from: data) else {
            return
        }
        config = loaded
        currentMode = loaded.currentMode
    }

    func toggleMode() {
        currentMode = currentMode == "fast" ? "reasoning" : "fast"
        config.currentMode = currentMode
        saveConfig()
    }
}

extension AppConfig {
    // Defaults ship with NO API keys — enter them in Settings (stored in UserDefaults).
    // Defaults to DeepSeek; switch provider/baseURL in Settings.
    static let defaultConfig = AppConfig(
        apiKey: "",
        baseURL: "https://api.deepseek.com/v1",
        fastModel: "deepseek-v4-flash",
        reasoningModel: "deepseek-v4-pro",
        currentMode: "fast",
        tavilyApiKey: "",
        enableWebSearch: true
    )
}
