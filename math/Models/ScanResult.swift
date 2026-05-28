import Foundation

/// Represents the output of camera text recognition
struct ScanResult: Identifiable, Codable {
    /// Unique identifier
    let id: UUID
    
    /// Raw text as recognized by OCR
    let rawText: String
    
    /// User-edited version of the text (optional)
    let correctedText: String?
    
    /// OCR confidence score (0.0 - 1.0)
    let confidence: Float
    
    /// When the scan was performed
    let timestamp: Date
    
    init(
        rawText: String,
        confidence: Float,
        correctedText: String? = nil
    ) {
        self.id = UUID()
        self.rawText = rawText
        self.confidence = min(max(confidence, 0.0), 1.0)  // Clamp to 0-1 range
        self.correctedText = correctedText?.isEmpty == true ? nil : correctedText
        self.timestamp = Date()
    }
}

// MARK: - State Management

extension ScanResult {
    /// The text to use for solving (user's correction if available, otherwise raw text)
    var textToSolve: String {
        correctedText ?? rawText
    }
    
    /// Whether the confidence is acceptable (>= 70%)
    var hasGoodConfidence: Bool {
        confidence >= 0.7
    }
}
