import Foundation

/// Service for generating step-by-step explanations of algebraic operations
/// Supports multiple difficulty levels and learning styles
class StepExplainer {
    
    /// Generate an explanation for why a specific solving step is correct
    /// - Parameters:
    ///   - step: The SolutionStep to explain
    ///   - difficulty: The difficulty level (affects language complexity)
    /// - Returns: Human-readable explanation string
    func explain(step: SolutionStep, difficulty: Difficulty) -> String {
        switch step.operation {
        case .addBothSides(let value):
            return explainAddBothSides(value: value, difficulty: difficulty)
        case .subtractBothSides(let value):
            return explainSubtractBothSides(value: value, difficulty: difficulty)
        case .multiplyBothSides(let value):
            return explainMultiplyBothSides(value: value, difficulty: difficulty)
        case .divideBothSides(let value):
            return explainDivideBothSides(value: value, difficulty: difficulty)
        case .factor:
            return explainFactor(difficulty: difficulty)
        case .applyQuadraticFormula:
            return explainQuadraticFormula(difficulty: difficulty)
        case .substitute(let variable, _):
            return explainSubstitute(variable: variable, difficulty: difficulty)
        case .simplify:
            return explainSimplify(difficulty: difficulty)
        case .collectLikeTerms:
            return explainCollectLikeTerms(difficulty: difficulty)
        case .applyTrigIdentity(let identity):
            return "Apply the trigonometric identity: \(identity)"
        case .applyLogRule(let rule):
            return "Apply the logarithmic rule: \(rule)"
        case .differentiate(let rule):
            return "Differentiate using \(rule)"
        case .integrate(let rule):
            return "Integrate using \(rule)"
        case .substituteValue(let variable, let value):
            return "Substitute \(variable) = \(value)"
        case .rewrite(let from, let to):
            return "Rewrite \(from) as \(to)"
        case .calculateMean:
            return "Calculate the mean of the data set"
        case .calculateMedian:
            return "Calculate the median of the data set"
        case .calculateMode:
            return "Calculate the mode of the data set"
        case .calculateVariance:
            return "Calculate the variance of the data set"
        case .calculateStandardDeviation:
            return "Calculate the standard deviation"
        case .sortData:
            return "Sort the data in ascending order"
        case .calculateZScore:
            return "Calculate the z-score"
        case .identifyFormula(let formula):
            return "Identified formula: \(formula)"
        case .substituteValues:
            return "Substitute known values into the formula"
        case .rearrangeFormula(let formula):
            return "Rearrange to solve: \(formula)"
        case .convertUnit(let from, let to):
            return "Convert units from \(from) to \(to)"
        case .computeResult:
            return "Calculate the final result"
        case .evaluateLimit(let method):
            return "Evaluate the limit using \(method)"
        case .simplifyExpression:
            return "Simplify the expression algebraically"
        case .evaluateAtBounds:
            return "Evaluate at bounds and subtract"
        case .identifyIndeterminateForm(let form):
            return "Identify the indeterminate form: \(form)"
        }
    }
    
    // MARK: - Operation-Specific Explainers
    
    private func explainAddBothSides(value: Double, difficulty: Difficulty) -> String {
        let absValue = Int(abs(value))
        switch difficulty {
        case .beginner:
            return "We add \(absValue) to both sides to keep the equation balanced. Think of it like a balanced scale—whatever you do to one side, you must do to the other."
        case .intermediate:
            return "Adding the same value to both sides maintains the equality. This is the additive property of equality: if a = b, then a + \(absValue) = b + \(absValue)."
        case .advanced:
            return "Apply the additive identity property: adding \(absValue) to both sides preserves the solution set since both expressions remain equal."
        }
    }
    
    private func explainSubtractBothSides(value: Double, difficulty: Difficulty) -> String {
        let absValue = Int(abs(value))
        switch difficulty {
        case .beginner:
            return "We subtract \(absValue) from both sides to keep things equal. A balanced scale stays balanced whether you add or remove the same weight from each side."
        case .intermediate:
            return "Subtracting the same value from both sides maintains equality. This is the subtractive property of equality: if a = b, then a - \(absValue) = b - \(absValue)."
        case .advanced:
            return "The subtractive property of equality ensures that subtracting \(absValue) from both sides preserves the equation's equivalence class."
        }
    }
    
    private func explainMultiplyBothSides(value: Double, difficulty: Difficulty) -> String {
        let intValue = Int(value)
        switch difficulty {
        case .beginner:
            return "We multiply both sides by \(intValue). Just like adding or subtracting, multiplying both sides the same way keeps the equation balanced."
        case .intermediate:
            return "The multiplicative property of equality states: if a = b, then \(intValue) × a = \(intValue) × b. Both sides stay equal when multiplied by the same non-zero number."
        case .advanced:
            return "Multiplying both sides by the non-zero scalar \(intValue) preserves equality and maintains the solution set."
        }
    }
    
    private func explainDivideBothSides(value: Double, difficulty: Difficulty) -> String {
        let intValue = Int(value)
        switch difficulty {
        case .beginner:
            return "We divide both sides by \(intValue). This is the opposite of multiplying, and it helps us isolate the variable x on one side."
        case .intermediate:
            return "The multiplicative property of equality allows us to divide both sides by \(intValue) (since \(intValue) ≠ 0). If a = b, then a/\(intValue) = b/\(intValue)."
        case .advanced:
            return "Multiplying both sides by the multiplicative inverse 1/\(intValue) solves for the isolated variable while preserving equation equivalence."
        }
    }
    
    private func explainFactor(difficulty: Difficulty) -> String {
        switch difficulty {
        case .beginner:
            return "Factoring means finding what we multiplied together to get this expression. Like breaking a number into its building blocks."
        case .intermediate:
            return "Factoring rewrites the quadratic as a product of two linear expressions. This allows us to use the zero product property: if AB = 0, then A = 0 or B = 0."
        case .advanced:
            return "Factoring decomposes the quadratic polynomial into linear factors over the coefficient field, enabling application of the zero product property."
        }
    }
    
    private func explainQuadraticFormula(difficulty: Difficulty) -> String {
        switch difficulty {
        case .beginner:
            return "The quadratic formula (x = -b ± √(b² - 4ac)) / 2a) is a special recipe that works for ANY quadratic equation. We just plug in our numbers a, b, and c."
        case .intermediate:
            return "The quadratic formula is derived from completing the square. It directly provides the solutions without needing to factor: x = (-b ± √(b² - 4ac)) / (2a)."
        case .advanced:
            return "The quadratic formula solves ax² + bx + c = 0 by completing the square, yielding x = (-b ± √Δ) / (2a) where Δ = b² - 4ac is the discriminant."
        }
    }
    
    private func explainSubstitute(variable: String, difficulty: Difficulty) -> String {
        switch difficulty {
        case .beginner:
            return "We substitute (replace) \(variable) with its value in the other equation. This helps us when we have a system of equations."
        case .intermediate:
            return "Substitution replaces the variable with its known value from another equation. This reduces the system complexity and moves toward the solution."
        case .advanced:
            return "Substitution method: replacing the variable with its solved expression reduces the system dimensionality from n equations in n unknowns."
        }
    }
    
    private func explainSimplify(difficulty: Difficulty) -> String {
        switch difficulty {
        case .beginner:
            return "Simplify means combining what we can to make the equation simpler. Like combining similar items into a single count."
        case .intermediate:
            return "Simplifying combines like terms and performs arithmetic operations to express the equation in its most basic form."
        case .advanced:
            return "Simplification reduces the expression by combining homogeneous terms and evaluating constants to canonical form."
        }
    }
    
    private func explainCollectLikeTerms(difficulty: Difficulty) -> String {
        switch difficulty {
        case .beginner:
            return "Like terms are terms with the same variable. For example, 2x and 3x are like terms, so 2x + 3x = 5x. Collecting them makes the equation simpler."
        case .intermediate:
            return "Collecting like terms combines terms with the same variables and exponents. Terms with x are combined separately from constants."
        case .advanced:
            return "Combining like terms groups coefficients of identical monomials, reducing polynomial degree and simplifying the expression."
        }
    }
    /// Generate hints for each step in progressive detail
    /// - Parameters:
    ///   - step: The SolutionStep to generate hints for
    ///   - hintLevel: 1 (vague), 2 (medium), 3 (detailed)
    /// - Returns: A hint that guides without revealing the answer
    func generateHint(for step: SolutionStep, level: Int) -> String {
        switch step.operation {
        case .addBothSides(let value):
            return hintForAddBothSides(value: value, level: level)
        case .subtractBothSides(let value):
            return hintForSubtractBothSides(value: value, level: level)
        case .multiplyBothSides(let value):
            return hintForMultiplyBothSides(value: value, level: level)
        case .divideBothSides(let value):
            return hintForDivideBothSides(value: value, level: level)
        case .factor:
            return hintForFactor(level: level)
        case .applyQuadraticFormula:
            return hintForQuadraticFormula(level: level)
        case .substitute(let variable, _):
            return hintForSubstitute(variable: variable, level: level)
        case .simplify:
            return hintForSimplify(level: level)
        case .collectLikeTerms:
            return hintForCollectLikeTerms(level: level)
        case .applyTrigIdentity(let identity):
            return "Hint: Apply the identity \(identity)"
        case .applyLogRule(let rule):
            return "Hint: Apply the rule \(rule)"
        case .differentiate(let rule):
            return "Hint: Use the \(rule) to differentiate"
        case .integrate(let rule):
            return "Hint: Use \(rule) to integrate"
        case .substituteValue(let variable, let value):
            return "Hint: Replace \(variable) with \(value)"
        case .rewrite(let from, let to):
            return "Hint: Rewrite \(from) in the form \(to)"
        case .calculateMean, .calculateMedian, .calculateMode,
             .calculateVariance, .calculateStandardDeviation,
             .sortData, .calculateZScore:
            return "Hint: Follow the statistical calculation step"
        case .identifyFormula:
            return "Hint: Identify the correct formula to use"
        case .substituteValues:
            return "Hint: Substitute the known values into the formula"
        case .rearrangeFormula:
            return "Hint: Rearrange the formula to solve for the unknown"
        case .convertUnit(let from, let to):
            return "Hint: Convert from \(from) to \(to)"
        case .computeResult:
            return "Hint: Calculate the final numerical result"
        case .evaluateLimit(let method):
            return "Hint: Evaluate the limit using \(method)"
        case .simplifyExpression:
            return "Hint: Simplify the expression algebraically"
        case .evaluateAtBounds:
            return "Hint: Evaluate the antiderivative at the bounds and subtract"
        case .identifyIndeterminateForm(let form):
            return "Hint: Identify the indeterminate form \(form)"
        }
    }
    
    // MARK: - Hint Generators
    
    private func hintForAddBothSides(value: Double, level: Int) -> String {
        let absValue = Int(abs(value))
        switch level {
        case 1:
            return "What do you need to do to both sides?"
        case 2:
            return "Try adding or subtracting \(absValue) from both sides. Which one should it be?"
        case 3:
            return "Add \(absValue) to both sides, then simplify."
        default:
            return "Review: add \(absValue) to both sides to isolate the variable term."
        }
    }
    
    private func hintForSubtractBothSides(value: Double, level: Int) -> String {
        let absValue = Int(abs(value))
        switch level {
        case 1:
            return "What number should you move to the other side?"
        case 2:
            return "Subtract \(absValue) from both sides to move it."
        case 3:
            return "Subtract \(absValue) from both sides, then simplify both sides."
        default:
            return "Review: subtract \(absValue) from both sides to isolate terms."
        }
    }
    
    private func hintForMultiplyBothSides(value: Double, level: Int) -> String {
        let intValue = Int(value)
        switch level {
        case 1:
            return "What operation connects the variable to its coefficient?"
        case 2:
            return "The variable has a coefficient. Multiply or divide to isolate it."
        case 3:
            return "Multiply both sides by \(intValue) to eliminate fractions or isolate the variable."
        default:
            return "Review: multiply both sides by \(intValue) to solve."
        }
    }
    
    private func hintForDivideBothSides(value: Double, level: Int) -> String {
        let intValue = Int(value)
        switch level {
        case 1:
            return "The variable has a number multiplied with it. What should you do?"
        case 2:
            return "Divide both sides by \(intValue) to separate the variable from its coefficient."
        case 3:
            return "Divide both sides by \(intValue), then simplify to get x alone."
        default:
            return "Review: divide both sides by \(intValue) to isolate x."
        }
    }
    
    private func hintForFactor(level: Int) -> String {
        switch level {
        case 1:
            return "Can this expression be written as a product?"
        case 2:
            return "Look for two numbers that multiply and add up to certain values in the quadratic."
        case 3:
            return "Factor as two binomials, then apply the zero product property."
        default:
            return "Review: find factors that help solve the quadratic."
        }
    }
    
    private func hintForQuadraticFormula(level: Int) -> String {
        switch level {
        case 1:
            return "There's a formula for quadratics. What are its parts?"
        case 2:
            return "Use x = (-b ± √(b² - 4ac)) / (2a). What are your a, b, and c values?"
        case 3:
            return "Identify a, b, c, plug into the formula, and simplify."
        default:
            return "Review: apply the quadratic formula with your coefficients."
        }
    }
    
    private func hintForSubstitute(variable: String, level: Int) -> String {
        switch level {
        case 1:
            return "You know what one variable is. Substitute it into the other equation."
        case 2:
            return "Replace \(variable) with what you found, then solve for the other variable."
        case 3:
            return "Substitute the value of \(variable) into the other equation and solve."
        default:
            return "Review: substitute \(variable) to eliminate it from the other equation."
        }
    }
    
    private func hintForSimplify(level: Int) -> String {
        switch level {
        case 1:
            return "Can you make this simpler by combining things?"
        case 2:
            return "Combine like terms and do the arithmetic."
        case 3:
            return "Combine all like terms and perform any possible arithmetic."
        default:
            return "Review: simplify by combining like terms."
        }
    }
    
    private func hintForCollectLikeTerms(level: Int) -> String {
        switch level {
        case 1:
            return "Which terms look similar?"
        case 2:
            return "Find all terms with x, find all numbers without x. Group them together."
        case 3:
            return "Add all x terms together and all number terms together."
        default:
            return "Review: collect similar terms and add them."
        }
    }
}

// MARK: - Singleton Instance

/// Global singleton instance of StepExplainer
let stepExplainer = StepExplainer()
