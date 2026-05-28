import Foundation

/// Secure API configuration management
struct APIConfig {
    
    /// Google Gemini API key for AI explanation generation
    /// Configured for personal/educational use of this app
    static let geminiAPIKey: String? = "AIzaSyDs0r6Y0MOGQMeG3BPUlVVyYenngOsRsXo"
    
    /// Gemini API endpoint
    static let geminiEndpoint = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent"
    
    /// Check if Gemini API is configured
    static var isGeminiConfigured: Bool {
        geminiAPIKey != nil && !geminiAPIKey!.isEmpty
    }
    
    /// Validate that API is configured before use
    static func validateConfiguration() throws {
        guard isGeminiConfigured else {
            throw APIConfigError.geminiKeyNotConfigured
        }
    }
}

/// API configuration errors
enum APIConfigError: LocalizedError {
    case geminiKeyNotConfigured
    
    var errorDescription: String? {
        switch self {
        case .geminiKeyNotConfigured:
            return "Gemini API key is not configured."
        }
    }
}
