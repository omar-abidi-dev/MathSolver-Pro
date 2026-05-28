import SwiftUI

/// Detail view for a single solution step with expandable explanation
struct StepDetailView: View {
    let step: SolutionStep
    let difficulty: Difficulty
    let stepExplainer: StepExplainer
    let isExpanded: Bool
    let onToggle: () -> Void
    
    @State private var generatedExplanation: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Step header (always visible)
            Button(action: onToggle) {
                HStack(spacing: 12) {
                    // Step number badge
                    Text("Step \(step.stepNumber)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .frame(width: 50)
                        .padding(8)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(6)
                    
                    // Step description
                    VStack(alignment: .leading, spacing: 4) {
                        Text(step.description)
                            .font(.body)
                            .fontWeight(.medium)
                        
                        Text(step.resultEquation)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    // Expand/collapse indicator
                    Image(systemName: "chevron.right")
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .foregroundColor(.gray)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(12)
            .background(Color(.systemBackground))
            
            // Expandable explanation section
            if isExpanded {
                Divider()
                
                VStack(alignment: .leading, spacing: 12) {
                    ExplanationCard(
                        explanation: generatedExplanation ?? step.explanation,
                        iconName: "lightbulb.fill",
                        title: "Why this step?"
                    )
                    
                    // Operation details
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Operation")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.gray)
                        
                        Text(operationDescription)
                            .font(.caption)
                            .monospaced()
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(6)
                    }
                }
                .padding(12)
                .background(Color(.systemGray6))
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
        )
        .onAppear {
            generatedExplanation = stepExplainer.explain(step: step, difficulty: difficulty)
        }
    }
    
    private var operationDescription: String {
        switch step.operation {
        case .addBothSides(let value):
            return "Add \(Int(value)) to both sides"
        case .subtractBothSides(let value):
            return "Subtract \(Int(value)) from both sides"
        case .multiplyBothSides(let value):
            return "Multiply both sides by \(Int(value))"
        case .divideBothSides(let value):
            return "Divide both sides by \(Int(value))"
        case .factor:
            return "Factor the expression"
        case .applyQuadraticFormula:
            return "Apply the quadratic formula"
        case .substitute(let variable, let into):
            return "Substitute \(variable) into equation \(into)"
        case .simplify:
            return "Simplify"
        case .collectLikeTerms:
            return "Collect like terms"
        case .applyTrigIdentity(let identity):
            return "Apply identity: \(identity)"
        case .applyLogRule(let rule):
            return "Apply log rule: \(rule)"
        case .differentiate(let rule):
            return "Differentiate using \(rule)"
        case .integrate(let rule):
            return "Integrate using \(rule)"
        case .substituteValue(let variable, let value):
            return "Substitute \(variable) = \(value)"
        case .rewrite(let from, let to):
            return "Rewrite \(from) as \(to)"
        case .calculateMean:
            return "Calculate the mean"
        case .calculateMedian:
            return "Calculate the median"
        case .calculateMode:
            return "Calculate the mode"
        case .calculateVariance:
            return "Calculate the variance"
        case .calculateStandardDeviation:
            return "Calculate the standard deviation"
        case .sortData:
            return "Sort the data"
        case .calculateZScore:
            return "Calculate the z-score"
        case .identifyFormula(let formula):
            return "Identified formula: \(formula)"
        case .substituteValues:
            return "Substitute known values"
        case .rearrangeFormula(let formula):
            return "Rearrange: \(formula)"
        case .convertUnit(let from, let to):
            return "Convert \(from) to \(to)"
        case .computeResult:
            return "Calculate final result"
        case .evaluateLimit(let method):
            return "Evaluate limit using \(method)"
        case .simplifyExpression:
            return "Simplify expression"
        case .evaluateAtBounds:
            return "Evaluate at bounds"
        case .identifyIndeterminateForm(let form):
            return "Identify indeterminate form: \(form)"
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        StepDetailView(
            step: SolutionStep(
                stepNumber: 1,
                operation: .subtractBothSides(5),
                description: "Subtract 5 from both sides",
                resultEquation: "2x = 10",
                explanation: "We want to isolate terms with x on the left side."
            ),
            difficulty: .intermediate,
            stepExplainer: stepExplainer,
            isExpanded: true,
            onToggle: { }
        )
        
        StepDetailView(
            step: SolutionStep(
                stepNumber: 2,
                operation: .divideBothSides(2),
                description: "Divide both sides by 2",
                resultEquation: "x = 5",
                explanation: "Divide by the coefficient of x to isolate the variable."
            ),
            difficulty: .intermediate,
            stepExplainer: stepExplainer,
            isExpanded: false,
            onToggle: { }
        )
    }
    .padding()
}
