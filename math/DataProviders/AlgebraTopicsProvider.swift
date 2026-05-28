import Foundation

/// Provides curated algebra topics for learning
struct AlgebraTopicsProvider {
    /// Polynomials topic
    static let polynomials = Topic(
        id: "algebra_polynomials",
        title: "Polynomials",
        category: .algebra,
        description: "Expressions with multiple terms and variables",
        explanation: """
            A polynomial is an expression with variables and coefficients.
            
            General form: aₙxⁿ + aₙ₋₁xⁿ⁻¹ + ... + a₁x + a₀
            
            Key concepts:
            • Degree: highest power of the variable
            • Terms: separated by + or -
            • Like terms: same variable and power
            • Operations: addition, subtraction, multiplication, division
            
            Types:
            • Monomial: one term (3x²)
            • Binomial: two terms (x + 2)
            • Trinomial: three terms (x² + 2x + 1)
            """,
        examples: [
            Example(
                title: "Combining like terms",
                description: "3x² + 2x + 5x² - x",
                solution: "(3x² + 5x²) + (2x - x) = 8x² + x"
            ),
            Example(
                title: "Polynomial multiplication",
                description: "(x + 2)(x + 3)",
                solution: "= x² + 3x + 2x + 6 = x² + 5x + 6"
            )
        ],
        relatedFormulas: []
    )
    
    /// Equations and inequalities topic
    static let equationsInequalities = Topic(
        id: "algebra_equations",
        title: "Equations and Inequalities",
        category: .algebra,
        description: "Solving for unknowns and comparing values",
        explanation: """
            An equation states that two expressions are equal.
            An inequality shows a relationship between expressions (>, <, ≥, ≤).
            
            Solving principles:
            • Same operation on both sides
            • Inverse operations to isolate variable
            • For inequalities: reverse sign if multiply/divide by negative
            
            Types:
            • Linear: ax + b = c
            • Quadratic: ax² + bx + c = 0
            • Absolute value: |x| = a
            • Systems: multiple equations
            """,
        examples: [
            Example(
                title: "Linear equation",
                description: "2x + 3 = 11",
                solution: "2x = 8, x = 4"
            ),
            Example(
                title: "Quadratic equation",
                description: "x² + 5x + 6 = 0",
                solution: "(x + 2)(x + 3) = 0, so x = -2 or x = -3"
            )
        ],
        relatedFormulas: []
    )
    
    /// Factoring topic
    static let factoring = Topic(
        id: "algebra_factoring",
        title: "Factoring",
        category: .algebra,
        description: "Breaking down expressions into factor pairs",
        explanation: """
            Factoring is finding what to multiply to get the polynomial.
            
            Methods:
            • GCF (Greatest Common Factor): factor out the largest common divisor
            • Difference of squares: a² - b² = (a + b)(a - b)
            • Trinomials: ax² + bx + c with factoring patterns
            • Grouping: group terms and factor
            
            Common patterns:
            • x² + 2xy + y² = (x + y)²
            • x² - 2xy + y² = (x - y)²
            • x³ + y³ = (x + y)(x² - xy + y²)
            • x³ - y³ = (x - y)(x² + xy + y²)
            """,
        examples: [
            Example(
                title: "GCF factoring",
                description: "6x² + 9x + 3",
                solution: "= 3(2x² + 3x + 1) = 3(2x + 1)(x + 1)"
            ),
            Example(
                title: "Difference of squares",
                description: "x² - 16",
                solution: "= (x + 4)(x - 4)"
            )
        ],
        relatedFormulas: []
    )
    
    /// Functions topic
    static let functions = Topic(
        id: "algebra_functions",
        title: "Functions",
        category: .algebra,
        description: "Relationships between inputs and outputs",
        explanation: """
            A function relates inputs to outputs where each input has exactly one output.
            
            Notation: f(x) where x is input and f(x) is output
            
            Key concepts:
            • Domain: all possible inputs
            • Range: all possible outputs
            • Mapping: how inputs relate to outputs
            • Composition: combining functions f(g(x))
            
            Function operations:
            • (f + g)(x) = f(x) + g(x)
            • (f - g)(x) = f(x) - g(x)
            • (f·g)(x) = f(x)·g(x)
            • (f/g)(x) = f(x)/g(x), g(x) ≠ 0
            """,
        examples: [
            Example(
                title: "Function evaluation",
                description: "If f(x) = 2x + 1, find f(3)",
                solution: "f(3) = 2(3) + 1 = 7"
            ),
            Example(
                title: "Function composition",
                description: "If f(x) = x + 2 and g(x) = x², find f(g(2))",
                solution: "g(2) = 4, f(4) = 6"
            )
        ],
        relatedFormulas: []
    )
    
    /// Rational expressions topic
    static let rationalExpressions = Topic(
        id: "algebra_rational",
        title: "Rational Expressions",
        category: .algebra,
        description: "Fractions with polynomials",
        explanation: """
            A rational expression is a quotient of two polynomials.
            
            Form: P(x)/Q(x) where P and Q are polynomials, Q ≠ 0
            
            Operations:
            • Simplify: factor and cancel common terms
            • Multiply: (P/Q) · (R/S) = PR/QS
            • Divide: (P/Q) ÷ (R/S) = (P/Q) · (S/R)
            • Add/Subtract: find common denominator
            
            Domain restrictions: exclude values that make denominator 0
            """,
        examples: [
            Example(
                title: "Simplify",
                description: "(x² + 5x + 6)/(x + 2)",
                solution: "= (x + 2)(x + 3)/(x + 2) = x + 3"
            ),
            Example(
                title: "Multiply",
                description: "(2x)/(x + 1) · (x + 1)/(4)",
                solution: "= 2x·(x + 1) / [4(x + 1)] = 2x/4 = x/2"
            )
        ],
        relatedFormulas: []
    )
    
    /// All algebra topics in order of progression
    static let allTopics: [Topic] = [
        polynomials,
        equationsInequalities,
        factoring,
        functions,
        rationalExpressions
    ]
    
    /// Get topic by ID
    static func topic(withId id: String) -> Topic? {
        allTopics.first { $0.id == id }
    }
}
