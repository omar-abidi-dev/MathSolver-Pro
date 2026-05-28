import Foundation
import JavaScriptCore

/// Converts JSValue results from math.js into Swift native types
/// Handles parsing of solutions, steps, and numeric results from JavaScript context
struct MathJSResultParser {
    
    /// Parse a JavaScript value into a MathJSSolution
    static func parseSolution(from jsResult: JSValue) -> MathJSSolution? {
        guard !jsResult.isUndefined else { return nil }
        
        // Extract solutions array
        guard let solutionsJS = jsResult.objectForKeyedSubscript("solutions") else {
            return nil
        }
        
        let solutions = parseStringArray(solutionsJS)
        guard !solutions.isEmpty else { return nil }
        
        // Extract numeric values (optional)
        var numericValues: [Double]? = nil
        if let numericValuesJS = jsResult.objectForKeyedSubscript("numericValues"),
           !numericValuesJS.isNull,
           !numericValuesJS.isUndefined {
            numericValues = parseDoubleArray(numericValuesJS)
        }
        
        // Extract steps
        let steps = parseStepsArray(jsResult.objectForKeyedSubscript("steps")) ?? [MathJSStep]()
        
        // Extract expression type
        let expressionType = jsResult.objectForKeyedSubscript("expressionType")?.toString() ?? "equation"
        
        return MathJSSolution(
            solutions: solutions,
            numericValues: numericValues,
            steps: steps,
            expressionType: expressionType
        )
    }
    
    /// Parse a JavaScript value into a Double
    static func parseDouble(from jsValue: JSValue) -> Double? {
        if jsValue.isNumber {
            return jsValue.toNumber()?.doubleValue
        }
        return nil
    }
    
    /// Parse a JavaScript value into a String
    static func parseString(from jsValue: JSValue) -> String? {
        if jsValue.isString {
            return jsValue.toString()
        }
        return nil
    }
    
    /// Parse a JavaScript array into a [String]
    static func parseStringArray(_ jsArray: JSValue) -> [String] {
        guard let array = jsArray.toArray() else { return [] }
        
        return array.compactMap { item in
            if let str = item as? String {
                return str
            } else if let jsVal = item as? JSValue {
                return jsVal.toString()
            }
            return nil
        }
    }
    
    /// Parse a JavaScript array into a [Double]
    static func parseDoubleArray(_ jsArray: JSValue) -> [Double] {
        guard let array = jsArray.toArray() else { return [] }
        
        return array.compactMap { item in
            if let num = item as? NSNumber {
                return num.doubleValue
            } else if let jsVal = item as? JSValue, jsVal.isNumber {
                return jsVal.toNumber()?.doubleValue
            }
            return nil
        }
    }
    
    /// Parse a JavaScript array of step objects into [MathJSStep]
    static func parseStepsArray(_ jsArray: JSValue?) -> [MathJSStep]? {
        guard let jsArray = jsArray, let array = jsArray.toArray() else { return nil }
        
        var steps: [MathJSStep] = []
        
        for item in array {
            if let jsVal = item as? JSValue {
                if let step = parseStep(jsVal) {
                    steps.append(step)
                }
            }
        }
        
        return steps.isEmpty ? nil : steps
    }
    
    /// Parse a single JavaScript step object into a MathJSStep
    static func parseStep(_ jsObject: JSValue) -> MathJSStep? {
        guard let stepNumber = jsObject.objectForKeyedSubscript("stepNumber")?.toNumber() as? NSNumber else {
            return nil
        }
        
        let operation = jsObject.objectForKeyedSubscript("operation")?.toString() ?? ""
        let inputExpr = jsObject.objectForKeyedSubscript("inputExpression")?.toString() ?? ""
        let outputExpr = jsObject.objectForKeyedSubscript("outputExpression")?.toString() ?? ""
        
        var rule: String? = nil
        if let ruleJS = jsObject.objectForKeyedSubscript("rule"),
           !ruleJS.isNull,
           !ruleJS.isUndefined {
            rule = ruleJS.toString()
        }
        
        return MathJSStep(
            stepNumber: stepNumber.intValue,
            operation: operation,
            inputExpression: inputExpr,
            outputExpression: outputExpr,
            rule: rule
        )
    }
    
    /// Check if a JSValue represents an error
    static func isError(_ jsValue: JSValue) -> Bool {
        return jsValue.objectForKeyedSubscript("error") != nil ||
               jsValue.objectForKeyedSubscript("isError")?.toBool() ?? false
    }
    
    /// Safe get property from JSValue with type checking
    static func getProperty<T>(_ jsObject: JSValue, _ key: String, as type: T.Type) -> T? {
        guard let prop = jsObject.objectForKeyedSubscript(key) else { return nil }
        
        if type == String.self {
            return prop.toString() as? T
        } else if type == Double.self {
            return prop.toNumber()?.doubleValue as? T
        } else if type == Int.self {
            return (prop.toNumber()?.intValue as NSNumber?) as? T
        } else if type == Bool.self {
            return prop.toBool() as? T
        }
        
        return nil
    }
}

// MARK: - Math.js Expression Parser

/// Helper to parse mathematical expressions and check their validity
struct MathExpressionParser {
    
    /// Validate that an expression string contains valid math syntax
    static func isValidExpression(_ expression: String) -> Bool {
        let trimmed = expression.trimmingCharacters(in: .whitespaces)
        
        guard !trimmed.isEmpty else { return false }
        
        // Basic validation: check for balanced parentheses
        return hasBalancedParentheses(trimmed)
    }
    
    /// Check if an expression has balanced parentheses and brackets
    static func hasBalancedParentheses(_ expression: String) -> Bool {
        var parenCount = 0
        var bracketCount = 0
        var braceCount = 0
        
        for char in expression {
            switch char {
            case "(": parenCount += 1
            case ")": 
                parenCount -= 1
                if parenCount < 0 { return false }
            case "[": bracketCount += 1
            case "]":
                bracketCount -= 1
                if bracketCount < 0 { return false }
            case "{": braceCount += 1
            case "}":
                braceCount -= 1
                if braceCount < 0 { return false }
            default:
                break
            }
        }
        
        return parenCount == 0 && bracketCount == 0 && braceCount == 0
    }
    
    /// Normalize mathematical notation for math.js compatibility
    /// Converts common notation variations to math.js syntax
    static func normalize(_ expression: String) -> String {
        var normalized = expression
        
        // Replace × with * (multiplication)
        normalized = normalized.replacingOccurrences(of: "×", with: "*")
        
        // Replace ÷ with / (division)
        normalized = normalized.replacingOccurrences(of: "÷", with: "/")
        
        // Replace ^ with ** for exponentiation (optional, math.js accepts both)
        // normalized = normalized.replacingOccurrences(of: "^", with: "**")
        
        // Replace π with pi
        normalized = normalized.replacingOccurrences(of: "π", with: "pi")
        
        // Replace √ with sqrt()
        normalized = normalized.replacingOccurrences(of: "√", with: "sqrt")
        
        // Normalize equals sign (math.js expects =)
        normalized = normalized.replacingOccurrences(of: "==", with: "=")
        normalized = normalized.replacingOccurrences(of: "≠", with: "!=")
        
        // Remove extra spaces
        normalized = normalized.replacingOccurrences(of: #"\s+"#, with: "", options: .regularExpression)
        
        return normalized
    }
    
    /// Extract the variable from an equation
    /// Looks for common variable names like x, y, z, a, b, c, etc.
    static func detectVariable(in equation: String) -> String? {
        let commonVariables = ["x", "y", "z", "a", "b", "c", "t", "n"]
        let lowerEquation = equation.lowercased()
        
        for variable in commonVariables {
            if lowerEquation.contains(variable) {
                return variable
            }
        }
        
        return nil
    }
}
