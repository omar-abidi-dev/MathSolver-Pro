import Foundation

/// Represents a user's attempted solution with step-by-step work
struct UserAttempt: Identifiable {
    let id: UUID
    let equation: Equation
    let steps: [AttemptStep]
    var firstErrorIndex: Int?
    var errorDescription: String?
    var isCorrect: Bool {
        firstErrorIndex == nil && errorDescription == nil
    }
    
    init(
        equation: Equation,
        steps: [AttemptStep],
        firstErrorIndex: Int? = nil,
        errorDescription: String? = nil
    ) {
        self.id = UUID()
        self.equation = equation
        self.steps = steps
        self.firstErrorIndex = firstErrorIndex
        self.errorDescription = errorDescription
    }
}

/// Represents a single step in a user's work
struct AttemptStep: Identifiable {
    let id: UUID
    let stepNumber: Int
    let rawInput: String
    var parsedExpression: Equation?
    var isValid: Bool = false
    var correction: String?
    
    init(
        stepNumber: Int,
        rawInput: String,
        parsedExpression: Equation? = nil,
        isValid: Bool = false,
        correction: String? = nil
    ) {
        self.id = UUID()
        self.stepNumber = stepNumber
        self.rawInput = rawInput
        self.parsedExpression = parsedExpression
        self.isValid = isValid
        self.correction = correction
    }
}
