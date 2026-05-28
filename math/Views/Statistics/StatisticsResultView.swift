import SwiftUI

/// Statistics results display with expandable sections
struct StatisticsResultView: View {
    let result: StatisticsResult
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Dataset Summary
                    VStack(spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Sample Size")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Text("\(result.count)")
                                    .font(.headline)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Range")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Text("\(String(format: "%.4g", result.min)) — \(String(format: "%.4g", result.max))")
                                    .font(.subheadline)
                            }
                        }
                        .padding(12)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .padding(.horizontal, 16)
                    
                    // Central Tendency Section
                    StatisticsSectionView(
                        title: "Central Tendency",
                        rows: [
                            (label: "Mean", value: result.mean, valueText: nil, steps: findSteps(for: "mean", in: result.steps)),
                            (label: "Median", value: result.median, valueText: nil, steps: findSteps(for: "median", in: result.steps)),
                            (label: "Mode", value: result.mode.count == 1 ? result.mode[0] : nil, valueText: result.mode.isEmpty ? "No mode" : result.mode.map { String(format: "%.4g", $0) }.joined(separator: ", "), steps: findSteps(for: "mode", in: result.steps))
                        ]
                    )
                    
                    // Spread Section
                    StatisticsSectionView(
                        title: "Spread (Dispersion)",
                        rows: [
                            (label: "Minimum", value: result.min, valueText: nil, steps: findSteps(for: "minimum", in: result.steps)),
                            (label: "Maximum", value: result.max, valueText: nil, steps: findSteps(for: "maximum", in: result.steps)),
                            (label: "Range", value: result.range, valueText: nil, steps: findSteps(for: "range", in: result.steps))
                        ]
                    )
                    
                    // Variance & Standard Deviation Section
                    StatisticsSectionView(
                        title: "Variance & Standard Deviation",
                        rows: varianceRows
                    )
                }
                .padding(.vertical, 16)
            }
            .navigationTitle("Analysis Results")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func findSteps(for keyword: String, in steps: [SolutionStep]) -> [SolutionStep] {
        return steps.filter { $0.description.lowercased().contains(keyword.lowercased()) }
    }
    
    private var varianceRows: [(label: String, value: Double?, valueText: String?, steps: [SolutionStep]?)] {
        var rows: [(label: String, value: Double?, valueText: String?, steps: [SolutionStep]?)] = [
            (label: "Population Variance (σ²)", value: result.populationVariance, valueText: nil, steps: findSteps(for: "variance", in: result.steps)),
            (label: "Population Std Dev (σ)", value: result.populationStdDev, valueText: nil, steps: findSteps(for: "standard deviation", in: result.steps))
        ]
        if let sampleVar = result.sampleVariance {
            rows.append((label: "Sample Variance (s²)", value: sampleVar, valueText: nil, steps: nil))
        }
        if let sampleStd = result.sampleStdDev {
            rows.append((label: "Sample Std Dev (s)", value: sampleStd, valueText: nil, steps: nil))
        }
        return rows
    }
}

// MARK: - Statistic Section Component

struct StatisticsSectionView: View {
    let title: String
    let rows: [(label: String, value: Double?, valueText: String?, steps: [SolutionStep]?)]
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: { isExpanded.toggle() }) {
                HStack(spacing: 12) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.gray)
                        .font(.system(size: 12, weight: .semibold))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .contentShape(Rectangle())
            }
            
            if isExpanded {
                VStack(spacing: 0) {
                    Divider()
                        .padding(.vertical, 8)
                    
                    ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                        if index > 0 {
                            Divider()
                        }
                        StatisticRowView(label: row.label, value: row.value, valueText: row.valueText, steps: row.steps)
                    }
                    .padding(12)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(.systemGray5), lineWidth: 1))
        .padding(.horizontal, 16)
    }
}

// MARK: - Statistic Row Component

struct StatisticRowView: View {
    let label: String
    let value: Double?
    let valueText: String?
    let steps: [SolutionStep]?
    @State private var showSteps = false
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Spacer()
                
                if let val = value {
                    Text(String(format: "%.6g", val))
                        .font(.system(.body, design: .monospaced))
                        .fontWeight(.semibold)
                } else if let text = valueText {
                    Text(text)
                        .font(.system(.body, design: .monospaced))
                        .fontWeight(.semibold)
                }
                
                if steps != nil && !(steps?.isEmpty ?? true) {
                    Button(action: { showSteps.toggle() }) {
                        Image(systemName: showSteps ? "chevron.up" : "chevron.down")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.blue)
                    }
                }
            }
            
            if showSteps, let steps = steps, !steps.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(steps, id: \.stepNumber) { step in
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Step \(step.stepNumber): \(step.description)")
                                .font(.caption)
                                .fontWeight(.semibold)
                            
                            Text(step.explanation)
                                .font(.caption2)
                                .foregroundColor(.gray)
                            
                            Text(step.resultEquation)
                                .font(.caption2)
                                .fontMonospaced()
                                .padding(4)
                                .background(Color(.systemGray5))
                                .cornerRadius(4)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(6)
            }
        }
    }
}

// MARK: - View Extension

extension View {
    func fontMonospaced() -> some View {
        self.font(.system(.caption2, design: .monospaced))
    }
}

#Preview {
    StatisticsResultView(result: StatisticsResult(
        dataset: [4, 8, 6, 5, 3, 7, 8, 9],
        sortedData: [3, 4, 5, 6, 7, 8, 8, 9],
        mean: 6.25,
        median: 6.5,
        mode: [8],
        range: 6,
        min: 3,
        max: 9,
        populationVariance: 3.9375,
        sampleVariance: 4.5,
        populationStdDev: 1.984,
        sampleStdDev: 2.121,
        steps: []
    ))
}
