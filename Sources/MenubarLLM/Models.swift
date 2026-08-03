import Foundation

struct Message: Identifiable, Codable {
    let id: UUID
    let role: String // "system", "user", "assistant"
    var content: String
    let timestamp: Date
}

struct SearchResult: Identifiable {
    let id = UUID()
    let title: String
    let url: String
    let content: String
}

// WARNING: For simplicity, API keys are stored in UserDefaults.
// In a production app, use the macOS Keychain for sensitive credentials.
struct AppConfig: Codable {
    var apiKey: String
    var baseURL: String // e.g., "https://api.openai.com/v1"
    var fastModel: String // e.g., "gpt-4o-mini"
    var reasoningModel: String // e.g., "o1-mini" or "claude-3-sonnet"
    var currentMode: String // "fast" or "reasoning"
    var tavilyApiKey: String
    var enableWebSearch: Bool
}
