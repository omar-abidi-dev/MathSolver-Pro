import Foundation

/// Solver for symbolic differentiation
struct DerivativeSolver {
    /// Compute the derivative of an expression
    static func solve(
        expression: Expression,
        variable: String = "x"
    ) -> Result<CalcSolution, CalcSolverError> {
        var steps: [SolutionStep] = []
        
        // Differentiate
        let (derivative, diffSteps) = differentiate(expression, with: variable)
        steps.append(contentsOf: diffSteps)
        
        // Simplify
        let simplified = derivative.simplify()
        let simpStep = SolutionStep(
            stepNumber: steps.count + 1,
            operation: .simplifyExpression,
            description: "Simplify: \(simplified.description())",
            resultEquation: simplified.description(),
            explanation: "After applying simplification rules."
        )
        steps.append(simpStep)
        
        let solution = CalcSolution(
            mode: .derivatives,
            inputExpression: expression.description(),
            resultExpression: simplified.description(),
            variable: variable,
            steps: steps
        )
        return .success(solution)
    }
    
    private static func differentiate(_ expr: Expression, with variable: String) -> (Expression, [SolutionStep]) {
        var steps: [SolutionStep] = []
        let stepNum = 1
        
        let result: Expression
        
        switch expr {
        case .constant:
            // d/dx[c] = 0
            result = .constant(0)
            let step = SolutionStep(
                stepNumber: stepNum,
                operation: .differentiate(rule: "Constant Rule"),
                description: "d/dx[constant] = 0",
                resultEquation: "0",
                explanation: "The derivative of a constant is zero."
            )
            steps.append(step)
            
        case .variable(let name):
            if name == variable {
                // d/dx[x] = 1
                result = .constant(1)
                let step = SolutionStep(
                    stepNumber: stepNum,
                    operation: .differentiate(rule: "Power Rule (d/dx[x] = 1)"),
                    description: "d/dx[x] = 1",
                    resultEquation: "1",
                    explanation: "The derivative of x with respect to x is 1."
                )
                steps.append(step)
            } else {
                // d/dx[y] = 0 (y is not the variable)
                result = .constant(0)
                let step = SolutionStep(
                    stepNumber: stepNum,
                    operation: .differentiate(rule: "Constant Rule (other variable)"),
                    description: "d/dx[other variable] = 0",
                    resultEquation: "0",
                    explanation: "Variables other than x are treated as constants."
                )
                steps.append(step)
            }
            
        case .binaryOp(let op, let left, let right):
            let (leftDeriv, leftSteps) = differentiate(left, with: variable)
            let (rightDeriv, rightSteps) = differentiate(right, with: variable)
            
            switch op {
            case .add:
                // d/dx[f + g] = f' + g'
                result = .binaryOp(.add, leftDeriv, rightDeriv)
                steps.append(contentsOf: leftSteps)
                steps.append(contentsOf: rightSteps)
                let sumStep = SolutionStep(
                    stepNumber: steps.count + 1,
                    operation: .differentiate(rule: "Sum Rule"),
                    description: "d/dx[f + g] = f' + g'",
                    resultEquation: result.description(),
                    explanation: "Apply the sum rule: derivative of each term."
                )
                steps.append(sumStep)
                
            case .subtract:
                // d/dx[f - g] = f' - g'
                result = .binaryOp(.subtract, leftDeriv, rightDeriv)
                steps.append(contentsOf: leftSteps)
                steps.append(contentsOf: rightSteps)
                let diffStep = SolutionStep(
                    stepNumber: steps.count + 1,
                    operation: .differentiate(rule: "Difference Rule"),
                    description: "d/dx[f - g] = f' - g'",
                    resultEquation: result.description(),
                    explanation: "Apply the difference rule."
                )
                steps.append(diffStep)
                
            case .multiply:
                // Product rule: d/dx[f*g] = f'*g + f*g'
                result = .binaryOp(
                    .add,
                    .binaryOp(.multiply, leftDeriv, right),
                    .binaryOp(.multiply, left, rightDeriv)
                )
                steps.append(contentsOf: leftSteps)
                steps.append(contentsOf: rightSteps)
                let prodStep = SolutionStep(
                    stepNumber: steps.count + 1,
                    operation: .differentiate(rule: "Product Rule"),
                    description: "d/dx[f*g] = f'*g + f*g'",
                    resultEquation: result.description(),
                    explanation: "Apply the product rule."
                )
                steps.append(prodStep)
                
            case .divide:
                // Quotient rule: d/dx[f/g] = (f'*g - f*g') / g²
                result = .binaryOp(
                    .divide,
                    .binaryOp(
                        .subtract,
                        .binaryOp(.multiply, leftDeriv, right),
                        .binaryOp(.multiply, left, rightDeriv)
                    ),
                    .binaryOp(.power, right, .constant(2))
                )
                steps.append(contentsOf: leftSteps)
                steps.append(contentsOf: rightSteps)
                let quotStep = SolutionStep(
                    stepNumber: steps.count + 1,
                    operation: .differentiate(rule: "Quotient Rule"),
                    description: "d/dx[f/g] = (f'*g - f*g') / g²",
                    resultEquation: result.description(),
                    explanation: "Apply the quotient rule."
                )
                steps.append(quotStep)
                
            case .power:
                // Assume right is constant (power rule)
                if case .constant(let n) = right {
                    // d/dx[f^n] = n * f^(n-1) * f'
                    result = .binaryOp(
                        .multiply,
                        .binaryOp(
                            .multiply,
                            .constant(n),
                            .binaryOp(.power, left, .constant(n - 1))
                        ),
                        leftDeriv
                    )
                    let powStep = SolutionStep(
                        stepNumber: 1,
                        operation: .differentiate(rule: "Power Rule"),
                        description: "d/dx[f^n] = n*f^(n-1)*f'",
                        resultEquation: result.description(),
                        explanation: "Apply the power rule with chain rule."
                    )
                    steps = [powStep]
                } else {
                    result = .constant(0) // Fallback
                }
            }
            
        case .unaryOp(let op, let operand):
            let (opDeriv, opSteps) = differentiate(operand, with: variable)
            steps.append(contentsOf: opSteps)
            
            switch op {
            case .negate:
                // d/dx[-f] = -f'
                result = .unaryOp(.negate, opDeriv)
            }
            
        case .function(let name, let inner):
            let (innerDeriv, innerSteps) = differentiate(inner, with: variable)
            steps.append(contentsOf: innerSteps)
            
            // Chain rule: d/dx[func(f)] = func'(f) * f'
            let derivative: Expression
            
            switch name {
            case "sin":
                // d/dx[sin(f)] = cos(f) * f'
                derivative = .binaryOp(.multiply, .function("cos", inner), innerDeriv)
                let step = SolutionStep(
                    stepNumber: steps.count + 1,
                    operation: .differentiate(rule: "Chain Rule (sine)"),
                    description: "d/dx[sin(f)] = cos(f) * f'",
                    resultEquation: derivative.description(),
                    explanation: "Apply chain rule to sine function."
                )
                steps.append(step)
                result = derivative
                
            case "cos":
                // d/dx[cos(f)] = -sin(f) * f'
                derivative = .binaryOp(
                    .multiply,
                    .unaryOp(.negate, .function("sin", inner)),
                    innerDeriv
                )
                let step = SolutionStep(
                    stepNumber: steps.count + 1,
                    operation: .differentiate(rule: "Chain Rule (cosine)"),
                    description: "d/dx[cos(f)] = -sin(f) * f'",
                    resultEquation: derivative.description(),
                    explanation: "Apply chain rule to cosine function."
                )
                steps.append(step)
                result = derivative
                
            case "ln":
                // d/dx[ln(f)] = f' / f
                derivative = .binaryOp(.divide, innerDeriv, inner)
                let step = SolutionStep(
                    stepNumber: steps.count + 1,
                    operation: .differentiate(rule: "Chain Rule (ln)"),
                    description: "d/dx[ln(f)] = f' / f",
                    resultEquation: derivative.description(),
                    explanation: "Apply chain rule to natural logarithm."
                )
                steps.append(step)
                result = derivative
                
            case "exp":
                // d/dx[exp(f)] = exp(f) * f'
                derivative = .binaryOp(.multiply, .function("exp", inner), innerDeriv)
                let step = SolutionStep(
                    stepNumber: steps.count + 1,
                    operation: .differentiate(rule: "Chain Rule (exp)"),
                    description: "d/dx[exp(f)] = exp(f) * f'",
                    resultEquation: derivative.description(),
                    explanation: "Apply chain rule to exponential function."
                )
                steps.append(step)
                result = derivative
                
            default:
                result = .constant(0) // Unsupported function
            }
        }
        
        return (result, steps)
    }
}
