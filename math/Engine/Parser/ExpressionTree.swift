import Foundation

/// Algebraic expression tree node types using indirect recursion
/// Represents parsed mathematical expressions in abstract syntax tree form
indirect enum Expression: Equatable {
    /// Constant numeric value (e.g., 5.0)
    case constant(Double)
    
    /// Variable reference (e.g., "x", "y")
    case variable(String)
    
    /// Binary operation node (e.g., 2 * x, x + 5)
    case binaryOp(Operator, Expression, Expression)
    
    /// Unary operation node (e.g., -x)
    case unaryOp(UnaryOperator, Expression)
    
    /// Function node (e.g., sin(x), ln(x))
    case function(String, Expression)
    
    /// Evaluate expression at a given variable assignment
    /// Returns the numeric result or nil if evaluation fails (e.g., division by zero)
    func evaluate(variables: [String: Double]) -> Double? {
        switch self {
        case .constant(let value):
            return value
            
        case .variable(let name):
            return variables[name]
            
        case .binaryOp(let op, let left, let right):
            guard let leftVal = left.evaluate(variables: variables),
                  let rightVal = right.evaluate(variables: variables) else {
                return nil
            }
            
            switch op {
            case .add:
                return leftVal + rightVal
            case .subtract:
                return leftVal - rightVal
            case .multiply:
                return leftVal * rightVal
            case .divide:
                guard rightVal != 0 else { return nil }
                return leftVal / rightVal
            case .power:
                return pow(leftVal, rightVal)
            }
            
        case .unaryOp(let op, let operand):
            guard let val = operand.evaluate(variables: variables) else {
                return nil
            }
            
            switch op {
            case .negate:
                return -val
            }
        
        case .function(let name, let inner):
            guard let innerVal = inner.evaluate(variables: variables) else {
                return nil
            }
            
            switch name {
            case "sin":
                return sin(innerVal)
            case "cos":
                return cos(innerVal)
            case "tan":
                return tan(innerVal)
            case "ln":
                guard innerVal > 0 else { return nil }
                return log(innerVal)
            case "log":
                guard innerVal > 0 else { return nil }
                return log10(innerVal)
            case "exp":
                return exp(innerVal)
            case "sqrt":
                guard innerVal >= 0 else { return nil }
                return sqrt(innerVal)
            case "abs":
                return abs(innerVal)
            default:
                return nil
            }
        }
    }
    
    /// Convert expression to human-readable string representation
    func description() -> String {
        switch self {
        case .constant(let value):
            if value == floor(value) {
                return String(Int(value))
            }
            return String(format: "%.10g", value)
            
        case .variable(let name):
            return name
            
        case .binaryOp(let op, let left, let right):
            let leftStr = left.description()
            let rightStr = right.description()
            let opStr = op.rawValue
            return "(\(leftStr) \(opStr) \(rightStr))"
            
        case .unaryOp(let op, let operand):
            let operandStr = operand.description()
            switch op {
            case .negate:
                return "-\(operandStr)"
            }
        
        case .function(let name, let inner):
            let innerStr = inner.description()
            return "\(name)(\(innerStr))"
        }
    }
    
    /// Simplify expression by applying algebraic simplification rules (bottom-up)
    /// Returns a simplified Expression that is mathematically equivalent
    func simplify() -> Expression {
        // First, simplify children
        let simplifiedSelf: Expression
        
        switch self {
        case .constant, .variable:
            simplifiedSelf = self
            
        case .binaryOp(let op, let left, let right):
            let simLeft = left.simplify()
            let simRight = right.simplify()
            simplifiedSelf = .binaryOp(op, simLeft, simRight)
            
        case .unaryOp(let op, let operand):
            let simOperand = operand.simplify()
            simplifiedSelf = .unaryOp(op, simOperand)
            
        case .function(let name, let inner):
            let simInner = inner.simplify()
            simplifiedSelf = .function(name, simInner)
        }
        
        // Apply simplification rules to parent
        switch simplifiedSelf {
        case .binaryOp(let op, let left, let right):
            // 0 + x = x
            if case .constant(let val) = left, val == 0, op == .add {
                return right
            }
            // x + 0 = x
            if case .constant(let val) = right, val == 0, op == .add {
                return left
            }
            // 0 * x = 0
            if case .constant(let val) = left, val == 0, op == .multiply {
                return .constant(0)
            }
            // x * 0 = 0
            if case .constant(let val) = right, val == 0, op == .multiply {
                return .constant(0)
            }
            // 1 * x = x
            if case .constant(let val) = left, val == 1, op == .multiply {
                return right
            }
            // x * 1 = x
            if case .constant(let val) = right, val == 1, op == .multiply {
                return left
            }
            // x - 0 = x
            if case .constant(let val) = right, val == 0, op == .subtract {
                return left
            }
            // x / 1 = x
            if case .constant(let val) = right, val == 1, op == .divide {
                return left
            }
            // x ^ 0 = 1
            if case .constant(let val) = right, val == 0, op == .power {
                return .constant(1)
            }
            // x ^ 1 = x
            if case .constant(let val) = right, val == 1, op == .power {
                return left
            }
            // constant op constant = fold to single constant
            if case .constant(let lVal) = left, case .constant(let rVal) = right {
                if let result = evaluateConstantOp(op, lVal, rVal) {
                    return .constant(result)
                }
            }
            // -(-x) = x
            if op == .multiply,
               case .constant(let val) = left, val == -1,
               case .unaryOp(let uOp, let operand) = right,
               case .negate = uOp {
                return operand
            }
            
            return simplifiedSelf
            
        case .unaryOp(let op, let operand):
            // -(-x) = x
            if case .negate = op, case .unaryOp(let innerOp, let innerOperand) = operand, case .negate = innerOp {
                return innerOperand
            }
            return simplifiedSelf
            
        default:
            return simplifiedSelf
        }
    }
    
    /// Helper function to evaluate constant binary operations
    private func evaluateConstantOp(_ op: Operator, _ left: Double, _ right: Double) -> Double? {
        switch op {
        case .add:
            return left + right
        case .subtract:
            return left - right
        case .multiply:
            return left * right
        case .divide:
            guard right != 0 else { return nil }
            return left / right
        case .power:
            return pow(left, right)
        }
    }
}

/// Represents a complete mathematical equation (LHS = RHS)
struct Equation {
    /// Unique identifier for this equation
    let id: UUID
    
    /// The original user-entered text (e.g., "2x + 5 = 15")
    let rawInput: String
    
    /// Detected equation type (linear, quadratic, or system)
    var equationType: EquationType
    
    /// Parsed abstract syntax tree for the left-hand side of the equation
    let leftExpression: Expression
    
    /// Parsed abstract syntax tree for the right-hand side of the equation
    let rightExpression: Expression
    
    /// Variable → value mapping of all solutions found
    /// For example: ["x": 5.0] for "2x + 5 = 15"
    var solutions: [String: Double] = [:]
    
    /// Step-by-step solution process, populated by solvers
    var solutionSteps: [SolutionStep] = []
    
    /// Timestamp when this equation was created
    let createdAt: Date
    
    /// Designated initializer
    /// - Parameters:
    ///   - rawInput: The original equation string from user
    ///   - equationType: Detected type of equation
    ///   - leftExpression: Parsed left side of the equation
    ///   - rightExpression: Parsed right side of the equation
    init(
        rawInput: String,
        equationType: EquationType,
        leftExpression: Expression,
        rightExpression: Expression
    ) {
        self.id = UUID()
        self.rawInput = rawInput
        self.equationType = equationType
        self.leftExpression = leftExpression
        self.rightExpression = rightExpression
        self.createdAt = Date()
    }
    
    /// Check if this equation is solved (has solutions populated)
    var isSolved: Bool {
        !solutions.isEmpty || equationType == .system
    }
}
