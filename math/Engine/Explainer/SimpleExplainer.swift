import Foundation

/// Generates simple, child-friendly explanations for mathematical problems
class SimpleExplainer {
    /// Generates a plain-language explanation a 10-year-old would understand
    /// - Parameters:
    ///   - equation: The original equation
    ///   - steps: The solution steps
    /// - Returns: A simple explanation with no jargon
    static func explainSimply(equation: Equation, steps: [SolutionStep]) -> String {
        switch equation.equationType {
        case .linear:
            return explainLinearSimply(equation: equation, steps: steps)
        case .quadratic:
            return explainQuadraticSimply(equation: equation, steps: steps)
        case .system:
            return explainSystemSimply(equation: equation, steps: steps)
        case .trigonometric, .logarithmic, .polynomial, .derivative, .integral, .statistics, .physics:
            return "This type of equation is not yet supported in simple explanations."
        }
    }
    
    private static func explainLinearSimply(equation: Equation, steps: [SolutionStep]) -> String {
        return """
        🔍 **Finding the Hidden Number**
        
        Think of this like a mystery! We have a hidden number (that's x), and we need to find it.
        
        Here's how we solve it:
        1. We started with some clues about the hidden number
        2. We moved all the plain numbers to one side
        3. We moved all the stuff with the hidden number to the other side
        4. Then we figured out what the hidden number is!
        
        It's like solving a puzzle - we work backwards from what we know to find the missing piece. 🧩
        """
    }
    
    private static func explainQuadraticSimply(equation: Equation, steps: [SolutionStep]) -> String {
        return """
        📦 **Finding Two Hidden Numbers**
        
        Imagine you're building a square shape, and the area is already given. We need to find how long each side is.
        
        For these tricky equations:
        1. We either try to split it into smaller pieces (like factoring)
        2. Or we use a special formula (the quadratic formula - like a superhero tool!)
        3. This gives us TWO possible answers (two hidden numbers!)
        
        Both answers are correct - it's like saying "the number could be this OR that!" ✨
        """
    }
    
    private static func explainSystemSimply(equation: Equation, steps: [SolutionStep]) -> String {
        return """
        👥 **Two Friends with a Mystery**
        
        Imagine two friends, and each has a clue about hidden numbers. We need to find the numbers that make BOTH clues true at the same time.
        
        Here's the trick:
        1. We look at what the first friend knows
        2. We look at what the second friend knows
        3. We find the numbers that make BOTH happy!
        
        It's like saying: "Which numbers will solve the first puzzle AND the second puzzle?" 🔑
        """
    }
}
