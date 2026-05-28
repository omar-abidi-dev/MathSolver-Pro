import Foundation

// MARK: - StatisticsEngine
// Pure computation functions — no SwiftUI imports.
// Every function is static and side-effect-free.

struct StatisticsEngine {

    // MARK: - Core Statistics

    /// Count of values in the dataset.
    static func count(_ data: [Double]) -> Int {
        data.count
    }

    /// Sum of all values: Σxᵢ
    static func sum(_ data: [Double]) -> Double {
        data.reduce(0, +)
    }

    /// Arithmetic mean: x̄ = Σxᵢ / n
    static func mean(_ data: [Double]) -> Double {
        guard !data.isEmpty else { return 0 }
        return sum(data) / Double(data.count)
    }

    /// Median: middle value of the sorted dataset.
    /// For even n, returns the average of the two middle values.
    static func median(_ sortedData: [Double]) -> Double {
        guard !sortedData.isEmpty else { return 0 }
        let n = sortedData.count
        if n % 2 == 1 {
            return sortedData[n / 2]
        }
        return (sortedData[n / 2 - 1] + sortedData[n / 2]) / 2.0
    }

    /// Mode: value(s) that appear most frequently.
    /// Returns empty array if every value is unique (no repeats).
    static func mode(_ data: [Double]) -> [Double] {
        guard !data.isEmpty else { return [] }
        var freq: [Double: Int] = [:]
        for v in data { freq[v, default: 0] += 1 }
        let maxFreq = freq.values.max() ?? 0
        if maxFreq <= 1 { return [] } // all unique
        return freq.filter { $0.value == maxFreq }.keys.sorted()
    }

    /// Range: max − min
    static func range(_ data: [Double]) -> Double {
        guard let lo = data.min(), let hi = data.max() else { return 0 }
        return hi - lo
    }

    /// Minimum value
    static func minimum(_ data: [Double]) -> Double {
        data.min() ?? 0
    }

    /// Maximum value
    static func maximum(_ data: [Double]) -> Double {
        data.max() ?? 0
    }

    // MARK: - Spread

    /// Population variance: σ² = Σ(xᵢ − x̄)² / n
    static func variance(_ data: [Double]) -> Double {
        guard data.count > 0 else { return 0 }
        let m = mean(data)
        let sumSq = data.reduce(0.0) { $0 + ($1 - m) * ($1 - m) }
        return sumSq / Double(data.count)
    }

    /// Population standard deviation: σ = √variance
    static func standardDeviation(_ data: [Double]) -> Double {
        sqrt(variance(data))
    }

    // MARK: - Quartiles

    /// First quartile (Q1): median of the lower half.
    /// Uses the exclusive method (lower half excludes the true median for odd n).
    static func q1(_ sortedData: [Double]) -> Double {
        guard sortedData.count >= 2 else { return sortedData.first ?? 0 }
        let lowerHalf = Array(sortedData.prefix(sortedData.count / 2))
        return median(lowerHalf)
    }

    /// Third quartile (Q3): median of the upper half.
    static func q3(_ sortedData: [Double]) -> Double {
        guard sortedData.count >= 2 else { return sortedData.last ?? 0 }
        let startIndex = (sortedData.count + 1) / 2
        let upperHalf = Array(sortedData.suffix(from: startIndex))
        return median(upperHalf)
    }

    /// Interquartile range: IQR = Q3 − Q1
    static func iqr(_ sortedData: [Double]) -> Double {
        q3(sortedData) - q1(sortedData)
    }

    // MARK: - Frequency map (used by charts)

    /// Returns sorted (value, frequency) pairs.
    static func frequencyTable(_ data: [Double]) -> [(value: Double, count: Int)] {
        var freq: [Double: Int] = [:]
        for v in data { freq[v, default: 0] += 1 }
        return freq.sorted { $0.key < $1.key }.map { (value: $0.key, count: $0.value) }
    }

    // MARK: - Formatting

    /// Rounds to at most 4 decimal places; strips trailing zeros.
    static func fmt(_ value: Double) -> String {
        if value == value.rounded() && abs(value) < 1e12 {
            return String(Int(value))
        }
        let s = String(format: "%.4f", value)
        // strip trailing zeros after the decimal point
        var trimmed = s
        while trimmed.hasSuffix("0") { trimmed = String(trimmed.dropLast()) }
        if trimmed.hasSuffix(".") { trimmed = String(trimmed.dropLast()) }
        return trimmed
    }
}
