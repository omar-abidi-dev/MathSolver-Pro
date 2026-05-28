import SwiftUI

/// Displays validation results when user checks their work
struct ErrorResultView: View {
    let attempt: UserAttempt
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                if attempt.isCorrect {
                    // Success state
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                        
                        VStack(spacing: 8) {
                            Text("Perfect!")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text("Your work is completely correct!")
                                .font(.body)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                } else if let errorIndex = attempt.firstErrorIndex, errorIndex < attempt.steps.count {
                    // Error state
                    VStack(spacing: 16) {
                        // Error indicator
                        VStack(spacing: 12) {
                            HStack(spacing: 12) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(.orange)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Error Found")
                                        .font(.headline)
                                        .fontWeight(.bold)
                                    
                                    Text("Step \(errorIndex + 1) is incorrect")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                
                                Spacer()
                            }
                            .padding(16)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(12)
                        }
                        
                        // Steps review
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Your Work")
                                .font(.headline)
                            
                            ScrollView {
                                VStack(spacing: 12) {
                                    ForEach(attempt.steps.indices, id: \.self) { index in
                                        StepReviewCard(
                                            stepNumber: index + 1,
                                            text: attempt.steps[index].rawInput,
                                            isError: index == errorIndex
                                        )
                                    }
                                }
                            }
                        }
                        
                        // Explanation
                        if let errorDesc = attempt.errorDescription {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("What Went Wrong")
                                    .font(.headline)
                                
                                Text(errorDesc)
                                    .font(.body)
                                    .lineLimit(4)
                            }
                            .padding(16)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(12)
                        }
                        
                        Spacer()
                        
                        // Try again button
                        Button(action: { dismiss() }) {
                            HStack {
                                Image(systemName: "arrow.counterclockwise")
                                Text("Try Again")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(16)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Check Results")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
        }
    }
}

// MARK: - Step Review Card

struct StepReviewCard: View {
    let stepNumber: Int
    let text: String
    let isError: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .center, spacing: 4) {
                Text("\(stepNumber)")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .frame(width: 40, height: 40)
            .background(isError ? Color.red : Color.green)
            .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Step \(stepNumber)")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Text(text)
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.semibold)
            }
            
            Spacer()
            
            Image(systemName: isError ? "xmark.circle.fill" : "checkmark.circle.fill")
                .foregroundColor(isError ? .red : .green)
        }
        .padding(12)
        .background(isError ? Color.red.opacity(0.05) : Color.green.opacity(0.05))
        .cornerRadius(8)
        .border(isError ? Color.red.opacity(0.3) : Color.green.opacity(0.3), width: 1)
    }
}

#Preview {
    // Error state
    let errorAttempt = UserAttempt(
        equation: Equation(
            rawInput: "2x + 5 = 15",
            equationType: .linear,
            leftExpression: .binaryOp(.add, .binaryOp(.multiply, .constant(2), .variable("x")), .constant(5)),
            rightExpression: .constant(15)
        ),
        steps: [
            AttemptStep(stepNumber: 1, rawInput: "2x = 10"),
            AttemptStep(stepNumber: 2, rawInput: "x = 10")
        ],
        firstErrorIndex: 1,
        errorDescription: "You forgot to divide by 2. The correct step should be x = 5"
    )
    
    ErrorResultView(attempt: errorAttempt)
}
