import SwiftUI

/// Displays history of previously solved equations
struct HistoryView: View {
    @State private var solutions: [Solution] = Solution.samples
    @State private var selectedSolution: Solution?
    @State private var showDeleteConfirmation = false
    @State private var solutionToDelete: Solution?
    
    var body: some View {
        NavigationView {
            Group {
                if solutions.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        
                        Text("No Solution History")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Text("Solved equations will appear here")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground))
                } else {
                    List {
                        ForEach(solutions.sorted { $0.timestamp > $1.timestamp }) { solution in
                            NavigationLink(destination: SolutionView(solution: solution)) {
                                HistoryRow(solution: solution)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    solutionToDelete = solution
                                    showDeleteConfirmation = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("History")
            .toolbar {
                if !solutions.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: clearHistory) {
                            Text("Clear")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .alert("Delete Solution?", isPresented: $showDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    if let solution = solutionToDelete {
                        solutions.removeAll { $0.id == solution.id }
                    }
                }
                Button("Cancel", role: .cancel) { }
            }
        }
    }
    
    private func clearHistory() {
        solutions.removeAll()
    }
}

// MARK: - History Row

struct HistoryRow: View {
    let solution: Solution
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: typeIcon)
                .font(.system(size: 20))
                .foregroundColor(typeColor)
                .frame(width: 32, height: 32)
                .background(typeColor.opacity(0.1))
                .cornerRadius(8)
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(solution.equation)
                    .font(.headline)
                    .lineLimit(1)
                
                HStack(spacing: 12) {
                    Label(solution.displaySolutions, systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Text(solution.formattedDate)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding(.vertical, 8)
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
}

#Preview {
    HistoryView()
}
