import Foundation

/// Solves linear equations of the form ax + b = c
/// Handles edge cases: no solution (0x = non-zero), infinite solutions (0x = 0)
class LinearSolver {
    
    /// Solve a linear equation and return step-by-step solution
    /// - Parameter equation: The Equation to solve (must be equationType == .linear)
    /// - Returns: SolverResult with solutions and steps, or unsupported/error cases
    func solve(equation: Equation) -> SolverResult {
        var steps: [SolutionStep] = []
        var stepNumber = 1
        
        // Start with original equation
        let originalEq = "\(equation.leftExpression.description()) = \(equation.rightExpression.description())"
        
        // Step 1: Move all non-variable terms to the right side
        // We do this by converting to standard form: ax + b = c
        // Then we work to get: ax = c - b
        // Then: x = (c - b) / a
        
        // Extract coefficients for variable x and constant terms
        // by evaluating the expressions symbolically
        
        let coefficientsResult = extractLinearCoefficients(equation)
        guard let (aCoeff, bCoeff, cCoeff) = coefficientsResult else {
            return .unsupported(reason: "Could not extract linear coefficients")
        }
        
        // At this point we have: aCoeff * x + bCoeff = cCoeff
        // Rearrange to: aCoeff * x = cCoeff - bCoeff
        
        var currentA = aCoeff
        var currentB = bCoeff
        var currentC = cCoeff
        
        // Step: Collect constants (move bCoeff to right side)
        if currentB != 0 {
            let moveValue = currentB
            stepNumber += 1
            
            let operation: StepOperation = moveValue > 0 ? .subtractBothSides(-moveValue) : .addBothSides(moveValue)
            let operationDesc = moveValue > 0 ? "Subtract \(Int(-moveValue)) from both sides" : "Add \(Int(moveValue)) to both sides"
            
            let newC = currentC - moveValue
            let resultEq = formatEquation(aCoeff: currentA, constant: newC)
            
            let explanation = explainCollectConstants(moveValue: moveValue, difficulty: .intermediate)
            
            steps.append(SolutionStep(
                stepNumber: steps.count + 1,
                operation: operation,
                description: operationDesc,
                resultEquation: resultEq,
                explanation: explanation
            ))
            
            currentC = newC
            currentB = 0
        }
        
        // Now we have: currentA * x = currentC
        // Step: Divide both sides by currentA to isolate x
        
        if currentA == 0 {
            // Special cases: 0x = something
            if currentC == 0 {
                // 0x = 0 → infinite solutions
                steps.append(SolutionStep(
                    stepNumber: steps.count + 1,
                    operation: .simplify,
                    description: "Simplify",
                    resultEquation: "0 = 0",
                    explanation: "This equation is always true, no matter what x is."
                ))
                return .infiniteSolutions(
                    reason: "The equation is equivalent to 0 = 0, which is always true",
                    steps: steps
                )
            } else {
                // 0x = non-zero → no solution
                steps.append(SolutionStep(
                    stepNumber: steps.count + 1,
                    operation: .simplify,
                    description: "Simplify",
                    resultEquation: "0 = \(Int(currentC))",
                    explanation: "This is a false statement. No value of x can make this true."
                ))
                return .noSolution(
                    reason: "The equation simplifies to \(Int(currentC)) = 0, which is never true",
                    steps: steps
                )
            }
        }
        
        // Divide both sides by currentA
        let solution = currentC / currentA
        
        let operationDesc = currentA == 1 ? "x is isolated" : "Divide both sides by \(Int(currentA))"
        let operation: StepOperation = .divideBothSides(currentA)
        
        let resultEq = "x = \(formatNumber(solution))"
        let explanation = explainDivide(divisor: currentA, difficulty: .intermediate)
        
        steps.append(SolutionStep(
            stepNumber: steps.count + 1,
            operation: operation,
            description: operationDesc,
            resultEquation: resultEq,
            explanation: explanation
        ))
        
        return .solved(solution: ["x": solution], steps: steps)
    }
    
    // MARK: - Helper Methods
    
    /// Extract linear coefficients from equation
    /// Returns (coeff_of_x, constant_left, constant_right)
    private func extractLinearCoefficients(_ equation: Equation) -> (Double, Double, Double)? {
        // Evaluate left and right sides at two points to extract coefficients
        // If LHS = ax + b, then: f(0) = b, f(1) = a + b
        
        let leftAt0 = equation.leftExpression.evaluate(variables: ["x": 0]) ?? 0
        let leftAt1 = equation.leftExpression.evaluate(variables: ["x": 1]) ?? 0
        let rightAt0 = equation.rightExpression.evaluate(variables: ["x": 0]) ?? 0
        let rightAt1 = equation.rightExpression.evaluate(variables: ["x": 1]) ?? 0
        
        // Extract coefficients
        let aCoeff = (leftAt1 - leftAt0) - (rightAt1 - rightAt0)
        let constantLeft = leftAt0 - rightAt0
        let constantRight = 0.0
        
        return (aCoeff, constantLeft, constantRight)
    }
    
    /// Format equation string for display
    private func formatEquation(aCoeff: Double, constant: Double) -> String {
        let xPart = formatCoefficient(aCoeff) + "x"
        let constPart = constant < 0 ? "- \(Int(-constant))" : "+ \(Int(constant))"
        
        if constant == 0 {
            return "\(xPart) = 0"
        }
        if aCoeff == 0 {
            return "0 = \(Int(constant))"
        }
        
        return "\(xPart) = \(Int(constant))"
    }
    
    /// Format coefficient for display
    private func formatCoefficient(_ value: Double) -> String {
        if value == 1 {
            return ""
        } else if value == -1 {
            return "-"
        } else {
            return String(Int(value))
        }
    }
    
    /// Format a number for display
    private func formatNumber(_ value: Double) -> String {
        if value == floor(value) {
            return String(Int(value))
        }
        return String(format: "%.10g", value)
    }
    
    /// Generate explanation for collecting like terms
    private func explainCollectConstants(moveValue: Double, difficulty: Difficulty) -> String {
        let absValue = Int(abs(moveValue))
        let direction = moveValue > 0 ? "subtract" : "add"
        
        switch difficulty {
        case .beginner:
            return "We want to get all the numbers (without x) on one side. To do this, we \(direction) \(absValue) from both sides."
        case .intermediate:
            return "Rearrange to collect constant terms on the right side. \(moveValue > 0 ? "Subtract" : "Add") \(absValue) from both sides to balance the equation."
        case .advanced:
            return "Apply the additive inverse of \(Int(moveValue)) to both sides to isolate terms with the variable."
        }
    }
    
    /// Generate explanation for division step
    private func explainDivide(divisor: Double, difficulty: Difficulty) -> String {
        let intDivisor = Int(divisor)
        
        switch difficulty {
        case .beginner:
            return "Now x is multiplied by \(intDivisor). To undo multiplication, we divide both sides by \(intDivisor)."
        case .intermediate:
            return "Divide both sides by the coefficient of x (\(intDivisor)) to isolate the variable."
        case .advanced:
            return "Apply the multiplicative inverse (1/\(intDivisor)) to both sides to obtain the unique solution."
        }
    }
}
