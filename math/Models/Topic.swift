import Foundation

/// Category for educational topics
enum TopicCategory: String, Codable, CaseIterable {
    case algebra = "Algebra"
    case calculus = "Calculus"
    case trigonometry = "Trigonometry"
    case preCalculus = "Pre-Calculus"
    case physics = "Physics"
    case statistics = "Statistics"
}

/// An educational topic with explanation and worked examples
struct Topic: Identifiable {
    let id: String
    let title: String
    let category: TopicCategory
    let description: String
    let explanation: String
    let examples: [Example]
    let relatedFormulas: [String]
}

/// A worked example within a topic
struct Example {
    let title: String
    let description: String
    let solution: String
}
