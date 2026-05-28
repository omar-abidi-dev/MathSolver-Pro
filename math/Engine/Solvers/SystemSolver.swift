import Foundation

/// Solves systems of 2 linear equations with 2 variables using elimination method
/// e.g., x + y = 10 and x - y = 2
class SystemSolver {
    
    /// Solve a system of 2 linear equations with 2 variables
    /// - Parameter equations: Array of exactly 2 Equation objects
    /// - Returns: SolverResult with solutions (x and y values) and steps
    func solve(equations: [Equation]) -> SolverResult {
        guard equations.count == 2 else {
            return .unsupported(reason: "This solver only handles systems of 2 equations")
        }
        
        var steps: [SolutionStep] = []
        
        let eq1 = equations[0]
        let eq2 = equations[1]
        
        // Extract coefficients for both equations
        // eq1: a1*x + b1*y = c1
        // eq2: a2*x + b2*y = c2
        
        guard let (a1, b1, c1) = extractLinearCoefficients(eq1),
              let (a2, b2, c2) = extractLinearCoefficients(eq2) else {
            return .unsupported(reason: "Could not extract coefficients")
        }
        
        // Add initial step showing the system
        steps.append(SolutionStep(
            stepNumber: steps.count + 1,
            operation: .simplify,
            description: "System of equations",
            resultEquation: "Equation 1: \(formatEquation(a: a1, b: b1, c: c1))\nEquation 2: \(formatEquation(a: a2, b: b2, c: c2))",
            explanation: "We need to find x and y that satisfy both equations simultaneously."
        ))
        
        // Use elimination method to eliminate x
        // Multiply equation 1 by a2 and equation 2 by a1, then subtract
        
        let mult1 = a2
        let mult2 = a1
        
        // After multiplication: mult1*(a1*x + b1*y) = mult1*c1
        //                      mult2*(a2*x + b2*y) = mult2*c2
        // After subtraction: (mult1*b1 - mult2*b2)*y = mult1*c1 - mult2*c2
        
        let yCoeff = (mult1 * b1) - (mult2 * b2)
        let yConstant = (mult1 * c1) - (mult2 * c2)
        
        // Check for special cases
        if yCoeff == 0 {
            if yConstant == 0 {
                // Infinite solutions - equations are the same line
                steps.append(SolutionStep(
                    stepNumber: steps.count + 1,
                    operation: .simplify,
                    description: "Check for dependencies",
                    resultEquation: "0 = 0",
                    explanation: "The two equations represent the same line, so there are infinitely many solutions."
                ))
                
                return .infiniteSolutions(
                    reason: "The two equations are dependent (represent the same line)",
                    steps: steps
                )
            } else {
                // No solutions - parallel lines
                steps.append(SolutionStep(
                    stepNumber: steps.count + 1,
                    operation: .simplify,
                    description: "Check for consistency",
                    resultEquation: "0 = \(Int(yConstant))",
                    explanation: "This is impossible, meaning the lines are parallel and never intersect."
                ))
                
                return .noSolution(
                    reason: "The equations represent parallel lines (no intersection)",
                    steps: steps
                )
            }
        }
        
        // Solve for y
        let yValue = yConstant / yCoeff
        
        steps.append(SolutionStep(
            stepNumber: steps.count + 1,
            operation: .collectLikeTerms,
            description: "Eliminate x by combining equations",
            resultEquation: "y = \(formatNumber(yValue))",
            explanation: "After elimination and simplification, we get the value of y."
        ))
        
        // Substitute y back into equation 1 to solve for x
        // a1*x + b1*y = c1
        // a1*x = c1 - b1*y
        
        let xConstant = c1 - (b1 * yValue)
        
        if a1 == 0 {
            // This shouldn't happen if we have a valid 2x2 system
            return .unsupported(reason: "Invalid system: coefficient of x is zero")
        }
        
        let xValue = xConstant / a1
        
        steps.append(SolutionStep(
            stepNumber: steps.count + 1,
            operation: .substitute(variable: "y", into: 1),
            description: "Substitute y back into equation 1",
            resultEquation: "x = \(formatNumber(xValue))",
            explanation: "We substitute the value of y into the first equation to find x."
        ))
        
        // Verify the solution (optional detail step)
        let verifyLeft1 = (a1 * xValue) + (b1 * yValue)
        let verifyLeft2 = (a2 * xValue) + (b2 * yValue)
        
        steps.append(SolutionStep(
            stepNumber: steps.count + 1,
            operation: .simplify,
            description: "Verify the solution",
            resultEquation: "x = \(formatNumber(xValue)), y = \(formatNumber(yValue))",
            explanation: "Both equations are satisfied: Equation 1 gives \(formatNumber(verifyLeft1)) = \(Int(c1)), Equation 2 gives \(formatNumber(verifyLeft2)) = \(Int(c2))"
        ))
        
        return .solved(solution: ["x": xValue, "y": yValue], steps: steps)
    }
    
    // MARK: - Helper Methods
    
    private func extractLinearCoefficients(_ equation: Equation) -> (Double, Double, Double)? {
        // Evaluate at x=0, y=0; x=1, y=0; x=0, y=1
        // We need to find a, b, c such that: a*x + b*y - c = 0
        
        // Evaluate LHS - RHS at different points
        let at00 = equation.leftExpression.evaluate(variables: ["x": 0, "y": 0]) ?? 0
                - (equation.rightExpression.evaluate(variables: ["x": 0, "y": 0]) ?? 0)
        
        let at10 = equation.leftExpression.evaluate(variables: ["x": 1, "y": 0]) ?? 0
                - (equation.rightExpression.evaluate(variables: ["x": 1, "y": 0]) ?? 0)
        
        let at01 = equation.leftExpression.evaluate(variables: ["x": 0, "y": 1]) ?? 0
                - (equation.rightExpression.evaluate(variables: ["x": 0, "y": 1]) ?? 0)
        
        // Extract: constant = at00, a = at10 - at00, b = at01 - at00
        let constant = -at00  // Moving to RHS, so negate
        let a = at10 - at00
        let b = at01 - at00
        
        return (a, b, constant)
    }
    
    private func formatEquation(a: Double, b: Double, c: Double) -> String {
        var parts: [String] = []
        
        if a != 0 {
            if a == 1 {
                parts.append("x")
            } else if a == -1 {
                parts.append("-x")
            } else {
                parts.append("\(Int(a))x")
            }
        }
        
        if b != 0 {
            if b > 0 && !parts.isEmpty {
                if b == 1 {
                    parts.append("+ y")
                } else {
                    parts.append("+ \(Int(b))y")
                }
            } else if b < 0 {
                if b == -1 {
                    parts.append("- y")
                } else {
                    parts.append("- \(Int(-b))y")
                }
            } else {
                if b == 1 {
                    parts.append("y")
                } else {
                    parts.append("\(Int(b))y")
                }
            }
        }
        
        let lhs = parts.isEmpty ? "0" : parts.joined(separator: " ")
        return "\(lhs) = \(Int(c))"
    }
    
    private func formatNumber(_ value: Double) -> String {
        if value == floor(value) {
            return String(Int(value))
        }
        return String(format: "%.10g", value)
    }
}
