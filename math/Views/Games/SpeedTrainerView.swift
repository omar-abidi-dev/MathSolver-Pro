import SwiftUI
import SwiftData

/// Speed Trainer game view - timed practice with difficulty escalation
struct SpeedTrainerView: View {
    @StateObject private var gameService = GameService()
    @Environment(\.modelContext) private var modelContext
    @State private var timeRemaining: Int = 30
    @State private var timer: Timer?
    @State private var userAnswer: String = ""
    @State private var showFeedback: Bool = false
    @State private var isCorrect: Bool = false
    @State private var streak: Int = 0
    @State private var showSessionSummary: Bool = false
    @State private var selectedDifficulty: Difficulty = .intermediate
    
    // Custom keyboard support
    @State private var showKeyboard = false
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Header with timer and score
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Score")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text("\(gameService.score)")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .center, spacing: 8) {
                        Text("Time")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text("\(timeRemaining)s")
                            .font(.system(.title2, design: .monospaced))
                            .fontWeight(.bold)
                            .foregroundColor(timeRemaining < 10 ? .red : .green)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 8) {
                        Text("Streak")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text("\(streak)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                
                Spacer()
                
                // Equation display
                VStack(spacing: 24) {
                    Text("Solve:")
                        .font(.headline)
                        .foregroundColor(.gray)
                    
                    Text(gameService.currentEquation)
                        .font(.system(.title, design: .monospaced))
                        .fontWeight(.bold)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemBlue).opacity(0.1))
                        .cornerRadius(12)
                }
                .padding()
                
                Spacer()
                
                // Answer input
                VStack(spacing: 16) {
                    HStack {
                        Text("Your Answer")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Button(action: { showKeyboard.toggle() }) {
                            HStack(spacing: 8) {
                                Image(systemName: "keyboard")
                                Text(showKeyboard ? "Hide Keyboard" : "Show Keyboard")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(12)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(8)
                        }
                    }
                    
                    TextField("Your answer", text: $userAnswer)
                        .font(.title3)
                        .keyboardType(.decimalPad)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .disabled(showSessionSummary || !gameService.isSessionActive)
                        .onTapGesture {
                            showKeyboard = true
                        }
                    
                    Button(action: submitAnswer) {
                        Text("Submit")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .disabled(userAnswer.isEmpty || showSessionSummary || !gameService.isSessionActive)
                    
                    // Custom Numeric Keyboard
                    if showKeyboard {
                        CalculusNumKeyboard(
                            text: $userAnswer,
                            onDone: {
                                showKeyboard = false
                                submitAnswer()
                            }
                        )
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .transition(.move(edge: .bottom))
                    }
                }
                .padding()
            }
            
            // Feedback overlay
            if showFeedback {
                VStack {
                    Spacer()
                    
                    VStack(spacing: 12) {
                        Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(isCorrect ? .green : .red)
                        
                        Text(isCorrect ? "Correct!" : "Incorrect")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        if isCorrect {
                            Text("+\(10 + Int.random(in: 0...10)) points")
                                .font(.headline)
                                .foregroundColor(.green)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .padding()
                    
                    Spacer()
                }
                .transition(.scale)
            }
        }
        .onAppear {
            startGame()
        }
        .onDisappear {
            timer?.invalidate()
        }
        .sheet(isPresented: $showSessionSummary) {
            SessionSummaryView(
                score: gameService.score,
                totalQuestions: gameService.questionsAnswered,
                accuracy: gameService.currentSession?.accuracy ?? 0
            )
        }
    }
    
    private func startGame() {
        gameService.startSession(mode: .speedTrainer, difficulty: selectedDifficulty)
        startTimer()
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            timeRemaining -= 1
            if timeRemaining <= 0 {
                endGame()
            }
        }
    }
    
    private func submitAnswer() {
        let correct = gameService.submitAnswer(userAnswer)
        
        withAnimation(.spring()) {
            isCorrect = correct
            showFeedback = true
            
            if correct {
                streak += 1
            } else {
                streak = 0
            }
        }
        
        userAnswer = ""
        
        // Show feedback for 1 second, then next question
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation {
                showFeedback = false
                gameService.nextQuestion(mode: .speedTrainer)
            }
        }
    }
    
    private func endGame() {
        timer?.invalidate()
        
        let finalSession = gameService.endSession()
        
        // Save to leaderboard
        if let session = finalSession {
            let entry = LeaderboardEntry(
                nickname: "Player",
                score: gameService.score,
                gameMode: .speedTrainer,
                difficulty: selectedDifficulty,
                accuracy: session.accuracy,
                date: Date()
            )
            
            modelContext.insert(entry)
            try? modelContext.save()
        }
        
        showSessionSummary = true
    }
}

/// Session summary after game ends
struct SessionSummaryView: View {
    let score: Int
    let totalQuestions: Int
    let accuracy: Double
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Session Complete!")
                    .font(.title)
                    .fontWeight(.bold)
                
                VStack(spacing: 16) {
                    SummaryRow(label: "Final Score", value: "\(score)")
                    SummaryRow(label: "Questions", value: "\(totalQuestions)")
                    SummaryRow(label: "Accuracy", value: String(format: "%.1f%%", accuracy))
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Text("Back to Home")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct SummaryRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .fontWeight(.bold)
        }
    }
}

#Preview {
    SpeedTrainerView()
}
