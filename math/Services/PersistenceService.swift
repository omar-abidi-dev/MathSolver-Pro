import SwiftData
import Foundation

/// Service for managing all SwiftData persistence operations
/// Provides CRUD operations for leaderboard, preferences, and game sessions
class PersistenceService {
    /// ModelContext for database operations
    private let modelContext: ModelContext
    
    /// Designated initializer
    /// - Parameter modelContext: The SwiftData ModelContext (typically from @Environment(\.modelContext))
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Leaderboard Operations
    
    /// Save a leaderboard entry to the database
    /// - Parameter entry: The LeaderboardEntry to save
    func saveScore(_ entry: LeaderboardEntry) {
        modelContext.insert(entry)
        try? modelContext.save()
    }
    
    /// Fetch leaderboard entries for a specific game mode, sorted by score descending
    /// - Parameters:
    ///   - mode: The game mode to filter by
    ///   - limit: Maximum number of entries to return (default: 10)
    /// - Returns: Array of LeaderboardEntry objects sorted by score descending
    func fetchLeaderboard(mode: GameMode, limit: Int = 10) -> [LeaderboardEntry] {
        let modeString = mode.rawValue
        let descriptor = FetchDescriptor<LeaderboardEntry>(
            predicate: #Predicate { $0.gameMode == modeString },
            sortBy: [SortDescriptor(\.score, order: .reverse)]
        )
        
        do {
            let entries = try modelContext.fetch(descriptor)
            return Array(entries.prefix(limit))
        } catch {
            print("Error fetching leaderboard: \(error)")
            return []
        }
    }
    
    /// Clear all leaderboard entries for a specific game mode
    /// - Parameter mode: The game mode to clear
    func clearLeaderboard(mode: GameMode) {
        let modeString = mode.rawValue
        let descriptor = FetchDescriptor<LeaderboardEntry>(
            predicate: #Predicate { $0.gameMode == modeString }
        )
        
        do {
            let entries = try modelContext.fetch(descriptor)
            for entry in entries {
                modelContext.delete(entry)
            }
            try modelContext.save()
        } catch {
            print("Error clearing leaderboard: \(error)")
        }
    }
    
    /// Get the top score for a specific game mode
    /// - Parameter mode: The game mode to query
    /// - Returns: The highest score or 0 if no entries exist
    func getTopScore(for mode: GameMode) -> Int {
        return fetchLeaderboard(mode: mode, limit: 1).first?.score ?? 0
    }
    
    // MARK: - Preferences Operations
    
    /// Load user preferences from the database
    /// Creates default preferences if none exist
    /// - Returns: UserPreferences object (existing or newly created defaults)
    func loadPreferences() -> UserPreferences {
        // Try to fetch the singleton preferences entry
        let descriptor = FetchDescriptor<UserPreferences>()
        
        do {
            let entries = try modelContext.fetch(descriptor)
            if let existing = entries.first {
                return existing
            }
        } catch {
            print("Error loading preferences: \(error)")
        }
        
        // Create default preferences if none exist
        let defaults = UserPreferences()
        modelContext.insert(defaults)
        try? modelContext.save()
        return defaults
    }
    
    /// Save or update user preferences
    /// - Parameter prefs: The UserPreferences object to save
    func savePreferences(_ prefs: UserPreferences) {
        // Check if this preference already exists in context
        let descriptor = FetchDescriptor<UserPreferences>()
        
        do {
            let existing = try modelContext.fetch(descriptor)
            if !existing.isEmpty {
                // Update existing
                existing[0].defaultDifficulty = prefs.defaultDifficulty
                existing[0].nickname = prefs.nickname
                existing[0].soundEnabled = prefs.soundEnabled
                existing[0].hapticEnabled = prefs.hapticEnabled
                existing[0].lastUsedMode = prefs.lastUsedMode
            } else {
                // Insert new
                modelContext.insert(prefs)
            }
        } catch {
            print("Error saving preferences: \(error)")
            modelContext.insert(prefs)
        }
        
        try? modelContext.save()
    }
    
    /// Update a single preference field
    /// - Parameters:
    ///   - field: The field to update (e.g., "defaultDifficulty", "nickname")
    ///   - value: The new value
    func updatePreference(field: String, value: Any) {
        let prefs = loadPreferences()
        
        switch field {
        case "defaultDifficulty":
            if let difficulty = value as? Difficulty {
                prefs.defaultDifficulty = difficulty.rawValue
            }
        case "nickname":
            if let nickname = value as? String {
                prefs.nickname = nickname
            }
        case "soundEnabled":
            if let enabled = value as? Bool {
                prefs.soundEnabled = enabled
            }
        case "hapticEnabled":
            if let enabled = value as? Bool {
                prefs.hapticEnabled = enabled
            }
        case "lastUsedMode":
            if let mode = value as? GameMode {
                prefs.lastUsedMode = mode.rawValue
            }
        default:
            break
        }
        
        savePreferences(prefs)
    }
    
    // MARK: - Game Session Operations
    
    /// Save a game session to the database
    /// - Parameter session: The GameSession to save
    func saveSession(_ session: GameSession) {
        modelContext.insert(session)
        try? modelContext.save()
    }
    
    /// Fetch recent game sessions, sorted by start time descending
    /// - Parameter limit: Maximum number of sessions to return (default: 20)
    /// - Returns: Array of GameSession objects sorted by date descending
    func fetchRecentSessions(limit: Int = 20) -> [GameSession] {
        let descriptor = FetchDescriptor<GameSession>(
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        
        do {
            let sessions = try modelContext.fetch(descriptor)
            return Array(sessions.prefix(limit))
        } catch {
            print("Error fetching sessions: \(error)")
            return []
        }
    }
    
    /// Fetch game sessions for a specific mode
    /// - Parameters:
    ///   - mode: The game mode to filter by
    ///   - limit: Maximum number of sessions to return
    /// - Returns: Array of GameSession objects for the specified mode
    func fetchSessions(for mode: GameMode, limit: Int = 20) -> [GameSession] {
        let modeString = mode.rawValue
        let descriptor = FetchDescriptor<GameSession>(
            predicate: #Predicate { $0.mode == modeString },
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        
        do {
            let sessions = try modelContext.fetch(descriptor)
            return Array(sessions.prefix(limit))
        } catch {
            print("Error fetching sessions: \(error)")
            return []
        }
    }
    
    /// Get average score across all sessions for a specific mode
    /// - Parameter mode: The game mode to analyze
    /// - Returns: Average score or 0 if no sessions exist
    func getAverageScore(for mode: GameMode) -> Double {
        let sessions = fetchSessions(for: mode, limit: 100)
        guard !sessions.isEmpty else { return 0 }
        
        let totalScore = sessions.reduce(0) { $0 + $1.score }
        return Double(totalScore) / Double(sessions.count)
    }
    
    /// Delete a specific game session
    /// - Parameter session: The GameSession to delete
    func deleteSession(_ session: GameSession) {
        modelContext.delete(session)
        try? modelContext.save()
    }
    
    /// Clear all game sessions older than a specified date
    /// - Parameter before: Only delete sessions started before this date
    func clearOldSessions(before date: Date) {
        let descriptor = FetchDescriptor<GameSession>(
            predicate: #Predicate { $0.startedAt < date }
        )
        
        do {
            let oldSessions = try modelContext.fetch(descriptor)
            for session in oldSessions {
                modelContext.delete(session)
            }
            try modelContext.save()
        } catch {
            print("Error clearing old sessions: \(error)")
        }
    }
    
    // MARK: - Utility Methods
    
    /// Get comprehensive statistics for a game mode
    /// - Parameter mode: The game mode to analyze
    /// - Returns: Dictionary with keys: "topScore", "averageScore", "totalSessions", "accuracy"
    func getStats(for mode: GameMode) -> [String: Double] {
        let sessions = fetchSessions(for: mode, limit: 100)
        let leaderboard = fetchLeaderboard(mode: mode, limit: 1)
        
        let topScore = leaderboard.first?.score ?? 0
        let totalSessions = Double(sessions.count)
        
        let totalCorrect = sessions.reduce(0) { $0 + $1.correctAnswers }
        let totalAttempts = sessions.reduce(0) { $0 + $1.totalQuestions }
        
        let accuracy = totalAttempts > 0
            ? Double(totalCorrect) / Double(totalAttempts) * 100
            : 0
        
        let averageScore = totalSessions > 0
            ? Double(sessions.reduce(0) { $0 + $1.score }) / totalSessions
            : 0
        
        return [
            "topScore": Double(topScore),
            "averageScore": averageScore,
            "totalSessions": totalSessions,
            "accuracy": accuracy
        ]
    }
    
    /// Clear all data from the database
    /// Warning: This is irreversible
    func clearAllData() {
        // Clear all leaderboard entries
        let leaderboardDescriptor = FetchDescriptor<LeaderboardEntry>()
        do {
            let entries = try modelContext.fetch(leaderboardDescriptor)
            for entry in entries {
                modelContext.delete(entry)
            }
        } catch {
            print("Error clearing leaderboard: \(error)")
        }
        
        // Clear all game sessions
        let sessionDescriptor = FetchDescriptor<GameSession>()
        do {
            let sessions = try modelContext.fetch(sessionDescriptor)
            for session in sessions {
                modelContext.delete(session)
            }
        } catch {
            print("Error clearing sessions: \(error)")
        }
        
        // Reset preferences to defaults
        let prefDescriptor = FetchDescriptor<UserPreferences>()
        do {
            let prefs = try modelContext.fetch(prefDescriptor)
            for pref in prefs {
                modelContext.delete(pref)
            }
        } catch {
            print("Error clearing preferences: \(error)")
        }
        
        try? modelContext.save()
    }
}

// MARK: - Singleton Instance

/// Global singleton instance of PersistenceService
/// Will be initialized once in the app
private var _persistenceService: PersistenceService?

/// Get or create the global PersistenceService instance
/// - Parameter modelContext: The SwiftData ModelContext
/// - Returns: The singleton PersistenceService instance
func getPersistenceService(with modelContext: ModelContext) -> PersistenceService {
    if let existing = _persistenceService {
        return existing
    }
    
    let service = PersistenceService(modelContext: modelContext)
    _persistenceService = service
    return service
}
