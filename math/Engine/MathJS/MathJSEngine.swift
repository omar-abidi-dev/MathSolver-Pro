import Foundation
import JavaScriptCore

// MARK: - MathEngineError

enum MathEngineError: LocalizedError {
    case initializationFailed(String)
    case parseError(String)
    case unsolvable(String)
    case evaluationError(String)
    case timeout
    
    var errorDescription: String? {
        switch self {
        case .initializationFailed(let message):
            return "Failed to initialize math engine: \(message)"
        case .parseError(let message):
            return "Invalid equation syntax: \(message)"
        case .unsolvable(let message):
            return "Cannot solve this equation: \(message)"
        case .evaluationError(let message):
            return "Evaluation error: \(message)"
        case .timeout:
            return "Calculation took too long"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .initializationFailed:
            return "Please restart the app"
        case .parseError:
            return "Check your equation syntax and try again"
        case .unsolvable:
            return "This type of equation cannot be solved analytically"
        case .evaluationError:
            return "There was an error calculating the result"
        case .timeout:
            return "The calculation exceeded the time limit, try a simpler equation"
        }
    }
}

// MARK: - MathJSEngine

/// Singleton wrapper around JavaScriptCore for math.js library
/// Provides methods for solving equations, evaluating expressions, and generating solution steps
actor MathJSEngine {
    static let shared = MathJSEngine()
    
    private var jsContext: JSContext?
    private let executionQueue = DispatchQueue(label: "com.mathsolver.mathjs.execution", qos: .userInitiated)
    private var isInitialized = false
    private let initializationLock = NSLock()
    
    private init() {}
    
    /// Initialize the JavaScript context and load math.js library
    /// Must be called once at app launch before any other methods
    func initialize() throws {
        initializationLock.lock()
        defer { initializationLock.unlock() }
        
        guard !isInitialized else { return }
        
        jsContext = JSContext()
        
        guard let context = jsContext else {
            throw MathEngineError.initializationFailed("Failed to create JavaScript context")
        }
        
        // Disable Web APIs that don't make sense in this context
        context.evaluateScript("var navigator = undefined;")
        
        // Load math.js library from bundle
        guard let mathJSPath = Bundle.main.path(forResource: "math.min", ofType: "js") else {
            throw MathEngineError.initializationFailed("math.min.js not found in app bundle")
        }
        
        do {
            let mathJSCode = try String(contentsOfFile: mathJSPath, encoding: .utf8)
            context.evaluateScript(mathJSCode)
            
            // Verify math object is available
            if context.objectForKeyedSubscript("math") == nil {
                throw MathEngineError.initializationFailed("math.js library failed to load")
            }
            
            isInitialized = true
        } catch {
            throw MathEngineError.initializationFailed("Failed to load math.js: \(error.localizedDescription)")
        }
    }
    
    /// Check if engine is initialized
    var initialized: Bool {
        isInitialized
    }
    
    // MARK: - Solution Methods
    
    /// Solve an equation for a given variable
    /// Example: solve(equation: "2*x + 3 = 7", variable: "x")
    func solve(equation: String, variable: String = "x") -> Result<MathJSSolution, MathEngineError> {
        guard isInitialized, let context = jsContext else {
            return .failure(.initializationFailed("Engine not initialized"))
        }
        
        let result = executeWithTimeout {
            // Prepare the equation string for math.js
            let cleanEquation = equation.trimmingCharacters(in: .whitespaces)
            
            // Create a JavaScript function to solve the equation
            let jsCode = """
            (function() {
                try {
                    var expr = '\(cleanEquation)';
                    var variable = '\(variable)';
                    
                    // Parse and solve
                    var solutions = math.solve(expr, variable);
                    
                    // Convert solutions to array if single value
                    var solArray = Array.isArray(solutions) ? solutions : [solutions];
                    
                    // Format solutions as strings
                    var formattedSolutions = solArray.map(function(sol) {
                        return variable + ' = ' + math.format(sol);
                    });
                    
                    // Extract numeric values if possible
                    var numericValues = solArray.map(function(sol) {
                        var num = parseFloat(sol.toString());
                        return isNaN(num) ? null : num;
                    }).filter(function(n) { return n !== null; });
                    
                    return {
                        solutions: formattedSolutions,
                        numericValues: numericValues.length > 0 ? numericValues : null,
                        expressionType: 'equation'
                    };
                } catch(err) {
                    return { error: err.toString() };
                }
            })()
            """
            
            guard let jsResult = context.evaluateScript(jsCode) else {
                return Result<MathJSSolution, MathEngineError>.failure(.evaluationError("Failed to execute solve"))
            }
            
            // Check for JavaScript errors
            if let errorMessage = jsResult.objectForKeyedSubscript("error")?.toString() {
                return Result<MathJSSolution, MathEngineError>.failure(.unsolvable(errorMessage))
            }
            
            // Parse the result
            guard
                let solutionsJS = jsResult.objectForKeyedSubscript("solutions"),
                let solutions = solutionsJS.toArray() as? [String],
                !solutions.isEmpty
            else {
                return Result<MathJSSolution, MathEngineError>.failure(.unsolvable("No solutions found for this equation"))
            }
            
            var numericValues: [Double]? = nil
            if let numericValuesJS = jsResult.objectForKeyedSubscript("numericValues"),
               let numericArray = numericValuesJS.toArray() as? [Double],
               !numericArray.isEmpty {
                numericValues = numericArray
            }
            
            // Generate steps (simplified: just basic steps for now)
            let steps = self.generateBasicSteps(equation: equation, solutions: solutions)
            
            let solution = MathJSSolution(
                solutions: solutions,
                numericValues: numericValues,
                steps: steps,
                expressionType: "equation"
            )
            
            return Result<MathJSSolution, MathEngineError>.success(solution)
        }
        
        return result ?? .failure(.timeout)
    }
    
    /// Evaluate a numeric expression
    /// Example: evaluate(expression: "sin(3.14159/6)") returns 0.5
    func evaluate(expression: String) -> Result<Double, MathEngineError> {
        guard isInitialized, let context = jsContext else {
            return .failure(.initializationFailed("Engine not initialized"))
        }
        
        let result = executeWithTimeout {
            let cleanExpression = expression.trimmingCharacters(in: .whitespaces)
            
            let jsCode = """
            (function() {
                try {
                    var expr = '\(cleanExpression)';
                    var result = math.evaluate(expr);
                    return result;
                } catch(err) {
                    return { error: err.toString() };
                }
            })()
            """
            
            guard let jsResult = context.evaluateScript(jsCode) else {
                return Result<Double, MathEngineError>.failure(.evaluationError("Failed to evaluate"))
            }
            
            // Check for error object
            if jsResult.objectForKeyedSubscript("error") != nil {
                let errorMsg = jsResult.objectForKeyedSubscript("error")?.toString() ?? "Unknown error"
                return Result<Double, MathEngineError>.failure(.parseError(errorMsg))
            }
            
            guard let doubleValue = jsResult.toNumber()?.doubleValue else {
                return Result<Double, MathEngineError>.failure(.evaluationError("Could not convert result to number"))
            }
            
            return Result<Double, MathEngineError>.success(doubleValue)
        }
        
        return result ?? .failure(.timeout)
    }
    
    /// Simplify an algebraic expression
    /// Example: simplify(expression: "2*x + 3*x") returns "5 * x"
    func simplify(expression: String) -> Result<String, MathEngineError> {
        guard isInitialized, let context = jsContext else {
            return .failure(.initializationFailed("Engine not initialized"))
        }
        
        let result = executeWithTimeout {
            let cleanExpression = expression.trimmingCharacters(in: .whitespaces)
            
            let jsCode = """
            (function() {
                try {
                    var expr = '\(cleanExpression)';
                    var simplified = math.simplify(expr).toString();
                    return simplified;
                } catch(err) {
                    return { error: err.toString() };
                }
            })()
            """
            
            guard let jsResult = context.evaluateScript(jsCode) else {
                return Result<String, MathEngineError>.failure(.evaluationError("Failed to simplify"))
            }
            
            // Check for error
            if jsResult.objectForKeyedSubscript("error") != nil {
                let errorMsg = jsResult.objectForKeyedSubscript("error")?.toString() ?? "Unknown error"
                return Result<String, MathEngineError>.failure(.parseError(errorMsg))
            }
            
            guard let simplified = jsResult.toString() else {
                return Result<String, MathEngineError>.failure(.evaluationError("Could not simplify expression"))
            }
            
            return Result<String, MathEngineError>.success(simplified)
        }
        
        return result ?? .failure(.timeout)
    }
    
    /// Compute the derivative of an expression
    /// Example: derivative(expression: "x^3 + 2*x", variable: "x") returns "3 * x ^ 2 + 2"
    func derivative(expression: String, variable: String = "x") -> Result<String, MathEngineError> {
        guard isInitialized, let context = jsContext else {
            return .failure(.initializationFailed("Engine not initialized"))
        }
        
        let result = executeWithTimeout {
            let cleanExpression = expression.trimmingCharacters(in: .whitespaces)
            
            let jsCode = """
            (function() {
                try {
                    var expr = '\(cleanExpression)';
                    var variable = '\(variable)';
                    var symbol = math.parse(variable);
                    var parsed = math.parse(expr);
                    var deriv = parsed.derivative(symbol);
                    return deriv.toString();
                } catch(err) {
                    return { error: err.toString() };
                }
            })()
            """
            
            guard let jsResult = context.evaluateScript(jsCode) else {
                return Result<String, MathEngineError>.failure(.evaluationError("Failed to compute derivative"))
            }
            
            // Check for error
            if jsResult.objectForKeyedSubscript("error") != nil {
                let errorMsg = jsResult.objectForKeyedSubscript("error")?.toString() ?? "Unknown error"
                return Result<String, MathEngineError>.failure(.parseError(errorMsg))
            }
            
            guard let derivativeStr = jsResult.toString() else {
                return Result<String, MathEngineError>.failure(.evaluationError("Could not compute derivative"))
            }
            
            return Result<String, MathEngineError>.success(derivativeStr)
        }
        
        return result ?? .failure(.timeout)
    }
    
    // MARK: - Step Generation
    
    /// Generate step-by-step solution breakdown
    func generateSteps(equation: String, variable: String = "x") -> Result<[MathJSStep], MathEngineError> {
        // For now, return basic steps structure
        // Full step generation would require more sophisticated analysis of transformations
        
        guard isInitialized, let _ = jsContext else {
            return .failure(.initializationFailed("Engine not initialized"))
        }
        
        // Solve first to get the solution
        let solveResult = solve(equation: equation, variable: variable)
        
        switch solveResult {
        case .success(let solution):
            var steps: [MathJSStep] = []
            
            // Step 1: Original equation
            steps.append(MathJSStep(
                stepNumber: 1,
                operation: "Given equation",
                inputExpression: equation,
                outputExpression: equation,
                rule: nil
            ))
            
            // Step 2-N: Add intermediate simplification steps
            // This is a simplified version; full implementation would generate actual transformation steps
            
            // Final step: Show solution
            if let firstSolution = solution.solutions.first {
                steps.append(MathJSStep(
                    stepNumber: steps.count + 1,
                    operation: "Solve for \(variable)",
                    inputExpression: equation,
                    outputExpression: firstSolution,
                    rule: "solve"
                ))
            }
            
            return .success(steps)
            
        case .failure(let error):
            return .failure(error)
        }
    }
    
    // MARK: - Private Helpers
    
    /// Generate basic solution steps (simplified placeholder)
    private func generateBasicSteps(equation: String, solutions: [String]) -> [MathJSStep] {
        var steps: [MathJSStep] = []
        
        // Step 1: Original
        steps.append(MathJSStep(
            stepNumber: 1,
            operation: "Given equation",
            inputExpression: equation,
            outputExpression: equation,
            rule: nil
        ))
        
        // Step 2: Solution
        if let firstSolution = solutions.first {
            steps.append(MathJSStep(
                stepNumber: 2,
                operation: "Solve",
                inputExpression: equation,
                outputExpression: firstSolution,
                rule: "solve"
            ))
        }
        
        return steps
    }
    
    /// Execute JavaScript code with timeout protection
    /// Timeout is 5 seconds (5000 milliseconds)
    private func executeWithTimeout<T>(_ block: @escaping () -> T) -> T? {
        var result: T?
        let semaphore = DispatchSemaphore(value: 0)
        let timeoutInterval: TimeInterval = 5.0
        
        executionQueue.async {
            result = block()
            semaphore.signal()
        }
        
        let waitResult = semaphore.wait(timeout: .now() + timeoutInterval)
        
        if waitResult == .timedOut {
            return nil
        }
        
        return result
    }
}

// MARK: - Data Types

/// Solution returned from the math engine
struct MathJSSolution {
    let solutions: [String]          // e.g., ["x = 2", "x = 3"]
    let numericValues: [Double]?     // e.g., [2.0, 3.0] when applicable
    let steps: [MathJSStep]          // Ordered solution steps
    let expressionType: String       // e.g., "linear", "quadratic"
}

/// Individual step in a solution
struct MathJSStep {
    let stepNumber: Int              // 1-based index
    let operation: String            // Human-readable operation name
    let inputExpression: String      // Expression before this step
    let outputExpression: String     // Expression after this step
    let rule: String?                // Named rule applied (e.g., "power_rule")
}
