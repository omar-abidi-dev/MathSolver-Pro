import SwiftUI

/// Homework helper view with progressive hints and step validation
struct HomeworkHelperView: View {
    @State private var equationText = ""
    @State private var currentStepIndex = 0
    @State private var userStepText = ""
    @State private var hintsShown = 0
    @State private var attemptCount = 0
    @State private var isStepCorrect: Bool?
    @State private var errorMessage: String?
    @State private var steps: [SolutionStep] = []
    @State private var showCorrectAnswer = false
    
    // Custom keyboard support
    enum HomeworkFieldType { case equation, step }
    @State private var showKeyboard = false
    @State private var focusedField: HomeworkFieldType?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                // Header
                VStack(spacing: 8) {
                    Text("Homework Helper")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Practice with hints and guidance")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Equation input (if no steps loaded yet)
                        if steps.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Enter Equation")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                }
                                
                                TextField("e.g., 2x + 5 = 15", text: $equationText)
                                    .textFieldStyle(.roundedBorder)
                                    .font(.system(.body, design: .monospaced))
                                    .onTapGesture {
                                        focusedField = .equation
                                        showKeyboard = true
                                    }
                                
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
                                
                                if let error = errorMessage {
                                    HStack(spacing: 8) {
                                        Image(systemName: "exclamationmark.circle.fill")
                                            .foregroundColor(.red)
                                        Text(error)
                                            .font(.caption)
                                    }
                                    .padding(8)
                                    .background(Color.red.opacity(0.1))
                                    .cornerRadius(6)
                                }
                                
                                Button(action: loadSteps) {
                                    HStack {
                                        Image(systemName: "book.circle.fill")
                                        Text("Start Practice")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(12)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                                }
                            }
                            .padding(16)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        } else {
                            // Step-by-step practice
                            VStack(alignment: .leading, spacing: 12) {
                                // Progress
                                HStack {
                                    Text("Step \(currentStepIndex + 1) of \(steps.count)")
                                        .font(.headline)
                                    
                                    Spacer()
                                    
                                    Text("\(Int(Double(currentStepIndex) / Double(steps.count) * 100))%")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                
                                // Current step guidance
                                if currentStepIndex < steps.count {
                                    let step = steps[currentStepIndex]
                                    
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("What's the next step?")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                        
                                        Text(step.description)
                                            .font(.headline)
                                        
                                        Text("Result: \(step.resultEquation)")
                                            .font(.system(.caption, design: .monospaced))
                                            .padding(8)
                                            .background(Color.blue.opacity(0.1))
                                            .cornerRadius(6)
                                    }
                                    .padding(12)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                                }
                                
                                // Hints section
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Need help?")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    
                                    HStack(spacing: 8) {
                                        ForEach(1...3, id: \.self) { level in
                                            Button(action: { showHint(level: level) }) {
                                                Text("Hint \(level)")
                                                    .font(.caption)
                                                    .frame(maxWidth: .infinity)
                                                    .padding(8)
                                                    .background(hintsShown >= level ? Color.yellow.opacity(0.3) : Color.gray.opacity(0.2))
                                                    .foregroundColor(.primary)
                                                    .cornerRadius(6)
                                            }
                                            .disabled(attemptCount > 2 && level == 3)
                                        }
                                    }
                                    
                                    if hintsShown > 0 && currentStepIndex < steps.count {
                                        Text(getHintText(level: min(hintsShown, 3)))
                                            .font(.caption)
                                            .italic()
                                            .padding(8)
                                            .background(Color.yellow.opacity(0.1))
                                            .cornerRadius(6)
                                    }
                                }
                                
                                // User input
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("Your Answer")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                        
                                    }
                                    
                                    TextField("Type your step...", text: $userStepText)
                                        .textFieldStyle(.roundedBorder)
                                        .font(.system(.body, design: .monospaced))
                                        .onTapGesture {
                                            focusedField = .step
                                            showKeyboard = true
                                        }
                                    
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
                                
                                // Feedback
                                if let isCorrect = isStepCorrect {
                                    if isCorrect {
                                        HStack(spacing: 8) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.green)
                                            Text("Correct!")
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                        }
                                        .padding(8)
                                        .background(Color.green.opacity(0.1))
                                        .cornerRadius(6)
                                    } else {
                                        VStack(alignment: .leading, spacing: 8) {
                                            HStack(spacing: 8) {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundColor(.red)
                                                Text("Not quite right")
                                                    .font(.subheadline)
                                                    .fontWeight(.semibold)
                                            }
                                            
                                            if attemptCount >= 2 && !showCorrectAnswer {
                                                Button(action: { showCorrectAnswer = true }) {
                                                    Text("Show me the answer")
                                                        .font(.caption)
                                                        .foregroundColor(.blue)
                                                }
                                            } else if showCorrectAnswer {
                                                Text("The correct step is: \(steps[currentStepIndex].resultEquation)")
                                                    .font(.caption)
                                            }
                                        }
                                        .padding(8)
                                        .background(Color.red.opacity(0.1))
                                        .cornerRadius(6)
                                    }
                                }
                                
                                // Action buttons
                                HStack(spacing: 12) {
                                    Button(action: checkStep) {
                                        HStack {
                                            Image(systemName: "checkmark.circle")
                                            Text("Check")
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(12)
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                    }
                                    
                                    if isStepCorrect == true && currentStepIndex < steps.count - 1 {
                                        Button(action: nextStep) {
                                            HStack {
                                                Text("Next")
                                                Image(systemName: "chevron.right")
                                            }
                                            .frame(maxWidth: .infinity)
                                            .padding(12)
                                            .background(Color.green)
                                            .foregroundColor(.white)
                                            .cornerRadius(8)
                                        }
                                    }
                                }
                            }
                            .padding(16)
                        }
                    }
                    .padding(16)
                }
                
                Spacer()
                
                // Custom Math Keyboard
                if showKeyboard {
                    MathKeyboard(
                        text: focusedField == .equation ? $equationText : $userStepText,
                        onDone: { showKeyboard = false }
                    )
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .transition(.move(edge: .bottom))
                }
            }
            .navigationTitle("Homework Help")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func loadSteps() {
        guard !equationText.isEmpty else {
            errorMessage = "Please enter an equation"
            return
        }
        
        errorMessage = nil
        
        // Create sample steps for demo
        steps = [
            SolutionStep(
                stepNumber: 1,
                operation: .subtractBothSides(5),
                description: "Subtract 5 from both sides",
                resultEquation: "2x = 10",
                explanation: "We move the constant term to the right side."
            ),
            SolutionStep(
                stepNumber: 2,
                operation: .divideBothSides(2),
                description: "Divide both sides by 2",
                resultEquation: "x = 5",
                explanation: "We divide by the coefficient to isolate x."
            )
        ]
        
        currentStepIndex = 0
        hintsShown = 0
        attemptCount = 0
        isStepCorrect = nil
        userStepText = ""
        showCorrectAnswer = false
    }
    
    private func checkStep() {
        if currentStepIndex >= steps.count {
            return
        }
        
        attemptCount += 1
        
        // Simple validation - check if user's answer matches expected
        let expectedResult = steps[currentStepIndex].resultEquation
        let userInputMatches = userStepText.trimmingCharacters(in: .whitespaces).lowercased() == expectedResult.lowercased()
        
        isStepCorrect = userInputMatches
        
        if !userInputMatches && attemptCount >= 3 {
            showCorrectAnswer = true
        }
    }
    
    private func nextStep() {
        currentStepIndex += 1
        hintsShown = 0
        attemptCount = 0
        isStepCorrect = nil
        userStepText = ""
        showCorrectAnswer = false
    }
    
    private func showHint(level: Int) {
        if level > hintsShown {
            hintsShown = level
        }
    }
    
    private func getHintText(level: Int) -> String {
        if currentStepIndex >= steps.count { return "" }
        return stepExplainer.generateHint(for: steps[currentStepIndex], level: level)
    }
}

#Preview {
    HomeworkHelperView()
}
