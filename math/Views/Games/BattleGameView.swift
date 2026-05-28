import SwiftUI
import SwiftData

/// Battle game view - defeat enemies by solving equations
struct BattleGameView: View {
    @StateObject private var gameService = GameService()
    @Environment(\.modelContext) private var modelContext
    @State private var battleState = BattleState()
    @State private var isGameStarted = false
    @State private var selectedDifficulty: Difficulty = .intermediate
    @State private var userAnswer: String = ""
    @State private var showFeedback = false
    @State private var feedbackMessage = ""
    @State private var feedbackColor = Color.green
    @State private var damageAnimation = false
    @State private var showBattleOver = false
    
    // Custom keyboard support
    @State private var showKeyboard = false
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            if !isGameStarted {
                // Battle start screen
                startBattleView
            } else {
                // Active battle view
                activeBattleView
            }
            
            // Damage feedback
            if damageAnimation {
                VStack {
                    Text("-\(battleState.enemy.currentHealth == 0 ? 50 : 25)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                        .offset(y: -50)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .sheet(isPresented: $showBattleOver) {
            BattleSummaryView(
                battleState: battleState,
                isVictory: battleState.enemy.currentHealth == 0 || battleState.enemies.count > 0
            )
        }
    }
    
    private var startBattleView: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    Image(systemName: "gamecontroller.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.pink)
                    
                    Text("Battle Mode")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Defeat enemies by solving equations")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Select Difficulty")
                        .font(.headline)
                    
                    Picker("Difficulty", selection: $selectedDifficulty) {
                        ForEach(Difficulty.allCases, id: \.self) { difficulty in
                            Text(difficulty.rawValue.capitalized).tag(difficulty)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .padding()
                
                Button(action: startBattle) {
                    Text("Start Battle")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.pink)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding()
                
                Spacer()
            }
            .navigationTitle("Battle")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private var activeBattleView: some View {
        VStack(spacing: 16) {
            // Header with score and round
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Level")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("\(battleState.currentRound)")
                        .font(.headline)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                VStack(alignment: .center, spacing: 4) {
                    Text("Score")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("\(battleState.score)")
                        .font(.headline)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Enemies")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("\(battleState.enemies.count)")
                        .font(.headline)
                        .fontWeight(.bold)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            
            // Player health bar
            VStack(spacing: 4) {
                HStack {
                    Text("Your Health")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Spacer()
                    Text("\(battleState.playerHealth)/\(battleState.maxPlayerHealth)")
                        .font(.caption)
                        .fontWeight(.bold)
                }
                
                ProgressView(value: battleState.playerHealthPercentage)
                    .tint(.green)
            }
            .padding()
            
            // Enemy display
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: battleState.enemy.icon)
                                .font(.system(size: 32))
                            VStack(alignment: .leading) {
                                Text(battleState.enemy.name)
                                    .font(.headline)
                                    .fontWeight(.bold)
                                Text("Level \(battleState.enemy.level)")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    
                    Spacer()
                }
                
                VStack(spacing: 4) {
                    HStack {
                        Text("Enemy Health")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Spacer()
                        Text("\(battleState.enemy.currentHealth)/\(battleState.enemy.maxHealth)")
                            .font(.caption)
                            .fontWeight(.bold)
                    }
                    
                    ProgressView(value: battleState.enemy.healthPercentage)
                        .tint(.red)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            // Equation display
            VStack(spacing: 12) {
                Text("Solve:")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Text(gameService.currentEquation)
                    .font(.system(.title2, design: .monospaced))
                    .fontWeight(.bold)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
            }
            .padding()
            
            // Answer input
            VStack(spacing: 12) {
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
                    .disabled(showBattleOver)
                    .onTapGesture {
                        showKeyboard = true
                    }
                
                Button(action: submitAnswer) {
                    Text("Attack!")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.pink)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .disabled(userAnswer.isEmpty || showBattleOver)
                
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
            
            Spacer()
            
            if showFeedback {
                Text(feedbackMessage)
                    .font(.headline)
                    .foregroundColor(feedbackColor)
                    .transition(.opacity)
            }
        }
    }
    
    private func startBattle() {
        battleState = BattleState(startingDifficulty: selectedDifficulty)
        gameService.startSession(mode: .battle, difficulty: selectedDifficulty)
        isGameStarted = true
    }
    
    private func submitAnswer() {
        let isCorrect = gameService.submitAnswer(userAnswer)
        
        withAnimation(.easeInOut(duration: 0.5)) {
            if isCorrect {
                feedbackMessage = "Correct! Attack!"
                feedbackColor = .green
                let damage = 25 + Int.random(in: 0...10)
                battleState.attackEnemy(damage: damage)
                damageAnimation = true
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                    withAnimation {
                        damageAnimation = false
                    }
                }
                
                if battleState.enemy.currentHealth > 0 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        battleState.enemyCounterAttack()
                        if !battleState.isPlayerAlive {
                            endBattle()
                        }
                    }
                }
            } else {
                feedbackMessage = "Incorrect! Enemy attacks!"
                feedbackColor = .red
                battleState.handleWrongAnswer()
                
                if !battleState.isPlayerAlive {
                    endBattle()
                }
            }
            
            showFeedback = true
        }
        
        userAnswer = ""
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                showFeedback = false
                gameService.nextQuestion(mode: .battle)
            }
        }
    }
    
    private func endBattle() {
        let _ = gameService.endSession()
        let entry = LeaderboardEntry(
            nickname: "Warrior",
            score: battleState.score,
            gameMode: .battle,
            difficulty: selectedDifficulty,
            accuracy: Double(battleState.correctAnswersInBattle) / Double(max(1, battleState.totalAttacks)) * 100,
            date: Date()
        )
        modelContext.insert(entry)
        try? modelContext.save()
        
        showBattleOver = true
    }
}

struct BattleSummaryView: View {
    let battleState: BattleState
    let isVictory: Bool
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if isVictory {
                    VStack(spacing: 12) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.yellow)
                        Text("Victory!")
                            .font(.title)
                            .fontWeight(.bold)
                    }
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.red)
                        Text("Defeated")
                            .font(.title)
                            .fontWeight(.bold)
                    }
                }
                
                VStack(spacing: 16) {
                    SummaryRow(label: "Final Score", value: "\(battleState.score)")
                    SummaryRow(label: "Enemies Defeated", value: "\(battleState.enemies.count)")
                    SummaryRow(label: "Highest Level", value: "\(battleState.currentRound)")
                    SummaryRow(label: "Accuracy", value: String(format: "%.1f%%", Double(battleState.correctAnswersInBattle) / Double(max(1, battleState.totalAttacks)) * 100))
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
                        .background(Color.pink)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    BattleGameView()
}
