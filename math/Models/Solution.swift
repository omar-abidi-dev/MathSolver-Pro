import Foundation

/// Represents a complete solution to an equation
struct Solution: Identifiable, Codable {
    let id: UUID
    let equation: String
    let type: EquationType
    let solutions: [String]
    let steps: [Step]
    let difficulty: String
    let timestamp: Date
    let explanation: String
    let source: InputSource?
    let explanationSource: ExplanationSource?
    
    init(
        equation: String,
        type: EquationType,
        solutions: [String],
        steps: [Step],
        difficulty: String = "Intermediate",
        explanation: String = "",
        source: InputSource? = nil,
        explanationSource: ExplanationSource? = nil
    ) {
        self.id = UUID()
        self.equation = equation
        self.type = type
        self.solutions = solutions
        self.steps = steps
        self.difficulty = difficulty
        self.timestamp = Date()
        self.explanation = explanation
        self.source = source
        self.explanationSource = explanationSource
    }
}

// MARK: - Solution Extensions

extension Solution {
    var displaySolutions: String {
        solutions.joined(separator: ", ")
    }
    
    var isSystemOfEquations: Bool {
        type == .system
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
}

// MARK: - Sample Solutions

extension Solution {
    static let linearSample = Solution(
        equation: "2x + 4 = 10",
        type: .linear,
        solutions: ["x = 3"],
        steps: Step.samples,
        difficulty: "Beginner",
        explanation: "To solve this linear equation, we isolate x by subtracting 4 and dividing by 2."
    )
    
    static let quadraticSample = Solution(
        equation: "x² - 5x + 6 = 0",
        type: .quadratic,
        solutions: ["x = 2", "x = 3"],
        steps: [
            Step(description: "Original equation", expression: "x² - 5x + 6 = 0", explanation: "Given equation"),
            Step(description: "Factor", expression: "(x - 2)(x - 3) = 0", explanation: "Factor the quadratic"),
            Step(description: "Apply zero product", expression: "x = 2 or x = 3", explanation: "Each factor equals zero")
        ],
        difficulty: "Intermediate",
        explanation: "We factored the quadratic equation and used the zero product property."
    )
    
    static let samples: [Solution] = [
        .linearSample,
        .quadraticSample
    ]
}
