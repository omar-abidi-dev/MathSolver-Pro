import SwiftUI

/// Reusable component for displaying explanations with consistent styling
/// Used across solver, debugger, and homework helper views
struct ExplanationCard: View {
    /// The explanation text to display
    let explanation: String
    
    /// Icon name (SF Symbol) displayed above the text
    let iconName: String
    
    /// Title of the explanation card
    let title: String
    
    /// Background color (default: light blue)
    var backgroundColor: Color = Color.blue.opacity(0.1)
    
    /// Foreground text color
    var foregroundColor: Color = .primary
    
    /// Optional explanation object with source information (T040)
    var sourceExplanation: Explanation? = nil
    
    /// Whether this is a fallback explanation (T041)
    var isFallback: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Fallback banner (T041)
            if isFallback {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                    
                    Text("AI explanation unavailable — showing template instead")
                        .font(.caption)
                        .foregroundColor(.orange)
                    
                    Spacer()
                }
                .padding(12)
                .background(Color.orange.opacity(0.15))
                .cornerRadius(12, corners: [.topLeft, .topRight])
            }
            
            VStack(alignment: .leading, spacing: 12) {
                // Header with icon, title, and source badge (T040)
                HStack(spacing: 10) {
                    Image(systemName: iconName)
                        .font(.title2)
                        .foregroundColor(.blue)
                    
                    Text(title)
                        .font(.headline)
                        .foregroundColor(foregroundColor)
                    
                    Spacer()
                    
                    // Source badge (T040)
                    if let sourceExplanation = sourceExplanation {
                        HStack(spacing: 4) {
                            Image(systemName: sourceExplanation.source == .ai ? "sparkles" : "book.fill")
                                .font(.caption2)
                            
                            Text(sourceExplanation.source == .ai ? "AI" : "Template")
                                .font(.caption2)
                                .fontWeight(.semibold)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(sourceExplanation.source == .ai ? Color.indigo.opacity(0.2) : Color.gray.opacity(0.2))
                        .foregroundColor(sourceExplanation.source == .ai ? .indigo : .gray)
                        .cornerRadius(6)
                    }
                }
                
                Divider()
                
                // Explanation text
                Text(explanation)
                    .font(.body)
                    .foregroundColor(foregroundColor)
                    .lineSpacing(4)
            }
            .padding(16)
            .background(backgroundColor)
            .cornerRadius(12, corners: isFallback ? [.bottomLeft, .bottomRight] : .allCorners)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.blue.opacity(0.2), lineWidth: 1)
            )
        }
    }
}

// MARK: - RoundedRectangle with specific corners

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    VStack(spacing: 12) {
        ExplanationCard(
            explanation: "We subtract 5 from both sides to keep the equation balanced. A balanced scale stays balanced whether you add or remove from each side.",
            iconName: "lightbulb.fill",
            title: "Why this step?"
        )
        
        ExplanationCard(
            explanation: "This equation is always true, no matter what x is. Any value you substitute will make both sides equal.",
            iconName: "checkmark.circle.fill",
            title: "Result",
            backgroundColor: Color.green.opacity(0.1),
            foregroundColor: .green,
            sourceExplanation: Explanation(content: "Template", source: .template, difficulty: .intermediate, equationId: UUID())
        )
        
        ExplanationCard(
            explanation: "This elegant approach isolates the variable by applying inverse operations symmetrically to maintain equation equivalence.",
            iconName: "sparkles",
            title: "AI Explanation",
            backgroundColor: Color.indigo.opacity(0.1),
            foregroundColor: .primary,
            sourceExplanation: Explanation(content: "AI", source: .ai, difficulty: .advanced, equationId: UUID())
        )
        
        ExplanationCard(
            explanation: "No AI connection available at this time. Here's the standard explanation: solve by combining like terms.",
            iconName: "exclamationmark.circle",
            title: "Explanation",
            backgroundColor: Color.orange.opacity(0.1),
            sourceExplanation: Explanation(content: "Fallback", source: .template, difficulty: .beginner, equationId: UUID()),
            isFallback: true
        )
    }
    .padding()
}
