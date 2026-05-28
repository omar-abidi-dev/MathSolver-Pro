import SwiftUI

/// Calculus solver hub - main entry point for limits, derivatives, and integrals
struct CalculusView: View {
    @State private var selectedMode: CalculusMode = .limits
    @State private var expression: String = ""
    @State private var variable: String = "x"
    @State private var approachValue: String = ""
    @State private var lowerBound: String = ""
    @State private var upperBound: String = ""
    @State private var isDefinite: Bool = false
    @State private var solution: CalcSolution?
    @State private var errorMessage: String?
    @State private var isSolving = false
    @State private var showSolution = false
    
    // Keyboard state management
    @State private var focusedField: CalculusFieldType?
    @State private var showKeyboard = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 20) {
                        // Mode Picker
                        Picker("Calculus Mode", selection: $selectedMode) {
                            ForEach(CalculusMode.allCases, id: \.self) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(16)
                        
                        // Mode-specific inputs
                        VStack(alignment: .leading, spacing: 12) {
                            // Expression input (same for all modes)
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Expression")
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
                                
                                TextField("e.g., 3x^2 + 5x", text: $expression)
                                    .padding(12)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                                    .onTapGesture {
                                        focusedField = .expression
                                        showKeyboard = true
                                    }
                            }
                            
                            // Variable input
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Variable")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                
                                TextField("x", text: $variable)
                                    .padding(12)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                                    .frame(maxWidth: 60)
                                    .onTapGesture {
                                        focusedField = .variable
                                        showKeyboard = true
                                    }
                            }
                            
                            // Mode-specific inputs
                            if selectedMode == .limits {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Approach Value")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    
                                    TextField("e.g., 1 or 0", text: $approachValue)
                                        .padding(12)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(8)
                                        .onTapGesture {
                                            focusedField = .approachValue
                                            showKeyboard = true
                                        }
                                }
                            } else if selectedMode == .integrals {
                                VStack(alignment: .leading, spacing: 8) {
                                    Toggle("Definite Integral", isOn: $isDefinite)
                                    
                                    if isDefinite {
                                        HStack(spacing: 12) {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text("Lower Bound")
                                                    .font(.caption)
                                                TextField("a", text: $lowerBound)
                                                    .padding(8)
                                                    .background(Color(.systemGray6))
                                                    .cornerRadius(6)
                                                    .onTapGesture {
                                                        focusedField = .lowerBound
                                                        showKeyboard = true
                                                    }
                                            }
                                            
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text("Upper Bound")
                                                    .font(.caption)
                                                TextField("b", text: $upperBound)
                                                    .padding(8)
                                                    .background(Color(.systemGray6))
                                                    .cornerRadius(6)
                                                    .onTapGesture {
                                                        focusedField = .upperBound
                                                        showKeyboard = true
                                                    }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(16)
                        
                        // Error message
                        if let error = errorMessage {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 12) {
                                    Image(systemName: "exclamationmark.circle.fill")
                                        .foregroundColor(.red)
                                    Text(error)
                                        .font(.subheadline)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(12)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(8)
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                    .padding(.vertical, 16)
                }
                .frame(maxHeight: .infinity)
                
                // Solve Button
                VStack(spacing: 12) {
                    Button(action: solve) {
                        HStack {
                            Image(systemName: "function")
                            Text("Solve")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.indigo)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .disabled(expression.isEmpty || isSolving)
                    .opacity(expression.isEmpty ? 0.6 : 1.0)
                }
                .padding(16)
                .frame(maxWidth: .infinity)
                
                // Custom Keyboard
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
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Calculus Solver")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $showSolution) {
                if let solution = solution {
                    CalculusSolutionView(solution: solution)
                }
            }
        }
    }
    
    private func solve() {
        errorMessage = nil
        
        guard !expression.isEmpty else {
            errorMessage = "Please enter an expression"
            return
        }
        
        isSolving = true
        
        // Parse expression using EquationParser
        guard let parsedExpr = parseExpression(expression) else {
            errorMessage = "Invalid expression"
            isSolving = false
            return
        }
        
        // Solve based on mode
        switch selectedMode {
        case .limits:
            guard let approachVal = Double(approachValue) else {
                errorMessage = "Invalid approach value"
                isSolving = false
                return
            }
            let result = LimitsSolver.solve(
                expression: parsedExpr,
                variable: variable,
                approachValue: approachVal
            )
            handleResult(result)
            
        case .derivatives:
            let result = DerivativeSolver.solve(
                expression: parsedExpr,
                variable: variable
            )
            handleResult(result)
            
        case .integrals:
            let lower = isDefinite ? Double(lowerBound) : nil
            let upper = isDefinite ? Double(upperBound) : nil
            
            if isDefinite && (lower == nil || upper == nil) {
                errorMessage = "Invalid bounds"
                isSolving = false
                return
            }
            
            let result = IntegralSolver.solve(
                expression: parsedExpr,
                variable: variable,
                lowerBound: lower,
                upperBound: upper
            )
            handleResult(result)
        }
        
        isSolving = false
    }
    
    private func handleResult(_ result: Result<CalcSolution, CalcSolverError>) {
        switch result {
        case .success(let sol):
            self.solution = sol
            self.showSolution = true
        case .failure(let error):
            self.errorMessage = "Error: \(error)"
        }
    }
    
    private func parseExpression(_ text: String) -> Expression? {
        return parseExpressionString(text)
    }
    
    private var currentFieldBinding: Binding<String> {
        switch focusedField {
        case .expression:
            return $expression
        case .variable:
            return $variable
        case .approachValue:
            return $approachValue
        case .lowerBound:
            return $lowerBound
        case .upperBound:
            return $upperBound
        case nil:
            return $expression // default
        }
    }
    
    private func performLayout() {
        // Hide the system keyboard
        UITextView.hideKeyboard()
        showKeyboard = false
    }
}

#Preview {
    CalculusView()
}
