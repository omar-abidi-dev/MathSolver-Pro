import Foundation

// MARK: - Token Types

/// Tokens produced by the tokenizer
enum Token: Equatable {
    case number(Double)
    case variable(String)
    case leftParen
    case rightParen
    case plus
    case minus
    case multiply
    case divide
    case power
    case equals
    case comma
    case eof
}

// MARK: - Tokenizer

/// Tokenizes equation input string into a sequence of tokens
/// Handles implicit multiplication (e.g., "2x" → number*variable)
class Tokenizer {
    private let input: String
    private var position: String.Index
    
    init(_ input: String) {
        self.input = input.trimmingCharacters(in: .whitespaces)
        self.position = self.input.startIndex
    }
    
    /// Get current character without advancing
    private var currentChar: Character? {
        guard position < input.endIndex else { return nil }
        return input[position]
    }
    
    /// Peek ahead n characters
    private func peekChar(offset: Int = 1) -> Character? {
        let targetIndex = input.index(position, offsetBy: offset, limitedBy: input.endIndex)
        guard let idx = targetIndex, idx < input.endIndex else { return nil }
        return input[idx]
    }
    
    /// Advance to next character
    private func advance() {
        if position < input.endIndex {
            position = input.index(after: position)
        }
    }
    
    /// Skip whitespace
    private func skipWhitespace() {
        while let char = currentChar, char.isWhitespace {
            advance()
        }
    }
    
    /// Parse a number (integer or decimal)
    private func readNumber() -> Double? {
        var numStr = ""
        
        while let char = currentChar, char.isNumber {
            numStr.append(char)
            advance()
        }
        
        // Handle decimal point
        if currentChar == "." {
            numStr.append(".")
            advance()
            
            while let char = currentChar, char.isNumber {
                numStr.append(char)
                advance()
            }
        }
        
        return Double(numStr)
    }
    
    /// Parse a variable/function name (single or multi-character lowercase identifier)
    private func readVariable() -> String? {
        guard let char = currentChar, char.isLowercase else { return nil }
        var identifier = ""
        
        while let char = currentChar, char.isLowercase {
            identifier.append(char)
            advance()
        }
        
        return identifier.isEmpty ? nil : identifier
    }
    
    /// Get next token
    func nextToken() -> Token {
        skipWhitespace()
        
        guard let char = currentChar else {
            return .eof
        }
        
        // Numbers
        if char.isNumber {
            if let num = readNumber() {
                return .number(num)
            }
        }
        
        // Variables (single lowercase letters)
        if char.isLowercase {
            if let variable = readVariable() {
                return .variable(variable)
            }
        }
        
        // Operators and delimiters
        switch char {
        case "(":
            advance()
            return .leftParen
        case ")":
            advance()
            return .rightParen
        case "+":
            advance()
            return .plus
        case "-":
            advance()
            return .minus
        case "*", "×":
            advance()
            return .multiply
        case "/", "÷":
            advance()
            return .divide
        case "^":
            advance()
            return .power
        case "=":
            advance()
            return .equals
        case ",":
            advance()
            return .comma
        default:
            advance()
            return nextToken() // Skip unknown character
        }
    }
    
    /// Tokenize entire input into array of tokens
    func tokenize() -> [Token] {
        var tokens: [Token] = []
        var token = nextToken()
        
        while token != .eof {
            tokens.append(token)
            token = nextToken()
        }
        
        tokens.append(.eof)
        return tokens
    }
}

// MARK: - Recursive Descent Parser

/// Recursive-descent parser for mathematical equations
/// Respects operator precedence: power > multiply/divide > add/subtract
class EquationParser {
    private var tokens: [Token]
    private var position: Int = 0
    
    init(tokens: [Token]) {
        self.tokens = tokens
    }
    
    /// Get current token
    private var currentToken: Token {
        guard position < tokens.count else { return .eof }
        return tokens[position]
    }
    
    /// Advance to next token
    private func advance() {
        if position < tokens.count {
            position += 1
        }
    }
    
    /// Check if current token matches and consume it
    private func match(_ expected: Token) -> Bool {
        if currentToken == expected {
            advance()
            return true
        }
        return false
    }
    
    // MARK: Parsing Methods (Recursive Descent)
    
    /// Parse a complete equation (expression = expression)
    func parseEquation() -> Result<Equation, ParseError> {
        do {
            // Parse left side
            let left = try parseExpression()
            
            // Expect equals sign
            guard match(.equals) else {
                return .failure(.noEqualsSign)
            }
            
            // Parse right side
            let right = try parseExpression()
            
            // Detect equation type
            let equationType = detectEquationType(left: left, right: right)
            
            let equation = Equation(
                rawInput: tokensToString(),
                equationType: equationType,
                leftExpression: left,
                rightExpression: right
            )
            
            return .success(equation)
        } catch let error as ParseError {
            return .failure(error)
        } catch {
            return .failure(.unexpectedEndOfInput)
        }
    }
    
    /// Public entry point for parsing a standalone expression (no '=' required)
    func parseExpressionPublic() -> Expression? {
        do {
            let result = try parseExpression()
            return result
        } catch {
            return nil
        }
    }
    
    /// Parse additive expression (+ and - operations, lowest precedence)
    private func parseExpression() throws -> Expression {
        var result = try parseTerm()
        
        while currentToken == .plus || currentToken == .minus {
            let op = currentToken == .plus ? Operator.add : Operator.subtract
            advance()
            let right = try parseTerm()
            result = .binaryOp(op, result, right)
        }
        
        return result
    }
    
    /// Parse multiplicative expression (* and / operations)
    private func parseTerm() throws -> Expression {
        var result = try parseFactor()
        
        while currentToken == .multiply || currentToken == .divide {
            let op = currentToken == .multiply ? Operator.multiply : Operator.divide
            advance()
            let right = try parseFactor()
            result = .binaryOp(op, result, right)
        }
        
        return result
    }
    
    /// Parse power expression (highest precedence binary operation)
    private func parseFactor() throws -> Expression {
        var result = try parseUnary()
        
        // Right-associative: 2^3^2 = 2^(3^2)
        if currentToken == .power {
            advance()
            let right = try parseFactor()
            result = .binaryOp(.power, result, right)
        }
        
        return result
    }
    
    /// Parse unary expression (unary minus, implicit multiplication)
    private func parseUnary() throws -> Expression {
        // Handle unary minus
        if match(.minus) {
            let operand = try parseUnary()
            return .unaryOp(.negate, operand)
        }
        
        return try parsePrimary()
    }
    
    /// Parse primary expression (number, variable, parenthesized expression)
    /// Also handles implicit multiplication (e.g., 2x, (x+1)x)
    private func parsePrimary() throws -> Expression {
        var result = try parseAtom()
        
        // Handle implicit multiplication (number followed by variable or parenthesis)
        // Example: "2x" → number 2 followed by variable x
        while true {
            if case .variable = currentToken {
                result = .binaryOp(.multiply, result, try parseAtom())
            } else if currentToken == .leftParen {
                result = .binaryOp(.multiply, result, try parseAtom())
            } else {
                break
            }
        }
        
        return result
    }
    
    /// Parse atomic expression (number, variable, or parenthesized expression)
    private func parseAtom() throws -> Expression {
        switch currentToken {
        case .number(let value):
            advance()
            return .constant(value)
            
        case .variable(let name):
            // Check if this is a function name
            if isKnownFunction(name) {
                advance()
                // Expect left parenthesis for function
                guard match(.leftParen) else {
                    // If no paren, treat as variable
                    return .variable(name)
                }
                // Parse the function argument
                let innerExpr = try parseExpression()
                guard match(.rightParen) else {
                    throw ParseError.unmatchedParenthesis
                }
                return .function(name, innerExpr)
            } else {
                // Regular variable
                advance()
                return .variable(name)
            }
            
        case .leftParen:
            advance()
            let expr = try parseExpression()
            guard match(.rightParen) else {
                throw ParseError.unmatchedParenthesis
            }
            return expr
            
        case .eof:
            throw ParseError.unexpectedEndOfInput
            
        default:
            throw ParseError.invalidToken(position: position, character: Character("?"))
        }
    }
    
    /// Check if a name is a known function
    private func isKnownFunction(_ name: String) -> Bool {
        let knownFunctions = ["sin", "cos", "tan", "ln", "log", "exp", "sqrt", "abs"]
        return knownFunctions.contains(name)
    }
    
    // MARK: - Utilities
    
    /// Detect equation type based on parsed expressions
    private func detectEquationType(left: Expression, right: Expression) -> EquationType {
        // Check if either side contains a squared term (x^2)
        if containsSquaredTerm(left) || containsSquaredTerm(right) {
            return .quadratic
        }
        
        // Default to linear (system detection happens at a higher level)
        return .linear
    }
    
    /// Check if expression contains a power of 2 (e.g., x^2)
    private func containsSquaredTerm(_ expr: Expression) -> Bool {
        switch expr {
        case .constant, .variable:
            return false
        case .binaryOp(let op, let left, let right):
            if op == .power {
                // Check if right side is 2
                if case .constant(let val) = right, val == 2 {
                    return true
                }
            }
            return containsSquaredTerm(left) || containsSquaredTerm(right)
        case .unaryOp(_, let operand):
            return containsSquaredTerm(operand)
        case .function(_, let inner):
            return containsSquaredTerm(inner)
        }
    }
    
    /// Convert tokens back to string for raw input display
    private func tokensToString() -> String {
        return tokens
            .filter { $0 != .eof }
            .map { token -> String in
                switch token {
                case .number(let val):
                    if val == floor(val) {
                        return String(Int(val))
                    }
                    return String(format: "%.10g", val)
                case .variable(let name):
                    return name
                case .leftParen:
                    return "("
                case .rightParen:
                    return ")"
                case .plus:
                    return "+"
                case .minus:
                    return "-"
                case .multiply:
                    return "*"
                case .divide:
                    return "/"
                case .power:
                    return "^"
                case .equals:
                    return "="
                case .comma:
                    return ","
                case .eof:
                    return ""
                }
            }
            .joined(separator: " ")
    }
}

// MARK: - Public Parse Functions

/// Parse an equation string into an Equation object or system of equations
/// Detects system equations separated by comma or newline
/// - Parameter input: Raw equation string (e.g., "2x + 5 = 15" or "x + y = 10, x - y = 2")
/// - Returns: Result containing Equation array (1 or 2 equations) or ParseError
func parseEquation(_ input: String) -> Result<Equation, ParseError> {
    guard !input.trimmingCharacters(in: .whitespaces).isEmpty else {
        return .failure(.emptyInput)
    }
    
    // Check if this is a system of equations (has comma or multiple equals signs)
    let lines = input.split(separator: ",").map(String.init)
    if lines.count >= 2 {
        // Parse as system of equations
        var equations: [Equation] = []
        for line in lines.prefix(2) {  // Only take first 2 equations
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            let tokenizer = Tokenizer(trimmed)
            let tokens = tokenizer.tokenize()
            
            guard tokens.contains(where: { $0 == .equals }) else {
                return .failure(.noEqualsSign)
            }
            
            let parser = EquationParser(tokens: tokens)
            switch parser.parseEquation() {
            case .success(var equation):
                equation.equationType = .system
                equations.append(equation)
            case .failure(let error):
                return .failure(error)
            }
        }
        
        if equations.count == 2 {
            return .success(equations[0])  // Return first equation marked as system
        }
    }
    
    let tokenizer = Tokenizer(input)
    let tokens = tokenizer.tokenize()
    
    // Check for equals sign
    let hasEquals = tokens.contains { $0 == .equals }
    guard hasEquals else {
        return .failure(.noEqualsSign)
    }
    
    // Count equals signs (should be exactly 1 for simple equations)
    let equalsCount = tokens.filter { $0 == .equals }.count
    guard equalsCount <= 2 else {
        return .failure(.multipleEqualsSign)
    }
    
    let parser = EquationParser(tokens: tokens)
    return parser.parseEquation()
}

/// Parse a standalone mathematical expression (no '=' required)
/// Use this for calculus inputs like derivatives, integrals, and limits
/// - Parameter input: Raw expression string (e.g., "3x^2 + 5x", "ln(x)", "sin(x)/x")
/// - Returns: Parsed Expression tree, or nil if parsing fails
func parseExpressionString(_ input: String) -> Expression? {
    let trimmed = input.trimmingCharacters(in: .whitespaces)
    guard !trimmed.isEmpty else { return nil }
    
    let tokenizer = Tokenizer(trimmed)
    let tokens = tokenizer.tokenize()
    
    guard tokens.count > 1 else { return nil } // At least one token + eof
    
    let parser = EquationParser(tokens: tokens)
    return parser.parseExpressionPublic()
}
