import XCTest
@testable import MacAssistant

final class LLMServiceTests: XCTestCase {

    func testJSONParsing() throws {
        // Simulating the JSON structure expected from OpenAI
        let jsonString = """
        {
            "summary": "You have 2 emails.",
            "actionItems": [
                {
                    "title": "Pay invoice",
                    "description": "Invoice #123",
                    "suggestedDueDate": "2023-10-25"
                }
            ]
        }
        """

        struct LLMOutput: Decodable {
            let summary: String
            struct Item: Decodable {
                let title: String
                let description: String?
                let suggestedDueDate: String?
            }
            let actionItems: [Item]
        }

        let data = jsonString.data(using: .utf8)!
        let output = try JSONDecoder().decode(LLMOutput.self, from: data)

        XCTAssertEqual(output.summary, "You have 2 emails.")
        XCTAssertEqual(output.actionItems.count, 1)
        XCTAssertEqual(output.actionItems[0].title, "Pay invoice")
        XCTAssertEqual(output.actionItems[0].suggestedDueDate, "2023-10-25")
    }
}
