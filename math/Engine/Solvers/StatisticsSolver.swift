import Foundation

/// Solves descriptive statistics problems
struct StatisticsSolver {
    /// Solve a statistics problem from a numeric dataset
    static func solve(dataset: [Double]) -> Result<StatisticsResult, SolverError> {
        guard !dataset.isEmpty else {
            return .failure(.solverFailed("Dataset cannot be empty"))
        }
        
        guard dataset.allSatisfy({ $0.isFinite }) else {
            return .failure(.solverFailed("All values must be finite numbers"))
        }
        
        var steps: [SolutionStep] = []
        var stepNumber = 1
        
        // Step 1: Sort data
        let sortedData = dataset.sorted()
        steps.append(SolutionStep(
            stepNumber: stepNumber,
            operation: .sortData,
            description: "Sort the data in ascending order",
            resultEquation: sortedData.map { String(format: "%.2f", $0) }.joined(separator: ", "),
            explanation: "Sorting helps find median and identify patterns in the distribution."
        ))
        stepNumber += 1
        
        let count = Double(dataset.count)
        
        // Step 2: Calculate mean
        let sum = dataset.reduce(0, +)
        let mean = sum / count
        steps.append(SolutionStep(
            stepNumber: stepNumber,
            operation: .calculateMean,
            description: "Calculate the mean",
            resultEquation: "Mean = \(String(format: "%.4f", mean))",
            explanation: "Mean = Sum ÷ Count = \(String(format: "%.2f", sum)) ÷ \(Int(count)) = \(String(format: "%.4f", mean))"
        ))
        stepNumber += 1
        
        // Step 3: Calculate median
        let median: Double
        if dataset.count % 2 == 1 {
            median = sortedData[dataset.count / 2]
        } else {
            median = (sortedData[dataset.count / 2 - 1] + sortedData[dataset.count / 2]) / 2
        }
        steps.append(SolutionStep(
            stepNumber: stepNumber,
            operation: .calculateMedian,
            description: "Calculate the median",
            resultEquation: "Median = \(String(format: "%.4f", median))",
            explanation: "The median is the middle value of the sorted data."
        ))
        stepNumber += 1
        
        // Step 4: Calculate mode
        var frequencyMap: [Double: Int] = [:]
        for value in dataset {
            frequencyMap[value, default: 0] += 1
        }
        let maxFrequency = frequencyMap.values.max() ?? 0
        let mode = maxFrequency > 1 ? frequencyMap.filter { $0.value == maxFrequency }.keys.sorted() : []
        steps.append(SolutionStep(
            stepNumber: stepNumber,
            operation: .calculateMode,
            description: "Calculate the mode",
            resultEquation: mode.isEmpty ? "No mode (no repeating values)" : mode.map { String(format: "%.2f", $0) }.joined(separator: ", "),
            explanation: "The mode is the value(s) that appear most frequently. " + (mode.isEmpty ? "In this dataset, all values appear once." : "Frequency: \(maxFrequency) times")
        ))
        stepNumber += 1
        
        // Step 5: Calculate range
        let min = dataset.min() ?? 0
        let max = dataset.max() ?? 0
        let range = max - min
        steps.append(SolutionStep(
            stepNumber: stepNumber,
            operation: .simplify,
            description: "Calculate the range",
            resultEquation: "Range = \(String(format: "%.4f", range))",
            explanation: "Range = Max - Min = \(String(format: "%.2f", max)) - \(String(format: "%.2f", min)) = \(String(format: "%.4f", range))"
        ))
        stepNumber += 1
        
        // Step 6: Calculate population variance
        let sumSquaredDifferences = dataset.map { pow($0 - mean, 2) }.reduce(0, +)
        let populationVariance = sumSquaredDifferences / count
        steps.append(SolutionStep(
            stepNumber: stepNumber,
            operation: .calculateVariance,
            description: "Calculate the population variance",
            resultEquation: "σ² = \(String(format: "%.4f", populationVariance))",
            explanation: "Variance = Σ(x - mean)² ÷ N = \(String(format: "%.4f", populationVariance))"
        ))
        stepNumber += 1
        
        // Step 7: Calculate population standard deviation
        let populationStdDev = sqrt(populationVariance)
        steps.append(SolutionStep(
            stepNumber: stepNumber,
            operation: .calculateStandardDeviation,
            description: "Calculate the population standard deviation",
            resultEquation: "σ = \(String(format: "%.4f", populationStdDev))",
            explanation: "Standard Deviation = √(Variance) = √\(String(format: "%.4f", populationVariance)) = \(String(format: "%.4f", populationStdDev))"
        ))
        stepNumber += 1
        
        // Sample variance and standard deviation (only if n > 1)
        let sampleVariance: Double?
        let sampleStdDev: Double?
        if dataset.count > 1 {
            sampleVariance = sumSquaredDifferences / (count - 1)
            sampleStdDev = sqrt(sampleVariance ?? 0)
            steps.append(SolutionStep(
                stepNumber: stepNumber,
                operation: .calculateVariance,
                description: "Calculate the sample variance",
                resultEquation: "s² = \(String(format: "%.4f", sampleVariance ?? 0))",
                explanation: "Sample Variance = Σ(x - mean)² ÷ (N-1) = \(String(format: "%.4f", sampleVariance ?? 0))"
            ))
            stepNumber += 1
            
            steps.append(SolutionStep(
                stepNumber: stepNumber,
                operation: .calculateStandardDeviation,
                description: "Calculate the sample standard deviation",
                resultEquation: "s = \(String(format: "%.4f", sampleStdDev ?? 0))",
                explanation: "Sample Std Dev = √(Sample Variance) = \(String(format: "%.4f", sampleStdDev ?? 0))"
            ))
        } else {
            sampleVariance = nil
            sampleStdDev = nil
        }
        
        let result = StatisticsResult(
            dataset: dataset,
            sortedData: sortedData,
            mean: mean,
            median: median,
            mode: mode,
            range: range,
            min: min,
            max: max,
            populationVariance: populationVariance,
            sampleVariance: sampleVariance,
            populationStdDev: populationStdDev,
            sampleStdDev: sampleStdDev,
            steps: steps
        )
        
        return .success(result)
    }
    
    /// Calculate z-score: z = (x - μ) / σ
    static func calculateZScore(x: Double, mean: Double, stdDev: Double) -> Double {
        guard stdDev > 0 else { return 0 }
        return (x - mean) / stdDev
    }
    
    /// Approximate normal distribution CDF using Abramowitz & Stegun formula 26.2.17
    /// Accuracy: ~7 decimal places
    static func normalCDF(z: Double) -> Double {
        let b1 = 0.319381530
        let b2 = -0.356563782
        let b3 = 1.781477937
        let b4 = -1.821255978
        let b5 = 1.330274429
        let p = 0.2316419
        
        let t = 1.0 / (1.0 + p * abs(z))
        let t2 = t * t
        let t3 = t2 * t
        let t4 = t3 * t
        let t5 = t4 * t
        
        let phi = 1.0 / sqrt(2.0 * .pi) * exp(-0.5 * z * z)
        let cdf = phi * (b1 * t + b2 * t2 + b3 * t3 + b4 * t4 + b5 * t5)
        
        return z >= 0 ? 1.0 - cdf : cdf
    }
}
