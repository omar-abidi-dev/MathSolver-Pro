import SwiftUI

/// Tracks which input field is focused in the Debugger view
enum DebuggerFieldType: Hashable {
    case equation
    case step(Int)
}

/// View for students to debug their algebra work step-by-step
struct DebuggerView: View {
    @State private var equationText = ""
    @State private var steps: [String] = ["", ""]
    @State private var validationResult: UserAttempt?
    @State private var isChecking = false
    @State private var errorMessage: String?
    @State private var showKeyboard = false
    @State private var focusedField: DebuggerFieldType?
    
    private var currentFieldBinding: Binding<String> {
        switch focusedField {
        case .equation:
            return $equationText
        case .step(let index):
            return Binding(
                get: { steps.indices.contains(index) ? steps[index] : "" },
                set: { if steps.indices.contains(index) { steps[index] = $0 } }
            )
        case nil:
            return $equationText
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                // Header
                VStack(spacing: 8) {
                    Text("Check My Work")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Enter the problem and your solution steps")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Equation input
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Original Equation")
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
                        }
                        
                        Divider()
                        
                        // Steps input
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Your Work Steps")
                                    .font(.headline)
                                
                                Spacer()
                                
                                Button(action: addStep) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "plus.circle.fill")
                                        Text("Add Step")
                                    }
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                }
                            }
                            
                            ForEach(steps.indices, id: \.self) { index in
                                HStack(spacing: 12) {
                                    Text("Step \(index + 1)")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                        .frame(width: 50)
                                    
                                    TextField("e.g., 2x = 10", text: $steps[index])
                                        .textFieldStyle(.roundedBorder)
                                        .font(.system(.body, design: .monospaced))
                                        .onTapGesture {
                                            focusedField = .step(index)
                                            showKeyboard = true
                                        }
                                    
                                    if steps.count > 2 {
                                        Button(action: { removeStep(at: index) }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.red)
                                        }
                                    }
                                }
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
                        
                        // Error display
                        if let error = errorMessage {
                            HStack(spacing: 12) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundColor(.red)
                                Text(error)
                                    .font(.caption)
                                    .lineLimit(2)
                            }
                            .padding(12)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    .padding(16)
                }
                
                // Check button
                Button(action: checkWork) {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Check My Work")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(16)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(equationText.isEmpty || isChecking)
                .opacity(equationText.isEmpty ? 0.6 : 1.0)
                .padding(16)
                
                // Math Keyboard
                if showKeyboard {
                    VStack(spacing: 0) {
                        Divider()
                        MathKeyboard(
                            text: currentFieldBinding,
                            onDone: { showKeyboard = false }
                        )
                        .background(Color(.systemGray6))
                    }
                    .frame(height: 280)
                }
            }
            .navigationTitle("Equation Debugger")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $validationResult) { result in
                ErrorResultView(attempt: result)
            }
        }
    }
    
    private func addStep() {
        steps.append("")
    }
    
    private func removeStep(at index: Int) {
        steps.remove(at: index)
    }
    
    private func checkWork() {
        guard !equationText.isEmpty else {
            errorMessage = "Please enter an equation"
            return
        }
        
        guard !steps.allSatisfy({ $0.trimmingCharacters(in: .whitespaces).isEmpty }) else {
            errorMessage = "Please enter at least one step"
            return
        }
        
        isChecking = true
        errorMessage = nil
        
        // Simulate validation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            do {
                // Create a dummy equation (in real app, would parse properly)
                let equation = Equation(
                    rawInput: equationText,
                    equationType: .linear,
                    leftExpression: .variable("x"),
                    rightExpression: .constant(0)
                )
                
                // Create attempt from user input
                let attemptSteps = steps
                    .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
                    .enumerated()
                    .map { AttemptStep(stepNumber: $0.offset + 1, rawInput: $0.element) }
                
                let attempt = UserAttempt(equation: equation, steps: attemptSteps)
                
                // Validate (simplified - in real app, uses correct SolutionStep comparison)
                let validator = StepValidator()
                let validatedAttempt = validator.validate(attempt: attempt, correctSteps: [])
                
                validationResult = validatedAttempt
                isChecking = false
            } catch {
                errorMessage = error.localizedDescription
                isChecking = false
            }
        }
    }
}

#Preview {
    DebuggerView()
}
