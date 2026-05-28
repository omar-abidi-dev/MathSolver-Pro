import SwiftUI

/// Input view for entering mathematical equations
/// Provides text field, difficulty selector, and validation feedback
/// Supports both single equations and systems (comma or newline separated)
struct EquationInputView: View {
    @Binding var equationText: String
    @Binding var selectedDifficulty: Difficulty
    @Binding var errorMessage: String?
    @Binding var detectedType: EquationType
    
    let onSolve: () -> Void
    
    @State private var showKeyboard = false
    @State private var showSystemInput = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Title
            HStack {
                Text("Enter an Equation")
                    .font(.headline)
                
                Spacer()
                
                // Type badge
                HStack(spacing: 6) {
                    Image(systemName: typeIcon)
                        .font(.caption)
                    Text(detectedType.displayName)
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .padding(6)
                .background(typeColor.opacity(0.2))
                .foregroundColor(typeColor)
                .cornerRadius(6)
            }
            
            // System toggle
            Toggle("System of Equations", isOn: $showSystemInput)
                .tint(.blue)
            
            // Equation input field(s)
            VStack(alignment: .leading, spacing: 8) {
                if showSystemInput {
                    // System input: two equations
                    VStack(alignment: .leading, spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Equation 1")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            TextField("e.g., x + y = 10", text: .constant(""))
                                .font(.system(.body, design: .monospaced))
                                .padding(12)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                                .textInputAutocapitalization(.never)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Equation 2")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            TextField("e.g., x - y = 2", text: .constant(""))
                                .font(.system(.body, design: .monospaced))
                                .padding(12)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                                .textInputAutocapitalization(.never)
                        }
                    }
                    
                    Text("Tip: Or enter as 'x + y = 10, x - y = 2' in single field")
                        .font(.caption)
                        .foregroundColor(.gray)
                } else {
                    // Single equation
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Equation")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        TextField("e.g., 2x + 5 = 15", text: $equationText)
                            .font(.system(.title3, design: .monospaced))
                            .padding(12)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .textInputAutocapitalization(.never)
                            .onTapGesture {
                                showKeyboard = true
                            }
                        
                        // Input hints
                        Text("Use: x for variable, +, -, ×, ÷, ^, =, ( )")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            // Keyboard toggle button
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
            
            // Show keyboard if toggled
            if showKeyboard {
                MathKeyboard(text: $equationText, onDone: { showKeyboard = false })
                    .transition(.move(edge: .bottom))
            }
            
            // Error message
            if let error = errorMessage {
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.red)
                    
                    VStack(alignment: .leading) {
                        Text("Error")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        Text(error)
                            .font(.caption)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                }
                .padding(12)
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            }
            
            // Solve button
            Button(action: onSolve) {
                HStack(spacing: 12) {
                    Image(systemName: "sparkles.rectangle.stack")
                    Text("Solve Equation")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(16)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(equationText.trimmingCharacters(in: .whitespaces).isEmpty)
            .opacity(equationText.trimmingCharacters(in: .whitespaces).isEmpty ? 0.6 : 1.0)
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .onChange(of: equationText) {
            updateDetectedType()
        }
    }
    
    private var typeIcon: String {
        switch detectedType {
        case .linear:
            return "line.diagonal"
        case .quadratic:
            return "function"
        case .system:
            return "square.grid.2x2"
        case .trigonometric:
            return "waveform.circle"
        case .logarithmic:
            return "log.text"
        case .polynomial:
            return "function"
        case .derivative:
            return "d.square"
        case .integral:
            return "integral"
        case .statistics:
            return "chart.bar"
        case .physics:
            return "atom"
        }
    }
    
    private var typeColor: Color {
        switch detectedType {
        case .linear:
            return .blue
        case .quadratic:
            return .purple
        case .system:
            return .green
        case .trigonometric:
            return .orange
        case .logarithmic:
            return .red
        case .polynomial:
            return .indigo
        case .derivative:
            return .cyan
        case .integral:
            return .mint
        case .statistics:
            return .teal
        case .physics:
            return .brown
        }
    }
    
    private func updateDetectedType() {
        let trimmed = equationText.trimmingCharacters(in: .whitespaces)
        let lower = trimmed.lowercased()
        
        // Check for system (comma separated)
        if trimmed.contains(",") {
            detectedType = .system
            return
        }
        
        // Check for derivative indicators
        if lower.contains("d/dx") || lower.contains("dy/dx") || 
           lower.contains("derivative") || lower.contains("diff") ||
           trimmed.range(of: "[a-zA-Z]'\\(", options: .regularExpression) != nil {
            detectedType = .derivative
            return
        }
        
        // Check for integral indicators
        if lower.contains("∫") || lower.contains("integral") || lower.contains("∫") {
            detectedType = .integral
            return
        }
        
        // Check for trigonometric
        if lower.contains("sin") || lower.contains("cos") || lower.contains("tan") ||
           lower.contains("csc") || lower.contains("sec") || lower.contains("cot") ||
           lower.contains("sinh") || lower.contains("cosh") || lower.contains("tanh") ||
           lower.contains("arcsin") || lower.contains("arccos") || lower.contains("arctan") ||
           lower.contains("asin") || lower.contains("acos") || lower.contains("atan") {
            detectedType = .trigonometric
            return
        }
        
        // Check for logarithmic
        if lower.contains("log") || lower.contains("ln") {
            detectedType = .logarithmic
            return
        }
        
        // Check for polynomial (^3 or higher, or fractional exponents)
        if trimmed.range(of: "\\^\\s*[3-9]", options: .regularExpression) != nil ||
           trimmed.range(of: "[³⁴⁵⁶⁷⁸⁹]", options: .regularExpression) != nil {
            detectedType = .polynomial
            return
        }
        
        // Check for quadratic (contains ^2 or ²)
        if trimmed.contains("^2") || trimmed.contains("²") ||
           trimmed.range(of: "x\\s*\\^\\s*2", options: .regularExpression) != nil {
            detectedType = .quadratic
            return
        }
        
        // Default to linear
        detectedType = .linear
    }
}

extension EquationType {
    var displayName: String {
        switch self {
        case .linear:
            return "Linear"
        case .quadratic:
            return "Quadratic"
        case .system:
            return "System"
        case .trigonometric:
            return "Trigonometric"
        case .logarithmic:
            return "Logarithmic"
        case .polynomial:
            return "Polynomial"
        case .derivative:
            return "Derivative"
        case .integral:
            return "Integral"
        case .statistics:
            return "Statistics"
        case .physics:
            return "Physics"
        }
    }
}

#Preview {
    EquationInputView(
        equationText: .constant("2x + 5 = 15"),
        selectedDifficulty: .constant(.intermediate),
        errorMessage: .constant(nil),
        detectedType: .constant(.linear),
        onSolve: { }
    )
    .padding()
}
