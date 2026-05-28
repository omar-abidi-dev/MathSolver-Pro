import Foundation
import Combine

/// Manages game sessions, generates questions, validates answers, and tracks scores
class GameService: ObservableObject {
    @Published var currentSession: ActiveSession?
    @Published var currentEquation: String = ""
    @Published var currentAnswers: [String] = []
    @Published var score: Int = 0
    @Published var questionsAnswered: Int = 0
    @Published var isSessionActive: Bool = false
    
    private let difficultyProgression = [Difficulty.beginner, .intermediate, .advanced]
    private let equationTypes = [EquationType.linear, .quadratic]
    
    /// Starts a new game session
    func startSession(mode: GameMode, difficulty: Difficulty) {
        let session = ActiveSession(
            mode: mode,
            difficulty: difficulty
        )
        
        self.currentSession = session
        self.score = 0
        self.questionsAnswered = 0
        self.isSessionActive = true
        
        generateNextQuestion(difficulty: difficulty)
    }
    
    /// Generates the next question based on difficulty
    private func generateNextQuestion(difficulty: Difficulty) {
        let equationType = equationTypes.randomElement() ?? .linear
        let (equation, answers) = EquationGenerator.generate(type: equationType, difficulty: difficulty)
        
        currentEquation = equation
        currentAnswers = answers
    }
    
    /// Validates user answer and returns whether it's correct
    func submitAnswer(_ userAnswer: String) -> Bool {
        let isCorrect = validateAnswer(userAnswer)
        
        questionsAnswered += 1
        
        if isCorrect {
            let points = calculatePoints(difficulty: currentSession?.difficulty ?? .intermediate)
            score += points
            currentSession?.correctAnswers += 1
        }
        
        currentSession?.totalQuestions += 1
        
        return isCorrect
    }
    
    /// Checks if user answer matches expected answer
    private func validateAnswer(_ userAnswer: String) -> Bool {
        let trimmed = userAnswer.trimmingCharacters(in: .whitespaces).lowercased()
        
        for answer in currentAnswers {
            if trimmed == answer.lowercased() {
                return true
            }
            
            // Allow floating point variations
            if let userNum = Double(trimmed), let expectedNum = Double(answer) {
                if abs(userNum - expectedNum) < 0.01 {
                    return true
                }
            }
        }
        
        return false
    }
    
    /// Calculates points based on difficulty and speed bonus
    private func calculatePoints(difficulty: Difficulty) -> Int {
        let basePoints: Int
        switch difficulty {
        case .beginner:
            basePoints = 10
        case .intermediate:
            basePoints = 25
        case .advanced:
            basePoints = 50
        }
        
        let speedBonus = Int.random(in: 0...10)
        return basePoints + speedBonus
    }
    
    /// Proceeds to next question, escalating difficulty if in speed trainer
    func nextQuestion(mode: GameMode) {
        let nextDifficulty = getNextDifficulty(currentDifficulty: currentSession?.difficulty ?? .beginner, mode: mode)
        generateNextQuestion(difficulty: nextDifficulty)
    }
    
    /// Determines next difficulty level
    private func getNextDifficulty(currentDifficulty: Difficulty, mode: GameMode) -> Difficulty {
        switch mode {
        case .speedTrainer:
            if currentSession?.correctAnswers ?? 0 > 0 && (currentSession?.correctAnswers ?? 0) % 5 == 0 {
                let currentIndex = difficultyProgression.firstIndex(of: currentDifficulty) ?? 0
                if currentIndex < difficultyProgression.count - 1 {
                    return difficultyProgression[currentIndex + 1]
                }
            }
            return currentDifficulty
            
        case .battle:
            return currentDifficulty == .beginner ? .intermediate : .advanced
        }
    }
    
    /// Ends the current game session and returns it
    func endSession() -> ActiveSession? {
        guard var session = currentSession else { return nil }
        
        session.completedAt = Date()
        session.timeElapsed = Date().timeIntervalSince(session.startedAt)
        
        isSessionActive = false
        return session
    }
}

/// Lightweight runtime session (not persisted — use GameSession SwiftData model for persistence)
struct ActiveSession {
    let id: UUID = UUID()
    let mode: GameMode
    var difficulty: Difficulty
    var score: Int = 0
    var totalQuestions: Int = 0
    var correctAnswers: Int = 0
    var timeElapsed: TimeInterval = 0
    let startedAt: Date = Date()
    var completedAt: Date?
    
    var accuracy: Double {
        guard totalQuestions > 0 else { return 0 }
        return Double(correctAnswers) / Double(totalQuestions) * 100
    }
}
