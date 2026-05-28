import Foundation

/// Pure-function equation parser for the Graph module.
/// Handles normalization, evaluation, root-finding, intersection-finding, and vertex detection.
/// Named `GraphEquationParser` to avoid collision with the existing `EquationParser` class.
enum GraphEquationParser {

    // MARK: - Normalize (Fix 7 — input normalization)

    /// Normalize raw user input so the existing tokenizer / parser can handle it.
    /// • Strips leading "y =" / "y=" prefix
    /// • Lower-cases the string
    /// • Inserts explicit "*" for implicit multiplication:
    ///     "2x" → "2*x",  "2(x)" → "2*(x)",  "(x+1)(x-1)" → "(x+1)*(x-1)",
    ///     "x(" → "x*(", "2X" → "2*x"
    static func normalize(_ input: String) -> String {
        var s = input
            .trimmingCharacters(in: .whitespaces)
            .lowercased()

        // Remove leading "y=" or "y ="
        if let range = s.range(of: #"^y\s*=\s*"#, options: .regularExpression) {
            s.removeSubrange(range)
        }

        // Replace display operators with ASCII equivalents
        s = s.replacingOccurrences(of: "×", with: "*")
        s = s.replacingOccurrences(of: "÷", with: "/")

        // Remove stray spaces
        s = s.replacingOccurrences(of: " ", with: "")

        // Insert implicit multiplication:
        // digit before letter:    "2x" → "2*x"
        // digit before '(':      "2(" → "2*("
        // ')' before digit:      ")2" → ")*2"
        // ')' before letter:     ")x" → ")*x"
        // ')' before '(':        ")(" → ")*("
        // letter before '(':     "x(" → "x*("
        var result = ""
        let chars = Array(s)
        for (i, ch) in chars.enumerated() {
            result.append(ch)
            guard i + 1 < chars.count else { continue }
            let next = chars[i + 1]

            let needsStar: Bool = {
                // digit → letter
                if ch.isNumber && (next.isLetter || next == "(") { return true }
                // ')' → digit / letter / '('
                if ch == ")" && (next.isNumber || next.isLetter || next == "(") { return true }
                // letter → '('  (but not if it's a known function prefix handled later)
                // We leave function names as-is; the tokenizer already knows "sin(" etc.
                // However we DO need "x(" → "x*("
                if ch.isLetter && next == "(" {
                    // Check if it's NOT a function name ending here
                    let funcNames = ["sin", "cos", "tan", "log", "ln", "exp", "sqrt", "abs"]
                    let tail = String(result.suffix(4))
                    for fn in funcNames {
                        if tail.hasSuffix(fn) { return false }
                    }
                    return true
                }
                return false
            }()

            if needsStar { result.append("*") }
        }

        return result
    }

    // MARK: - Parse

    /// Parse a normalized expression string into an `Expression` AST.
    /// Uses the existing `Tokenizer` + `EquationParser` infrastructure.
    static func parse(_ normalized: String) -> Expression? {
        guard !normalized.isEmpty else { return nil }

        // If the string contains "=", treat it as an equation and take RHS.
        if normalized.contains("=") {
            let tokenizer = Tokenizer(normalized)
            let tokens = tokenizer.tokenize()
            let parser = EquationParser(tokens: tokens)
            if case .success(let eq) = parser.parseEquation() {
                return eq.rightExpression
            }
            return nil
        }

        // Otherwise parse as a standalone expression.
        return parseExpressionString(normalized)
    }

    // MARK: - Evaluate

    /// Evaluate an expression at a given x, returning nil for non-finite results.
    static func evaluate(_ expr: Expression, at x: Double) -> Double? {
        guard let y = expr.evaluate(variables: ["x": x]),
              y.isFinite else { return nil }
        return y
    }

    // MARK: - Root finding (bisection)

    /// Find x-intercepts of `expr` in the given range using high-resolution sampling
    /// followed by bisection refinement to 4 decimal places.
    static func findRoots(of expr: Expression,
                          in range: ClosedRange<Double>) -> [Double] {
        let n = 1000
        let step = (range.upperBound - range.lowerBound) / Double(n)
        var roots: [Double] = []
        var prevY: Double?
        var prevX: Double = range.lowerBound

        for i in 0...n {
            let x = range.lowerBound + Double(i) * step
            guard let y = evaluate(expr, at: x) else {
                prevY = nil
                prevX = x
                continue
            }
            if let py = prevY, py * y < 0 {
                // Sign change detected — refine via bisection
                if let root = bisect(expr, lo: prevX, hi: x) {
                    // Avoid duplicates
                    if roots.isEmpty || abs(root - roots.last!) > 1e-6 {
                        roots.append(root)
                    }
                }
            }
            // Exact zero
            if abs(y) < 1e-12 {
                if roots.isEmpty || abs(x - roots.last!) > 1e-6 {
                    roots.append(x)
                }
            }
            prevY = y
            prevX = x
        }
        return roots
    }

    // MARK: - Intersection finding (Fix 5)

    /// Find intersection points of two expressions using high-resolution sampling
    /// and bisection refinement to 4 decimal places.
    static func findIntersections(of e1: Expression,
                                  and e2: Expression,
                                  in range: ClosedRange<Double>) -> [CGPoint] {
        let n = 1000
        let step = (range.upperBound - range.lowerBound) / Double(n)
        var points: [CGPoint] = []
        var prevDiff: Double?
        var prevX: Double = range.lowerBound

        for i in 0...n {
            let x = range.lowerBound + Double(i) * step
            guard let y1 = evaluate(e1, at: x),
                  let y2 = evaluate(e2, at: x) else {
                prevDiff = nil
                prevX = x
                continue
            }
            let diff = y1 - y2
            if let pd = prevDiff, pd * diff < 0 {
                if let ix = bisectDiff(e1, e2, lo: prevX, hi: x) {
                    if let iy = evaluate(e1, at: ix) {
                        // Avoid duplicates
                        if points.isEmpty || abs(ix - Double(points.last!.x)) > 1e-6 {
                            points.append(CGPoint(x: ix, y: iy))
                        }
                    }
                }
            }
            if abs(diff) < 1e-12 {
                if points.isEmpty || abs(x - Double(points.last!.x)) > 1e-6 {
                    points.append(CGPoint(x: x, y: y1))
                }
            }
            prevDiff = diff
            prevX = x
        }
        return points
    }

    // MARK: - Vertex detection

    /// Attempts to detect a quadratic vertex from the expression AST.
    /// Uses numerical derivative zero-crossing near the center of typical ranges.
    static func findVertex(of expr: Expression) -> CGPoint? {
        // Use numerical approach: find where f'(x) ≈ 0 near x = 0
        // This works for any expression, not just symbolic quadratics.
        let h = 1e-5
        let searchRange = -50.0...50.0
        let n = 1000
        let step = (searchRange.upperBound - searchRange.lowerBound) / Double(n)
        var prevDeriv: Double?
        var prevX = searchRange.lowerBound

        for i in 0...n {
            let x = searchRange.lowerBound + Double(i) * step
            guard let yPlus = evaluate(expr, at: x + h),
                  let yMinus = evaluate(expr, at: x - h) else {
                prevDeriv = nil
                prevX = x
                continue
            }
            let deriv = (yPlus - yMinus) / (2 * h)
            if let pd = prevDeriv, pd * deriv < 0 {
                // Derivative sign change — refine
                var lo = prevX, hi = x
                for _ in 0..<50 {
                    let mid = (lo + hi) / 2
                    guard let yp = evaluate(expr, at: mid + h),
                          let ym = evaluate(expr, at: mid - h) else { break }
                    let dMid = (yp - ym) / (2 * h)
                    if pd * dMid < 0 { hi = mid } else { lo = mid }
                }
                let vx = (lo + hi) / 2
                if let vy = evaluate(expr, at: vx) {
                    // Verify it's actually a local extremum (second derivative)
                    guard let yp2 = evaluate(expr, at: vx + h),
                          let ym2 = evaluate(expr, at: vx - h),
                          let yc = evaluate(expr, at: vx) else { return nil }
                    let d2 = (yp2 - 2 * yc + ym2) / (h * h)
                    if abs(d2) > 0.1 { // curvature check — skip inflection
                        return CGPoint(x: vx, y: vy)
                    }
                }
            }
            prevDeriv = deriv
            prevX = x
        }
        return nil
    }

    // MARK: - Bisection helpers

    /// Bisection for root finding: f(x) = 0 between lo and hi.
    private static func bisect(_ expr: Expression,
                               lo: Double, hi: Double) -> Double? {
        var lo = lo, hi = hi
        guard let yLo = evaluate(expr, at: lo) else { return nil }
        var sLo = yLo
        for _ in 0..<60 {
            let mid = (lo + hi) / 2
            guard let yMid = evaluate(expr, at: mid) else { return nil }
            if sLo * yMid < 0 { hi = mid } else { lo = mid; sLo = yMid }
        }
        return (lo + hi) / 2
    }

    /// Bisection for intersection: f1(x) - f2(x) = 0 between lo and hi.
    private static func bisectDiff(_ e1: Expression, _ e2: Expression,
                                   lo: Double, hi: Double) -> Double? {
        var lo = lo, hi = hi
        guard let y1Lo = evaluate(e1, at: lo),
              let y2Lo = evaluate(e2, at: lo) else { return nil }
        var sLo = y1Lo - y2Lo
        for _ in 0..<60 {
            let mid = (lo + hi) / 2
            guard let y1 = evaluate(e1, at: mid),
                  let y2 = evaluate(e2, at: mid) else { return nil }
            let diff = y1 - y2
            if sLo * diff < 0 { hi = mid } else { lo = mid; sLo = diff }
        }
        return (lo + hi) / 2
    }
}
