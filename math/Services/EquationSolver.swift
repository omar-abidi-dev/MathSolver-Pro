import Foundation

/// Solves mathematical equations using real math solvers and Gemini API
class EquationSolver {
    private let equation: String
    private let difficulty: Difficulty
    
    init(equation: String, difficulty: Difficulty = .intermediate) {
        self.equation = equation.trimmingCharacters(in: .whitespaces)
        self.difficulty = difficulty
    }
    
    /// Solves the equation synchronously for types with built-in solvers (linear, quadratic, system)
    /// For advanced types, throws — use solveAsync() instead
    func solve() throws -> Solution {
        let detector = EquationTypeDetector(equation)
        if let error = detector.validate() {
            throw error
        }
        
        let type = detector.detectType()
        
        switch type {
        case .linear:
            return try solveLinear()
        case .quadratic:
            return try solveQuadratic()
        case .system:
            return try solveSystem()
        case .trigonometric, .logarithmic, .polynomial, .derivative, .integral:
            // These need async solving via Gemini — throw to signal caller should use solveAsync
            throw EquationError.invalidSyntax
        case .statistics, .physics:
            throw EquationError.invalidSyntax
        }
    }
    
    /// Solves any equation type — uses built-in solvers for linear/quadratic/system,
    /// falls back to Gemini API for trigonometric, logarithmic, polynomial, derivative, integral
    func solveAsync() async throws -> Solution {
        let detector = EquationTypeDetector(equation)
        if let error = detector.validate() {
            throw error
        }
        
        let type = detector.detectType()
        
        switch type {
        case .linear:
            return try solveLinear()
        case .quadratic:
            return try solveQuadratic()
        case .system:
            return try solveSystem()
        case .trigonometric, .logarithmic, .polynomial, .derivative, .integral:
            return try await solveWithGemini(type: type)
        case .statistics, .physics:
            throw EquationError.invalidSyntax
        }
    }
    
    // MARK: - Linear Equation Solving (Real)
    
    private func solveLinear() throws -> Solution {
        let parseResult = parseEquation(equation)
        switch parseResult {
        case .success(let parsedEquation):
            let solver = LinearSolver()
            let solverResult = solver.solve(equation: parsedEquation)
            return try convertSolverResult(solverResult, type: .linear)
        case .failure:
            throw EquationError.invalidSyntax
        }
    }
    
    // MARK: - Quadratic Equation Solving (Real)
    
    private func solveQuadratic() throws -> Solution {
        let parseResult = parseEquation(equation)
        switch parseResult {
        case .success(let parsedEquation):
            let solver = QuadraticSolver()
            let solverResult = solver.solve(equation: parsedEquation)
            return try convertSolverResult(solverResult, type: .quadratic)
        case .failure:
            throw EquationError.invalidSyntax
        }
    }
    
    // MARK: - System of Equations Solving (Real)
    
    private func solveSystem() throws -> Solution {
        let equationParts = equation.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
        guard equationParts.count >= 2 else {
            throw EquationError.invalidSyntax
        }
        
        var parsedEquations: [Equation] = []
        for eqStr in equationParts.prefix(2) {
            let result = parseEquation(eqStr)
            switch result {
            case .success(var parsedEq):
                parsedEq.equationType = .system
                parsedEquations.append(parsedEq)
            case .failure:
                throw EquationError.invalidSyntax
            }
        }
        
        guard parsedEquations.count == 2 else {
            throw EquationError.invalidSyntax
        }
        
        let solver = SystemSolver()
        let solverResult = solver.solve(equations: parsedEquations)
        return try convertSolverResult(solverResult, type: .system)
    }
    
    // MARK: - Gemini API Solving (Trig, Log, Polynomial, Derivative, Integral)
    
    private func solveWithGemini(type: EquationType) async throws -> Solution {
        guard APIConfig.isGeminiConfigured, let apiKey = APIConfig.geminiAPIKey else {
            throw EquationError.invalidSyntax
        }
        
        let systemPrompt = """
        You are a precise math solver. Solve the given equation and return ONLY valid JSON with no markdown formatting, no code blocks, no extra text.
        The JSON must have this exact structure:
        {"solutions":["x = value"],"steps":[{"description":"step title","expression":"math expression","explanation":"why this step"}]}
        Rules:
        - solutions: array of solution strings like "x = 5" or "x = pi/6"
        - steps: array of step objects showing the work
        - Include 3-6 clear steps
        - Be mathematically precise
        - For trig equations, include all solutions in [0, 2pi) and note the general form
        - For derivatives, the solution is the derivative expression
        - For integrals, the solution is the antiderivative + C
        """
        
        let userPrompt = "Solve: \(equation)"
        
        let content = GeminiContent(parts: [GeminiPart(text: userPrompt)])
        let systemInstruction = GeminiSystemInstruction(parts: [GeminiPart(text: systemPrompt)])
        let generationConfig = GeminiGenerationConfig(
            temperature: 0.1,
            topP: 0.95,
            topK: 40,
            maxOutputTokens: 1000
        )
        
        let request = GeminiRequest(
            contents: [content],
            generationConfig: generationConfig,
            systemInstruction: systemInstruction
        )
        
        guard var urlComponents = URLComponents(string: APIConfig.geminiEndpoint) else {
            throw EquationError.invalidSyntax
        }
        urlComponents.queryItems = [URLQueryItem(name: "key", value: apiKey)]
        
        guard let url = urlComponents.url else {
            throw EquationError.invalidSyntax
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.timeoutInterval = 30.0
        urlRequest.httpBody = try JSONEncoder().encode(request)
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw EquationError.invalidSyntax
        }
        
        let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
        
        guard let candidate = geminiResponse.candidates?.first,
              let responseContent = candidate.content,
              let parts = responseContent.parts,
              let firstPart = parts.first,
              let text = firstPart.text else {
            throw EquationError.invalidSyntax
        }
        
        // Parse the JSON response from Gemini
        return try parseGeminiSolveResponse(text, type: type)
    }
    
    /// Parse Gemini's JSON response into a Solution
    private func parseGeminiSolveResponse(_ text: String, type: EquationType) throws -> Solution {
        // Clean up the response — remove markdown code blocks if present
        var cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasPrefix("```json") {
            cleaned = String(cleaned.dropFirst(7))
        } else if cleaned.hasPrefix("```") {
            cleaned = String(cleaned.dropFirst(3))
        }
        if cleaned.hasSuffix("```") {
            cleaned = String(cleaned.dropLast(3))
        }
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let jsonData = cleaned.data(using: .utf8) else {
            throw EquationError.invalidSyntax
        }
        
        struct GeminiSolveResult: Decodable {
            let solutions: [String]
            let steps: [GeminiStep]
            
            struct GeminiStep: Decodable {
                let description: String
                let expression: String
                let explanation: String
            }
        }
        
        let result = try JSONDecoder().decode(GeminiSolveResult.self, from: jsonData)
        
        guard !result.solutions.isEmpty, !result.steps.isEmpty else {
            throw EquationError.invalidSyntax
        }
        
        let steps = result.steps.map { step in
            Step(
                description: step.description,
                expression: step.expression,
                explanation: step.explanation
            )
        }
        
        return Solution(
            equation: equation,
            type: type,
            solutions: result.solutions,
            steps: steps,
            difficulty: difficulty.rawValue.capitalized,
            explanation: generateDifficultyAdaptedExplanation(type: type, solutions: result.solutions),
            source: .manual,
            explanationSource: .ai
        )
    }
    
    // MARK: - Convert SolverResult to Solution
    
    private func convertSolverResult(_ result: SolverResult, type: EquationType) throws -> Solution {
        let steps: [Step]
        let solutions: [String]
        
        switch result {
        case .solved(let solutionMap, let solutionSteps):
            // Sort keys so "x" comes before "x2", "y", etc.
            solutions = solutionMap.sorted(by: { $0.key < $1.key }).map { key, value in
                let varName = key.hasPrefix("x2") ? "x" : key
                return "\(varName) = \(formatNumber(value))"
            }
            steps = solutionSteps.map { step in
                Step(description: step.description, expression: step.resultEquation, explanation: step.explanation)
            }
            
        case .noSolution(let reason, let solutionSteps):
            solutions = ["No solution: \(reason)"]
            steps = solutionSteps.map { step in
                Step(description: step.description, expression: step.resultEquation, explanation: step.explanation)
            }
            
        case .noRealSolution(let reason, let solutionSteps):
            solutions = ["No real solution: \(reason)"]
            steps = solutionSteps.map { step in
                Step(description: step.description, expression: step.resultEquation, explanation: step.explanation)
            }
            
        case .infiniteSolutions(let reason, let solutionSteps):
            solutions = ["Infinite solutions: \(reason)"]
            steps = solutionSteps.map { step in
                Step(description: step.description, expression: step.resultEquation, explanation: step.explanation)
            }
            
        case .unsupported(_):
            throw EquationError.invalidSyntax
        }
        
        // Always include the original equation as the first step if not already present
        var allSteps = steps
        if allSteps.isEmpty || !allSteps[0].expression.contains("=") {
            allSteps.insert(Step(
                description: "Original equation",
                expression: equation,
                explanation: "This is the given equation we need to solve."
            ), at: 0)
        }
        
        return Solution(
            equation: equation,
            type: type,
            solutions: solutions,
            steps: allSteps,
            difficulty: difficulty.rawValue.capitalized,
            explanation: generateDifficultyAdaptedExplanation(type: type, solutions: solutions)
        )
    }
    
    private func formatNumber(_ value: Double) -> String {
        if value == floor(value) && abs(value) < 1e15 {
            return String(Int(value))
        }
        return String(format: "%.10g", value)
    }
    
    // MARK: - Explanations
    
    private func generateDifficultyAdaptedExplanation(type: EquationType, solutions: [String]) -> String {
        switch type {
        case .linear:
            return getLinearExplanation()
        case .quadratic:
            return getQuadraticExplanation()
        case .system:
            return getSystemExplanation()
        case .trigonometric:
            return getTrigonometricExplanation()
        case .logarithmic:
            return getLogarithmicExplanation()
        case .polynomial:
            return getPolynomialExplanation()
        case .derivative:
            return getDerivativeExplanation()
        case .integral:
            return getIntegralExplanation()
        case .statistics:
            return "Statistical analysis performed on the provided dataset."
        case .physics:
            return "Physics problem solved using the appropriate formula."
        }
    }
    
    private func getLinearExplanation() -> String {
        switch difficulty {
        case .beginner:
            return "We solve for x by moving numbers to one side and dividing."
        case .intermediate:
            return "This linear equation is solved by isolating the variable through algebraic operations."
        case .advanced:
            return "We apply systematic algebraic transformations maintaining equation equivalence."
        }
    }
    
    private func getQuadraticExplanation() -> String {
        switch difficulty {
        case .beginner:
            return "Quadratic equations have two solutions found by factoring or using the quadratic formula."
        case .intermediate:
            return "We factor the quadratic expression or apply the quadratic formula to find both solutions."
        case .advanced:
            return "Solutions are determined via the quadratic formula, analyzing discriminant for real roots."
        }
    }
    
    private func getSystemExplanation() -> String {
        switch difficulty {
        case .beginner:
            return "We solve systems by finding values that work in all equations at once."
        case .intermediate:
            return "Systems are solved using substitution or elimination methods systematically."
        case .advanced:
            return "We employ matrix methods or systematic elimination to solve coupled equations."
        }
    }
    
    private func getTrigonometricExplanation() -> String {
        switch difficulty {
        case .beginner:
            return "Trigonometric equations involve sine, cosine, and tangent. We find angles that satisfy the equation."
        case .intermediate:
            return "We use trigonometric identities and inverse functions to find all solutions within the domain."
        case .advanced:
            return "Solutions employ trigonometric identities with periodic analysis for complete solution sets."
        }
    }
    
    private func getLogarithmicExplanation() -> String {
        switch difficulty {
        case .beginner:
            return "Logarithmic equations use logarithm properties to isolate variables."
        case .intermediate:
            return "We apply logarithm rules like product, quotient, and power rules systematically."
        case .advanced:
            return "Solutions employ logarithmic properties with domain analysis and change-of-base techniques."
        }
    }
    
    private func getPolynomialExplanation() -> String {
        switch difficulty {
        case .beginner:
            return "Polynomial equations of higher degree have multiple solutions we find using factoring or numerical methods."
        case .intermediate:
            return "We apply polynomial factoring, the rational root theorem, or synthetic division to find roots."
        case .advanced:
            return "Solutions employ polynomial analysis with multiplicity consideration and numerical root-finding."
        }
    }
    
    private func getDerivativeExplanation() -> String {
        switch difficulty {
        case .beginner:
            return "The derivative represents how a function changes. We compute it using basic differentiation rules."
        case .intermediate:
            return "We apply power rule, product rule, chain rule, and other differentiation techniques systematically."
        case .advanced:
            return "Derivatives employ rules for composite, implicit, and transcendental functions with analysis."
        }
    }
    
    private func getIntegralExplanation() -> String {
        switch difficulty {
        case .beginner:
            return "Integration is the reverse of differentiation. We find antiderivatives using basic rules."
        case .intermediate:
            return "We apply integration techniques like substitution, parts, and recognition of standard forms."
        case .advanced:
            return "Integration employs partial fractions, trigonometric substitution, and advanced techniques."
        }
    }
}

