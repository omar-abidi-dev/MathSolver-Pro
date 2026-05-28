import SwiftUI

/// Displays the step-by-step solution for a calculus operation
struct CalculusSolutionView: View {
    let solution: CalcSolution
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Result Header
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "equal")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.indigo)
                                .frame(width: 44, height: 44)
                                .background(Color.indigo.opacity(0.1))
                                .cornerRadius(8)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(modeLabel)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Text(solution.resultExpression)
                                    .font(.system(.title2, design: .monospaced))
                                    .fontWeight(.bold)
                            }
                            
                            Spacer()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(16)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Input Expression
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Input Expression")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(solution.inputExpression)
                            .font(.system(.body, design: .monospaced))
                            .padding(12)
                            .background(Color(.systemGray5))
                            .cornerRadius(8)
                    }
                    
                    // Numeric result if applicable
                    if let numericResult = solution.numericResult {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Numeric Result")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text(String(format: "%.10g", numericResult))
                                .font(.system(.body, design: .monospaced))
                                .fontWeight(.semibold)
                                .padding(12)
                                .background(Color.green.opacity(0.05))
                                .cornerRadius(8)
                        }
                    }
                    
                    // Steps
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Solution Steps")
                            .font(.headline)
                        
                        ForEach(solution.steps, id: \.id) { step in
                            VStack(alignment: .leading, spacing: 8) {
                                // Step number and operation
                                HStack(spacing: 12) {
                                    Text("Step \(step.stepNumber)")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                        .frame(width: 50, height: 28)
                                        .background(Color.indigo)
                                        .cornerRadius(6)
                                    
                                    Text(step.description)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    
                                    Spacer()
                                }
                                
                                // Result
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Result:")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Text(step.resultEquation)
                                        .font(.system(.body, design: .monospaced))
                                        .padding(8)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(6)
                                }
                                
                                // Explanation
                                Text(step.explanation)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .lineLimit(nil)
                            }
                            .padding(12)
                            .background(Color(.systemBackground))
                            .border(Color(.systemGray5), width: 1)
                            .cornerRadius(8)
                        }
                    }
                }
                .padding(16)
            }
            .navigationTitle(modeLabel)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
        }
    }
    
    private var modeLabel: String {
        switch solution.mode {
        case .limits:
            return "Limit " + (solution.approachValue.map { "as x → \($0)" } ?? "")
        case .derivatives:
            return "Derivative"
        case .integrals:
            if solution.isDefinite {
                return "Definite Integral"
            } else {
                return "Indefinite Integral"
            }
        }
    }
}

#Preview {
    let exampleSteps = [
        SolutionStep(
            stepNumber: 1,
            operation: .evaluateLimit(method: "Direct Substitution"),
            description: "Evaluate at x = 1",
            resultEquation: "2",
            explanation: "Direct substitution yields a finite value."
        )
    ]
    
    let exampleSolution = CalcSolution(
        mode: .limits,
        inputExpression: "(x^2 - 1)/(x - 1)",
        resultExpression: "2",
        numericResult: 2.0,
        variable: "x",
        approachValue: "1",
        steps: exampleSteps
    )
    
    CalculusSolutionView(solution: exampleSolution)
}
