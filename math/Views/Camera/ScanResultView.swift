import SwiftUI

// MARK: - ScanResultView

/// Displays complete scan→solve→explain flow results
/// Combines solution steps with AI explanation in a single view
/// Handles concurrent solving and explanation generation with partial results
struct ScanResultView: View {
    let scannedEquation: String
    let confidence: Float
    
    @State private var solution: Solution?
    @State private var aiExplanation: Explanation?
    @State private var isSolving = false
    @State private var isExplaining = false
    @State private var solveError: String?
    @State private var explainError: String?
    @State private var selectedStepIndex = 0
    @State private var showSimpleExplanation = false
    
    @StateObject private var geminiService = GeminiService.shared
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // Header with equation
                    headerSection
                    
                    // Solution section (T042, T044, T045)
                    if let solution = solution {
                        solutionSection(solution)
                    } else if isSolving {
                        loadingSection(title: "Solving", subtitle: "Finding answer and steps...")
                    } else if let error = solveError {
                        errorSection(title: "Failed to Solve", message: error, action: retryAll)
                    }
                    
                    // AI Explanation section (T042, T044, T045)
                    if let aiExplanation = aiExplanation {
                        aiExplanationSection(aiExplanation)
                    } else if isExplaining {
                        loadingSection(title: "Getting AI Explanation", subtitle: "Analyzing your solution...")
                    } else if let error = explainError {
                        errorSection(title: "AI Explanation Failed", message: error, action: retryExplanation)
                    }
                    
                    // Action buttons (T044)
                    if solution != nil || aiExplanation != nil {
                        actionButtonsSection
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding(16)
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
            .onAppear {
                loadContent()
            }
        }
    }
    
    // MARK: - Header Section
    
    @ViewBuilder
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Scanned Equation")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text(scannedEquation)
                        .font(.system(size: 18, design: .monospaced))
                        .lineLimit(2)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Confidence")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    HStack(spacing: 4) {
                        Image(systemName: confidenceIcon)
                            .font(.caption)
                        Text("\(Int(confidence * 100))%")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(confidenceColor)
                }
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Solution Section (T042, T044, T045)
    
    @ViewBuilder
    private func solutionSection(_ solution: Solution) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title with icon
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.green)
                    
                    Text("Solution")
                        .font(.headline)
                }
                
                Spacer()
                
                Text("\(selectedStepIndex + 1) of \(solution.steps.count)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            // Solution values
            VStack(alignment: .leading, spacing: 8) {
                Text("Answer")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(solution.solutions, id: \.self) { sol in
                            VStack(spacing: 4) {
                                Text("x =")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                
                                Text(sol)
                                    .font(.system(size: 16, weight: .semibold, design: .monospaced))
                            }
                            .frame(minWidth: 100)
                            .padding(12)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                }
            }
            
            // Step display (T044)
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
                        
                        if !step.explanation.isEmpty {
                            Text(step.explanation)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(12)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2), lineWidth: 1))
                    
                    // Step navigation
                    HStack(spacing: 8) {
                        Button(action: previousStep) {
                            Image(systemName: "chevron.left")
                                .frame(maxWidth: .infinity)
                                .padding(10)
                                .background(Color(.systemGray4))
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .disabled(selectedStepIndex == 0)
                        
                        HStack(spacing: 6) {
                            ForEach(solution.steps.indices, id: \.self) { index in
                                Circle()
                                    .fill(index == selectedStepIndex ? Color.blue : Color(.systemGray4))
                                    .frame(width: 8, height: 8)
                                    .onTapGesture {
                                        selectedStepIndex = index
                                    }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        
                        Button(action: nextStep) {
                            Image(systemName: "chevron.right")
                                .frame(maxWidth: .infinity)
                                .padding(10)
                                .background(Color(.systemGray4))
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .disabled(selectedStepIndex == solution.steps.count - 1)
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.systemGray6).opacity(0.5))
        .cornerRadius(12)
    }
    
    // MARK: - AI Explanation Section (T042, T044, T045)
    
    @ViewBuilder
    private func aiExplanationSection(_ explanation: Explanation) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.title3)
                        .foregroundColor(.indigo)
                    
                    Text("AI Explanation")
                        .font(.headline)
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: explanation.source == .ai ? "sparkles" : "book.fill")
                        .font(.caption2)
                    
                    Text(explanation.source == .ai ? "AI" : "Template")
                        .font(.caption2)
                        .fontWeight(.semibold)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(explanation.source == .ai ? Color.indigo.opacity(0.2) : Color.gray.opacity(0.2))
                .foregroundColor(explanation.source == .ai ? .indigo : .gray)
                .cornerRadius(6)
            }
            
            Text(explanation.content)
                .font(.body)
                .lineSpacing(4)
                .foregroundColor(.primary)
        }
        .padding(16)
        .background(Color.indigo.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Loading Section (T045)
    
    @ViewBuilder
    private func loadingSection(title: String, subtitle: String) -> some View {
        VStack(spacing: 12) {
            ProgressView()
                .scaleEffect(1.2)
            
            VStack(spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color(.systemGray6).opacity(0.5))
        .cornerRadius(12)
    }
    
    // MARK: - Error Section (T044)
    
    @ViewBuilder
    private func errorSection(title: String, message: String, action: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.red)
                    
                    Text(message)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.red)
            }
            
            Button(action: action) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Retry")
                }
                .frame(maxWidth: .infinity)
                .padding(12)
                .background(Color.red.opacity(0.1))
                .foregroundColor(.red)
                .cornerRadius(8)
            }
        }
        .padding(16)
        .background(Color.red.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Action Buttons Section (T044)
    
    @ViewBuilder
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            Button(action: { dismiss() }) {
                HStack {
                    Image(systemName: "xmark.circle")
                    Text("Back")
                }
                .frame(maxWidth: .infinity)
                .padding(12)
                .background(Color(.systemGray4))
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            
            if let solution = solution {
                Button(action: { UIPasteboard.general.string = solution.displaySolutions }) {
                    HStack {
                        Image(systemName: "doc.on.doc")
                        Text("Copy Solution")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// Load both solution and AI explanation concurrently (T043)
    private func loadContent() {
        isSolving = true
        isExplaining = true
        solveError = nil
        explainError = nil
        
        // Solve equation
        solveConcurrently()
        
        // These will run concurrently
    }
    
    /// Solve the equation (T043)
    private func solveConcurrently() {
        Task {
            do {
                let solver = EquationSolver(
                    equation: scannedEquation,
                    difficulty: .intermediate
                )
                let sol = try await solver.solveAsync()
                solution = sol
                
                // Once we have the solution, fetch AI explanation
                if solution != nil {
                    fetchAIExplanation()
                }
            } catch let error as EquationError {
                solveError = error.errorDescription ?? "Failed to solve equation"
            } catch {
                solveError = "Failed to solve equation: \(error.localizedDescription)"
            }
            
            isSolving = false
        }
    }
    
    /// Fetch AI explanation for the solution (T043)
    private func fetchAIExplanation() {
        guard let solution = solution else { return }
        
        isExplaining = true
        explainError = nil
        
        Task {
            let explanation = await geminiService.generateExplanation(
                equation: scannedEquation,
                steps: solution.steps,
                answer: solution.displaySolutions,
                difficulty: Difficulty(rawValue: solution.difficulty) ?? .intermediate
            )
            
            await MainActor.run {
                self.aiExplanation = explanation
                self.isExplaining = false
                
                // Check if it fell back to template
                if explanation.source == .template {
                    self.explainError = nil  // Don't show error for template fallback
                }
            }
        }
    }
    
    /// Retry solving and AI explanation (T044)
    private func retryAll() {
        solution = nil
        aiExplanation = nil
        selectedStepIndex = 0
        loadContent()
    }
    
    /// Retry just the AI explanation (T044)
    private func retryExplanation() {
        aiExplanation = nil
        explainError = nil
        if solution != nil {
            fetchAIExplanation()
        }
    }
    
    /// Navigate to next step
    private func nextStep() {
        guard let solution = solution else { return }
        if selectedStepIndex < solution.steps.count - 1 {
            selectedStepIndex += 1
        }
    }
    
    /// Navigate to previous step
    private func previousStep() {
        if selectedStepIndex > 0 {
            selectedStepIndex -= 1
        }
    }
    
    // MARK: - Helpers
    
    private var confidenceColor: Color {
        if confidence >= 0.9 {
            return .green
        } else if confidence >= 0.7 {
            return .blue
        } else if confidence >= 0.5 {
            return .orange
        } else {
            return .red
        }
    }
    
    private var confidenceIcon: String {
        if confidence >= 0.9 {
            return "checkmark.circle.fill"
        } else if confidence >= 0.7 {
            return "checkmark.circle"
        } else if confidence >= 0.5 {
            return "exclamationmark.triangle"
        } else {
            return "xmark.circle"
        }
    }
}

#Preview {
    ScanResultView(scannedEquation: "sin(x) = 0.5", confidence: 0.92)
}
