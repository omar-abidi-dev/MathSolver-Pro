import Foundation

/// Solves quadratic equations of the form ax² + bx + c = 0
/// First attempts factoring, then falls back to quadratic formula
class QuadraticSolver {
    
    /// Solve a quadratic equation and return step-by-step solution
    /// - Parameter equation: The Equation to solve (must be equationType == .quadratic)
    /// - Returns: SolverResult with solutions and steps, or error cases
    func solve(equation: Equation) -> SolverResult {
        var steps: [SolutionStep] = []
        
        // Extract quadratic coefficients a, b, c from ax² + bx + c = 0
        guard let (a, b, c) = extractQuadraticCoefficients(equation) else {
            return .unsupported(reason: "Could not extract quadratic coefficients")
        }
        
        // Try factoring first
        if let (x1, x2, factoringSteps) = attemptFactoring(a: a, b: b, c: c) {
            steps.append(contentsOf: factoringSteps)
            
            // Add final step: solve each factor
            steps.append(SolutionStep(
                stepNumber: steps.count + 1,
                operation: .simplify,
                description: "The solutions are the values that make each factor zero",
                resultEquation: "x = \(formatNumber(x1)) or x = \(formatNumber(x2))",
                explanation: "From the factored form, we find x by setting each factor equal to zero."
            ))
            
            return .solved(solution: ["x": x1, "x2": x2], steps: steps)
        }
        
        // Fall back to quadratic formula
        let discriminant = b * b - 4 * a * c
        
        // Add step: identify quadratic formula approach
        steps.append(SolutionStep(
            stepNumber: steps.count + 1,
            operation: .applyQuadraticFormula,
            description: "Apply the quadratic formula",
            resultEquation: "x = (-b ± √(b² - 4ac)) / 2a",
            explanation: "We'll use the quadratic formula with a = \(Int(a)), b = \(Int(b)), c = \(Int(c))"
        ))
        
        // Add step: calculate discriminant
        let discriminantStep = steps.count + 1
        steps.append(SolutionStep(
            stepNumber: discriminantStep,
            operation: .simplify,
            description: "Calculate the discriminant (b² - 4ac)",
            resultEquation: "Discriminant = \(Int(discriminant))",
            explanation: "The discriminant tells us how many real solutions exist: \(Int(b))² - 4(\(Int(a)))(\(Int(c))) = \(Int(discriminant))"
        ))
        
        // Check discriminant
        if discriminant < 0 {
            steps.append(SolutionStep(
                stepNumber: steps.count + 1,
                operation: .simplify,
                description: "Evaluate the discriminant",
                resultEquation: "Discriminant = \(Int(discriminant)) < 0",
                explanation: "Since the discriminant is negative, there are no real solutions (only complex numbers)."
            ))
            
            return .noRealSolution(
                reason: "The discriminant is negative (\(Int(discriminant))), so there are no real solutions.",
                steps: steps
            )
        }
        
        // Calculate solutions using quadratic formula
        let sqrtDiscriminant = sqrt(discriminant)
        let x1 = (-b + sqrtDiscriminant) / (2 * a)
        let x2 = (-b - sqrtDiscriminant) / (2 * a)
        
        // Add step: calculate square root
        steps.append(SolutionStep(
            stepNumber: steps.count + 1,
            operation: .simplify,
            description: "Calculate √\(Int(discriminant))",
            resultEquation: "√\(Int(discriminant)) = \(formatNumber(sqrtDiscriminant))",
            explanation: "Take the square root of the discriminant."
        ))
        
        // Add step: calculate both solutions
        let solution1Str = formatNumber(x1)
        let solution2Str = formatNumber(x2)
        
        steps.append(SolutionStep(
            stepNumber: steps.count + 1,
            operation: .simplify,
            description: "Calculate the two solutions",
            resultEquation: "x = \(solution1Str) or x = \(solution2Str)",
            explanation: "x = (-\(Int(b)) ± \(formatNumber(sqrtDiscriminant))) / \(Int(2 * a))"
        ))
        
        return .solved(solution: ["x": x1, "x2": x2], steps: steps)
    }
    
    // MARK: - Factoring Attempt
    
    /// Attempt to factor the quadratic as (px + q)(rx + s) = 0
    /// Returns nil if factoring is not possible with integer coefficients
    private func attemptFactoring(
        a: Double,
        b: Double,
        c: Double
    ) -> (Double, Double, [SolutionStep])? {
        // For simplicity, only attempt factoring when coefficients are integers
        guard a == floor(a), b == floor(b), c == floor(c) else {
            return nil
        }
        
        let ai = Int(a)
        let bi = Int(b)
        let ci = Int(c)
        
        // Find factors of a*c that add up to b
        let product = ai * ci
        
        var steps: [SolutionStep] = []
        
        // Try to find factors
        for factor in stride(from: -abs(product), through: abs(product), by: 1) {
            let other = product / factor
            if other == 0 { continue }
            
            if factor + other == bi && factor * other == product {
                // Found factors! Rewrite bx as factor*x + other*x
                let factorStep = SolutionStep(
                    stepNumber: steps.count + 1,
                    operation: .factor,
                    description: "Factor the quadratic",
                    resultEquation: "(\(ai)x + \(other / ai))(\(ai)x + \(factor / ai)) = 0",
                    explanation: "We found that the quadratic factors into two linear expressions."
                )
                
                steps.append(factorStep)
                
                // Calculate the two solutions
                let x1 = Double(-other) / Double(ai)
                let x2 = Double(-factor) / Double(ai)
                
                return (x1, x2, steps)
            }
        }
        
        return nil
    }
    
    // MARK: - Coefficient Extraction
    
    private func extractQuadraticCoefficients(_ equation: Equation) -> (Double, Double, Double)? {
        // Move all terms to the left side and evaluate at 3 points
        // For ax² + bx + c = 0, evaluate at x = 0, 1, 2
        
        let point0 = evaluateDifference(equation, at: 0)
        let point1 = evaluateDifference(equation, at: 1)
        let point2 = evaluateDifference(equation, at: 2)
        
        // Set up system: point0 = c,  point1 = a + b + c,  point2 = 4a + 2b + c
        let c = point0
        let a = (point2 - 2 * point1 + c) / 2
        let b = point1 - a - c
        
        return (a, b, c)
    }
    
    private func evaluateDifference(_ equation: Equation, at x: Double) -> Double {
        let leftVal = equation.leftExpression.evaluate(variables: ["x": x]) ?? 0
        let rightVal = equation.rightExpression.evaluate(variables: ["x": x]) ?? 0
        return leftVal - rightVal
    }
    
    private func formatNumber(_ value: Double) -> String {
        if value == floor(value) {
            return String(Int(value))
        }
        return String(format: "%.10g", value)
    }
}
