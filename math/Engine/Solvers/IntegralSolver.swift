import Foundation

/// Solver for symbolic integration
struct IntegralSolver {
    /// Compute the integral of an expression
    static func solve(
        expression: Expression,
        variable: String = "x",
        lowerBound: Double? = nil,
        upperBound: Double? = nil
    ) -> Result<CalcSolution, CalcSolverError> {
        var steps: [SolutionStep] = []
        let isDefinite = lowerBound != nil && upperBound != nil
        
        // Integrate
        let (antiderivative, integSteps) = integrate(expression, with: variable)
        steps.append(contentsOf: integSteps)
        
        var resultExpression: String
        var numericResult: Double?
        
        if isDefinite, let lower = lowerBound, let upper = upperBound {
            // Definite integral: F(b) - F(a)
            let variables_upper = [variable: upper]
            let variables_lower = [variable: lower]
            
            if let upper_val = antiderivative.evaluate(variables: variables_upper),
               let lower_val = antiderivative.evaluate(variables: variables_lower) {
                numericResult = upper_val - lower_val
                resultExpression = String(format: "%.6g", numericResult ?? 0)
                
                let evalStep = SolutionStep(
                    stepNumber: steps.count + 1,
                    operation: .evaluateAtBounds,
                    description: "Evaluate F(\(upper)) - F(\(lower))",
                    resultEquation: resultExpression,
                    explanation: "Apply Fundamental Theorem of Calculus: ∫f dx from a to b = F(b) - F(a)"
                )
                steps.append(evalStep)
            } else {
                resultExpression = antiderivative.description()
            }
        } else {
            // Indefinite integral
            resultExpression = antiderivative.description() + " + C"
        }
        
        let solution = CalcSolution(
            mode: .integrals,
            inputExpression: expression.description(),
            resultExpression: resultExpression,
            numericResult: numericResult,
            variable: variable,
            lowerBound: lowerBound,
            upperBound: upperBound,
            isDefinite: isDefinite,
            steps: steps
        )
        return .success(solution)
    }
    
    private static func integrate(_ expr: Expression, with variable: String) -> (Expression, [SolutionStep]) {
        var steps: [SolutionStep] = []
        
        let result: Expression
        
        switch expr {
        case .constant(let c):
            // ∫c dx = c*x
            result = .binaryOp(.multiply, .constant(c), .variable(variable))
            let step = SolutionStep(
                stepNumber: 1,
                operation: .integrate(rule: "Constant Rule"),
                description: "∫c dx = c*x",
                resultEquation: result.description(),
                explanation: "Integrate a constant."
            )
            steps.append(step)
            
        case .variable(let name):
            if name == variable {
                // ∫x dx = x²/2
                result = .binaryOp(
                    .divide,
                    .binaryOp(.power, .variable(variable), .constant(2)),
                    .constant(2)
                )
                let step = SolutionStep(
                    stepNumber: 1,
                    operation: .integrate(rule: "Power Rule (n=1)"),
                    description: "∫x dx = x²/2",
                    resultEquation: result.description(),
                    explanation: "Integrate x using the reverse power rule."
                )
                steps.append(step)
            } else {
                // ∫y dx = y*x (other variable is constant)
                result = .binaryOp(.multiply, .variable(name), .variable(variable))
                let step = SolutionStep(
                    stepNumber: 1,
                    operation: .integrate(rule: "Constant Multiple"),
                    description: "∫y dx = y*x (y is constant)",
                    resultEquation: result.description(),
                    explanation: "Other variables are treated as constants."
                )
                steps.append(step)
            }
            
        case .binaryOp(let op, let left, let right):
            switch op {
            case .add:
                // ∫(f + g) dx = ∫f dx + ∫g dx
                let (leftInt, leftSteps) = integrate(left, with: variable)
                let (rightInt, rightSteps) = integrate(right, with: variable)
                result = .binaryOp(.add, leftInt, rightInt)
                steps.append(contentsOf: leftSteps)
                steps.append(contentsOf: rightSteps)
                let sumStep = SolutionStep(
                    stepNumber: steps.count + 1,
                    operation: .integrate(rule: "Sum Rule"),
                    description: "∫(f + g) dx = ∫f dx + ∫g dx",
                    resultEquation: result.description(),
                    explanation: "Integrate each term separately."
                )
                steps.append(sumStep)
                
            case .subtract:
                // ∫(f - g) dx = ∫f dx - ∫g dx
                let (leftInt, leftSteps) = integrate(left, with: variable)
                let (rightInt, rightSteps) = integrate(right, with: variable)
                result = .binaryOp(.subtract, leftInt, rightInt)
                steps.append(contentsOf: leftSteps)
                steps.append(contentsOf: rightSteps)
                let diffStep = SolutionStep(
                    stepNumber: steps.count + 1,
                    operation: .integrate(rule: "Difference Rule"),
                    description: "∫(f - g) dx = ∫f dx - ∫g dx",
                    resultEquation: result.description(),
                    explanation: "Integrate each term separately."
                )
                steps.append(diffStep)
                
            case .multiply:
                // Simplified: if one side is constant, factor it out
                if case .constant(let c) = left {
                    let (rightInt, rightSteps) = integrate(right, with: variable)
                    result = .binaryOp(.multiply, .constant(c), rightInt)
                    steps.append(contentsOf: rightSteps)
                    let constStep = SolutionStep(
                        stepNumber: steps.count + 1,
                        operation: .integrate(rule: "Constant Multiple Rule"),
                        description: "∫c*f dx = c*∫f dx",
                        resultEquation: result.description(),
                        explanation: "Factor out the constant."
                    )
                    steps.append(constStep)
                } else if case .constant(let c) = right {
                    let (leftInt, leftSteps) = integrate(left, with: variable)
                    result = .binaryOp(.multiply, leftInt, .constant(c))
                    steps.append(contentsOf: leftSteps)
                    let constStep = SolutionStep(
                        stepNumber: steps.count + 1,
                        operation: .integrate(rule: "Constant Multiple Rule"),
                        description: "∫f*c dx = ∫f dx * c",
                        resultEquation: result.description(),
                        explanation: "Factor out the constant."
                    )
                    steps.append(constStep)
                } else {
                    // General product — can't integrate easily
                    result = expr
                }
                
            case .power:
                // ∫f^n dx — simplified for constant n
                if case .constant(let n) = right, case .variable = left {
                    if n != -1 {
                        // x^n: ∫x^n dx = x^(n+1)/(n+1)
                        result = .binaryOp(
                            .divide,
                            .binaryOp(.power, left, .constant(n + 1)),
                            .constant(n + 1)
                        )
                        let step = SolutionStep(
                            stepNumber: 1,
                            operation: .integrate(rule: "Power Rule"),
                            description: "∫x^n dx = x^(n+1)/(n+1)",
                            resultEquation: result.description(),
                            explanation: "Apply the reverse power rule."
                        )
                        steps.append(step)
                    } else {
                        // 1/x: ∫1/x dx = ln|x|
                        result = .function("ln", .variable(variable))
                        let step = SolutionStep(
                            stepNumber: 1,
                            operation: .integrate(rule: "Logarithmic Rule"),
                            description: "∫1/x dx = ln|x|",
                            resultEquation: result.description(),
                            explanation: "Special case: 1/x integrates to natural log."
                        )
                        steps.append(step)
                    }
                } else {
                    result = expr
                }
                
            case .divide:
                // Simplified division
                result = expr
            }
            
        case .function(let name, let inner):
            switch name {
            case "sin":
                // ∫sin(x) dx = -cos(x)
                result = .unaryOp(.negate, .function("cos", inner))
                let step = SolutionStep(
                    stepNumber: 1,
                    operation: .integrate(rule: "Sine Rule"),
                    description: "∫sin(x) dx = -cos(x)",
                    resultEquation: result.description(),
                    explanation: "Standard integral of sine."
                )
                steps.append(step)
                
            case "cos":
                // ∫cos(x) dx = sin(x)
                result = .function("sin", inner)
                let step = SolutionStep(
                    stepNumber: 1,
                    operation: .integrate(rule: "Cosine Rule"),
                    description: "∫cos(x) dx = sin(x)",
                    resultEquation: result.description(),
                    explanation: "Standard integral of cosine."
                )
                steps.append(step)
                
            case "exp":
                // ∫exp(x) dx = exp(x)
                result = .function("exp", inner)
                let step = SolutionStep(
                    stepNumber: 1,
                    operation: .integrate(rule: "Exponential Rule"),
                    description: "∫exp(x) dx = exp(x)",
                    resultEquation: result.description(),
                    explanation: "Standard integral of exponential."
                )
                steps.append(step)
                
            default:
                result = expr
            }
            
        case .unaryOp:
            result = expr
        }
        
        return (result, steps)
    }
}
