import Foundation

/// OpenAI-compatible chat completion service with streaming support.
actor LLMService {
    /// Streams a chat completion from an LLM endpoint.
    /// - Parameters:
    ///   - messages: Conversation history.
    ///   - config: App configuration containing model, API key, etc.
    ///   - searchResults: Optional web search results to inject as context.
    /// - Returns: An async stream of text chunks.
    func streamChat(
        messages: [Message],
        config: AppConfig,
        searchResults: [SearchResult] = [],
        tavilyAnswer: String? = nil
    ) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    guard let url = URL(string: "\(config.baseURL)/chat/completions") else {
                        throw URLError(.badURL)
                    }

                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")

                    var apiMessages: [[String: String]] = []

                    // Determine which model is being used to tailor the system prompt.
                    let activeModel = config.currentMode == "reasoning" ? config.reasoningModel : config.fastModel
                    let isReasoning = activeModel.localizedCaseInsensitiveContains("o1")
                        || activeModel.localizedCaseInsensitiveContains("reasoning")

                    let systemPrompt = isReasoning
                        ? "You are a careful reasoning assistant. Think step by step."
                        : "You are a helpful assistant. Be concise and fast."

                    apiMessages.append(["role": "system", "content": systemPrompt])

                    // Convert existing messages.
                    for msg in messages {
                        apiMessages.append(["role": msg.role, "content": msg.content])
                    }

                    // Inject search results into the last user message if available.
                    if !searchResults.isEmpty, let lastIdx = apiMessages.indices.last,
                       apiMessages[lastIdx]["role"] == "user" {
                        var searchContext = ""
                        if let answer = tavilyAnswer, !answer.isEmpty {
                            searchContext += "Web search answer: \(answer)\n\nSources:\n"
                        }
                        searchContext += searchResults.map {
                            "[Source: \($0.title)](\($0.url))\n\($0.content)"
                        }.joined(separator: "\n\n---\n\n")

                        let original = apiMessages[lastIdx]["content"] ?? ""
                        let augmented = "Recent web search results (prioritize 48h recency):\n\n\(searchContext)\n\n---\n\nUser query: \(original)"
                        apiMessages[lastIdx]["content"] = augmented
                    }

                    let body: [String: Any] = [
                        "model": activeModel,
                        "messages": apiMessages,
                        "stream": true
                    ]

                    request.httpBody = try JSONSerialization.data(withJSONObject: body)

                    let (bytes, response) = try await URLSession.shared.bytes(for: request)

                    guard let httpResponse = response as? HTTPURLResponse else {
                        throw LLMError.noResponse
                    }

                    guard httpResponse.statusCode == 200 else {
                        // Read error body and throw descriptive error
                        var errorBody = ""
                        for try await line in bytes.lines {
                            errorBody += line
                        }
                        let msg = parseErrorMessage(from: errorBody, status: httpResponse.statusCode)
                        throw LLMError.apiError(httpResponse.statusCode, msg)
                    }

                    for try await line in bytes.lines {
                        guard line.hasPrefix("data: ") else { continue }
                        let dataStr = String(line.dropFirst(6))

                        if dataStr == "[DONE]" {
                            continuation.finish()
                            return
                        }

                        guard let data = dataStr.data(using: .utf8),
                              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                              let choices = json["choices"] as? [[String: Any]],
                              let first = choices.first else { continue }

                        // Standard streaming delta format.
                        if let delta = first["delta"] as? [String: Any],
                           let content = delta["content"] as? String {
                            continuation.yield(content)
                        }
                        // Fallback for non-streaming or alternative field names.
                        else if let messageDict = first["message"] as? [String: Any],
                                let content = messageDict["content"] as? String {
                            continuation.yield(content)
                        }
                    }

                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}

// MARK: - Error handling

enum LLMError: LocalizedError {
    case noResponse
    case apiError(Int, String)
    case badURL

    var errorDescription: String? {
        switch self {
        case .noResponse:
            return "No response from server"
        case .apiError(let code, let msg):
            if code == 401 {
                return "Invalid API key (401). Check your key in Settings."
            } else if code == 429 {
                return "Rate limit reached. \(msg)"
            }
            return "API error \(code): \(msg)"
        case .badURL:
            return "Invalid API URL"
        }
    }
}

private func parseErrorMessage(from body: String, status: Int) -> String {
    guard let data = body.data(using: .utf8),
          let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
          let error = json["error"] as? [String: Any],
          let message = error["message"] as? String else {
        return body.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    return message
}
