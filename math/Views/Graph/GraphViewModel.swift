import SwiftUI
import Combine

// MARK: - Key-point data

/// Computed key points for a single equation.
struct GraphKeyPoints {
    var yIntercept: CGPoint?          // (0, f(0))
    var xIntercepts: [CGPoint] = []   // (root, 0)
    var vertex: CGPoint?              // parabola vertex
}

// MARK: - View Model

@MainActor
final class GraphViewModel: ObservableObject {

    // --- input ----------------------------------------------------------------
    @Published var equation1: String = ""
    @Published var equation2: String = ""

    // --- parsed expressions ---------------------------------------------------
    @Published var expr1: Expression?
    @Published var expr2: Expression?

    // --- UI state -------------------------------------------------------------
    @Published var isInputCollapsed = false
    @Published var animationProgress: CGFloat = 1.0
    @Published var isAnimating = false
    @Published var errorMessage: String?
    @Published var activeField: Int?          // 1 or 2

    // --- key-points analysis --------------------------------------------------
    @Published var keyPoints1 = GraphKeyPoints()
    @Published var keyPoints2 = GraphKeyPoints()
    @Published var intersections: [CGPoint] = []

    // --- viewport -------------------------------------------------------------
    @Published var xMin: Double = -10
    @Published var xMax: Double =  10
    @Published var yMin: Double = -10
    @Published var yMax: Double =  10

    // MARK: - Parse & graph

    func graph() {
        errorMessage = nil
        expr1 = nil
        expr2 = nil
        keyPoints1 = GraphKeyPoints()
        keyPoints2 = GraphKeyPoints()
        intersections = []
        animationProgress = 1.0

        if !equation1.isEmpty {
            let norm = GraphEquationParser.normalize(equation1)
            if let e = GraphEquationParser.parse(norm) {
                expr1 = e
                keyPoints1 = computeKeyPoints(for: e)
            } else {
                errorMessage = "Could not parse Equation 1"
                return
            }
        }

        if !equation2.isEmpty {
            let norm = GraphEquationParser.normalize(equation2)
            if let e = GraphEquationParser.parse(norm) {
                expr2 = e
                keyPoints2 = computeKeyPoints(for: e)
            } else {
                errorMessage = "Could not parse Equation 2"
                return
            }
        }

        if let e1 = expr1, let e2 = expr2 {
            intersections = GraphEquationParser.findIntersections(
                of: e1, and: e2, in: xMin...xMax
            )
        }

        withAnimation(.spring()) { isInputCollapsed = true }
        activeField = nil
    }

    // MARK: - Animate (Fix 1)

    func animate() {
        graph()
        guard expr1 != nil || expr2 != nil else { return }
        isAnimating = true
        animationProgress = 0
        withAnimation(.linear(duration: 1.5)) {
            animationProgress = 1.0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.55) { [weak self] in
            self?.isAnimating = false
        }
    }

    // MARK: - Key-point computation

    private func computeKeyPoints(for expr: Expression) -> GraphKeyPoints {
        var kp = GraphKeyPoints()

        // y-intercept: f(0)
        if let y = expr.evaluate(variables: ["x": 0]),
           y.isFinite {
            kp.yIntercept = CGPoint(x: 0, y: y)
        }

        // x-intercepts via bisection
        kp.xIntercepts = GraphEquationParser.findRoots(of: expr, in: xMin...xMax)
            .map { CGPoint(x: $0, y: 0) }

        // Vertex detection for quadratics
        kp.vertex = GraphEquationParser.findVertex(of: expr)

        return kp
    }

    // MARK: - Expand / collapse

    func expandInput() {
        withAnimation(.spring()) { isInputCollapsed = false }
    }

    // MARK: - Helpers

    /// Evaluate an expression, returning nil for NaN/Inf.
    func eval(_ expr: Expression, at x: Double) -> Double? {
        guard let y = expr.evaluate(variables: ["x": x]),
              y.isFinite else { return nil }
        return y
    }
}
