import Foundation

/// Represents a single step in solving an equation
struct Step: Identifiable, Codable {
    let id: UUID
    let description: String
    let expression: String
    let explanation: String
    
    init(description: String, expression: String, explanation: String) {
        self.id = UUID()
        self.description = description
        self.expression = expression
        self.explanation = explanation
    }
}

extension Step {
    static let samples: [Step] = [
        Step(
            description: "Original equation",
            expression: "2x + 4 = 10",
            explanation: "We start with the given equation."
        ),
        Step(
            description: "Subtract 4 from both sides",
            expression: "2x = 6",
            explanation: "To isolate the variable term, we subtract 4 from both sides."
        ),
        Step(
            description: "Divide both sides by 2",
            expression: "x = 3",
            explanation: "We divide by the coefficient of x to solve for the variable."
        )
    ]
}
