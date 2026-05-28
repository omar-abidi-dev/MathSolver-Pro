import SwiftUI

/// Displays the complete solution with steps
struct SolutionView: View {
    let solution: Solution
    @State private var selectedStepIndex = 0
    @State private var showSimpleExplanation = false
    @State private var aiExplanation: Explanation?
    @State private var isLoadingExplanation = false
    @State private var isExplanationExpanded = false
    @State private var isAIExpanded = false
    @State private var isSimpleExpanded = false
    @StateObject private var geminiService = GeminiService.shared
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // Header
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Equation Type")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            HStack(spacing: 8) {
                                Image(systemName: typeIcon)
                                    .foregroundColor(typeColor)
                                
                                Text(solution.type.displayName)
                                    .fontWeight(.semibold)
                            }
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Difficulty")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            Text(solution.difficulty)
                                .fontWeight(.semibold)
                        }
                    }
                    
                    // Original equation
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Original Equation")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Text(solution.equation)
                            .font(.system(size: 18, design: .monospaced))
                            .padding(12)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                }
                .padding(16)
                .background(Color(.systemBackground))
                .cornerRadius(12)
                
                // Solution cards
                VStack(alignment: .leading, spacing: 12) {
                    Text("Solutions")
                        .font(.headline)
                        .padding(.horizontal, 16)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(solution.solutions, id: \.self) { sol in
                                VStack(spacing: 4) {
                                    Text("Solution")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    
                                    Text(sol)
                                        .font(.system(size: 16, weight: .semibold, design: .monospaced))
                                }
                                .frame(minWidth: 120)
                                .padding(12)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
                
                // Steps
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Solution Steps")
                            .font(.headline)
                        
                        Spacer()
                        
                        Text("\(selectedStepIndex + 1) of \(solution.steps.count)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal, 16)
                    
                    if !solution.steps.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            let step = solution.steps[selectedStepIndex]
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text(step.description)
                                    .font(.headline)
                                
                                Text(step.expression)
                                    .font(.system(size: 16, design: .monospaced))
                                    .padding(12)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                Text(step.explanation)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                            .padding(16)
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            
                            // Step navigation
                            HStack(spacing: 12) {
                                Button(action: previousStep) {
                                    Image(systemName: "chevron.left")
                                        .frame(maxWidth: .infinity)
                                        .padding(12)
                                        .background(Color(.systemGray4))
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                }
                                .disabled(selectedStepIndex == 0)
                                
                                ForEach(solution.steps.indices, id: \.self) { index in
                                    Circle()
                                        .fill(index == selectedStepIndex ? Color.blue : Color(.systemGray4))
                                        .frame(width: 8, height: 8)
                                        .onTapGesture {
                                            selectedStepIndex = index
                                        }
                                }
                                
                                Button(action: nextStep) {
                                    Image(systemName: "chevron.right")
                                        .frame(maxWidth: .infinity)
                                        .padding(12)
                                        .background(Color(.systemGray4))
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                }
                                .disabled(selectedStepIndex == solution.steps.count - 1)
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                }
                
                // Explanation (T004)
                if !solution.explanation.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Explanation")
                                .font(.headline)
                            
                            Spacer()
                            
                            Text(isExplanationExpanded ? "Show Less" : "Show More")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        
                        Text(solution.explanation)
                            .font(.body)
                            .lineLimit(isExplanationExpanded ? nil : 3)
                    }
                    .padding(16)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal, 16)
                    .onTapGesture { isExplanationExpanded.toggle() }
                }
                
                // AI Explanation (if generated) (T005)
                if let aiExplanation = aiExplanation {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            HStack(spacing: 4) {
                                Image(systemName: "sparkles")
                                    .font(.caption)
                                Text("AI Explanation")
                                    .font(.headline)
                            }
                            
                            Spacer()
                            
                            Text(isAIExpanded ? "Show Less" : "Show More")
                                .font(.caption)
                                .foregroundColor(.blue)
                            
                            Button(action: { self.aiExplanation = nil }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        Text(aiExplanation.content)
                            .font(.body)
                            .lineLimit(isAIExpanded ? nil : 3)
                    }
                    .padding(16)
                    .background(Color.indigo.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal, 16)
                    .onTapGesture { isAIExpanded.toggle() }
                }
                
                // Simple explanation (if shown) (T006)
                if showSimpleExplanation {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Explained Simply")
                                .font(.headline)
                            
                            Spacer()
                            
                            Text(isSimpleExpanded ? "Show Less" : "Show More")
                                .font(.caption)
                                .foregroundColor(.blue)
                            
                            Button(action: { showSimpleExplanation = false }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        Text(generateSimpleExplanation())
                            .font(.body)
                            .lineLimit(isSimpleExpanded ? nil : 3)
                    }
                    .padding(16)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal, 16)
                    .onTapGesture { isSimpleExpanded.toggle() }
                }
                
                // Action buttons
                VStack(spacing: 12) {
                    // AI Explanation button
                    Button(action: generateAIExplanation) {
                        HStack {
                            if isLoadingExplanation {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "sparkles")
                            }
                            Text(aiExplanation != nil ? "AI Explanation Generated" : "Explain with AI")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(16)
                        .background(Color.indigo)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(isLoadingExplanation || aiExplanation != nil)
                    
                    Button(action: { showSimpleExplanation.toggle() }) {
                        HStack {
                            Image(systemName: "book.circle.fill")
                            Text(showSimpleExplanation ? "Hide Simple" : "Explain Simply")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(16)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    
                    // Copy button
                    Button(action: copySolution) {
                        HStack {
                            Image(systemName: "doc.on.doc")
                            Text("Copy Solution")
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
            .navigationTitle("Solution")
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
    
    private var typeIcon: String {
        switch solution.type {
        case .linear:
            return "line.diagonal"
        case .quadratic:
            return "function"
        case .system:
            return "square.grid.2x2"
        case .trigonometric:
            return "wave.3"
        case .logarithmic:
            return "log.variable"
        case .polynomial:
            return "polynomial"
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
        switch solution.type {
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
            return .yellow
        case .derivative:
            return .cyan
        case .integral:
            return .indigo
        case .statistics:
            return .teal
        case .physics:
            return .brown
        }
    }
    
    private func nextStep() {
        if selectedStepIndex < solution.steps.count - 1 {
            selectedStepIndex += 1
        }
    }
    
    private func previousStep() {
        if selectedStepIndex > 0 {
            selectedStepIndex -= 1
        }
    }
    
    private func copySolution() {
        let content = """
        \(solution.equation)
        
        Solutions: \(solution.displaySolutions)
        
        Type: \(solution.type.displayName)
        Difficulty: \(solution.difficulty)
        """
        
        UIPasteboard.general.string = content
    }
    
    private func generateSimpleExplanation() -> String {
        switch solution.type {
        case .linear:
            return """
            🔍 **Finding the Hidden Number**
            
            Think of this like a mystery! We have a hidden number (that's x), and we need to find it.
            
            Here's how we solve it:
            1. We started with some clues about the hidden number
            2. We moved all the numbers to one side
            3. We moved all the stuff with x to the other side
            4. Then we figured out what the hidden number is!
            """
        case .quadratic:
            return """
            📦 **Finding Two Hidden Numbers**
            
            These special equations have TWO answers! Think of a square where we know the area.
            
            There are often two different side lengths that work. That's why we get two answers!
            """
        case .system:
            return """
            👥 **Two Friends with a Mystery**
            
            We have two equations and need to find the numbers that make BOTH true at the same time.
            
            It's like two friends giving you clues, and you need to find the answer that works for both! 🔑
            """
        case .trigonometric:
            return "Trigonometric equations involve sine, cosine, and tangent functions."
        case .logarithmic:
            return "Logarithmic equations solve for values using logarithmic functions."
        case .polynomial:
            return "Polynomial equations can have many solutions depending on their degree."
        case .derivative:
            return "This equation involves taking the derivative of a function."
        case .integral:
            return "This equation involves integrating a function."
        case .statistics:
            return "Statistical analysis performed on the provided dataset."
        case .physics:
            return "Physics problem solved using the appropriate formula."
        }
    }
    
    private func generateAIExplanation() {
        isLoadingExplanation = true
        
        Task {
            let explanation = await geminiService.generateExplanation(
                equation: solution.equation,
                steps: solution.steps,
                answer: solution.displaySolutions,
                difficulty: Difficulty(rawValue: solution.difficulty) ?? .intermediate
            )
            
            await MainActor.run {
                self.aiExplanation = explanation
                self.isLoadingExplanation = false
            }
        }
    }
}

#Preview {
    SolutionView(solution: .linearSample)
}
