import Foundation

/// Represents an explanation of a solution
/// Generated either by AI or from built-in templates
struct Explanation: Identifiable, Codable {
    /// Unique identifier
    let id: UUID
    
    /// The explanation text (supports markdown)
    let content: String
    
    /// Whether explanation is AI-generated or from template
    let source: ExplanationSource
    
    /// The difficulty level used to generate this explanation
    let difficulty: Difficulty
    
    /// Reference to the originating solution's equation
    let equationId: UUID
    
    /// When the explanation was generated
    let generatedAt: Date
    
    init(
        content: String,
        source: ExplanationSource,
        difficulty: Difficulty,
        equationId: UUID
    ) {
        self.id = UUID()
        self.content = content
        self.source = source
        self.difficulty = difficulty
        self.equationId = equationId
        self.generatedAt = Date()
    }
}

// MARK: - Validation

extension Explanation {
    /// Validates explanation content length and relevance
    /// Returns true if explanation meets quality standards
    func isValid() -> Bool {
        let contentLength = content.count
        let hasMinimumLength = contentLength >= 50
        let hasMaximumLength = contentLength <= 2000
        
        return hasMinimumLength && hasMaximumLength
    }
    
    /// Check if explanation is from AI source
    var isAIGenerated: Bool {
        source == .ai
    }
    
    /// Check if explanation is from template fallback
    var isTemplate: Bool {
        source == .template
    }
}
