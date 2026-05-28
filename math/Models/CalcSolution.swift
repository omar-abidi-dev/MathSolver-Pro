import Foundation

/// Represents the result of a calculus computation (limits, derivatives, or integrals)
struct CalcSolution: Identifiable, Equatable {
    /// Unique identifier
    let id: UUID
    
    /// Which calculus operation was performed
    let mode: CalculusMode
    
    /// Original expression as entered by user
    let inputExpression: String
    
    /// Symbolic result (e.g., "6x + 5" for a derivative)
    let resultExpression: String
    
    /// Numeric result if applicable (definite integrals, limits evaluated to a number)
    let numericResult: Double?
    
    /// The variable of differentiation/integration (default "x")
    let variable: String
    
    /// For limits: the approach value as string (e.g., "1", "∞")
    let approachValue: String?
    
    /// For definite integrals: lower bound
    let lowerBound: Double?
    
    /// For definite integrals: upper bound
    let upperBound: Double?
    
    /// For integrals: whether definite or indefinite
    let isDefinite: Bool
    
    /// Step-by-step breakdown of the solution
    let steps: [SolutionStep]
    
    /// Initializer for calculus solutions
    init(
        mode: CalculusMode,
        inputExpression: String,
        resultExpression: String,
        numericResult: Double? = nil,
        variable: String = "x",
        approachValue: String? = nil,
        lowerBound: Double? = nil,
        upperBound: Double? = nil,
        isDefinite: Bool = false,
        steps: [SolutionStep]
    ) {
        self.id = UUID()
        self.mode = mode
        self.inputExpression = inputExpression
        self.resultExpression = resultExpression
        self.numericResult = numericResult
        self.variable = variable
        self.approachValue = approachValue
        self.lowerBound = lowerBound
        self.upperBound = upperBound
        self.isDefinite = isDefinite
        self.steps = steps
        
        // Validate
        assert(!inputExpression.isEmpty, "inputExpression must be non-empty")
        assert(!resultExpression.isEmpty, "resultExpression must be non-empty")
        assert(!steps.isEmpty, "steps must have at least 1 step")
        
        if mode == .limits {
            assert(approachValue != nil, "If mode == .limits, approachValue must be non-nil")
        }
        
        if mode == .integrals && isDefinite {
            assert(lowerBound != nil && upperBound != nil, "If definite integral, bounds must be non-nil")
            assert(numericResult != nil, "If definite integral, numericResult must be non-nil")
        }
    }
    
    /// Two CalcSolutions are equal if they have the same content (ignoring ID)
    static func == (lhs: CalcSolution, rhs: CalcSolution) -> Bool {
        lhs.mode == rhs.mode &&
        lhs.inputExpression == rhs.inputExpression &&
        lhs.resultExpression == rhs.resultExpression &&
        lhs.numericResult == rhs.numericResult &&
        lhs.variable == rhs.variable &&
        lhs.approachValue == rhs.approachValue &&
        lhs.lowerBound == rhs.lowerBound &&
        lhs.upperBound == rhs.upperBound &&
        lhs.isDefinite == rhs.isDefinite &&
        lhs.steps == rhs.steps
    }
}
