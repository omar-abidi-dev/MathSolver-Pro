import Foundation

// MARK: - StepOperation Enum

/// Represents the algebraic operation performed in a solution step
enum StepOperation: Equatable, Codable {
    /// Add the same value to both sides of the equation
    case addBothSides(Double)
    
    /// Subtract the same value from both sides of the equation
    case subtractBothSides(Double)
    
    /// Multiply both sides of the equation by the same value
    case multiplyBothSides(Double)
    
    /// Divide both sides of the equation by the same value
    case divideBothSides(Double)
    
    /// Factor a quadratic expression (e.g., x² - 4x + 3 = (x-1)(x-3))
    case factor
    
    /// Apply the quadratic formula to solve ax² + bx + c = 0
    case applyQuadraticFormula
    
    /// Substitute a variable with an expression (used in systems of equations)
    case substitute(variable: String, into: Int)
    
    /// Simplify the equation by combining like terms or reducing
    case simplify
    
    /// Collect like terms (e.g., 2x + 3x = 5x)
    case collectLikeTerms
    
    /// Apply a trigonometric identity (e.g., sin²x + cos²x = 1)
    case applyTrigIdentity(String)
    
    /// Apply a logarithm rule (e.g., log(ab) = log(a) + log(b))
    case applyLogRule(String)
    
    /// Apply differentiation rule (power rule, chain rule, etc.)
    case differentiate(rule: String)
    
    /// Apply integration rule
    case integrate(rule: String)
    
    /// Substitute a numeric value into an expression
    case substituteValue(variable: String, value: Double)
    
    /// Rewrite expression in equivalent form (e.g., convert trig to exponential)
    case rewrite(from: String, to: String)
    
    // Statistics and Physics operations
    case calculateMean
    case calculateMedian
    case calculateMode
    case calculateVariance
    case calculateStandardDeviation
    case sortData
    case calculateZScore
    case identifyFormula(String)
    case substituteValues
    case rearrangeFormula(String)
    case convertUnit(from: String, to: String)
    case computeResult
    
    // Calculus operations
    case evaluateLimit(method: String)
    case simplifyExpression
    case evaluateAtBounds
    case identifyIndeterminateForm(String)
    
    /// Human-readable description of the operation
    var description: String {
        switch self {
        case .addBothSides(let value):
            return "Add \(Int(value)) to both sides"
        case .subtractBothSides(let value):
            return "Subtract \(Int(value)) from both sides"
        case .multiplyBothSides(let value):
            let absVal = abs(value)
            return value >= 0 ? "Multiply both sides by \(Int(absVal))" : "Divide both sides by \(Int(absVal))"
        case .divideBothSides(let value):
            return "Divide both sides by \(Int(value))"
        case .factor:
            return "Factor the quadratic"
        case .applyQuadraticFormula:
            return "Apply the quadratic formula"
        case .substitute(let variable, _):
            return "Substitute \(variable)"
        case .simplify:
            return "Simplify"
        case .collectLikeTerms:
            return "Collect like terms"
        case .applyTrigIdentity(let identity):
            return "Apply identity: \(identity)"
        case .applyLogRule(let rule):
            return "Apply log rule: \(rule)"
        case .differentiate(let rule):
            return "Differentiate using \(rule)"
        case .integrate(let rule):
            return "Integrate using \(rule)"
        case .substituteValue(let variable, let value):
            return "Substitute \(variable) = \(value)"
        case .rewrite(let from, let to):
            return "Rewrite \(from) as \(to)"
        case .calculateMean:
            return "Calculate the mean"
        case .calculateMedian:
            return "Calculate the median"
        case .calculateMode:
            return "Calculate the mode"
        case .calculateVariance:
            return "Calculate the variance"
        case .calculateStandardDeviation:
            return "Calculate the standard deviation"
        case .sortData:
            return "Sort the data"
        case .calculateZScore:
            return "Calculate the z-score"
        case .identifyFormula(let formula):
            return "Identified formula: \(formula)"
        case .substituteValues:
            return "Substitute known values"
        case .rearrangeFormula(let formula):
            return "Rearrange to solve: \(formula)"
        case .convertUnit(let from, let to):
            return "Convert \(from) to \(to)"
        case .computeResult:
            return "Calculate final result"
        case .evaluateLimit(let method):
            return "Evaluate limit using \(method)"
        case .simplifyExpression:
            return "Simplify expression"
        case .evaluateAtBounds:
            return "Evaluate at bounds"
        case .identifyIndeterminateForm(let form):
            return "Identify indeterminate form: \(form)"
        }
    }
}

// MARK: - SolutionStep Struct

/// Represents a single step in the solving process of an equation
struct SolutionStep: Identifiable, Equatable {
    /// Unique identifier for this step
    let id: UUID
    
    /// Step number in the sequence (1-based)
    let stepNumber: Int
    
    /// The algebraic operation performed in this step
    let operation: StepOperation
    
    /// Human-readable description of what was done (e.g., "Subtract 5 from both sides")
    let description: String
    
    /// The resulting equation after this step (e.g., "2x = 10")
    let resultEquation: String
    
    /// Detailed explanation of why this step is correct
    /// Complexity varies by difficulty level (set by explainer)
    let explanation: String
    
    /// Optional simple explanation suitable for young learners
    /// Lazy-populated by SimpleExplainer if needed
    var simpleExplanation: String?
    
    /// Designated initializer
    init(
        stepNumber: Int,
        operation: StepOperation,
        description: String,
        resultEquation: String,
        explanation: String,
        simpleExplanation: String? = nil
    ) {
        self.id = UUID()
        self.stepNumber = stepNumber
        self.operation = operation
        self.description = description
        self.resultEquation = resultEquation
        self.explanation = explanation
        self.simpleExplanation = simpleExplanation
    }
    
    /// Two SolutionSteps are equal if they have the same content (ignoring ID and timestamps)
    static func == (lhs: SolutionStep, rhs: SolutionStep) -> Bool {
        lhs.stepNumber == rhs.stepNumber &&
        lhs.operation == rhs.operation &&
        lhs.description == rhs.description &&
        lhs.resultEquation == rhs.resultEquation &&
        lhs.explanation == rhs.explanation
    }
}

// MARK: - SolverResult Enum

/// Result of attempting to solve an equation
enum SolverResult: Equatable {
    /// Successfully solved with one or more solutions
    case solved(solution: [String: Double], steps: [SolutionStep])
    
    /// Equation has no solution (e.g., "0 = 5")
    case noSolution(reason: String, steps: [SolutionStep])
    
    /// Equation has infinitely many solutions (e.g., "x = x")
    case infiniteSolutions(reason: String, steps: [SolutionStep])
    
    /// Equation type is not supported by this solver
    case unsupported(reason: String)
    
    /// No real solutions exist (e.g., quadratic with negative discriminant)
    case noRealSolution(reason: String, steps: [SolutionStep])
    
    /// Extract solution dictionary if available
    var solutions: [String: Double]? {
        switch self {
        case .solved(let solution, _):
            return solution
        default:
            return nil
        }
    }
    
    /// Extract solution steps if available
    var steps: [SolutionStep]? {
        switch self {
        case .solved(_, let steps):
            return steps
        case .noSolution(_, let steps):
            return steps
        case .infiniteSolutions(_, let steps):
            return steps
        case .noRealSolution(_, let steps):
            return steps
        case .unsupported:
            return nil
        }
    }
    
    /// Human-readable summary of the result
    var summary: String {
        switch self {
        case .solved(let solution, _):
            if solution.count == 1, let (variable, value) = solution.first {
                if value == floor(value) {
                    return "\(variable) = \(Int(value))"
                }
                return String(format: "%@ = %.10g", variable, value)
            }
            // Multiple solutions
            return solution.map { k, v in
                if v == floor(v) {
                    return "\(k) = \(Int(v))"
                }
                return String(format: "%@ = %.10g", k, v)
            }.joined(separator: ", ")
            
        case .noSolution(let reason, _):
            return "No solution: \(reason)"
        case .infiniteSolutions(let reason, _):
            return "Infinite solutions: \(reason)"
        case .unsupported(let reason):
            return "Could not solve: \(reason)"
        case .noRealSolution(let reason, _):
            return "No real solutions: \(reason)"
        }
    }
}
