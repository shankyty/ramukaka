import Foundation

class MockLLMService: LLMService {
    func processEmails(_ emails: [Email]) async throws -> EmailAnalysis {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1 * 1_000_000_000)

        let summary = "You have \(emails.count) unread emails. Here is a summary."

        var actionItems: [ActionItem] = []

        for email in emails {
            // Simple keyword matching to simulate "Intelligence"
            if email.subject.localizedCaseInsensitiveContains("urgent") ||
               email.subject.localizedCaseInsensitiveContains("invoice") {
                let item = ActionItem(
                    title: "Follow up: \(email.subject)",
                    description: "From: \(email.sender)",
                    suggestedDueDate: Date().addingTimeInterval(3600 * 24) // Tomorrow
                )
                actionItems.append(item)
            }
        }

        return EmailAnalysis(summary: summary, actionItems: actionItems)
    }
}

class OpenAILLMService: LLMService {
    private let apiKey: String
    private let endpoint = URL(string: "https://api.openai.com/v1/chat/completions")!

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    func processEmails(_ emails: [Email]) async throws -> EmailAnalysis {
        // 1. Construct Prompt
        var emailContent = ""
        for (index, email) in emails.enumerated() {
            emailContent += "Email \(index + 1):\nFrom: \(email.sender)\nSubject: \(email.subject)\nBody: \(email.body.prefix(300))\n\n"
        }

        let systemPrompt = """
        You are a helpful assistant. Analyze the following emails.
        Produce a JSON response with the following schema:
        {
          "summary": "Overall summary of the emails",
          "actionItems": [
            {
              "title": "Action title",
              "description": "Details",
              "suggestedDueDate": "YYYY-MM-DD"
            }
          ]
        }
        If no due date is clear, leave suggestedDueDate null.
        """

        let messages: [[String: String]] = [
            ["role": "system", "content": systemPrompt],
            ["role": "user", "content": emailContent]
        ]

        let requestBody: [String: Any] = [
            "model": "gpt-4-turbo-preview",
            "messages": messages,
            "response_format": ["type": "json_object"]
        ]

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        // 2. Network Call
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            // Attempt to read error body
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "OpenAI", code: 1, userInfo: [NSLocalizedDescriptionKey: "API Error: \(errorText)"])
        }

        // 3. Parse Response
        struct OpenAIResponse: Decodable {
            struct Choice: Decodable {
                struct Message: Decodable {
                    let content: String
                }
                let message: Message
            }
            let choices: [Choice]
        }

        let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        guard let content = openAIResponse.choices.first?.message.content.data(using: .utf8) else {
             throw NSError(domain: "OpenAI", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])
        }

        // Helper struct for intermediate decoding
        struct LLMOutput: Decodable {
            let summary: String
            struct Item: Decodable {
                let title: String
                let description: String?
                let suggestedDueDate: String?
            }
            let actionItems: [Item]
        }

        let llmOutput = try JSONDecoder().decode(LLMOutput.self, from: content)

        // Map to Domain Model
        let actionItems = llmOutput.actionItems.map { item -> ActionItem in
            var date: Date? = nil
            if let dateStr = item.suggestedDueDate {
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withFullDate] // Expects YYYY-MM-DD
                date = formatter.date(from: dateStr)
            }
            return ActionItem(title: item.title, description: item.description, suggestedDueDate: date)
        }

        return EmailAnalysis(summary: llmOutput.summary, actionItems: actionItems)
    }
}

class OllamaLLMService: LLMService {
    private let host: URL
    private let model: String

    init(host: String, model: String) {
        // Ensure host has a scheme
        var urlString = host
        if !urlString.lowercased().hasPrefix("http://") && !urlString.lowercased().hasPrefix("https://") {
            urlString = "http://" + urlString
        }
        // Remove trailing slash if present
        if urlString.hasSuffix("/") {
            urlString.removeLast()
        }

        self.host = URL(string: urlString) ?? URL(string: "http://localhost:11434")!
        self.model = model
    }

    func processEmails(_ emails: [Email]) async throws -> EmailAnalysis {
        let endpoint = host.appendingPathComponent("/api/chat")

        // 1. Construct Prompt
        var emailContent = ""
        for (index, email) in emails.enumerated() {
            emailContent += "Email \(index + 1):\nFrom: \(email.sender)\nSubject: \(email.subject)\nBody: \(email.body.prefix(300))\n\n"
        }

        let systemPrompt = """
        You are a helpful assistant. Analyze the following emails.
        Produce a JSON response with the following schema:
        {
          "summary": "Overall summary of the emails",
          "actionItems": [
            {
              "title": "Action title",
              "description": "Details",
              "suggestedDueDate": "YYYY-MM-DD"
            }
          ]
        }
        If no due date is clear, leave suggestedDueDate null.
        """

        let messages: [[String: String]] = [
            ["role": "system", "content": systemPrompt],
            ["role": "user", "content": emailContent]
        ]

        let requestBody: [String: Any] = [
            "model": model,
            "messages": messages,
            "format": "json",
            "stream": false
        ]

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        // 2. Network Call
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "Ollama", code: 1, userInfo: [NSLocalizedDescriptionKey: "API Error: \(errorText)"])
        }

        // 3. Parse Response
        struct OllamaResponse: Decodable {
            struct Message: Decodable {
                let content: String
            }
            let message: Message
        }

        let ollamaResponse = try JSONDecoder().decode(OllamaResponse.self, from: data)
        guard let content = ollamaResponse.message.content.data(using: .utf8) else {
             throw NSError(domain: "Ollama", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])
        }

        // Helper struct for intermediate decoding (Shared with OpenAI service logic, could be refactored)
        struct LLMOutput: Decodable {
            let summary: String
            struct Item: Decodable {
                let title: String
                let description: String?
                let suggestedDueDate: String?
            }
            let actionItems: [Item]
        }

        let llmOutput = try JSONDecoder().decode(LLMOutput.self, from: content)

        // Map to Domain Model
        let actionItems = llmOutput.actionItems.map { item -> ActionItem in
            var date: Date? = nil
            if let dateStr = item.suggestedDueDate {
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withFullDate] // Expects YYYY-MM-DD
                date = formatter.date(from: dateStr)
            }
            return ActionItem(title: item.title, description: item.description, suggestedDueDate: date)
        }

        return EmailAnalysis(summary: llmOutput.summary, actionItems: actionItems)
    }
}
