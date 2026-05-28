import Foundation

/// Solves physics problems using formula catalog and algebraic rearrangement
struct PhysicsSolver {
    /// Common SI/imperial unit conversions
    static let unitConversions: [String: (from: String, to: String, factor: Double)] = [
        "km_to_m": ("km", "m", 1000),
        "m_to_km": ("m", "km", 1/1000),
        "km/h_to_m/s": ("km/h", "m/s", 1/3.6),
        "m/s_to_km/h": ("m/s", "km/h", 3.6),
        "g_to_kg": ("g", "kg", 1/1000),
        "kg_to_g": ("kg", "g", 1000),
        "cm_to_m": ("cm", "m", 1/100),
        "m_to_cm": ("m", "cm", 100),
    ]
    
    /// Find the most relevant formula from the catalog based on variables present
    static func findFormula(forVariables variables: [String]) -> PhysicsFormula? {
        let variableSet = Set(variables.map { $0.lowercased() })
        
        // Find formula that uses the most of the given variables
        var bestFormula: PhysicsFormula?
        var bestMatch = 0
        
        for formula in PhysicsFormula.catalog {
            let formulaVars = Set(formula.variables.map { $0.symbol.lowercased() })
            let matchCount = variableSet.intersection(formulaVars).count
            
            if matchCount > bestMatch {
                bestMatch = matchCount
                bestFormula = formula
            }
        }
        
        return bestFormula
    }
    
    /// Solve a physics problem given a formula and known variables
    static func solve(
        formula: PhysicsFormula,
        knownVariables: [String: Double],
        unknownVariable: String
    ) -> Result<PhysicsSolution, SolverError> {
        var steps: [SolutionStep] = []
        var stepNumber = 1
        
        // Step 1: Identify formula
        steps.append(SolutionStep(
            stepNumber: stepNumber,
            operation: .identifyFormula(formula.expression),
            description: "Identify the formula",
            resultEquation: formula.expression,
            explanation: "\(formula.name): \(formula.expression)"
        ))
        stepNumber += 1
        
        // Verify all necessary variables are provided
        let formulaVars = Set(formula.variables.map { $0.symbol.lowercased() })
        let knownVars = Set(knownVariables.keys.map { $0.lowercased() })
        let missingVars = formulaVars.filter { !knownVars.contains($0) && $0.lowercased() != unknownVariable.lowercased() }
        
        guard missingVars.isEmpty else {
            let missing = missingVars.joined(separator: ", ")
            return .failure(.solverFailed("Missing required variables: \(missing)"))
        }
        
        // Step 2: List known values
        var knownValuesStr = ""
        var knownVariablesWithUnits: [String: (value: Double, unit: String)] = [:]
        
        for (symbol, value) in knownVariables {
            if let variable = formula.variables.first(where: { $0.symbol.lowercased() == symbol.lowercased() }) {
                knownValuesStr += "\(variable.symbol) = \(String(format: "%.2f", value)) \(variable.unit)\n"
                knownVariablesWithUnits[variable.symbol] = (value: value, unit: variable.unit)
            }
        }
        
        steps.append(SolutionStep(
            stepNumber: stepNumber,
            operation: .substituteValues,
            description: "List known values",
            resultEquation: knownValuesStr,
            explanation: "Given values: " + knownValuesStr.replacingOccurrences(of: "\n", with: ", ")
        ))
        stepNumber += 1
        
        // Step 3: Rearrange for unknown (simple symbolic rearrangement)
        let rearrangedFormula = "Solve for \(unknownVariable): [rearranged algebraically]"
        steps.append(SolutionStep(
            stepNumber: stepNumber,
            operation: .rearrangeFormula(rearrangedFormula),
            description: "Rearrange formula for the unknown",
            resultEquation: rearrangedFormula,
            explanation: "Algebraically isolate \(unknownVariable) on one side of the equation."
        ))
        stepNumber += 1
        
        // Step 4: Compute result (simplified computation for the known formulas)
        let result = computeResult(
            formula: formula,
            knownVariables: knownVariables,
            unknownVariable: unknownVariable
        )
        
        guard let (resultValue, resultUnit) = result else {
            return .failure(.solverFailed("Could not compute result. Check formula and variables."))
        }
        
        steps.append(SolutionStep(
            stepNumber: stepNumber,
            operation: .computeResult,
            description: "Calculate final result",
            resultEquation: "\(unknownVariable) = \(String(format: "%.2f", resultValue)) \(resultUnit)",
            explanation: "Substituting values: \(unknownVariable) = \(String(format: "%.2f", resultValue)) \(resultUnit)"
        ))
        
        let solution = PhysicsSolution(
            formula: formula,
            knownVariables: knownVariablesWithUnits,
            unknownVariable: unknownVariable,
            result: resultValue,
            resultUnit: resultUnit,
            steps: steps
        )
        
        return .success(solution)
    }
    
    /// Compute the result based on formula and known variables
    /// Handles common kinematics, forces, and energy formulas
    private static func computeResult(
        formula: PhysicsFormula,
        knownVariables: [String: Double],
        unknownVariable: String
    ) -> (Double, String)? {
        let unknown = unknownVariable.lowercased()
        
        // Create normalized dictionary (lowercase keys)
        var vars: [String: Double] = [:]
        for (k, v) in knownVariables {
            vars[k.lowercased()] = v
        }
        
        // Special case: gravity constant
        if !vars.keys.contains("g") {
            vars["g"] = 9.8 // Standard gravity
        }
        
        // Compute based on formula ID
        switch formula.id {
        case "kinematic_v_uat":
            // v = u + at
            if unknown == "v", let u = vars["u"], let a = vars["a"], let t = vars["t"] {
                return (u + a * t, "m/s")
            } else if unknown == "u", let v = vars["v"], let a = vars["a"], let t = vars["t"] {
                return (v - a * t, "m/s")
            } else if unknown == "a", let v = vars["v"], let u = vars["u"], let t = vars["t"], t != 0 {
                return ((v - u) / t, "m/s²")
            } else if unknown == "t", let v = vars["v"], let u = vars["u"], let a = vars["a"], a != 0 {
                return ((v - u) / a, "s")
            }
            
        case "kinematic_s_ut_at2":
            // s = ut + ½at²
            if unknown == "s", let u = vars["u"], let a = vars["a"], let t = vars["t"] {
                return (u * t + 0.5 * a * t * t, "m")
            }
            
        case "kinematic_v2_u2_2as":
            // v² = u² + 2as
            if unknown == "v", let u = vars["u"], let a = vars["a"], let s = vars["s"] {
                return (sqrt(u * u + 2 * a * s), "m/s")
            } else if unknown == "a", let v = vars["v"], let u = vars["u"], let s = vars["s"], s != 0 {
                return ((v * v - u * u) / (2 * s), "m/s²")
            }
            
        case "kinematic_s_avg_t":
            // s = ½(u + v)t
            if unknown == "s", let u = vars["u"], let v = vars["v"], let t = vars["t"] {
                return (0.5 * (u + v) * t, "m")
            }
            
        case "kinematic_v_avg":
            // v = d / t
            if unknown == "v", let d = vars["d"], let t = vars["t"], t != 0 {
                return (d / t, "m/s")
            } else if unknown == "d", let v = vars["v"], let t = vars["t"] {
                return (v * t, "m")
            } else if unknown == "t", let d = vars["d"], let v = vars["v"], v != 0 {
                return (d / v, "s")
            }
            
        case "forces_f_ma":
            // F = ma
            if unknown == "f", let m = vars["m"], let a = vars["a"] {
                return (m * a, "N")
            } else if unknown == "m", let f = vars["f"], let a = vars["a"], a != 0 {
                return (f / a, "kg")
            } else if unknown == "a", let f = vars["f"], let m = vars["m"], m != 0 {
                return (f / m, "m/s²")
            }
            
        case "forces_w_mg":
            // W = mg
            if unknown == "w", let m = vars["m"], let g = vars["g"] {
                return (m * g, "N")
            } else if unknown == "m", let w = vars["w"], let g = vars["g"], g != 0 {
                return (w / g, "kg")
            }
            
        case "forces_f_friction":
            // f = μN
            if unknown == "f", let mu = vars["μ"], let n = vars["n"] {
                return (mu * n, "N")
            } else if unknown == "μ", let f = vars["f"], let n = vars["n"], n != 0 {
                return (f / n, "")
            } else if unknown == "n", let f = vars["f"], let mu = vars["μ"], mu != 0 {
                return (f / mu, "N")
            }
            
        case "forces_p_mv":
            // p = mv
            if unknown == "p", let m = vars["m"], let v = vars["v"] {
                return (m * v, "kg·m/s")
            } else if unknown == "m", let p = vars["p"], let v = vars["v"], v != 0 {
                return (p / v, "kg")
            } else if unknown == "v", let p = vars["p"], let m = vars["m"], m != 0 {
                return (p / m, "m/s")
            }
            
        case "forces_impulse":
            // F·t = Δp
            if unknown == "δp", let f = vars["f"], let t = vars["t"] {
                return (f * t, "kg·m/s")
            } else if unknown == "f", let deltaP = vars["δp"], let t = vars["t"], t != 0 {
                return (deltaP / t, "N")
            } else if unknown == "t", let deltaP = vars["δp"], let f = vars["f"], f != 0 {
                return (deltaP / f, "s")
            }
            
        case "energy_ke":
            // KE = ½mv²
            if unknown == "ke", let m = vars["m"], let v = vars["v"] {
                return (0.5 * m * v * v, "J")
            } else if unknown == "m", let ke = vars["ke"], let v = vars["v"], v != 0 {
                return (2 * ke / (v * v), "kg")
            } else if unknown == "v", let ke = vars["ke"], let m = vars["m"], m != 0 {
                return (sqrt(2 * ke / m), "m/s")
            }
            
        case "energy_pe":
            // PE = mgh
            if unknown == "pe", let m = vars["m"], let g = vars["g"], let h = vars["h"] {
                return (m * g * h, "J")
            } else if unknown == "m", let pe = vars["pe"], let g = vars["g"], let h = vars["h"], (g * h) != 0 {
                return (pe / (g * h), "kg")
            } else if unknown == "h", let pe = vars["pe"], let m = vars["m"], let g = vars["g"], (m * g) != 0 {
                return (pe / (m * g), "m")
            }
            
        case "energy_work":
            // W = Fd
            if unknown == "w", let f = vars["f"], let d = vars["d"] {
                return (f * d, "J")
            } else if unknown == "f", let w = vars["w"], let d = vars["d"], d != 0 {
                return (w / d, "N")
            } else if unknown == "d", let w = vars["w"], let f = vars["f"], f != 0 {
                return (w / f, "m")
            }
            
        case "energy_power_1":
            // P = W / t
            if unknown == "p", let w = vars["w"], let t = vars["t"], t != 0 {
                return (w / t, "W")
            } else if unknown == "w", let p = vars["p"], let t = vars["t"] {
                return (p * t, "J")
            } else if unknown == "t", let p = vars["p"], let w = vars["w"], p != 0 {
                return (w / p, "s")
            }
            
        case "energy_power_2":
            // P = Fv
            if unknown == "p", let f = vars["f"], let v = vars["v"] {
                return (f * v, "W")
            } else if unknown == "f", let p = vars["p"], let v = vars["v"], v != 0 {
                return (p / v, "N")
            } else if unknown == "v", let p = vars["p"], let f = vars["f"], f != 0 {
                return (p / f, "m/s")
            }
            
        case "density":
            // ρ = m / V
            if unknown == "ρ", let m = vars["m"], let v = vars["v"], v != 0 {
                return (m / v, "kg/m³")
            } else if unknown == "m", let rho = vars["ρ"], let v = vars["v"] {
                return (rho * v, "kg")
            } else if unknown == "v", let rho = vars["ρ"], let m = vars["m"], rho != 0 {
                return (m / rho, "m³")
            }
            
        case "pressure":
            // P = F / A
            if unknown == "p", let f = vars["f"], let a = vars["a"], a != 0 {
                return (f / a, "Pa")
            } else if unknown == "f", let p = vars["p"], let a = vars["a"] {
                return (p * a, "N")
            } else if unknown == "a", let p = vars["p"], let f = vars["f"], p != 0 {
                return (f / p, "m²")
            }
            
        default:
            return nil
        }
        
        return nil
    }
    
    /// Convert a value from one unit to another
    static func convertUnit(value: Double, from: String, to: String) -> Double? {
        guard from != to else { return value }
        
        for (_, conversion) in unitConversions {
            if conversion.from.lowercased() == from.lowercased() && conversion.to.lowercased() == to.lowercased() {
                return value * conversion.factor
            }
        }
        
        return nil
    }
}
