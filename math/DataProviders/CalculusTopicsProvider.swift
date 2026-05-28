import Foundation

/// Provides curated calculus topics for learning
struct CalculusTopicsProvider {
    /// Limits topic with explanation and examples
    static let limits = Topic(
        id: "calculus_limits",
        title: "Limits",
        category: .calculus,
        description: "Understanding function behavior as variables approach specific values",
        explanation: """
            A limit describes the value that a function approaches as the input approaches some value.
            
            Notation: lim(x→a) f(x) = L means as x gets closer to a, f(x) gets closer to L.
            
            Key concepts:
            • One-sided limits (left and right)
            • Infinite limits
            • Limits at infinity
            • Continuity and limits
            """,
        examples: [
            Example(
                title: "Simple limit",
                description: "lim(x→2) (x² + 1)",
                solution: "= 2² + 1 = 5"
            ),
            Example(
                title: "Limit with indeterminate form",
                description: "lim(x→2) (x² - 4)/(x - 2)",
                solution: "Factor: (x - 2)(x + 2)/(x - 2) = x + 2 = 4"
            )
        ],
        relatedFormulas: []
    )
    
    /// Derivatives topic with explanation and examples
    static let derivatives = Topic(
        id: "calculus_derivatives",
        title: "Derivatives",
        category: .calculus,
        description: "Rate of change and slope of functions",
        explanation: """
            A derivative measures how a function changes as its input changes.
            It represents the slope of the function at a given point.
            
            Definition: f'(x) = lim(h→0) [f(x+h) - f(x)]/h
            
            Key rules:
            • Power rule: d/dx(xⁿ) = n·x^(n-1)
            • Product rule: (fg)' = f'g + fg'
            • Quotient rule: (f/g)' = (f'g - fg')/g²
            • Chain rule: d/dx[f(g(x))] = f'(g(x))·g'(x)
            """,
        examples: [
            Example(
                title: "Power rule",
                description: "Find derivative of f(x) = x³ + 2x²",
                solution: "f'(x) = 3x² + 4x"
            ),
            Example(
                title: "Chain rule",
                description: "Find derivative of f(x) = (3x + 1)⁵",
                solution: "f'(x) = 5(3x + 1)⁴ · 3 = 15(3x + 1)⁴"
            )
        ],
        relatedFormulas: []
    )
    
    /// Integrals topic with explanation and examples
    static let integrals = Topic(
        id: "calculus_integrals",
        title: "Integrals",
        category: .calculus,
        description: "Accumulation and antiderivatives",
        explanation: """
            An integral is the reverse of a derivative.
            It represents the area under a curve or the antiderivative of a function.
            
            Indefinite integral: ∫f(x)dx = F(x) + C (where F'(x) = f(x))
            Definite integral: ∫[a to b] f(x)dx = F(b) - F(a)
            
            Key rules:
            • Power rule: ∫xⁿ dx = x^(n+1)/(n+1) + C
            • Constant multiple: ∫k·f(x)dx = k·∫f(x)dx
            • Sum rule: ∫[f(x) + g(x)]dx = ∫f(x)dx + ∫g(x)dx
            • Integration by parts: ∫u dv = uv - ∫v du
            """,
        examples: [
            Example(
                title: "Power rule",
                description: "⌠x³ + 2x dx",
                solution: "= x⁴/4 + x² + C"
            ),
            Example(
                title: "Definite integral",
                description: "⌠₀² (x + 1) dx",
                solution: "= [x²/2 + x]₀² = (2 + 2) - 0 = 4"
            )
        ],
        relatedFormulas: []
    )
    
    /// Series and sequences topic
    static let seriesSequences = Topic(
        id: "calculus_series",
        title: "Series and Sequences",
        category: .calculus,
        description: "Infinite series and convergence",
        explanation: """
            A sequence is a list of numbers following a pattern.
            A series is the sum of a sequence.
            
            Convergence: A series converges if its partial sums approach a limit.
            
            Key series:
            • Arithmetic series: Sum = n(a₁ + aₙ)/2
            • Geometric series: Sum = a₁(1 - rⁿ)/(1 - r)
            • Power series: ∑(n=0 to ∞) aₙ·xⁿ
            • Taylor series: f(x) = ∑(n=0 to ∞) f⁽ⁿ⁾(a)/n! · (x - a)ⁿ
            """,
        examples: [
            Example(
                title: "Arithmetic series",
                description: "Sum of 2 + 4 + 6 + 8 + 10",
                solution: "= 5(2 + 10)/2 = 30"
            ),
            Example(
                title: "Geometric series",
                description: "Sum of 2 + 4 + 8 + 16 (first 4 terms)",
                solution: "= 2(1 - 2⁴)/(1 - 2) = 2(-15)/(-1) = 30"
            )
        ],
        relatedFormulas: []
    )
    
    /// All calculus topics in order of progression
    static let allTopics: [Topic] = [
        limits,
        derivatives,
        integrals,
        seriesSequences
    ]
    
    /// Get topic by ID
    static func topic(withId id: String) -> Topic? {
        allTopics.first { $0.id == id }
    }
}
