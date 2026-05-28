import Foundation

/// Detects and analyzes equation types
struct EquationTypeDetector {
    private let equation: String
    
    init(_ equation: String) {
        self.equation = equation.trimmingCharacters(in: .whitespaces)
    }
    
    /// Detects the type of equation
    func detectType() -> EquationType {
        // Check for system of equations (comma-separated)
        if equation.contains(",") {
            return .system
        }
        
        // Check for derivative or integral indicators (highest priority for symbolic equations)
        if isDerivative() {
            return .derivative
        }
        
        if isIntegral() {
            return .integral
        }
        
        // Check for trigonometric functions
        if isTrigonometric() {
            return .trigonometric
        }
        
        // Check for logarithmic functions
        if isLogarithmic() {
            return .logarithmic
        }
        
        // Check for polynomial (exponents > 2)
        if isPolynomial() {
            return .polynomial
        }
        
        // Check for quadratic (contains ^2, x^2, or similar patterns)
        if isQuadratic() {
            return .quadratic
        }
        
        // Default to linear
        return .linear
    }
    
    /// Checks if equation is quadratic
    private func isQuadratic() -> Bool {
        // Check for explicit ^2
        if equation.contains("^2") {
            return true
        }
        
        // Check for ² unicode
        if equation.contains("²") {
            return true
        }
        
        // Check for x² pattern
        if equation.range(of: "[a-zA-Z]\\s*²", options: .regularExpression) != nil {
            return true
        }
        
        // Check for x^2 pattern
        if equation.range(of: "[a-zA-Z]\\s*\\^\\s*2", options: .regularExpression) != nil {
            return true
        }
        
        return false
    }
    
    /// Checks if equation is polynomial (exponents > 2)
    private func isPolynomial() -> Bool {
        // Check for ^3, ^4, ^5, etc. (but not ^2)
        if equation.range(of: "\\^\\s*[3-9]", options: .regularExpression) != nil {
            return true
        }
        
        // Check for unicode superscripts (³, ⁴, etc.)
        if equation.range(of: "[³⁴⁵⁶⁷⁸⁹]", options: .regularExpression) != nil {
            return true
        }
        
        // Check for fractional exponents x^(1/2), x^(2/3), etc.
        if equation.range(of: "\\^\\s*\\([0-9]/[0-9]\\)", options: .regularExpression) != nil {
            return true
        }
        
        return false
    }
    
    /// Checks if equation is trigonometric
    private func isTrigonometric() -> Bool {
        let trigPatterns = [
            "sin", "cos", "tan",
            "csc", "sec", "cot",
            "sinh", "cosh", "tanh",
            "arcsin", "arccos", "arctan",
            "asin", "acos", "atan"
        ]
        
        let lowerEquation = equation.lowercased()
        for pattern in trigPatterns {
            if lowerEquation.contains(pattern) {
                return true
            }
        }
        
        return false
    }
    
    /// Checks if equation is logarithmic
    private func isLogarithmic() -> Bool {
        let logPatterns = ["log", "ln"]
        let lowerEquation = equation.lowercased()
        
        for pattern in logPatterns {
            if lowerEquation.contains(pattern) {
                return true
            }
        }
        
        return false
    }
    
    /// Checks if equation is a derivative
    private func isDerivative() -> Bool {
        let derivativePatterns = [
            "d/dx",
            "dy/dx",
            "d'",
            "f'",
            "'(x)",
            "derivative",
            "diff"
        ]
        
        let lowerEquation = equation.lowercased()
        for pattern in derivativePatterns {
            if lowerEquation.contains(pattern) {
                return true
            }
        }
        
        // Also check for prime notation like f'(x), f''(x)
        if equation.range(of: "[a-zA-Z]'\\(", options: .regularExpression) != nil {
            return true
        }
        
        return false
    }
    
    /// Checks if equation is an integral
    private func isIntegral() -> Bool {
        let integralPatterns = [
            "∫",
            "integral",
            "∫",
            "integrate"
        ]
        
        let lowerEquation = equation.lowercased()
        for pattern in integralPatterns {
            if lowerEquation.contains(pattern) {
                return true
            }
        }
        
        // Check for integral symbol or ∫ notation
        if equation.contains("∫") {
            return true
        }
        
        return false
    }
    
    /// Validates equation syntax
    func validate() -> EquationError? {
        if equation.isEmpty {
            return .emptyEquation
        }
        
        // Check for balanced parentheses
        if !hasBalancedParentheses() {
            return .unbalancedParentheses
        }
        
        // Check for equal sign
        if !equation.contains("=") {
            return .missingEqualSign
        }
        
        // Check for valid characters
        if !hasValidCharacters() {
            return .invalidCharacters
        }
        
        return nil
    }
    
    private func hasBalancedParentheses() -> Bool {
        var count = 0
        for char in equation {
            if char == "(" { count += 1 }
            else if char == ")" { count -= 1 }
            if count < 0 { return false }
        }
        return count == 0
    }
    
    private func hasValidCharacters() -> Bool {
        let validChars = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.+-*/^()= ,²³⁴⁵⁶⁷⁸⁹∫π√'")
        let equationChars = CharacterSet(charactersIn: equation)
        return equationChars.isSubset(of: validChars)
    }
    
    /// Extracts individual equations from system
    func extractEquations() -> [String] {
        return equation.split(separator: ",")
            .map { String($0).trimmingCharacters(in: .whitespaces) }
    }
}

// MARK: - Equation Error

enum EquationError: LocalizedError {
    case emptyEquation
    case unbalancedParentheses
    case missingEqualSign
    case invalidCharacters
    case invalidSyntax
    
    var errorDescription: String? {
        switch self {
        case .emptyEquation:
            return "Please enter an equation"
        case .unbalancedParentheses:
            return "Parentheses are not balanced"
        case .missingEqualSign:
            return "Equation must contain an '=' sign"
        case .invalidCharacters:
            return "Equation contains invalid characters"
        case .invalidSyntax:
            return "Equation syntax is invalid"
        }
    }
}

