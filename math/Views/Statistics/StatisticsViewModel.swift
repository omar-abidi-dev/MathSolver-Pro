import SwiftUI
import Combine

/// Represents a single computed statistic with its metadata and step-by-step explanation.
struct StatItem: Identifiable {
    let id = UUID()
    let name: String
    let icon: String        // SF Symbol name
    let formula: String     // e.g. "x̄ = Σxᵢ / n"
    let value: String       // formatted result
    let isAvailable: Bool   // false → show "N/A"
    let steps: [String]     // human-readable calculation steps using actual numbers
}

// MARK: - ViewModel

@MainActor
final class StatisticsViewModel: ObservableObject {

    // MARK: Published state

    @Published var inputText: String = ""
    @Published var parsedValues: [Double] = []
    @Published var errorMessage: String?
    @Published var hasCalculated: Bool = false

    // MARK: Computed statistics (derived from parsedValues)

    var sortedValues: [Double] { parsedValues.sorted() }

    var n: Int             { StatisticsEngine.count(parsedValues) }
    var total: Double      { StatisticsEngine.sum(parsedValues) }
    var mean: Double       { StatisticsEngine.mean(parsedValues) }
    var median: Double     { StatisticsEngine.median(sortedValues) }
    var modeValues: [Double] { StatisticsEngine.mode(parsedValues) }
    var dataRange: Double  { StatisticsEngine.range(parsedValues) }
    var minVal: Double     { StatisticsEngine.minimum(parsedValues) }
    var maxVal: Double     { StatisticsEngine.maximum(parsedValues) }
    var variance: Double   { StatisticsEngine.variance(parsedValues) }
    var stdDev: Double     { StatisticsEngine.standardDeviation(parsedValues) }
    var q1: Double         { StatisticsEngine.q1(sortedValues) }
    var q3: Double         { StatisticsEngine.q3(sortedValues) }
    var iqr: Double        { StatisticsEngine.iqr(sortedValues) }

    var frequencyTable: [(value: Double, count: Int)] {
        StatisticsEngine.frequencyTable(parsedValues)
    }

    // MARK: - Stat cards

    /// Build the full array of stat items based on the current dataset.
    var statItems: [StatItem] {
        let f = StatisticsEngine.fmt
        let singleValue = (n == 1)

        return [
            StatItem(
                name: "Count (n)", icon: "number",
                formula: "n = number of values",
                value: "\(n)", isAvailable: true,
                steps: ["Count all entered values → n = \(n)"]
            ),
            StatItem(
                name: "Sum", icon: "plus.forwardslash.minus",
                formula: "Σxᵢ",
                value: f(total), isAvailable: true,
                steps: sumSteps()
            ),
            StatItem(
                name: "Mean (x̄)", icon: "divide",
                formula: "x̄ = Σxᵢ / n",
                value: f(mean), isAvailable: true,
                steps: meanSteps()
            ),
            StatItem(
                name: "Median", icon: "line.horizontal.3",
                formula: "Middle value of sorted data",
                value: f(median), isAvailable: true,
                steps: medianSteps()
            ),
            StatItem(
                name: "Mode", icon: "chart.bar",
                formula: "Most frequent value(s)",
                value: modeValues.isEmpty ? "None" : modeValues.map { f($0) }.joined(separator: ", "),
                isAvailable: true,
                steps: modeSteps()
            ),
            StatItem(
                name: "Range", icon: "arrow.left.and.right",
                formula: "Range = Max − Min",
                value: singleValue ? "N/A" : f(dataRange),
                isAvailable: !singleValue,
                steps: singleValue ? ["Need at least 2 values"] : rangeSteps()
            ),
            StatItem(
                name: "Min", icon: "arrow.down.to.line",
                formula: "Smallest value",
                value: f(minVal), isAvailable: true,
                steps: ["Min = \(f(minVal))"]
            ),
            StatItem(
                name: "Max", icon: "arrow.up.to.line",
                formula: "Largest value",
                value: f(maxVal), isAvailable: true,
                steps: ["Max = \(f(maxVal))"]
            ),
            StatItem(
                name: "Variance (σ²)", icon: "v.square",
                formula: "σ² = Σ(xᵢ − x̄)² / n",
                value: singleValue ? "N/A" : f(variance),
                isAvailable: !singleValue,
                steps: singleValue ? ["Need at least 2 values"] : varianceSteps()
            ),
            StatItem(
                name: "Std Dev (σ)", icon: "s.square",
                formula: "σ = √(Variance)",
                value: singleValue ? "N/A" : f(stdDev),
                isAvailable: !singleValue,
                steps: singleValue ? ["Need at least 2 values"] : stdDevSteps()
            ),
            StatItem(
                name: "Q1", icon: "chart.line.downtrend.xyaxis",
                formula: "First quartile",
                value: n < 2 ? "N/A" : f(q1),
                isAvailable: n >= 2,
                steps: n < 2 ? ["Need at least 2 values"] : q1Steps()
            ),
            StatItem(
                name: "Q3", icon: "chart.line.uptrend.xyaxis",
                formula: "Third quartile",
                value: n < 2 ? "N/A" : f(q3),
                isAvailable: n >= 2,
                steps: n < 2 ? ["Need at least 2 values"] : q3Steps()
            ),
            StatItem(
                name: "IQR", icon: "rectangle.split.3x1",
                formula: "IQR = Q3 − Q1",
                value: n < 2 ? "N/A" : f(iqr),
                isAvailable: n >= 2,
                steps: n < 2 ? ["Need at least 2 values"] : iqrSteps()
            ),
        ]
    }

    // MARK: - Actions

    func calculate() {
        errorMessage = nil
        hasCalculated = false

        let trimmed = inputText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            errorMessage = "Enter at least one number"
            return
        }

        let separators = CharacterSet(charactersIn: ", \n\t")
        let tokens = trimmed.components(separatedBy: separators).filter { !$0.isEmpty }

        var values: [Double] = []
        for (i, token) in tokens.enumerated() {
            guard let v = Double(token), v.isFinite else {
                errorMessage = "Invalid number at position \(i + 1): \"\(token)\""
                return
            }
            values.append(v)
        }

        parsedValues = values
        hasCalculated = true
    }

    // MARK: - Step builders (use actual numbers)

    private func sumSteps() -> [String] {
        let f = StatisticsEngine.fmt
        let expr = parsedValues.map { f($0) }.joined(separator: " + ")
        return ["Step 1: Add all values → \(expr) = \(f(total))"]
    }

    private func meanSteps() -> [String] {
        let f = StatisticsEngine.fmt
        return [
            "Step 1: Sum = \(parsedValues.map { f($0) }.joined(separator: " + ")) = \(f(total))",
            "Step 2: Divide by count → \(f(total)) ÷ \(n) = \(f(mean))"
        ]
    }

    private func medianSteps() -> [String] {
        let f = StatisticsEngine.fmt
        let sorted = sortedValues
        var steps = ["Step 1: Sort data → \(sorted.map { f($0) }.joined(separator: ", "))"]
        if n % 2 == 1 {
            let midIdx = n / 2
            steps.append("Step 2: Odd count → middle value at position \(midIdx + 1) = \(f(sorted[midIdx]))")
        } else {
            let lo = sorted[n / 2 - 1]
            let hi = sorted[n / 2]
            steps.append("Step 2: Even count → average of positions \(n/2) and \(n/2 + 1)")
            steps.append("Step 3: (\(f(lo)) + \(f(hi))) ÷ 2 = \(f(median))")
        }
        return steps
    }

    private func modeSteps() -> [String] {
        let f = StatisticsEngine.fmt
        let freq = StatisticsEngine.frequencyTable(parsedValues)
        let freqStr = freq.map { "\(f($0.value)): \($0.count)×" }.joined(separator: ", ")
        var steps = ["Step 1: Count frequencies → \(freqStr)"]
        if modeValues.isEmpty {
            steps.append("Step 2: All values appear equally → No mode")
        } else {
            let maxF = freq.map(\.count).max() ?? 0
            steps.append("Step 2: Highest frequency = \(maxF) → Mode = \(modeValues.map { f($0) }.joined(separator: ", "))")
        }
        return steps
    }

    private func rangeSteps() -> [String] {
        let f = StatisticsEngine.fmt
        return ["Step 1: Range = Max − Min = \(f(maxVal)) − \(f(minVal)) = \(f(dataRange))"]
    }

    private func varianceSteps() -> [String] {
        let f = StatisticsEngine.fmt
        let deviations = parsedValues.map { "(\(f($0)) − \(f(mean)))²" }.joined(separator: " + ")
        return [
            "Step 1: Mean = \(f(mean))",
            "Step 2: Squared deviations: \(deviations)",
            "Step 3: Sum of squared deviations = \(f(parsedValues.reduce(0) { $0 + ($1 - mean) * ($1 - mean) }))",
            "Step 4: Divide by n = \(n) → σ² = \(f(variance))"
        ]
    }

    private func stdDevSteps() -> [String] {
        let f = StatisticsEngine.fmt
        return [
            "Step 1: Variance σ² = \(f(variance))",
            "Step 2: σ = √\(f(variance)) = \(f(stdDev))"
        ]
    }

    private func q1Steps() -> [String] {
        let f = StatisticsEngine.fmt
        let lower = Array(sortedValues.prefix(n / 2))
        return [
            "Step 1: Lower half → \(lower.map { f($0) }.joined(separator: ", "))",
            "Step 2: Median of lower half = \(f(q1))"
        ]
    }

    private func q3Steps() -> [String] {
        let f = StatisticsEngine.fmt
        let startIndex = (n + 1) / 2
        let upper = Array(sortedValues.suffix(from: startIndex))
        return [
            "Step 1: Upper half → \(upper.map { f($0) }.joined(separator: ", "))",
            "Step 2: Median of upper half = \(f(q3))"
        ]
    }

    private func iqrSteps() -> [String] {
        let f = StatisticsEngine.fmt
        return ["Step 1: IQR = Q3 − Q1 = \(f(q3)) − \(f(q1)) = \(f(iqr))"]
    }
}
