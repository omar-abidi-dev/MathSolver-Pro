import Foundation

/// Represents a solved physics problem
struct PhysicsSolution {
    /// The identified/applied formula
    let formula: PhysicsFormula
    
    /// Known variable values with their units: [symbol: (value, unit)]
    let knownVariables: [String: (value: Double, unit: String)]
    
    /// The symbol being solved for
    let unknownVariable: String
    
    /// Computed answer
    let result: Double
    
    /// Unit of the result
    let resultUnit: String
    
    /// Step-by-step solution breakdown
    let steps: [SolutionStep]
    
    /// Initialize from formula and known variables
    init(
        formula: PhysicsFormula,
        knownVariables: [String: (value: Double, unit: String)],
        unknownVariable: String,
        result: Double,
        resultUnit: String,
        steps: [SolutionStep]
    ) {
        self.formula = formula
        self.knownVariables = knownVariables
        self.unknownVariable = unknownVariable
        self.result = result
        self.resultUnit = resultUnit
        self.steps = steps
    }
    
    /// Summary of the solution
    var summary: String {
        "Solved for \(unknownVariable) = \(String(format: "%.2f", result)) \(resultUnit)"
    }
    
    /// Formatted output for display
    var formattedOutput: String {
        var output = "Formula: \(formula.name)\n"
        output += "Expression: \(formula.expression)\n\n"
        output += "Known Variables:\n"
        for (symbol, data) in knownVariables {
            output += "  \(symbol) = \(String(format: "%.2f", data.value)) \(data.unit)\n"
        }
        output += "\nSolution Steps:\n"
        for step in steps {
            output += step.formattedText
        }
        output += "\nFinal Result:\n"
        output += "\(unknownVariable) = \(String(format: "%.2f", result)) \(resultUnit)\n"
        return output
    }
}

// MARK: - SolutionStep Formatting Extension

extension SolutionStep {
    /// Formatted text for physics solution display
    var formattedText: String {
        "Step \(stepNumber): \(description)\n"
        + "  \(explanation)\n"
        + "  Result: \(resultEquation)\n\n"
    }
}
