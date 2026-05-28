import Foundation

/// Generates random solvable equations with known answers
class EquationGenerator {
    
    /// Generates a random equation based on type and difficulty
    /// - Parameters:
    ///   - type: Type of equation (linear, quadratic, system)
    ///   - difficulty: Difficulty level (beginner, intermediate, advanced)
    /// - Returns: A tuple containing the equation string and correct answer(s)
    static func generate(type: EquationType, difficulty: Difficulty) -> (equation: String, answers: [String]) {
        switch type {
        case .linear:
            return generateLinear(difficulty: difficulty)
        case .quadratic:
            return generateQuadratic(difficulty: difficulty)
        case .system:
            return generateSystem(difficulty: difficulty)
        case .trigonometric, .logarithmic, .polynomial, .derivative, .integral, .statistics, .physics:
            // Return a placeholder for unsupported types
            return (equation: "Unsupported equation type", answers: [])
        }
    }
    
    /// Generate a random linear equation
    private static func generateLinear(difficulty: Difficulty) -> (equation: String, answers: [String]) {
        let coeffRange: ClosedRange<Int>
        let constantRange: ClosedRange<Int>
        
        switch difficulty {
        case .beginner:
            coeffRange = 1...10
            constantRange = 1...20
        case .intermediate:
            coeffRange = -50...50
            constantRange = -100...100
        case .advanced:
            coeffRange = -100...100
            constantRange = -200...200
        }
        
        let a = Int.random(in: coeffRange)
        let b = Int.random(in: constantRange)
        let x = Int.random(in: -10...10)
        
        // Equation: ax + b = c
        let c = a * x + b
        
        let equation = "\(a)x + \(b) = \(c)"
        let answer = String(x)
        
        return (equation, [answer])
    }
    
    /// Generate a random quadratic equation
    private static func generateQuadratic(difficulty: Difficulty) -> (equation: String, answers: [String]) {
        let maxCoeff: Int
        
        switch difficulty {
        case .beginner:
            maxCoeff = 5
        case .intermediate:
            maxCoeff = 10
        case .advanced:
            maxCoeff = 15
        }
        
        let a = Int.random(in: 1...maxCoeff)
        let x1 = Int.random(in: -10...10)
        let x2 = Int.random(in: -10...10)
        
        // Equation: a(x - x1)(x - x2) = 0 => ax^2 - a(x1+x2)x + a*x1*x2 = 0
        let b = -a * (x1 + x2)
        let c = a * x1 * x2
        
        let equation = "\(a)x^2 + \(b)x + \(c) = 0"
        let answers = [String(min(x1, x2)), String(max(x1, x2))]
        
        return (equation, answers)
    }
    
    /// Generate a system of linear equations
    private static func generateSystem(difficulty: Difficulty) -> (equation: String, answers: [String]) {
        let range: ClosedRange<Int>
        
        switch difficulty {
        case .beginner:
            range = 1...5
        case .intermediate:
            range = -10...10
        case .advanced:
            range = -20...20
        }
        
        let x = Int.random(in: range)
        let y = Int.random(in: range)
        
        let a1 = Int.random(in: 1...5)
        let b1 = Int.random(in: 1...5)
        let c1 = a1 * x + b1 * y
        
        let a2 = Int.random(in: 1...5)
        let b2 = Int.random(in: 1...5)
        let c2 = a2 * x + b2 * y
        
        let equation = "\(a1)x + \(b1)y = \(c1), \(a2)x + \(b2)y = \(c2)"
        let answers = ["x=\(x), y=\(y)"]
        
        return (equation, answers)
    }
}
