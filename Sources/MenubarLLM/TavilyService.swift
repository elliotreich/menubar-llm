import Foundation

/// Tavily web search service.
/// Actor-isolated for thread-safe concurrent access.
actor TavilyService {
    /// Performs a search using the Tavily API.
    /// - Returns: Tuple of (searchResults, tavilyAnswer) where tavilyAnswer is an LLM-generated summary
    func search(query: String, apiKey: String) async throws -> ([SearchResult], String?) {
        guard let url = URL(string: "https://api.tavily.com/search") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "query": query,
            "api_key": apiKey,
            "search_depth": "advanced",
            "max_results": 5,
            "include_answer": true,
            "include_raw_content": true
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let results = json["results"] as? [[String: Any]] else {
            throw URLError(.badServerResponse)
        }

        let answer = json["answer"] as? String
        let searchResults = results.compactMap { dict in
            guard let title = dict["title"] as? String,
                  let url = dict["url"] as? String else { return nil as SearchResult? }
            let content = dict["raw_content"] as? String ?? dict["content"] as? String ?? ""
            return SearchResult(title: title, url: url, content: content)
        }

        return (searchResults, answer)
    }
}
