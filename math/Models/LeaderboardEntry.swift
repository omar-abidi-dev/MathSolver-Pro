import Foundation
import SwiftData

/// Represents a user's locally-stored leaderboard entry
@Model
final class LeaderboardEntry {
    @Attribute(.unique) var id: UUID
    var nickname: String
    var score: Int
    var gameMode: String  // GameMode enum stored as string
    var difficulty: String  // Difficulty enum stored as string
    var accuracy: Double  // Percentage 0-100
    var date: Date
    
    init(
        id: UUID = UUID(),
        nickname: String,
        score: Int,
        gameMode: GameMode,
        difficulty: Difficulty,
        accuracy: Double,
        date: Date = Date()
    ) {
        self.id = id
        self.nickname = nickname
        self.score = score
        self.gameMode = gameMode.rawValue
        self.difficulty = difficulty.rawValue
        self.accuracy = accuracy
        self.date = date
    }
    
    // Computed properties for type-safe access
    var gameModeEnum: GameMode? {
        GameMode(rawValue: gameMode)
    }
    
    var difficultyEnum: Difficulty? {
        Difficulty(rawValue: difficulty)
    }
}
