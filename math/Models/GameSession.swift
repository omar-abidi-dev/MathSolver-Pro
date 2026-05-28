import Foundation
import SwiftData

/// A single round within a game session
struct GameRound: Codable {
    var equation: String
    var correctAnswer: String
    var userAnswer: String?
    var isCorrect: Bool
    var responseTime: TimeInterval
    var pointsAwarded: Int
}

/// Represents a game session (Speed Trainer or Battle mode)
@Model
final class GameSession {
    @Attribute(.unique) var id: UUID
    var mode: String  // GameMode enum
    var difficulty: String  // Difficulty enum
    var score: Int
    var totalQuestions: Int
    var correctAnswers: Int
    var timeElapsed: TimeInterval
    var rounds: [GameRound]
    var startedAt: Date
    var completedAt: Date?
    
    init(
        id: UUID = UUID(),
        mode: String,
        difficulty: String,
        score: Int = 0,
        totalQuestions: Int = 0,
        correctAnswers: Int = 0,
        timeElapsed: TimeInterval = 0,
        rounds: [GameRound] = [],
        startedAt: Date = Date(),
        completedAt: Date? = nil
    ) {
        self.id = id
        self.mode = mode
        self.difficulty = difficulty
        self.score = score
        self.totalQuestions = totalQuestions
        self.correctAnswers = correctAnswers
        self.timeElapsed = timeElapsed
        self.rounds = rounds
        self.startedAt = startedAt
        self.completedAt = completedAt
    }
}
