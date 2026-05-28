import Foundation

/// Error types from SolverService wrapping ParseError and solver errors
enum SolverError: LocalizedError {
    /// Error occurred while parsing the equation
    case parseError(ParseError)
    
    /// Equation type is not yet supported
    case unsupportedEquationType(String)
    
    /// Solver returned an error
    case solverFailed(String)
    
    /// Generic solving failure
    case unknownError(String)
    
    var errorDescription: String? {
        switch self {
        case .parseError(let parseError):
            return parseError.errorDescription
        case .unsupportedEquationType(let type):
            return "Unsupported equation type: \(type)"
        case .solverFailed(let reason):
            return "Solving failed: \(reason)"
        case .unknownError(let message):
            return message
        }
    }
}

// MARK: - SolverService

/// Orchestration service that coordinates parsing, type detection, and solving
/// Routes equations to appropriate solvers (Linear, Quadratic, System)
/// Phase 2 implementation: Provides routing structure; Phase 3 will integrate actual solvers
class SolverService {
    
    /// Solve an equation from a user-provided string
    /// - Parameter input: Raw equation string (e.g., "2x + 5 = 15")
    /// - Returns: Result containing the solved Equation or a SolverError
    func solve(input: String) -> Result<Equation, SolverError> {
        // Step 1: Parse the equation
        let parseResult = parseEquation(input)
        guard case .success(var equation) = parseResult else {
            if case .failure(let parseError) = parseResult {
                return .failure(.parseError(parseError))
            }
            return .failure(.unknownError("Parse failed"))
        }
        
        // Step 2: Detect equation type (already done by parser)
        // The parser sets equationType automatically
        
        // Step 3: Route to appropriate solver
        let solveResult = routeToSolver(equation)
        guard case .success(let solverResult) = solveResult else {
            if case .failure(let error) = solveResult {
                return .failure(error)
            }
            return .failure(.unknownError("Solver routing failed"))
        }
        
        // Step 4: Attach solutions and steps to equation
        switch solverResult {
        case .solved(let solution, let steps):
            equation.solutions = solution
            equation.solutionSteps = steps
            return .success(equation)
            
        case .noSolution(_, let steps):
            equation.solutions = [:]
            equation.solutionSteps = steps
            // Return as success but with empty solutions (indicates no-solution case)
            return .success(equation)
            
        case .infiniteSolutions(_, let steps):
            equation.solutions = ["infinite": Double.infinity]
            equation.solutionSteps = steps
            return .success(equation)
            
        case .noRealSolution(_, let steps):
            equation.solutions = [:]
            equation.solutionSteps = steps
            return .success(equation)
            
        case .unsupported(let reason):
            return .failure(.unsupportedEquationType(reason))
        }
    }
    
    /// Route parsed equation to the appropriate solver based on type
    /// Handles linear, quadratic, and system equations
    /// Also routes new equation types to MathJSEngine (Phase 3+)
    /// - Parameter equation: The parsed equation with detected type
    /// - Returns: Result containing SolverResult or SolverError
    private func routeToSolver(_ equation: Equation) -> Result<SolverResult, SolverError> {
        switch equation.equationType {
        // New equation types - route through MathJSEngine (Phase 3+)
        case .trigonometric, .logarithmic, .polynomial, .derivative, .integral,
             .statistics, .physics:
            return solveThroughMathJS(equation)
            
        // Existing equation types - use traditional solvers with MathJS as primary
        case .linear, .quadratic, .system:
            // Try MathJS first, fall back to traditional solvers
            let mathJSResult = solveThroughMathJS(equation)
            if case .success = mathJSResult {
                return mathJSResult
            }
            
            // Fall back to traditional solvers
            return routeToTraditionalSolver(equation)
        }
    }
    
    /// Route to traditional Swift solvers (Linear, Quadratic, System)
    private func routeToTraditionalSolver(_ equation: Equation) -> Result<SolverResult, SolverError> {
        switch equation.equationType {
        case .linear:
            let solver = LinearSolver()
            return .success(solver.solve(equation: equation))
            
        case .quadratic:
            let solver = QuadraticSolver()
            return .success(solver.solve(equation: equation))
            
        case .system:
            let solver = SystemSolver()
            return .success(solver.solve(equations: [equation]))
            
        default:
            return .failure(.unsupportedEquationType("Type not supported by traditional solvers"))
        }
    }
    
    /// Solve through MathJS engine for advanced equation types
    private func solveThroughMathJS(_ equation: Equation) -> Result<SolverResult, SolverError> {
        // Note: This is a placeholder that returns unsupported
        // Actual implementation in Phase 3 (T019) will use MathJSEngine
        return .failure(.unsupportedEquationType("MathJS integration pending (Phase 3)"))
    }
    
    // MARK: - Future Integration Points
    
    /// Phase 3: LinearSolver integration
    /// Placeholder for the linear equation solver
    /// Will be called when equation.equationType == .linear
    func solveLinear(_ equation: Equation) -> Result<SolverResult, SolverError> {
        // To be implemented in Phase 3 (Task T011)
        return .failure(.unsupportedEquationType("LinearSolver not yet implemented"))
    }
    
    /// Phase 3: QuadraticSolver integration
    /// Placeholder for the quadratic equation solver
    /// Will be called when equation.equationType == .quadratic
    func solveQuadratic(_ equation: Equation) -> Result<SolverResult, SolverError> {
        // To be implemented in Phase 3 (Task T020)
        return .failure(.unsupportedEquationType("QuadraticSolver not yet implemented"))
    }
    
    /// Phase 3: SystemSolver integration
    /// Placeholder for the system of equations solver
    /// Will be called when equation.equationType == .system
    func solveSystem(_ elements: [Equation]) -> Result<SolverResult, SolverError> {
        // To be implemented in Phase 3 (Task T021)
        return .failure(.unsupportedEquationType("SystemSolver not yet implemented"))
    }
}

// MARK: - Shared Instance

/// Global singleton instance of SolverService for convenient access
let solverService = SolverService()
