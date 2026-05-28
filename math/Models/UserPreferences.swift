import Foundation
import SwiftData

/// Singleton user preferences stored locally via SwiftData
@Model
final class UserPreferences {
    @Attribute(.unique) var id: UUID
    var defaultDifficulty: String  // Difficulty enum
    var nickname: String
    var soundEnabled: Bool
    var hapticEnabled: Bool
    var lastUsedMode: String?
    
    init(
        id: UUID = UUID(uuidString: "00000000-0000-0000-0000-000000000001") ?? UUID(),
        defaultDifficulty: String = "intermediate",
        nickname: String = "Player",
        soundEnabled: Bool = true,
        hapticEnabled: Bool = true,
        lastUsedMode: String? = nil
    ) {
        self.id = id
        self.defaultDifficulty = defaultDifficulty
        self.nickname = nickname
        self.soundEnabled = soundEnabled
        self.hapticEnabled = hapticEnabled
        self.lastUsedMode = lastUsedMode
    }
}
