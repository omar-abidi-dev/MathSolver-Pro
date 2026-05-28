import SwiftUI

/// Main solver view with tab navigation
struct SolverView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Solver Tab
            SolverTabView()
                .tabItem {
                    Label("Solve", systemImage: "function")
                }
                .tag(0)
            
            // History Tab
            HistoryView()
                .tabItem {
                    Label("History", systemImage: "clock.fill")
                }
                .tag(1)
            
            // Settings Tab
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(2)
        }
    }
}

// MARK: - Solver Tab View

struct SolverTabView: View {
    @State private var equationText = ""
    @State private var selectedDifficulty = Difficulty.intermediate
    @State private var currentSolution: Solution?
    @State private var showSolution = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showKeyboard = false
    @State private var detectedType: EquationType = .linear
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                // Header
                VStack(spacing: 8) {
                    Text("Math Equation Solver")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Enter your equation to solve")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                
                // Solver Content
                ScrollView {
                    EquationInputView(
                        equationText: $equationText,
                        selectedDifficulty: $selectedDifficulty,
                        errorMessage: $errorMessage,
                        detectedType: $detectedType,
                        onSolve: solveEquation
                    )
                    .padding(.horizontal, 16)
                }
                
                // Loading indicator
                if isLoading {
                    VStack(spacing: 12) {
                        ProgressView()
                        Text("Solving...")
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(16)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal, 16)
                }
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showSolution) {
                if let solution = currentSolution {
                    SolutionView(solution: solution)
                }
            }
        }
    }
    
    private func solveEquation() {
        guard !equationText.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Please enter an equation"
            return
        }
        
        errorMessage = nil
        isLoading = true
        
        Task {
            do {
                let solver = EquationSolver(equation: equationText, difficulty: selectedDifficulty)
                let solution = try await solver.solveAsync()
                currentSolution = solution
                showSolution = true
                equationText = ""
            } catch let error as EquationError {
                errorMessage = error.errorDescription
            } catch {
                errorMessage = "Failed to solve equation: \(error.localizedDescription)"
            }
            isLoading = false
        }
    }
}

#Preview {
    SolverView()
}
