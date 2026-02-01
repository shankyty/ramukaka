import Foundation

struct Email: Identifiable, Codable {
    let id: String
    let sender: String
    let subject: String
    let body: String
    let date: Date
}

struct ActionItem: Codable, Identifiable {
    var id: UUID = UUID()
    let title: String
    let description: String?
    let suggestedDueDate: Date?

    // CodingKeys to exclude id if it's not coming from JSON
    enum CodingKeys: String, CodingKey {
        case title
        case description
        case suggestedDueDate
    }
}

struct EmailAnalysis: Codable {
    let summary: String
    let actionItems: [ActionItem]
}
