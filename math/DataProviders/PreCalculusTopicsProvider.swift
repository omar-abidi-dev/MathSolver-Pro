import Foundation

/// Provides curated pre-calculus topics for learning
struct PreCalculusTopicsProvider {
    /// Exponents and logarithms topic
    static let exponentsLogarithms = Topic(
        id: "precalc_exponents",
        title: "Exponents and Logarithms",
        category: .preCalculus,
        description: "Powers and their inverse operations",
        explanation: """
            Exponents show repeated multiplication: x^n = x × x × ... × x (n times)
            
            Exponent rules:
            • x^a · x^b = x^(a+b)
            • x^a / x^b = x^(a-b)
            • (x^a)^b = x^(ab)
            • (xy)^a = x^a · y^a
            • x^0 = 1, x^(-a) = 1/x^a
            
            Logarithms are the inverse of exponents:
            • If x^a = y, then log_x(y) = a
            • log_x(x^a) = a
            • x^(log_x(a)) = a
            
            Logarithm rules:
            • log(ab) = log(a) + log(b)
            • log(a/b) = log(a) - log(b)
            • log(a^n) = n·log(a)
            • log_a(b) = log(b)/log(a)
            """,
        examples: [
            Example(
                title: "Exponent rules",
                description: "Simplify x³ · x⁵ / x²",
                solution: "= x^(3+5-2) = x^6"
            ),
            Example(
                title: "Logarithm",
                description: "Find x if log₂(x) = 3",
                solution: "x = 2³ = 8"
            )
        ],
        relatedFormulas: []
    )
    
    /// Linear and quadratic functions topic
    static let linearQuadratic = Topic(
        id: "precalc_linear_quadratic",
        title: "Linear and Quadratic Functions",
        category: .preCalculus,
        description: "Polynomial functions of degree 1 and 2",
        explanation: """
            Linear functions: f(x) = mx + b
            • m: slope (rise/run)
            • b: y-intercept
            • Graph: straight line
            
            Quadratic functions: f(x) = ax² + bx + c
            • Vertex form: f(x) = a(x - h)² + k, vertex at (h, k)
            • Standard form: ax² + bx + c
            • Axis of symmetry: x = -b/(2a)
            • Vertex: (-b/(2a), f(-b/(2a)))
            
            Roots (zeros):
            • Discriminant: Δ = b² - 4ac
            • Quadratic formula: x = (-b ± √Δ) / 2a
            """,
        examples: [
            Example(
                title: "Linear equation",
                description: "Find line through (1, 2) and (3, 6)",
                solution: "Slope m = (6-2)/(3-1) = 2, using point-slope: y - 2 = 2(x - 1), so y = 2x"
            ),
            Example(
                title: "Quadratic vertex",
                description: "Find vertex of f(x) = x² - 4x + 3",
                solution: "x = -b/(2a) = 4/2 = 2, f(2) = 4 - 8 + 3 = -1, vertex: (2, -1)"
            )
        ],
        relatedFormulas: []
    )
    
    /// Polynomial and rational functions topic
    static let polynomialRational = Topic(
        id: "precalc_polynomial_rational",
        title: "Polynomial and Rational Functions",
        category: .preCalculus,
        description: "Complex functions and their behavior",
        explanation: """
            Polynomial functions: f(x) = aₙx^n + aₙ₋₁x^(n-1) + ... + a₁x + a₀
            • Degree: n (highest power)
            • End behavior determined by leading term
            • Real zeros at x-intercepts
            
            Characteristics:
            • Zeros and multiplicity
            • Local extrema (maxima/minima)
            • Concavity
            • Turning points (at most n-1)
            
            Rational functions: f(x) = P(x)/Q(x)
            • Zeros: where P(x) = 0
            • Vertical asymptotes: where Q(x) = 0
            • Horizontal asymptotes: compare degrees of P and Q
            • Oblique asymptotes: when degree(P) = degree(Q) + 1
            """,
        examples: [
            Example(
                title: "Polynomial zeros",
                description: "Find zeros of f(x) = x³ - 6x² + 11x - 6",
                solution: "Factor: (x-1)(x-2)(x-3) = 0, zeros are x = 1, 2, 3"
            ),
            Example(
                title: "Rational asymptotes",
                description: "Find asymptotes of f(x) = x/(x² - 1)",
                solution: "Vertical: x = ±1, Horizontal: y = 0 (degree of denominator > numerator)"
            )
        ],
        relatedFormulas: []
    )
    
    /// Exponential and logarithmic functions topic
    static let exponentialLogarithmic = Topic(
        id: "precalc_exp_log_functions",
        title: "Exponential and Logarithmic Functions",
        category: .preCalculus,
        description: "Functions and their applications",
        explanation: """
            Exponential functions: f(x) = a · b^x (b > 0, b ≠ 1)
            • Base: b
            • Growth rate: b > 1 (growth), 0 < b < 1 (decay)
            • y-intercept: (0, a)
            • Horizontal asymptote: y = 0
            • Natural exponential: f(x) = e^x
            
            Logarithmic functions: f(x) = log_b(x)
            • Inverse of exponential: if y = b^x, then x = log_b(y)
            • Domain: x > 0
            • Vertical asymptote: x = 0
            • Natural logarithm: ln(x) = log_e(x)
            
            Applications:
            • Exponential growth/decay: N(t) = N₀ · b^t
            • Compound interest: A = P(1 + r/n)^(nt)
            • Half-life and doubling time
            """,
        examples: [
            Example(
                title: "Exponential growth",
                description: "Population grows as N(t) = 1000 · 2^(t/10). Find N(20)",
                solution: "N(20) = 1000 · 2² = 4000"
            ),
            Example(
                title: "Logarithmic equation",
                description: "Solve log(x) + log(x-1) = 1",
                solution: "log(x(x-1)) = 1, x(x-1) = 10, x² - x - 10 = 0, x ≈ 3.7"
            )
        ],
        relatedFormulas: []
    )
    
    /// Sequences and series topic
    static let sequencesSeries = Topic(
        id: "precalc_sequences_series",
        title: "Sequences and Series",
        category: .preCalculus,
        description: "Patterns of numbers and their sums",
        explanation: """
            Sequence: ordered list of numbers following a pattern
            • Arithmetic: constant difference d between consecutive terms
            • Geometric: constant ratio r between consecutive terms
            
            Arithmetic sequence:
            • General term: aₙ = a₁ + (n-1)d
            • Sum: Sₙ = n(a₁ + aₙ)/2 = n[2a₁ + (n-1)d]/2
            
            Geometric sequence:
            • General term: aₙ = a₁ · r^(n-1)
            • Sum (finite): Sₙ = a₁(1 - r^n)/(1 - r)
            • Sum (infinite, |r| < 1): S = a₁/(1 - r)
            
            Series: sum of sequence terms
            • Notation: ∑(i=1 to n) aᵢ
            • Partial sums and convergence
            """,
        examples: [
            Example(
                title: "Arithmetic sequence",
                description: "Find term 10 of sequence 2, 5, 8, 11, ...",
                solution: "d = 3, a₁ = 2, a₁₀ = 2 + 9(3) = 29"
            ),
            Example(
                title: "Geometric sum",
                description: "Find sum of 2 + 4 + 8 + 16 + 32",
                solution: "a₁ = 2, r = 2, n = 5, S₅ = 2(1 - 2⁵)/(1 - 2) = 2(-31)/(-1) = 62"
            )
        ],
        relatedFormulas: []
    )
    
    /// All pre-calculus topics in order of progression
    static let allTopics: [Topic] = [
        linearQuadratic,
        polynomialRational,
        exponentsLogarithms,
        exponentialLogarithmic,
        sequencesSeries
    ]
    
    /// Get topic by ID
    static func topic(withId id: String) -> Topic? {
        allTopics.first { $0.id == id }
    }
}
