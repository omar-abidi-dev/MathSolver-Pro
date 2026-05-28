import Foundation

/// Validates user's algebraic steps against expected solution steps
class StepValidator {
    /// Validates a user's attempt against the correct solution
    /// - Parameters:
    ///   - attempt: The user's attempted solution steps
    ///   - correctSteps: The correct solution steps
    /// - Returns: Updated UserAttempt with validation results
    func validate(attempt: UserAttempt, correctSteps: [SolutionStep]) -> UserAttempt {
        var validatedAttempt = attempt
        
        // Parse each user step
        var parsedSteps: [Equation] = []
        for step in attempt.steps {
            if let parsed = parseStep(step.rawInput) {
                parsedSteps.append(parsed)
            }
        }
        
        // Find first error by checking algebraic equivalence
        for (index, userStep) in parsedSteps.enumerated() {
            let isEquivalent = checkAlgebraicEquivalence(
                original: attempt.equation,
                userStep: userStep
            )
            
            if !isEquivalent {
                validatedAttempt.firstErrorIndex = index
                validatedAttempt.errorDescription = generateErrorDescription(
                    userStep: userStep,
                    expectedStep: index < correctSteps.count ? correctSteps[index] : nil
                )
                return validatedAttempt
            }
        }
        
        // All steps valid
        validatedAttempt.firstErrorIndex = nil
        validatedAttempt.errorDescription = nil
        
        return validatedAttempt
    }
    
    /// Parses a step string into an Equation
    private func parseStep(_ input: String) -> Equation? {
        // Create a dummy equation for validation purposes
        // In real implementation, would use EquationParser
        return Equation(
            rawInput: input,
            equationType: .linear,
            leftExpression: .variable("x"),
            rightExpression: .constant(0)
        )
    }
    
    /// Checks if user step is algebraically equivalent to original equation
    /// Uses 5 test points: x = -2, -1, 0, 1, 2
    private func checkAlgebraicEquivalence(original: Equation, userStep: Equation) -> Bool {
        let testPoints: [Double] = [-2, -1, 0, 1, 2]
        let tolerance = 1e-9
        
        for x in testPoints {
            let vars = ["x": x]
            
            guard let originalLHS = original.leftExpression.evaluate(variables: vars),
                  let originalRHS = original.rightExpression.evaluate(variables: vars),
                  let userLHS = userStep.leftExpression.evaluate(variables: vars),
                  let userRHS = userStep.rightExpression.evaluate(variables: vars) else {
                continue
            }
            
            // Check if the difference between sides diverged
            let originalDiff = abs(originalLHS - originalRHS)
            let userDiff = abs(userLHS - userRHS)
            
            if abs(originalDiff - userDiff) > tolerance {
                return false
            }
        }
        
        return true
    }
    
    /// Generates a user-friendly error description
    private func generateErrorDescription(userStep: Equation, expectedStep: SolutionStep?) -> String {
        if let expected = expectedStep {
            return "Step doesn't match the expected work. Expected: \(expected.description)"
        }
        return "This step contains an algebraic error. Please review and try again."
    }
}
