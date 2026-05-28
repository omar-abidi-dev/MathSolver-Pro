import Foundation
import SwiftData

/// Represents an enemy in battle mode
@Model
final class Enemy {
    @Attribute(.unique) var id: UUID
    var name: String
    var level: Int
    var maxHealth: Int
    var currentHealth: Int
    var basePointValue: Int  // Points awarded for defeating this enemy
    var icon: String  // SF Symbol name
    
    init(
        id: UUID = UUID(),
        name: String,
        level: Int,
        maxHealth: Int,
        basePointValue: Int,
        icon: String = "figure.wave"
    ) {
        self.id = id
        self.name = name
        self.level = level
        self.maxHealth = maxHealth
        self.currentHealth = maxHealth
        self.basePointValue = basePointValue
        self.icon = icon
    }
    
    /// Gets the next enemy of higher difficulty
    static func nextEnemy(after current: Enemy) -> Enemy {
        let level = current.level + 1
        let health = currentHealthForLevel(level)
        let points = basePointsForLevel(level)
        
        let enemyNames = [
            "Goblin", "Orc", "Troll", "Dragon", "Demon",
            "Shadow Beast", "Stone Giant", "Fire Elemental", "Ice Wraith", "Ancient Evil"
        ]
        
        let name = level <= enemyNames.count ? enemyNames[level - 1] : "Boss #\(level)"
        
        return Enemy(
            name: name,
            level: level,
            maxHealth: health,
            basePointValue: points
        )
    }
    
    /// Gets starting enemy for a battle
    static func startingEnemy() -> Enemy {
        return Enemy(
            name: "Goblin",
            level: 1,
            maxHealth: 10,
            basePointValue: 50
        )
    }
    
    private static func currentHealthForLevel(_ level: Int) -> Int {
        return 10 + (level - 1) * 5
    }
    
    private static func basePointsForLevel(_ level: Int) -> Int {
        return 50 + (level - 1) * 25
    }
    
    /// Damage enemy, returns true if defeated
    @discardableResult
    func takeDamage(_ amount: Int) -> Bool {
        currentHealth = max(0, currentHealth - amount)
        return currentHealth == 0
    }
    
    /// Health as percentage (0.0 to 1.0)
    var healthPercentage: Double {
        guard maxHealth > 0 else { return 0 }
        return Double(currentHealth) / Double(maxHealth)
    }
}

/// Represents the state of an active battle
struct BattleState {
    var enemy: Enemy
    var playerHealth: Int = 100
    var maxPlayerHealth: Int = 100
    var score: Int = 0
    var currentRound: Int = 1
    var correctAnswersInBattle: Int = 0
    var totalAttacks: Int = 0
    var isPlayerDefeated: Bool = false
    var isBattleOver: Bool = false
    
    // Battle progression
    var enemies: [Enemy] = []  // Defeated enemies
    var currentDifficulty: Difficulty = .beginner
    
    init(startingDifficulty: Difficulty = .intermediate) {
        self.enemy = Enemy.startingEnemy()
        self.currentDifficulty = startingDifficulty
    }
    
    /// Apply damage to enemy from correct answer
    mutating func attackEnemy(damage: Int) {
        totalAttacks += 1
        correctAnswersInBattle += 1
        
        let isDefeated = enemy.takeDamage(damage)
        score += damage * 10  // Base damage points
        
        if isDefeated {
            // Enemy defeated - move to next
            enemies.append(enemy)
            currentRound += 1
            
            // Escalate difficulty every 2 enemies
            if enemies.count % 2 == 0 {
                escalateDifficulty()
            }
            
            // Get next enemy
            enemy = Enemy.nextEnemy(after: enemy)
        }
    }
    
    /// Enemy counter attacks
    mutating func enemyCounterAttack() {
        let damageRange: ClosedRange<Int>
        switch currentDifficulty {
        case .beginner:
            damageRange = 5...10
        case .intermediate:
            damageRange = 10...15
        case .advanced:
            damageRange = 15...25
        }
        
        let damage = Int.random(in: damageRange)
        playerHealth = max(0, playerHealth - damage)
        
        if playerHealth == 0 {
            isPlayerDefeated = true
            isBattleOver = true
        }
    }
    
    /// Player answers incorrectly
    mutating func handleWrongAnswer() {
        totalAttacks += 1
        enemyCounterAttack()
    }
    
    /// Escalate to next difficulty
    private mutating func escalateDifficulty() {
        switch currentDifficulty {
        case .beginner:
            currentDifficulty = .intermediate
        case .intermediate:
            currentDifficulty = .advanced
        case .advanced:
            // Stay at advanced
            break
        }
    }
    
    /// Check if player is still alive
    var isPlayerAlive: Bool {
        return playerHealth > 0
    }
    
    /// Health as percentage (0.0 to 1.0)
    var playerHealthPercentage: Double {
        guard maxPlayerHealth > 0 else { return 0 }
        return Double(playerHealth) / Double(maxPlayerHealth)
    }
}
