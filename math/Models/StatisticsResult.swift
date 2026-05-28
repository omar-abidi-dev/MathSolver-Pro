import Foundation

/// Represents the complete output of a descriptive statistics calculation
struct StatisticsResult {
    /// Original input values
    let dataset: [Double]
    
    /// Dataset sorted in ascending order
    let sortedData: [Double]
    
    /// Number of values in the dataset
    let count: Int
    
    /// Arithmetic mean (average)
    let mean: Double
    
    /// Middle value(s) when sorted
    let median: Double
    
    /// Most frequent value(s); empty if no repeats
    let mode: [Double]
    
    /// Difference between max and min
    let range: Double
    
    /// Smallest value
    let min: Double
    
    /// Largest value
    let max: Double
    
    /// Population variance: Σ(xi - μ)² / N
    let populationVariance: Double
    
    /// Sample variance: Σ(xi - x̄)² / (N-1)
    let sampleVariance: Double?
    
    /// Population standard deviation: √(populationVariance)
    let populationStdDev: Double
    
    /// Sample standard deviation: √(sampleVariance)
    let sampleStdDev: Double?
    
    /// Step-by-step calculation breakdown
    let steps: [SolutionStep]
    
    /// Initialize from a dataset and pre-computed statistics
    init(
        dataset: [Double],
        sortedData: [Double],
        mean: Double,
        median: Double,
        mode: [Double],
        range: Double,
        min: Double,
        max: Double,
        populationVariance: Double,
        sampleVariance: Double?,
        populationStdDev: Double,
        sampleStdDev: Double?,
        steps: [SolutionStep]
    ) {
        self.dataset = dataset
        self.sortedData = sortedData
        self.count = dataset.count
        self.mean = mean
        self.median = median
        self.mode = mode
        self.range = range
        self.min = min
        self.max = max
        self.populationVariance = populationVariance
        self.sampleVariance = sampleVariance
        self.populationStdDev = populationStdDev
        self.sampleStdDev = sampleStdDev
        self.steps = steps
    }
}
