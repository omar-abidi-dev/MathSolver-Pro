import Foundation

/// Calculus solver errors
enum CalcSolverError: Error {
    case unsolvable(String)
    case invalidInput(String)
}

/// Solver for evaluating limits using direct substitution, algebraic simplification, and L'Hôpital's rule
struct LimitsSolver {
    /// Solve a limit: lim(x→approachValue) expression
    static func solve(
        expression: Expression,
        variable: String = "x",
        approachValue: Double
    ) -> Result<CalcSolution, CalcSolverError> {
        var steps: [SolutionStep] = []
        
        // Step 1: Try direct substitution
        let variables = [variable: approachValue]
        if let directResult = expression.evaluate(variables: variables) {
            if directResult.isFinite && !directResult.isNaN {
                let step = SolutionStep(
                    stepNumber: 1,
                    operation: .evaluateLimit(method: "Direct Substitution"),
                    description: "Evaluate at x = \(formatNumber(approachValue))",
                    resultEquation: formatNumber(directResult),
                    explanation: "Direct substitution yields a finite value."
                )
                steps.append(step)
                
                let solution = CalcSolution(
                    mode: .limits,
                    inputExpression: expression.description(),
                    resultExpression: formatNumber(directResult),
                    numericResult: directResult,
                    variable: variable,
                    approachValue: String(approachValue),
                    steps: steps
                )
                return .success(solution)
            }
        }
        
        // Step 2: Indeterminate form detected (0/0 or ∞/∞)
        let step1 = SolutionStep(
            stepNumber: steps.count + 1,
            operation: .identifyIndeterminateForm("0/0 or ∞/∞"),
            description: "Detected indeterminate form",
            resultEquation: "0/0",
            explanation: "Direct substitution gives an indeterminate form. Trying algebraic simplification or L'Hôpital's rule."
        )
        steps.append(step1)
        
        // Step 3: Try algebraic simplification
        let simplified = expression.simplify()
        if let simplResult = simplified.evaluate(variables: variables) {
            if simplResult.isFinite && !simplResult.isNaN {
                let step2 = SolutionStep(
                    stepNumber: steps.count + 1,
                    operation: .simplifyExpression,
                    description: "Simplify expression: \(simplified.description())",
                    resultEquation: formatNumber(simplResult),
                    explanation: "After algebraic simplification, the limit evaluates to \(formatNumber(simplResult))."
                )
                steps.append(step2)
                
                let solution = CalcSolution(
                    mode: .limits,
                    inputExpression: expression.description(),
                    resultExpression: formatNumber(simplResult),
                    numericResult: simplResult,
                    variable: variable,
                    approachValue: String(approachValue),
                    steps: steps
                )
                return .success(solution)
            }
        }
        
        // Step 4: Try L'Hôpital's rule for 0/0 forms (differentiate numerator and denominator)
        if case .binaryOp(.divide, let numerator, let denominator) = expression {
            let numDerivResult = DerivativeSolver.solve(expression: numerator, variable: variable)
            let denDerivResult = DerivativeSolver.solve(expression: denominator, variable: variable)
            
            if case .success(let numSol) = numDerivResult,
               case .success(let denSol) = denDerivResult {
                // Parse the derivative result expressions back
                if let numDeriv = parseExpressionString(numSol.resultExpression),
                   let denDeriv = parseExpressionString(denSol.resultExpression) {
                    let lhopitalExpr = Expression.binaryOp(.divide, numDeriv, denDeriv)
                    if let lhResult = lhopitalExpr.evaluate(variables: variables) {
                        if lhResult.isFinite && !lhResult.isNaN {
                            let stepLH = SolutionStep(
                                stepNumber: steps.count + 1,
                                operation: .evaluateLimit(method: "L'Hôpital's Rule"),
                                description: "Apply L'Hôpital's Rule: lim f/g = lim f'/g'",
                                resultEquation: "\(numSol.resultExpression) / \(denSol.resultExpression) = \(formatNumber(lhResult))",
                                explanation: "Differentiate numerator and denominator separately, then re-evaluate the limit."
                            )
                            steps.append(stepLH)
                            
                            let solution = CalcSolution(
                                mode: .limits,
                                inputExpression: expression.description(),
                                resultExpression: formatNumber(lhResult),
                                numericResult: lhResult,
                                variable: variable,
                                approachValue: String(approachValue),
                                steps: steps
                            )
                            return .success(solution)
                        }
                    }
                }
            }
        }
        
        // Step 5: Numerical approach — evaluate from both sides
        let epsilon = 1e-10
        let leftApproach = expression.evaluate(variables: [variable: approachValue - epsilon])
        let rightApproach = expression.evaluate(variables: [variable: approachValue + epsilon])
        
        if let left = leftApproach, let right = rightApproach,
           left.isFinite, right.isFinite,
           abs(left - right) < 1e-6 {
            let numericResult = (left + right) / 2.0
            let stepNum = SolutionStep(
                stepNumber: steps.count + 1,
                operation: .evaluateLimit(method: "Numerical Approach"),
                description: "Evaluate numerically from both sides",
                resultEquation: "lim ≈ \(formatNumber(numericResult))",
                explanation: "Approaching from left: \(formatNumber(left)), from right: \(formatNumber(right)). The limit converges."
            )
            steps.append(stepNum)
            
            let solution = CalcSolution(
                mode: .limits,
                inputExpression: expression.description(),
                resultExpression: formatNumber(numericResult),
                numericResult: numericResult,
                variable: variable,
                approachValue: String(approachValue),
                steps: steps
            )
            return .success(solution)
        }
        
        // Return failure if nothing worked
        let stepFail = SolutionStep(
            stepNumber: steps.count + 1,
            operation: .evaluateLimit(method: "Manual Review"),
            description: "Could not evaluate automatically",
            resultEquation: "Undefined",
            explanation: "The limit could not be determined using available methods. It may not exist or may require advanced techniques."
        )
        steps.append(stepFail)
        
        return .failure(.unsolvable("Could not evaluate limit using standard methods"))
    }
    
    private static func formatNumber(_ value: Double) -> String {
        if value == floor(value) {
            return String(Int(value))
        }
        return String(format: "%.6g", value)
    }
}
