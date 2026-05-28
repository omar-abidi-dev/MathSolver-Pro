import Foundation

/// Pure-function physics engine.
/// Every formula rearrangement is an explicit case — no generic solvers.
struct PhysicsEngine {

    // MARK: - Public API

    /// Solve `formula` for `unknown` given `knownValues`.
    /// Returns nil on invalid input; never force-unwraps.
    static func solve(
        formula: PhysicsFormula,
        knownValues: [String: Double],
        unknownSymbol: String
    ) -> PhysSolveResult? {

        // Look up the unknown variable metadata
        guard let unknownVar = formula.variables.first(where: { $0.symbol == unknownSymbol }) else {
            return nil
        }

        // Compute result + unit
        guard let (result, unit) = compute(formulaID: formula.id,
                                           vars: knownValues,
                                           unknown: unknownSymbol) else {
            return nil
        }

        // Build ordered known-value tuples (preserving formula variable order)
        let knownList: [(symbol: String, name: String, value: Double, unit: String)] =
            formula.variables.compactMap { v in
                guard v.symbol != unknownSymbol, let val = knownValues[v.symbol] else { return nil }
                return (v.symbol, v.name, val, v.unit)
            }

        // Build the 5 solution steps
        let steps = buildSteps(formula: formula,
                               knownList: knownList,
                               unknownSymbol: unknownSymbol,
                               unknownName: unknownVar.name,
                               result: result,
                               resultUnit: unit)

        return PhysSolveResult(
            formula: formula,
            knownValues: knownList,
            unknownSymbol: unknownSymbol,
            unknownName: unknownVar.name,
            result: result,
            resultUnit: unit,
            steps: steps
        )
    }

    // MARK: - Formatting helper

    static func fmt(_ v: Double) -> String {
        String(format: "%.2f", v)
    }

    // MARK: - Step builder

    private static func buildSteps(
        formula: PhysicsFormula,
        knownList: [(symbol: String, name: String, value: Double, unit: String)],
        unknownSymbol: String,
        unknownName: String,
        result: Double,
        resultUnit: String
    ) -> [PhysSolveStep] {
        let f = fmt

        // Step 1 — Identify formula
        let step1 = PhysSolveStep(
            number: 1, title: "Identify the Formula",
            lines: ["\(formula.name): \(formula.expression)"],
            expandedByDefault: false
        )

        // Step 2 — List known values
        let knownLines = knownList.map { "\($0.symbol) = \(f($0.value)) \($0.unit)" }
        let step2 = PhysSolveStep(
            number: 2, title: "List Known Values",
            lines: knownLines,
            expandedByDefault: false
        )

        // Step 3 — Rearrange
        let rearranged = rearrangedExpression(formulaID: formula.id, unknown: unknownSymbol)
        let step3Lines: [String]
        if rearranged == formula.expression {
            step3Lines = ["Formula is already solved for \(unknownSymbol)"]
        } else {
            step3Lines = ["\(formula.expression)  →  \(rearranged)"]
        }
        let step3 = PhysSolveStep(
            number: 3, title: "Rearrange for \(unknownSymbol)",
            lines: step3Lines,
            expandedByDefault: false
        )

        // Step 4 — Substitute values
        let subLines = substitutionLines(formulaID: formula.id,
                                          vars: Dictionary(uniqueKeysWithValues: knownList.map { ($0.symbol, $0.value) }),
                                          unknown: unknownSymbol,
                                          result: result)
        let step4 = PhysSolveStep(
            number: 4, title: "Substitute Values",
            lines: subLines,
            expandedByDefault: true
        )

        // Step 5 — Final result
        let step5 = PhysSolveStep(
            number: 5, title: "Calculate Result",
            lines: ["\(unknownSymbol) = \(f(result)) \(resultUnit)"],
            expandedByDefault: true
        )

        return [step1, step2, step3, step4, step5]
    }

    // MARK: - Algebraic computation (all rearrangements)

    /// Returns (resultValue, unitString) or nil on failure.
    private static func compute(
        formulaID: String,
        vars: [String: Double],
        unknown: String
    ) -> (Double, String)? {

        switch formulaID {

        // ─── KINEMATICS ─────────────────────────────────────

        case "final_velocity":
            // v = u + at
            switch unknown {
            case "v":
                guard let u = vars["u"], let a = vars["a"], let t = vars["t"] else { return nil }
                return (u + a * t, "m/s")                   // v = u + at
            case "u":
                guard let v = vars["v"], let a = vars["a"], let t = vars["t"] else { return nil }
                return (v - a * t, "m/s")                   // u = v − at
            case "a":
                guard let v = vars["v"], let u = vars["u"], let t = vars["t"], t != 0 else { return nil }
                return ((v - u) / t, "m/s²")                // a = (v − u) / t
            case "t":
                guard let v = vars["v"], let u = vars["u"], let a = vars["a"], a != 0 else { return nil }
                return ((v - u) / a, "s")                   // t = (v − u) / a
            default: return nil
            }

        case "displacement_uvt":
            // s = ((u + v) / 2) × t
            switch unknown {
            case "s":
                guard let u = vars["u"], let v = vars["v"], let t = vars["t"] else { return nil }
                return ((u + v) / 2.0 * t, "m")             // s = (u+v)/2 × t
            case "u":
                guard let s = vars["s"], let v = vars["v"], let t = vars["t"], t != 0 else { return nil }
                return (2.0 * s / t - v, "m/s")             // u = 2s/t − v
            case "v":
                guard let s = vars["s"], let u = vars["u"], let t = vars["t"], t != 0 else { return nil }
                return (2.0 * s / t - u, "m/s")             // v = 2s/t − u
            case "t":
                guard let s = vars["s"], let u = vars["u"], let v = vars["v"], (u + v) != 0 else { return nil }
                return (2.0 * s / (u + v), "s")             // t = 2s / (u+v)
            default: return nil
            }

        case "displacement_uat":
            // s = ut + ½at²
            switch unknown {
            case "s":
                guard let u = vars["u"], let a = vars["a"], let t = vars["t"] else { return nil }
                return (u * t + 0.5 * a * t * t, "m")       // s = ut + ½at²
            case "u":
                guard let s = vars["s"], let a = vars["a"], let t = vars["t"], t != 0 else { return nil }
                return ((s - 0.5 * a * t * t) / t, "m/s")   // u = (s − ½at²) / t
            case "a":
                guard let s = vars["s"], let u = vars["u"], let t = vars["t"], t != 0 else { return nil }
                return (2.0 * (s - u * t) / (t * t), "m/s²")// a = 2(s − ut) / t²
            case "t":
                // ½at² + ut − s = 0  →  quadratic in t, take positive root
                guard let s = vars["s"], let u = vars["u"], let a = vars["a"] else { return nil }
                if a == 0 {
                    guard u != 0 else { return nil }
                    return (s / u, "s")                      // linear fallback: t = s/u
                }
                let disc = u * u + 2.0 * a * s
                guard disc >= 0 else { return nil }
                let t1 = (-u + sqrt(disc)) / a
                let t2 = (-u - sqrt(disc)) / a
                let t = t1 >= 0 ? t1 : t2
                guard t >= 0 else { return nil }
                return (t, "s")
            default: return nil
            }

        case "velocity_squared":
            // v² = u² + 2as
            switch unknown {
            case "v":
                guard let u = vars["u"], let a = vars["a"], let s = vars["s"] else { return nil }
                let sq = u * u + 2.0 * a * s
                guard sq >= 0 else { return nil }
                return (sqrt(sq), "m/s")                     // v = √(u² + 2as)
            case "u":
                guard let v = vars["v"], let a = vars["a"], let s = vars["s"] else { return nil }
                let sq = v * v - 2.0 * a * s
                guard sq >= 0 else { return nil }
                return (sqrt(sq), "m/s")                     // u = √(v² − 2as)
            case "a":
                guard let v = vars["v"], let u = vars["u"], let s = vars["s"], s != 0 else { return nil }
                return ((v * v - u * u) / (2.0 * s), "m/s²") // a = (v²−u²)/(2s)
            case "s":
                guard let v = vars["v"], let u = vars["u"], let a = vars["a"], a != 0 else { return nil }
                return ((v * v - u * u) / (2.0 * a), "m")   // s = (v²−u²)/(2a)
            default: return nil
            }

        case "acceleration":
            // a = (v − u) / t  (same math as final_velocity)
            switch unknown {
            case "a":
                guard let v = vars["v"], let u = vars["u"], let t = vars["t"], t != 0 else { return nil }
                return ((v - u) / t, "m/s²")
            case "v":
                guard let a = vars["a"], let u = vars["u"], let t = vars["t"] else { return nil }
                return (u + a * t, "m/s")
            case "u":
                guard let a = vars["a"], let v = vars["v"], let t = vars["t"] else { return nil }
                return (v - a * t, "m/s")
            case "t":
                guard let v = vars["v"], let u = vars["u"], let a = vars["a"], a != 0 else { return nil }
                return ((v - u) / a, "s")
            default: return nil
            }

        // ─── FORCES ─────────────────────────────────────────

        case "newtons_second":
            // F = ma
            switch unknown {
            case "F":
                guard let m = vars["m"], let a = vars["a"] else { return nil }
                return (m * a, "N")
            case "m":
                guard let f = vars["F"], let a = vars["a"], a != 0 else { return nil }
                return (f / a, "kg")                         // m = F / a
            case "a":
                guard let f = vars["F"], let m = vars["m"], m != 0 else { return nil }
                return (f / m, "m/s²")                       // a = F / m
            default: return nil
            }

        case "weight":
            // W = mg
            switch unknown {
            case "W":
                guard let m = vars["m"], let g = vars["g"] else { return nil }
                return (m * g, "N")
            case "m":
                guard let w = vars["W"], let g = vars["g"], g != 0 else { return nil }
                return (w / g, "kg")
            case "g":
                guard let w = vars["W"], let m = vars["m"], m != 0 else { return nil }
                return (w / m, "m/s²")
            default: return nil
            }

        case "friction":
            // f = μN
            switch unknown {
            case "f":
                guard let mu = vars["μ"], let n = vars["N"] else { return nil }
                return (mu * n, "N")
            case "μ":
                guard let f = vars["f"], let n = vars["N"], n != 0 else { return nil }
                return (f / n, "")
            case "N":
                guard let f = vars["f"], let mu = vars["μ"], mu != 0 else { return nil }
                return (f / mu, "N")
            default: return nil
            }

        case "pressure":
            // P = F / A
            switch unknown {
            case "P":
                guard let f = vars["F"], let a = vars["A"], a != 0 else { return nil }
                return (f / a, "Pa")
            case "F":
                guard let p = vars["P"], let a = vars["A"] else { return nil }
                return (p * a, "N")                          // F = PA
            case "A":
                guard let f = vars["F"], let p = vars["P"], p != 0 else { return nil }
                return (f / p, "m²")                         // A = F / P
            default: return nil
            }

        case "momentum":
            // p = mv
            switch unknown {
            case "p":
                guard let m = vars["m"], let v = vars["v"] else { return nil }
                return (m * v, "kg·m/s")
            case "m":
                guard let p = vars["p"], let v = vars["v"], v != 0 else { return nil }
                return (p / v, "kg")
            case "v":
                guard let p = vars["p"], let m = vars["m"], m != 0 else { return nil }
                return (p / m, "m/s")
            default: return nil
            }

        case "impulse":
            // J = FΔt
            switch unknown {
            case "J":
                guard let f = vars["F"], let dt = vars["Δt"] else { return nil }
                return (f * dt, "N·s")
            case "F":
                guard let j = vars["J"], let dt = vars["Δt"], dt != 0 else { return nil }
                return (j / dt, "N")
            case "Δt":
                guard let j = vars["J"], let f = vars["F"], f != 0 else { return nil }
                return (j / f, "s")
            default: return nil
            }

        case "hookes_law":
            // F = kx
            switch unknown {
            case "F":
                guard let k = vars["k"], let x = vars["x"] else { return nil }
                return (k * x, "N")
            case "k":
                guard let f = vars["F"], let x = vars["x"], x != 0 else { return nil }
                return (f / x, "N/m")                        // k = F / x
            case "x":
                guard let f = vars["F"], let k = vars["k"], k != 0 else { return nil }
                return (f / k, "m")                          // x = F / k
            default: return nil
            }

        // ─── ENERGY ─────────────────────────────────────────

        case "kinetic_energy":
            // KE = ½mv²
            switch unknown {
            case "KE":
                guard let m = vars["m"], let v = vars["v"] else { return nil }
                return (0.5 * m * v * v, "J")
            case "m":
                guard let ke = vars["KE"], let v = vars["v"], v != 0 else { return nil }
                return (2.0 * ke / (v * v), "kg")            // m = 2KE / v²
            case "v":
                guard let ke = vars["KE"], let m = vars["m"], m != 0 else { return nil }
                let sq = 2.0 * ke / m
                guard sq >= 0 else { return nil }
                return (sqrt(sq), "m/s")                     // v = √(2KE/m)
            default: return nil
            }

        case "gravitational_pe":
            // GPE = mgh
            switch unknown {
            case "GPE":
                guard let m = vars["m"], let g = vars["g"], let h = vars["h"] else { return nil }
                return (m * g * h, "J")
            case "m":
                guard let gpe = vars["GPE"], let g = vars["g"], let h = vars["h"], g * h != 0 else { return nil }
                return (gpe / (g * h), "kg")
            case "g":
                guard let gpe = vars["GPE"], let m = vars["m"], let h = vars["h"], m * h != 0 else { return nil }
                return (gpe / (m * h), "m/s²")
            case "h":
                guard let gpe = vars["GPE"], let m = vars["m"], let g = vars["g"], m * g != 0 else { return nil }
                return (gpe / (m * g), "m")
            default: return nil
            }

        case "work_done":
            // W = Fd cosθ  (θ in degrees)
            switch unknown {
            case "W":
                guard let f = vars["F"], let d = vars["d"], let theta = vars["θ"] else { return nil }
                let rad = theta * .pi / 180.0
                return (f * d * cos(rad), "J")
            case "F":
                guard let w = vars["W"], let d = vars["d"], let theta = vars["θ"] else { return nil }
                let rad = theta * .pi / 180.0
                let denom = d * cos(rad)
                guard denom != 0 else { return nil }
                return (w / denom, "N")                      // F = W / (d cosθ)
            case "d":
                guard let w = vars["W"], let f = vars["F"], let theta = vars["θ"] else { return nil }
                let rad = theta * .pi / 180.0
                let denom = f * cos(rad)
                guard denom != 0 else { return nil }
                return (w / denom, "m")                      // d = W / (F cosθ)
            case "θ":
                guard let w = vars["W"], let f = vars["F"], let d = vars["d"], f * d != 0 else { return nil }
                let cosVal = w / (f * d)
                guard cosVal >= -1, cosVal <= 1 else { return nil }
                return (acos(cosVal) * 180.0 / .pi, "°")    // θ = arccos(W/(Fd))
            default: return nil
            }

        case "power":
            // P = W / t
            switch unknown {
            case "P":
                guard let w = vars["W"], let t = vars["t"], t != 0 else { return nil }
                return (w / t, "W")
            case "W":
                guard let p = vars["P"], let t = vars["t"] else { return nil }
                return (p * t, "J")
            case "t":
                guard let w = vars["W"], let p = vars["P"], p != 0 else { return nil }
                return (w / p, "s")
            default: return nil
            }

        case "efficiency":
            // η = (Wout / Win) × 100
            switch unknown {
            case "η":
                guard let wout = vars["Wout"], let win = vars["Win"], win != 0 else { return nil }
                return (wout / win * 100.0, "%")
            case "Wout":
                guard let eta = vars["η"], let win = vars["Win"] else { return nil }
                return (eta * win / 100.0, "J")              // Wout = η × Win / 100
            case "Win":
                guard let eta = vars["η"], let wout = vars["Wout"], eta != 0 else { return nil }
                return (wout * 100.0 / eta, "J")             // Win = Wout × 100 / η
            default: return nil
            }

        case "conservation_energy":
            // KEi + PEi = KEf + PEf
            switch unknown {
            case "KEi":
                guard let pei = vars["PEi"], let kef = vars["KEf"], let pef = vars["PEf"] else { return nil }
                return (kef + pef - pei, "J")                // KEi = KEf + PEf − PEi
            case "PEi":
                guard let kei = vars["KEi"], let kef = vars["KEf"], let pef = vars["PEf"] else { return nil }
                return (kef + pef - kei, "J")                // PEi = KEf + PEf − KEi
            case "KEf":
                guard let kei = vars["KEi"], let pei = vars["PEi"], let pef = vars["PEf"] else { return nil }
                return (kei + pei - pef, "J")                // KEf = KEi + PEi − PEf
            case "PEf":
                guard let kei = vars["KEi"], let pei = vars["PEi"], let kef = vars["KEf"] else { return nil }
                return (kei + pei - kef, "J")                // PEf = KEi + PEi − KEf
            default: return nil
            }

        default:
            return nil
        }
    }

    // MARK: - Rearranged expression string

    /// Return the symbolic expression rearranged for `unknown`.
    private static func rearrangedExpression(formulaID: String, unknown: String) -> String {
        switch formulaID {

        // ── Kinematics ──
        case "final_velocity":
            switch unknown {
            case "v": return "v = u + at"
            case "u": return "u = v − at"
            case "a": return "a = (v − u) / t"
            case "t": return "t = (v − u) / a"
            default:  return ""
            }
        case "displacement_uvt":
            switch unknown {
            case "s": return "s = ((u + v) / 2) × t"
            case "u": return "u = 2s / t − v"
            case "v": return "v = 2s / t − u"
            case "t": return "t = 2s / (u + v)"
            default:  return ""
            }
        case "displacement_uat":
            switch unknown {
            case "s": return "s = ut + ½at²"
            case "u": return "u = (s − ½at²) / t"
            case "a": return "a = 2(s − ut) / t²"
            case "t": return "½at² + ut − s = 0  (quadratic in t)"
            default:  return ""
            }
        case "velocity_squared":
            switch unknown {
            case "v": return "v = √(u² + 2as)"
            case "u": return "u = √(v² − 2as)"
            case "a": return "a = (v² − u²) / (2s)"
            case "s": return "s = (v² − u²) / (2a)"
            default:  return ""
            }
        case "acceleration":
            switch unknown {
            case "a": return "a = (v − u) / t"
            case "v": return "v = u + at"
            case "u": return "u = v − at"
            case "t": return "t = (v − u) / a"
            default:  return ""
            }

        // ── Forces ──
        case "newtons_second":
            switch unknown {
            case "F": return "F = ma"
            case "m": return "m = F / a"
            case "a": return "a = F / m"
            default:  return ""
            }
        case "weight":
            switch unknown {
            case "W": return "W = mg"
            case "m": return "m = W / g"
            case "g": return "g = W / m"
            default:  return ""
            }
        case "friction":
            switch unknown {
            case "f": return "f = μN"
            case "μ": return "μ = f / N"
            case "N": return "N = f / μ"
            default:  return ""
            }
        case "pressure":
            switch unknown {
            case "P": return "P = F / A"
            case "F": return "F = P × A"
            case "A": return "A = F / P"
            default:  return ""
            }
        case "momentum":
            switch unknown {
            case "p": return "p = mv"
            case "m": return "m = p / v"
            case "v": return "v = p / m"
            default:  return ""
            }
        case "impulse":
            switch unknown {
            case "J":  return "J = FΔt"
            case "F":  return "F = J / Δt"
            case "Δt": return "Δt = J / F"
            default:   return ""
            }
        case "hookes_law":
            switch unknown {
            case "F": return "F = kx"
            case "k": return "k = F / x"
            case "x": return "x = F / k"
            default:  return ""
            }

        // ── Energy ──
        case "kinetic_energy":
            switch unknown {
            case "KE": return "KE = ½mv²"
            case "m":  return "m = 2KE / v²"
            case "v":  return "v = √(2KE / m)"
            default:   return ""
            }
        case "gravitational_pe":
            switch unknown {
            case "GPE": return "GPE = mgh"
            case "m":   return "m = GPE / (gh)"
            case "g":   return "g = GPE / (mh)"
            case "h":   return "h = GPE / (mg)"
            default:    return ""
            }
        case "work_done":
            switch unknown {
            case "W": return "W = Fd cosθ"
            case "F": return "F = W / (d cosθ)"
            case "d": return "d = W / (F cosθ)"
            case "θ": return "θ = arccos(W / (Fd))"
            default:  return ""
            }
        case "power":
            switch unknown {
            case "P": return "P = W / t"
            case "W": return "W = P × t"
            case "t": return "t = W / P"
            default:  return ""
            }
        case "efficiency":
            switch unknown {
            case "η":    return "η = (Wout / Win) × 100"
            case "Wout": return "Wout = η × Win / 100"
            case "Win":  return "Win = Wout × 100 / η"
            default:     return ""
            }
        case "conservation_energy":
            switch unknown {
            case "KEi": return "KEi = KEf + PEf − PEi"
            case "PEi": return "PEi = KEf + PEf − KEi"
            case "KEf": return "KEf = KEi + PEi − PEf"
            case "PEf": return "PEf = KEi + PEi − KEf"
            default:    return ""
            }

        default: return ""
        }
    }

    // MARK: - Substitution lines (Step 4)

    /// Build human-readable substitution lines showing actual numbers.
    private static func substitutionLines(
        formulaID: String,
        vars: [String: Double],
        unknown: String,
        result: Double
    ) -> [String] {
        let f = fmt

        switch formulaID {

        // ── Kinematics ──────────────────────────────────────

        case "final_velocity":
            guard let u = vars["u"], let a = vars["a"], let t = vars["t"] else { break }
            switch unknown {
            case "v":
                return [
                    "v = \(f(u)) + (\(f(a)) × \(f(t)))",
                    "v = \(f(u)) + \(f(a * t))",
                    "v = \(f(result))"
                ]
            case "u":
                return ["u = \(f(vars["v"]!)) − (\(f(a)) × \(f(t)))", "u = \(f(result))"]
            case "a":
                return ["a = (\(f(vars["v"]!)) − \(f(u))) / \(f(t))", "a = \(f(result))"]
            case "t":
                return ["t = (\(f(vars["v"]!)) − \(f(u))) / \(f(a))", "t = \(f(result))"]
            default: break
            }

        case "displacement_uvt":
            guard let u = vars["u"], let v = vars["v"], let t = vars["t"] else { break }
            switch unknown {
            case "s":
                return [
                    "s = ((\(f(u)) + \(f(v))) / 2) × \(f(t))",
                    "s = (\(f(u + v)) / 2) × \(f(t))",
                    "s = \(f((u + v) / 2.0)) × \(f(t))",
                    "s = \(f(result))"
                ]
            case "u":
                return ["u = 2 × \(f(vars["s"]!)) / \(f(t)) − \(f(v))", "u = \(f(result))"]
            case "v":
                return ["v = 2 × \(f(vars["s"]!)) / \(f(t)) − \(f(u))", "v = \(f(result))"]
            case "t":
                return ["t = 2 × \(f(vars["s"]!)) / (\(f(u)) + \(f(v)))", "t = \(f(result))"]
            default: break
            }

        case "displacement_uat":
            guard let u = vars["u"], let a = vars["a"], let t = vars["t"] else { break }
            switch unknown {
            case "s":
                return [
                    "s = \(f(u)) × \(f(t)) + ½ × \(f(a)) × \(f(t))²",
                    "s = \(f(u * t)) + \(f(0.5 * a * t * t))",
                    "s = \(f(result))"
                ]
            case "u":
                return [
                    "u = (\(f(vars["s"]!)) − ½ × \(f(a)) × \(f(t))²) / \(f(t))",
                    "u = \(f(result))"
                ]
            case "a":
                return [
                    "a = 2 × (\(f(vars["s"]!)) − \(f(u)) × \(f(t))) / \(f(t))²",
                    "a = \(f(result))"
                ]
            case "t":
                return [
                    "½(\(f(a)))t² + (\(f(u)))t − \(f(vars["s"]!)) = 0",
                    "Solving quadratic → t = \(f(result))"
                ]
            default: break
            }

        case "velocity_squared":
            guard let u = vars["u"], let a = vars["a"], let s = vars["s"] else { break }
            switch unknown {
            case "v":
                return [
                    "v² = \(f(u))² + 2 × \(f(a)) × \(f(s))",
                    "v² = \(f(u * u)) + \(f(2 * a * s))",
                    "v = √\(f(u * u + 2 * a * s))",
                    "v = \(f(result))"
                ]
            case "u":
                return [
                    "u² = \(f(vars["v"]!))² − 2 × \(f(a)) × \(f(s))",
                    "u = √\(f(vars["v"]! * vars["v"]! - 2 * a * s))",
                    "u = \(f(result))"
                ]
            case "a":
                return [
                    "a = (\(f(vars["v"]!))² − \(f(u))²) / (2 × \(f(s)))",
                    "a = \(f(result))"
                ]
            case "s":
                return [
                    "s = (\(f(vars["v"]!))² − \(f(u))²) / (2 × \(f(a)))",
                    "s = \(f(result))"
                ]
            default: break
            }

        case "acceleration":
            guard let v = vars["v"], let u = vars["u"], let t = vars["t"] else { break }
            switch unknown {
            case "a": return ["a = (\(f(v)) − \(f(u))) / \(f(t))", "a = \(f(result))"]
            case "v": return ["v = \(f(u)) + \(f(vars["a"]!)) × \(f(t))", "v = \(f(result))"]
            case "u": return ["u = \(f(v)) − \(f(vars["a"]!)) × \(f(t))", "u = \(f(result))"]
            case "t": return ["t = (\(f(v)) − \(f(u))) / \(f(vars["a"]!))", "t = \(f(result))"]
            default: break
            }

        // ── Forces ──────────────────────────────────────────

        case "newtons_second":
            switch unknown {
            case "F":
                guard let m = vars["m"], let a = vars["a"] else { break }
                return ["F = \(f(m)) × \(f(a))", "F = \(f(result))"]
            case "m":
                guard let fv = vars["F"], let a = vars["a"] else { break }
                return ["m = \(f(fv)) / \(f(a))", "m = \(f(result))"]
            case "a":
                guard let fv = vars["F"], let m = vars["m"] else { break }
                return ["a = \(f(fv)) / \(f(m))", "a = \(f(result))"]
            default: break
            }

        case "weight":
            switch unknown {
            case "W":
                guard let m = vars["m"], let g = vars["g"] else { break }
                return ["W = \(f(m)) × \(f(g))", "W = \(f(result))"]
            case "m":
                guard let w = vars["W"], let g = vars["g"] else { break }
                return ["m = \(f(w)) / \(f(g))", "m = \(f(result))"]
            case "g":
                guard let w = vars["W"], let m = vars["m"] else { break }
                return ["g = \(f(w)) / \(f(m))", "g = \(f(result))"]
            default: break
            }

        case "friction":
            switch unknown {
            case "f":
                guard let mu = vars["μ"], let n = vars["N"] else { break }
                return ["f = \(f(mu)) × \(f(n))", "f = \(f(result))"]
            case "μ":
                guard let fv = vars["f"], let n = vars["N"] else { break }
                return ["μ = \(f(fv)) / \(f(n))", "μ = \(f(result))"]
            case "N":
                guard let fv = vars["f"], let mu = vars["μ"] else { break }
                return ["N = \(f(fv)) / \(f(mu))", "N = \(f(result))"]
            default: break
            }

        case "pressure":
            switch unknown {
            case "P":
                guard let fv = vars["F"], let a = vars["A"] else { break }
                return ["P = \(f(fv)) / \(f(a))", "P = \(f(result))"]
            case "F":
                guard let p = vars["P"], let a = vars["A"] else { break }
                return ["F = \(f(p)) × \(f(a))", "F = \(f(result))"]
            case "A":
                guard let fv = vars["F"], let p = vars["P"] else { break }
                return ["A = \(f(fv)) / \(f(p))", "A = \(f(result))"]
            default: break
            }

        case "momentum":
            switch unknown {
            case "p":
                guard let m = vars["m"], let v = vars["v"] else { break }
                return ["p = \(f(m)) × \(f(v))", "p = \(f(result))"]
            case "m":
                guard let p = vars["p"], let v = vars["v"] else { break }
                return ["m = \(f(p)) / \(f(v))", "m = \(f(result))"]
            case "v":
                guard let p = vars["p"], let m = vars["m"] else { break }
                return ["v = \(f(p)) / \(f(m))", "v = \(f(result))"]
            default: break
            }

        case "impulse":
            switch unknown {
            case "J":
                guard let fv = vars["F"], let dt = vars["Δt"] else { break }
                return ["J = \(f(fv)) × \(f(dt))", "J = \(f(result))"]
            case "F":
                guard let j = vars["J"], let dt = vars["Δt"] else { break }
                return ["F = \(f(j)) / \(f(dt))", "F = \(f(result))"]
            case "Δt":
                guard let j = vars["J"], let fv = vars["F"] else { break }
                return ["Δt = \(f(j)) / \(f(fv))", "Δt = \(f(result))"]
            default: break
            }

        case "hookes_law":
            switch unknown {
            case "F":
                guard let k = vars["k"], let x = vars["x"] else { break }
                return ["F = \(f(k)) × \(f(x))", "F = \(f(result))"]
            case "k":
                guard let fv = vars["F"], let x = vars["x"] else { break }
                return ["k = \(f(fv)) / \(f(x))", "k = \(f(result))"]
            case "x":
                guard let fv = vars["F"], let k = vars["k"] else { break }
                return ["x = \(f(fv)) / \(f(k))", "x = \(f(result))"]
            default: break
            }

        // ── Energy ──────────────────────────────────────────

        case "kinetic_energy":
            switch unknown {
            case "KE":
                guard let m = vars["m"], let v = vars["v"] else { break }
                return [
                    "KE = ½ × \(f(m)) × \(f(v))²",
                    "KE = 0.50 × \(f(m)) × \(f(v * v))",
                    "KE = \(f(result))"
                ]
            case "m":
                guard let ke = vars["KE"], let v = vars["v"] else { break }
                return ["m = 2 × \(f(ke)) / \(f(v))²", "m = \(f(result))"]
            case "v":
                guard let ke = vars["KE"], let m = vars["m"] else { break }
                return ["v = √(2 × \(f(ke)) / \(f(m)))", "v = \(f(result))"]
            default: break
            }

        case "gravitational_pe":
            switch unknown {
            case "GPE":
                guard let m = vars["m"], let g = vars["g"], let h = vars["h"] else { break }
                return [
                    "GPE = \(f(m)) × \(f(g)) × \(f(h))",
                    "GPE = \(f(m * g)) × \(f(h))",
                    "GPE = \(f(result))"
                ]
            case "m":
                guard let gpe = vars["GPE"], let g = vars["g"], let h = vars["h"] else { break }
                return ["m = \(f(gpe)) / (\(f(g)) × \(f(h)))", "m = \(f(result))"]
            case "g":
                guard let gpe = vars["GPE"], let m = vars["m"], let h = vars["h"] else { break }
                return ["g = \(f(gpe)) / (\(f(m)) × \(f(h)))", "g = \(f(result))"]
            case "h":
                guard let gpe = vars["GPE"], let m = vars["m"], let g = vars["g"] else { break }
                return ["h = \(f(gpe)) / (\(f(m)) × \(f(g)))", "h = \(f(result))"]
            default: break
            }

        case "work_done":
            switch unknown {
            case "W":
                guard let fv = vars["F"], let d = vars["d"], let theta = vars["θ"] else { break }
                let cosVal = cos(theta * .pi / 180.0)
                return [
                    "W = \(f(fv)) × \(f(d)) × cos(\(f(theta))°)",
                    "W = \(f(fv)) × \(f(d)) × \(f(cosVal))",
                    "W = \(f(result))"
                ]
            case "F":
                guard let w = vars["W"], let d = vars["d"], let theta = vars["θ"] else { break }
                let cosVal = cos(theta * .pi / 180.0)
                return [
                    "F = \(f(w)) / (\(f(d)) × cos(\(f(theta))°))",
                    "F = \(f(w)) / \(f(d * cosVal))",
                    "F = \(f(result))"
                ]
            case "d":
                guard let w = vars["W"], let fv = vars["F"], let theta = vars["θ"] else { break }
                let cosVal = cos(theta * .pi / 180.0)
                return [
                    "d = \(f(w)) / (\(f(fv)) × cos(\(f(theta))°))",
                    "d = \(f(w)) / \(f(fv * cosVal))",
                    "d = \(f(result))"
                ]
            case "θ":
                guard let w = vars["W"], let fv = vars["F"], let d = vars["d"] else { break }
                return [
                    "θ = arccos(\(f(w)) / (\(f(fv)) × \(f(d))))",
                    "θ = arccos(\(f(w / (fv * d))))",
                    "θ = \(f(result))°"
                ]
            default: break
            }

        case "power":
            switch unknown {
            case "P":
                guard let w = vars["W"], let t = vars["t"] else { break }
                return ["P = \(f(w)) / \(f(t))", "P = \(f(result))"]
            case "W":
                guard let p = vars["P"], let t = vars["t"] else { break }
                return ["W = \(f(p)) × \(f(t))", "W = \(f(result))"]
            case "t":
                guard let w = vars["W"], let p = vars["P"] else { break }
                return ["t = \(f(w)) / \(f(p))", "t = \(f(result))"]
            default: break
            }

        case "efficiency":
            switch unknown {
            case "η":
                guard let wout = vars["Wout"], let win = vars["Win"] else { break }
                return [
                    "η = (\(f(wout)) / \(f(win))) × 100",
                    "η = \(f(wout / win)) × 100",
                    "η = \(f(result))%"
                ]
            case "Wout":
                guard let eta = vars["η"], let win = vars["Win"] else { break }
                return ["Wout = \(f(eta)) × \(f(win)) / 100", "Wout = \(f(result))"]
            case "Win":
                guard let wout = vars["Wout"], let eta = vars["η"] else { break }
                return ["Win = \(f(wout)) × 100 / \(f(eta))", "Win = \(f(result))"]
            default: break
            }

        case "conservation_energy":
            switch unknown {
            case "KEi":
                guard let pei = vars["PEi"], let kef = vars["KEf"], let pef = vars["PEf"] else { break }
                return [
                    "KEi = \(f(kef)) + \(f(pef)) − \(f(pei))",
                    "KEi = \(f(result))"
                ]
            case "PEi":
                guard let kei = vars["KEi"], let kef = vars["KEf"], let pef = vars["PEf"] else { break }
                return [
                    "PEi = \(f(kef)) + \(f(pef)) − \(f(kei))",
                    "PEi = \(f(result))"
                ]
            case "KEf":
                guard let kei = vars["KEi"], let pei = vars["PEi"], let pef = vars["PEf"] else { break }
                return [
                    "KEf = \(f(kei)) + \(f(pei)) − \(f(pef))",
                    "KEf = \(f(result))"
                ]
            case "PEf":
                guard let kei = vars["KEi"], let pei = vars["PEi"], let kef = vars["KEf"] else { break }
                return [
                    "PEf = \(f(kei)) + \(f(pei)) − \(f(kef))",
                    "PEf = \(f(result))"
                ]
            default: break
            }

        default: break
        }

        return ["\(unknown) = \(f(result))"]
    }
}
