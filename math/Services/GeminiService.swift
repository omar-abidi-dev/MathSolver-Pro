import Foundation
import Combine
import Network

// MARK: - Network Monitor (T048)

@MainActor
class NetworkMonitor: ObservableObject {
    @Published var isConnected = true
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.mathsolver.network")
    
    static let shared = NetworkMonitor()
    
    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
            }
        }
        monitor.start(queue: queue)
    }
    
    deinit {
        monitor.cancel()
    }
}

// MARK: - Gemini Service Error

enum GeminiError: LocalizedError {
    case apiKeyNotConfigured
    case networkError(String)
    case invalidResponse
    case parseError(String)
    case invalidContent(String)
    case timeout
    case rateLimitExceeded
    case serverError(String)
    
    var errorDescription: String? {
        switch self {
        case .apiKeyNotConfigured:
            return "Google Gemini API not configured"
        case .networkError(let message):
            return "Network error: \(message)"
        case .invalidResponse:
            return "Invalid response from API"
        case .parseError(let message):
            return "Failed to parse response: \(message)"
        case .invalidContent(let message):
            return "Invalid content: \(message)"
        case .timeout:
            return "Request timed out"
        case .rateLimitExceeded:
            return "API rate limit exceeded"
        case .serverError(let message):
            return "Server error: \(message)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .apiKeyNotConfigured:
            return "Configure your Gemini API key in settings"
        case .networkError:
            return "Check your internet connection"
        case .timeout:
            return "Try again after waiting a moment"
        case .rateLimitExceeded:
            return "You've sent too many requests, wait before trying again"
        case .serverError:
            return "The API server is experiencing issues, try again later"
        default:
            return nil
        }
    }
}

// MARK: - Gemini Request/Response Models

struct GeminiRequest: Encodable {
    let contents: [GeminiContent]
    let generationConfig: GeminiGenerationConfig?
    let systemInstruction: GeminiSystemInstruction?
    
    enum CodingKeys: String, CodingKey {
        case contents
        case generationConfig
        case systemInstruction
    }
}

struct GeminiContent: Codable {
    let parts: [GeminiPart]?
}

struct GeminiPart: Codable {
    let text: String?
}

struct GeminiGenerationConfig: Encodable {
    let temperature: Float
    let topP: Float
    let topK: Int
    let maxOutputTokens: Int
    
    enum CodingKeys: String, CodingKey {
        case temperature
        case topP
        case topK
        case maxOutputTokens
    }
}

struct GeminiSystemInstruction: Encodable {
    let parts: [GeminiPart]
}

struct GeminiResponse: Decodable {
    let candidates: [GeminiCandidate]?
    let usageMetadata: GeminiUsageMetadata?
    
    enum CodingKeys: String, CodingKey {
        case candidates
        case usageMetadata
    }
}

struct GeminiCandidate: Decodable {
    let content: GeminiContent?
    let finishReason: String?
    
    enum CodingKeys: String, CodingKey {
        case content
        case finishReason
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.content = try container.decodeIfPresent(GeminiContent.self, forKey: .content)
        self.finishReason = try container.decodeIfPresent(String.self, forKey: .finishReason)
    }
}

struct GeminiUsageMetadata: Decodable {
    let promptTokenCount: Int?
    let candidatesTokenCount: Int?
    let totalTokenCount: Int?
}

// MARK: - GeminiService

@MainActor
class GeminiService: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var explanationsCache: [String: Explanation] = [:]
    @Published var isNetworkAvailable = true  // T048: Network status
    
    static let shared = GeminiService()
    
    private let networkMonitor = NetworkMonitor.shared
    
    private let apiEndpoint = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent"
    private let urlSession: URLSession
    private let timeoutInterval: TimeInterval = 30.0
    private let maxCacheSize = 50  // T049: Limit cache to prevent unbounded memory growth
    
    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30.0
        config.timeoutIntervalForResource = 60.0
        self.urlSession = URLSession(configuration: config)
        
        // T048: Monitor network connectivity
        networkMonitor.$isConnected.assign(to: &$isNetworkAvailable)
    }
    
    // MARK: - Main Explanation Generation (T034)
    
    /// Generate an AI explanation for a solved equation
    /// Falls back to template explanation if API fails
    func generateExplanation(
        equation: String,
        steps: [Step],
        answer: String,
        difficulty: Difficulty
    ) async -> Explanation {
        // Check cache first (T049: Avoid duplicate API calls for same equation/difficulty)
        let cacheKey = cacheKeyForEquation(equation, difficulty: difficulty)
        if let cached = explanationsCache[cacheKey] {
            return cached
        }
        
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        // Try AI explanation first
        if let aiExplanation = await tryAIExplanation(
            equation: equation,
            steps: steps,
            answer: answer,
            difficulty: difficulty
        ) {
            cacheExplanation(aiExplanation, key: cacheKey)  // T049: Cache the result
            return aiExplanation
        }
        
        // Fall back to template explanation (T038)
        let template = templateFallbackExplanation(
            equation: equation,
            steps: steps,
            difficulty: difficulty
        )
        cacheExplanation(template, key: cacheKey)  // T049: Cache template too
        return template
    }
    
    // MARK: - AI Explanation Attempt
    
    private func tryAIExplanation(
        equation: String,
        steps: [Step],
        answer: String,
        difficulty: Difficulty
    ) async -> Explanation? {
        guard let apiKey = APIConfig.geminiAPIKey else {
            errorMessage = GeminiError.apiKeyNotConfigured.errorDescription
            return nil
        }
        
        // T048: Check network connectivity before attempting API call
        guard isNetworkAvailable else {
            errorMessage = "No internet connection available. Using template explanation instead."
            return nil
        }
        
        // Construct the prompt (T035)
        let systemPrompt = constructSystemPrompt(difficulty: difficulty)
        let userPrompt = constructUserPrompt(
            equation: equation,
            steps: steps,
            answer: answer,
            difficulty: difficulty
        )
        
        // Build request
        let request = buildGeminiRequest(
            systemPrompt: systemPrompt,
            userPrompt: userPrompt,
            difficulty: difficulty
        )
        
        // Send request and parse response (T036, T037)
        do {
            let explanationText = try await sendGeminiRequest(
                request: request,
                apiKey: apiKey
            )
            
            // Validate content (T037)
            guard isValidExplanationContent(explanationText) else {
                errorMessage = "Generated explanation didn't meet quality standards"
                return nil
            }
            
            let explanation = Explanation(
                content: explanationText,
                source: .ai,
                difficulty: difficulty,
                equationId: UUID()
            )
            
            return explanation
        } catch let error as GeminiError {
            errorMessage = error.errorDescription
            return nil
        } catch {
            errorMessage = "Failed to generate explanation: \(error.localizedDescription)"
            return nil
        }
    }
    
    // MARK: - System Prompt Construction (T035)
    
    private func constructSystemPrompt(difficulty: Difficulty) -> String {
        let baseInstruction = """
        You are an expert math tutor explaining step-by-step solutions to students. \
        Your explanations should be clear, accurate, and encouraging.
        """
        
        let difficultyInstructions: String
        switch difficulty {
        case .beginner:
            difficultyInstructions = """
            For a beginner student:
            - Use simple language and avoid technical jargon
            - Break down concepts into small steps
            - Explain WHY each step is necessary
            - Use analogies to familiar concepts
            - Keep explanations concise (2-3 sentences per step)
            """
        case .intermediate:
            difficultyInstructions = """
            For an intermediate student:
            - Assume basic algebra knowledge
            - Explain the rules being applied
            - Connect steps to broader mathematical concepts
            - Point out common mistakes to avoid
            - Keep explanations focused (3-4 sentences per step)
            """
        case .advanced:
            difficultyInstructions = """
            For an advanced student:
            - Use proper mathematical terminology
            - Reference theorems and formal definitions
            - Discuss alternative approaches
            - Point out edge cases or special considerations
            - Explanation can be more detailed (4-5 sentences per step)
            """
        }
        
        return "\(baseInstruction)\n\n\(difficultyInstructions)"
    }
    
    // MARK: - User Prompt Construction (T035)
    
    private func constructUserPrompt(
        equation: String,
        steps: [Step],
        answer: String,
        difficulty: Difficulty
    ) -> String {
        var prompt = """
        Explain the solution to this math problem:
        
        **Equation:** \(equation)
        **Answer:** \(answer)
        
        The solution was solved in these steps:
        """
        
        for (index, step) in steps.enumerated() {
            prompt += "\n\(index + 1). \(step.description): \(step.expression)"
            if !step.explanation.isEmpty {
                prompt += "\n   Details: \(step.explanation)"
            }
        }
        
        prompt += """
        
        Please provide:
        1. A brief overview of the solution approach
        2. An explanation of each step in simple terms
        3. Key insights or patterns to remember
        
        Keep the explanation appropriate for a \(difficulty.rawValue)-level student.
        Format as a cohesive paragraph, not bullet points.
        """
        
        return prompt
    }
    
    // MARK: - Gemini Request Building
    
    private func buildGeminiRequest(
        systemPrompt: String,
        userPrompt: String,
        difficulty: Difficulty
    ) -> GeminiRequest {
        let temperature: Float
        let maxTokens: Int
        
        // Adjust parameters based on difficulty
        switch difficulty {
        case .beginner:
            temperature = 0.7  // More creative, varied explanations
            maxTokens = 500
        case .intermediate:
            temperature = 0.6  // Balanced
            maxTokens = 600
        case .advanced:
            temperature = 0.5  // More focused, precise
            maxTokens = 800
        }
        
        let generationConfig = GeminiGenerationConfig(
            temperature: temperature,
            topP: 0.95,
            topK: 40,
            maxOutputTokens: maxTokens
        )
        
        let systemInstruction = GeminiSystemInstruction(
            parts: [GeminiPart(text: systemPrompt)]
        )
        
        let content = GeminiContent(
            parts: [GeminiPart(text: userPrompt)]
        )
        
        return GeminiRequest(
            contents: [content],
            generationConfig: generationConfig,
            systemInstruction: systemInstruction
        )
    }
    
    // MARK: - HTTP Request Sending (T036)
    
    private func sendGeminiRequest(
        request: GeminiRequest,
        apiKey: String
    ) async throws -> String {
        guard var urlComponents = URLComponents(string: apiEndpoint) else {
            throw GeminiError.invalidResponse
        }
        
        urlComponents.queryItems = [URLQueryItem(name: "key", value: apiKey)]
        
        guard let url = urlComponents.url else {
            throw GeminiError.invalidResponse
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.timeoutInterval = timeoutInterval
        
        let encoder = JSONEncoder()
        urlRequest.httpBody = try encoder.encode(request)
        
        do {
            let (data, response) = try await urlSession.data(for: urlRequest)
            
            // Check HTTP status
            guard let httpResponse = response as? HTTPURLResponse else {
                throw GeminiError.invalidResponse
            }
            
            switch httpResponse.statusCode {
            case 200:
                break  // Success
            case 400...499:
                let error = try? JSONDecoder().decode(GeminiErrorResponse.self, from: data)
                throw GeminiError.parseError(error?.error?.message ?? "Request error")
            case 429:
                throw GeminiError.rateLimitExceeded
            case 500...599:
                throw GeminiError.serverError("HTTP \(httpResponse.statusCode)")
            default:
                throw GeminiError.serverError("HTTP \(httpResponse.statusCode)")
            }
            
            // Parse response
            let decoder = JSONDecoder()
            let geminiResponse = try decoder.decode(GeminiResponse.self, from: data)
            
            // Extract text from first candidate (T036)
            guard let candidate = geminiResponse.candidates?.first,
                  let content = candidate.content,
                  let parts = content.parts,
                  let firstPart = parts.first,
                  let text = firstPart.text else {
                throw GeminiError.parseError("No candidates in response")
            }
            
            return text
        } catch is DecodingError {
            throw GeminiError.parseError("Failed to decode response")
        } catch let urlError as URLError {
            throw GeminiError.networkError(urlError.localizedDescription)
        } catch {
            throw error
        }
    }
    
    // MARK: - Content Validation (T037)
    
    private func isValidExplanationContent(_ content: String) -> Bool {
        let trimmed = content.trimmingCharacters(in: .whitespaces)
        
        // Length check: 50-2000 characters
        guard trimmed.count >= 50 && trimmed.count <= 2000 else {
            return false
        }
        
        // Not empty or just punctuation
        let cleaned = trimmed.replacingOccurrences(of: "[^a-zA-Z0-9]", with: "", options: .regularExpression)
        guard !cleaned.isEmpty else {
            return false
        }
        
        // Contains meaningful content (not repetitive)
        let wordCount = trimmed.split(separator: " ").count
        guard wordCount >= 10 else {  // At least 10 words
            return false
        }
        
        return true
    }
    
    // MARK: - Template Fallback (T038)
    
    private func templateFallbackExplanation(
        equation: String,
        steps: [Step],
        difficulty: Difficulty
    ) -> Explanation {
        var explanation = ""
        
        switch difficulty {
        case .beginner:
            explanation = generateBeginnerExplanation(steps: steps)
        case .intermediate:
            explanation = generateIntermediateExplanation(equation: equation, steps: steps)
        case .advanced:
            explanation = generateAdvancedExplanation(equation: equation, steps: steps)
        }
        
        return Explanation(
            content: explanation,
            source: .template,
            difficulty: difficulty,
            equationId: UUID()
        )
    }
    
    private func generateBeginnerExplanation(steps: [Step]) -> String {
        var text = "Here's how we solve this step by step:\n\n"
        
        for (index, step) in steps.enumerated() {
            text += "**Step \(index + 1):** \(step.description)\n"
            text += "We get: \(step.expression)\n"
            if !step.explanation.isEmpty {
                text += "Why: \(step.explanation)\n"
            }
            text += "\n"
        }
        
        text += "By following these steps one at a time, we get the final answer!"
        return text
    }
    
    private func generateIntermediateExplanation(equation: String, steps: [Step]) -> String {
        var text = "To solve \(equation), we apply algebraic principles systematically:\n\n"
        
        for (index, step) in steps.enumerated() {
            text += "**Step \(index + 1):** \(step.description)\n"
            text += "Expression: \(step.expression)\n\n"
        }
        
        text += "This systematic approach ensures we isolate the variable and find all solutions."
        return text
    }
    
    private func generateAdvancedExplanation(equation: String, steps: [Step]) -> String {
        var text = "Analysis of \(equation):\n\n"
        
        for (index, step) in steps.enumerated() {
            text += "**Transformation \(index + 1):** \(step.description)\n"
            text += "Result: \(step.expression)\n\n"
        }
        
        text += "This sequence of transformations preserves equation equivalence while progressively isolating variables to determine the solution set."
        return text
    }
    
    // MARK: - Caching
    
    private func cacheKeyForEquation(_ equation: String, difficulty: Difficulty) -> String {
        let normalized = equation.lowercased().trimmingCharacters(in: .whitespaces)
        return "\(normalized)_\(difficulty.rawValue)"
    }
    
    /// Cache an explanation, enforcing size limit (T049)
    private func cacheExplanation(_ explanation: Explanation, key: String) {
        // If cache is full, remove oldest entries
        if explanationsCache.count >= maxCacheSize {
            // Remove the first (oldest) entry
            if let oldestKey = explanationsCache.keys.first {
                explanationsCache.removeValue(forKey: oldestKey)
            }
        }
        
        explanationsCache[key] = explanation
    }
    
    func clearCache() {
        explanationsCache.removeAll()
    }
}

// MARK: - Gemini Error Response

struct GeminiErrorResponse: Decodable {
    let error: GeminiErrorDetail?
}

struct GeminiErrorDetail: Decodable {
    let code: Int?
    let message: String?
}
