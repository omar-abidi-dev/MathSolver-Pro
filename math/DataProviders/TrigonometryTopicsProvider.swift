import Foundation

/// Provides curated trigonometry topics for learning
struct TrigonometryTopicsProvider {
    /// Right triangles and trigonometric ratios topic
    static let rightTriangles = Topic(
        id: "trig_right_triangles",
        title: "Right Triangles",
        category: .trigonometry,
        description: "Trigonometric ratios in right triangles",
        explanation: """
            Trigonometric ratios relate angles to side lengths in right triangles.
            
            SOHCAHTOA mnemonic:
            • sin(θ) = opposite/hypotenuse
            • cos(θ) = adjacent/hypotenuse
            • tan(θ) = opposite/adjacent
            
            Reciprocal ratios:
            • csc(θ) = 1/sin(θ) = hypotenuse/opposite
            • sec(θ) = 1/cos(θ) = hypotenuse/adjacent
            • cot(θ) = 1/tan(θ) = adjacent/opposite
            
            Pythagorean theorem: a² + b² = c²
            """,
        examples: [
            Example(
                title: "Find sin(θ)",
                description: "Right triangle with opposite = 3, hypotenuse = 5",
                solution: "sin(θ) = 3/5 = 0.6"
            ),
            Example(
                title: "Find angle",
                description: "cos(θ) = 0.8, find θ",
                solution: "θ = arccos(0.8) ≈ 36.87°"
            )
        ],
        relatedFormulas: []
    )
    
    /// Unit circle topic
    static let unitCircle = Topic(
        id: "trig_unit_circle",
        title: "Unit Circle",
        category: .trigonometry,
        description: "Trigonometric values on the unit circle",
        explanation: """
            The unit circle has radius 1 centered at the origin.
            
            Key angles (in degrees and radians):
            • 0° (0): (1, 0)
            • 30° (π/6): (√3/2, 1/2)
            • 45° (π/4): (√2/2, √2/2)
            • 60° (π/3): (1/2, √3/2)
            • 90° (π/2): (0, 1)
            • 180° (π): (-1, 0)
            • 270° (3π/2): (0, -1)
            • 360° (2π): (1, 0)
            
            On the unit circle: cos(θ) = x, sin(θ) = y
            """,
        examples: [
            Example(
                title: "Unit circle value",
                description: "Find sin(π/4) and cos(π/4)",
                solution: "sin(π/4) = √2/2, cos(π/4) = √2/2"
            ),
            Example(
                title: "Quadrant",
                description: "In which quadrant is sin positive and cos negative?",
                solution: "Second quadrant (90° < θ < 180°)"
            )
        ],
        relatedFormulas: []
    )
    
    /// Trigonometric identities topic
    static let identities = Topic(
        id: "trig_identities",
        title: "Trigonometric Identities",
        category: .trigonometry,
        description: "Relationships between trigonometric functions",
        explanation: """
            Identities are equations true for all values in their domains.
            
            Fundamental identities:
            • sin²(θ) + cos²(θ) = 1
            • 1 + tan²(θ) = sec²(θ)
            • 1 + cot²(θ) = csc²(θ)
            
            Angle sum formulas:
            • sin(A + B) = sin(A)cos(B) + cos(A)sin(B)
            • cos(A + B) = cos(A)cos(B) - sin(A)sin(B)
            • tan(A + B) = (tan(A) + tan(B))/(1 - tan(A)tan(B))
            
            Double angle formulas:
            • sin(2θ) = 2sin(θ)cos(θ)
            • cos(2θ) = cos²(θ) - sin²(θ)
            """,
        examples: [
            Example(
                title: "Verify identity",
                description: "Show sin²(θ) + cos²(θ) = 1",
                solution: "This is a fundamental identity derived from the Pythagorean theorem"
            ),
            Example(
                title: "Use angle sum",
                description: "Find sin(75°) = sin(45° + 30°)",
                solution: "= sin(45°)cos(30°) + cos(45°)sin(30°) = (√2/2)(√3/2) + (√2/2)(1/2)"
            )
        ],
        relatedFormulas: []
    )
    
    /// Inverse trigonometric functions topic
    static let inverseFunctions = Topic(
        id: "trig_inverse",
        title: "Inverse Trigonometric Functions",
        category: .trigonometry,
        description: "Finding angles from trigonometric values",
        explanation: """
            Inverse trig functions find the angle given a trig ratio.
            
            Notation and ranges:
            • arcsin(x) or sin⁻¹(x): range [-π/2, π/2]
            • arccos(x) or cos⁻¹(x): range [0, π]
            • arctan(x) or tan⁻¹(x): range (-π/2, π/2)
            
            Properties:
            • sin(arcsin(x)) = x for |x| ≤ 1
            • cos(arccos(x)) = x for |x| ≤ 1
            • tan(arctan(x)) = x for all real x
            • arcsin(x) + arccos(x) = π/2
            """,
        examples: [
            Example(
                title: "Find angle",
                description: "If sin(θ) = 1/2, find θ in [0°, 360°)",
                solution: "θ = 30° or θ = 150°"
            ),
            Example(
                title: "Arctan",
                description: "Find arctan(1)",
                solution: "= π/4 or 45°"
            )
        ],
        relatedFormulas: []
    )
    
    /// Graphs of trig functions topic
    static let graphs = Topic(
        id: "trig_graphs",
        title: "Graphs of Trigonometric Functions",
        category: .trigonometry,
        description: "Visual representation of trig functions",
        explanation: """
            Trigonometric functions have periodic graphs.
            
            Sine and cosine graphs:
            • Period: 2π (or 360°)
            • Amplitude: 1
            • Range: [-1, 1]
            • Sine: starts at (0, 0), cosine at (0, 1)
            
            Transformations:
            • y = A sin(Bx + C) + D
            • Amplitude: |A|
            • Period: 2π/|B|
            • Phase shift: -C/B
            • Vertical shift: D
            
            Tangent graph:
            • Period: π
            • Vertical asymptotes at odd multiples of π/2
            """,
        examples: [
            Example(
                title: "Period",
                description: "Find period of y = sin(2x)",
                solution: "Period = 2π/2 = π"
            ),
            Example(
                title: "Amplitude and shift",
                description: "Find amplitude, period, phase shift of y = 3sin(2x - π) + 1",
                solution: "Amplitude: 3, Period: π, Phase shift: π/2 right, Vertical shift: 1 up"
            )
        ],
        relatedFormulas: []
    )
    
    /// All trigonometry topics in order of progression
    static let allTopics: [Topic] = [
        rightTriangles,
        unitCircle,
        identities,
        inverseFunctions,
        graphs
    ]
    
    /// Get topic by ID
    static func topic(withId id: String) -> Topic? {
        allTopics.first { $0.id == id }
    }
}
