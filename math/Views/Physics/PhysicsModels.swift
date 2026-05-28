import Foundation

// MARK: - Domain

/// Physics domain categories
enum PhysicsDomain: String, CaseIterable, Codable {
    case kinematics = "Kinematics"
    case forces     = "Forces"
    case energy     = "Energy"
}

// MARK: - Variable

/// A single variable within a physics formula
struct PhysicsVariable: Identifiable, Codable {
    let symbol: String
    let name: String
    let unit: String
    let description: String
    var id: String { symbol }
}

// MARK: - Formula

/// A physics formula with its variables and catalog
struct PhysicsFormula: Identifiable, Codable {
    let id: String
    let name: String
    let domain: PhysicsDomain
    let expression: String
    let variables: [PhysicsVariable]
    let keywords: [String]
    let defaultUnknown: String            // symbol solved for by default

    // MARK: Catalog — 18 formulas across 3 domains

    static let catalog: [PhysicsFormula] = {
        var list: [PhysicsFormula] = []

        // ── KINEMATICS (5) ──────────────────────────────────────

        list.append(PhysicsFormula(
            id: "final_velocity", name: "Final Velocity",
            domain: .kinematics, expression: "v = u + at",
            variables: [
                PhysicsVariable(symbol: "v", name: "Final Velocity",   unit: "m/s",  description: "Speed at the end"),
                PhysicsVariable(symbol: "u", name: "Initial Velocity", unit: "m/s",  description: "Speed at the start"),
                PhysicsVariable(symbol: "a", name: "Acceleration",     unit: "m/s²", description: "Rate of velocity change"),
                PhysicsVariable(symbol: "t", name: "Time",             unit: "s",    description: "Duration"),
            ],
            keywords: ["velocity","acceleration","time","motion"],
            defaultUnknown: "v"
        ))

        list.append(PhysicsFormula(
            id: "displacement_uvt", name: "Displacement (v,u,t)",
            domain: .kinematics, expression: "s = ((u + v) / 2) × t",
            variables: [
                PhysicsVariable(symbol: "s", name: "Displacement",     unit: "m",   description: "Distance traveled"),
                PhysicsVariable(symbol: "u", name: "Initial Velocity", unit: "m/s", description: "Starting speed"),
                PhysicsVariable(symbol: "v", name: "Final Velocity",   unit: "m/s", description: "Ending speed"),
                PhysicsVariable(symbol: "t", name: "Time",             unit: "s",   description: "Duration"),
            ],
            keywords: ["displacement","average velocity","distance"],
            defaultUnknown: "s"
        ))

        list.append(PhysicsFormula(
            id: "displacement_uat", name: "Displacement (u,a,t)",
            domain: .kinematics, expression: "s = ut + ½at²",
            variables: [
                PhysicsVariable(symbol: "s", name: "Displacement",     unit: "m",    description: "Distance traveled"),
                PhysicsVariable(symbol: "u", name: "Initial Velocity", unit: "m/s",  description: "Starting speed"),
                PhysicsVariable(symbol: "a", name: "Acceleration",     unit: "m/s²", description: "Rate of velocity change"),
                PhysicsVariable(symbol: "t", name: "Time",             unit: "s",    description: "Duration"),
            ],
            keywords: ["displacement","distance","kinematics"],
            defaultUnknown: "s"
        ))

        list.append(PhysicsFormula(
            id: "velocity_squared", name: "Final Velocity Squared",
            domain: .kinematics, expression: "v² = u² + 2as",
            variables: [
                PhysicsVariable(symbol: "v", name: "Final Velocity",   unit: "m/s",  description: "Speed at end"),
                PhysicsVariable(symbol: "u", name: "Initial Velocity", unit: "m/s",  description: "Speed at start"),
                PhysicsVariable(symbol: "a", name: "Acceleration",     unit: "m/s²", description: "Rate of velocity change"),
                PhysicsVariable(symbol: "s", name: "Displacement",     unit: "m",    description: "Distance"),
            ],
            keywords: ["velocity","displacement","acceleration"],
            defaultUnknown: "v"
        ))

        list.append(PhysicsFormula(
            id: "acceleration", name: "Acceleration",
            domain: .kinematics, expression: "a = (v − u) / t",
            variables: [
                PhysicsVariable(symbol: "a", name: "Acceleration",     unit: "m/s²", description: "Rate of velocity change"),
                PhysicsVariable(symbol: "v", name: "Final Velocity",   unit: "m/s",  description: "Speed at end"),
                PhysicsVariable(symbol: "u", name: "Initial Velocity", unit: "m/s",  description: "Speed at start"),
                PhysicsVariable(symbol: "t", name: "Time",             unit: "s",    description: "Duration"),
            ],
            keywords: ["acceleration","velocity","time"],
            defaultUnknown: "a"
        ))

        // ── FORCES (7) ─────────────────────────────────────────

        list.append(PhysicsFormula(
            id: "newtons_second", name: "Newton's Second Law",
            domain: .forces, expression: "F = ma",
            variables: [
                PhysicsVariable(symbol: "F", name: "Force",        unit: "N",    description: "Net applied force"),
                PhysicsVariable(symbol: "m", name: "Mass",         unit: "kg",   description: "Amount of matter"),
                PhysicsVariable(symbol: "a", name: "Acceleration", unit: "m/s²", description: "Rate of velocity change"),
            ],
            keywords: ["force","mass","acceleration","Newton"],
            defaultUnknown: "F"
        ))

        list.append(PhysicsFormula(
            id: "weight", name: "Weight",
            domain: .forces, expression: "W = mg",
            variables: [
                PhysicsVariable(symbol: "W", name: "Weight",  unit: "N",    description: "Gravitational force"),
                PhysicsVariable(symbol: "m", name: "Mass",    unit: "kg",   description: "Amount of matter"),
                PhysicsVariable(symbol: "g", name: "Gravity", unit: "m/s²", description: "Gravitational acceleration (≈9.81)"),
            ],
            keywords: ["weight","mass","gravity"],
            defaultUnknown: "W"
        ))

        list.append(PhysicsFormula(
            id: "friction", name: "Friction",
            domain: .forces, expression: "f = μN",
            variables: [
                PhysicsVariable(symbol: "f", name: "Friction Force",          unit: "N", description: "Resistive force"),
                PhysicsVariable(symbol: "μ", name: "Coefficient of Friction", unit: "",  description: "Unitless friction constant"),
                PhysicsVariable(symbol: "N", name: "Normal Force",            unit: "N", description: "Perpendicular contact force"),
            ],
            keywords: ["friction","coefficient","normal force"],
            defaultUnknown: "f"
        ))

        list.append(PhysicsFormula(
            id: "pressure", name: "Pressure",
            domain: .forces, expression: "P = F / A",
            variables: [
                PhysicsVariable(symbol: "P", name: "Pressure", unit: "Pa", description: "Force per unit area"),
                PhysicsVariable(symbol: "F", name: "Force",    unit: "N",  description: "Applied force"),
                PhysicsVariable(symbol: "A", name: "Area",     unit: "m²", description: "Surface area"),
            ],
            keywords: ["pressure","force","area"],
            defaultUnknown: "P"
        ))

        list.append(PhysicsFormula(
            id: "momentum", name: "Momentum",
            domain: .forces, expression: "p = mv",
            variables: [
                PhysicsVariable(symbol: "p", name: "Momentum", unit: "kg·m/s", description: "Mass times velocity"),
                PhysicsVariable(symbol: "m", name: "Mass",     unit: "kg",     description: "Amount of matter"),
                PhysicsVariable(symbol: "v", name: "Velocity", unit: "m/s",    description: "Speed and direction"),
            ],
            keywords: ["momentum","mass","velocity"],
            defaultUnknown: "p"
        ))

        list.append(PhysicsFormula(
            id: "impulse", name: "Impulse",
            domain: .forces, expression: "J = FΔt",
            variables: [
                PhysicsVariable(symbol: "J",  name: "Impulse", unit: "N·s", description: "Change in momentum"),
                PhysicsVariable(symbol: "F",  name: "Force",   unit: "N",   description: "Applied force"),
                PhysicsVariable(symbol: "Δt", name: "Time",    unit: "s",   description: "Duration of force"),
            ],
            keywords: ["impulse","momentum","force","time"],
            defaultUnknown: "J"
        ))

        list.append(PhysicsFormula(
            id: "hookes_law", name: "Hooke's Law",
            domain: .forces, expression: "F = kx",
            variables: [
                PhysicsVariable(symbol: "F", name: "Spring Force",    unit: "N",   description: "Restoring force"),
                PhysicsVariable(symbol: "k", name: "Spring Constant", unit: "N/m", description: "Stiffness"),
                PhysicsVariable(symbol: "x", name: "Extension",       unit: "m",   description: "Displacement from equilibrium"),
            ],
            keywords: ["spring","hooke","elastic","force"],
            defaultUnknown: "F"
        ))

        // ── ENERGY (6) ─────────────────────────────────────────

        list.append(PhysicsFormula(
            id: "kinetic_energy", name: "Kinetic Energy",
            domain: .energy, expression: "KE = ½mv²",
            variables: [
                PhysicsVariable(symbol: "KE", name: "Kinetic Energy", unit: "J",   description: "Energy of motion"),
                PhysicsVariable(symbol: "m",  name: "Mass",           unit: "kg",  description: "Amount of matter"),
                PhysicsVariable(symbol: "v",  name: "Velocity",       unit: "m/s", description: "Speed"),
            ],
            keywords: ["kinetic","energy","motion","velocity"],
            defaultUnknown: "KE"
        ))

        list.append(PhysicsFormula(
            id: "gravitational_pe", name: "Gravitational PE",
            domain: .energy, expression: "GPE = mgh",
            variables: [
                PhysicsVariable(symbol: "GPE", name: "Gravitational PE", unit: "J",    description: "Energy due to height"),
                PhysicsVariable(symbol: "m",   name: "Mass",            unit: "kg",   description: "Amount of matter"),
                PhysicsVariable(symbol: "g",   name: "Gravity",         unit: "m/s²", description: "Gravitational acceleration"),
                PhysicsVariable(symbol: "h",   name: "Height",          unit: "m",    description: "Vertical distance"),
            ],
            keywords: ["potential","gravitational","height","energy"],
            defaultUnknown: "GPE"
        ))

        list.append(PhysicsFormula(
            id: "work_done", name: "Work Done",
            domain: .energy, expression: "W = Fd cosθ",
            variables: [
                PhysicsVariable(symbol: "W", name: "Work",  unit: "J", description: "Energy transferred"),
                PhysicsVariable(symbol: "F", name: "Force", unit: "N", description: "Applied force"),
                PhysicsVariable(symbol: "d", name: "Distance", unit: "m", description: "Distance moved"),
                PhysicsVariable(symbol: "θ", name: "Angle", unit: "°", description: "Angle between force and displacement"),
            ],
            keywords: ["work","force","distance","angle"],
            defaultUnknown: "W"
        ))

        list.append(PhysicsFormula(
            id: "power", name: "Power",
            domain: .energy, expression: "P = W / t",
            variables: [
                PhysicsVariable(symbol: "P", name: "Power", unit: "W", description: "Rate of energy transfer"),
                PhysicsVariable(symbol: "W", name: "Work",  unit: "J", description: "Energy transferred"),
                PhysicsVariable(symbol: "t", name: "Time",  unit: "s", description: "Duration"),
            ],
            keywords: ["power","work","time","rate"],
            defaultUnknown: "P"
        ))

        list.append(PhysicsFormula(
            id: "efficiency", name: "Efficiency",
            domain: .energy, expression: "η = (Wout / Win) × 100",
            variables: [
                PhysicsVariable(symbol: "η",    name: "Efficiency",    unit: "%", description: "Percentage of useful energy"),
                PhysicsVariable(symbol: "Wout", name: "Useful Output", unit: "J", description: "Useful energy output"),
                PhysicsVariable(symbol: "Win",  name: "Total Input",   unit: "J", description: "Total energy input"),
            ],
            keywords: ["efficiency","useful","output","input"],
            defaultUnknown: "η"
        ))

        list.append(PhysicsFormula(
            id: "conservation_energy", name: "Conservation of Energy",
            domain: .energy, expression: "KE₁ + PE₁ = KE₂ + PE₂",
            variables: [
                PhysicsVariable(symbol: "KEi", name: "Initial KE", unit: "J", description: "Kinetic energy at start"),
                PhysicsVariable(symbol: "PEi", name: "Initial PE", unit: "J", description: "Potential energy at start"),
                PhysicsVariable(symbol: "KEf", name: "Final KE",   unit: "J", description: "Kinetic energy at end"),
                PhysicsVariable(symbol: "PEf", name: "Final PE",   unit: "J", description: "Potential energy at end"),
            ],
            keywords: ["conservation","energy","kinetic","potential"],
            defaultUnknown: "KEf"
        ))

        return list
    }()

    /// Formulas filtered by domain
    static func formulas(for domain: PhysicsDomain) -> [PhysicsFormula] {
        catalog.filter { $0.domain == domain }
    }
}

// MARK: - Solution step (physics-specific, lightweight)

/// One of the 5 ordered solution steps shown in PhysicsSolutionView
struct PhysSolveStep: Identifiable {
    let id = UUID()
    let number: Int            // 1–5
    let title: String          // e.g. "Identify the Formula"
    let lines: [String]        // content lines
    let expandedByDefault: Bool
}

// MARK: - Full solution result

struct PhysSolveResult {
    let formula: PhysicsFormula
    let knownValues: [(symbol: String, name: String, value: Double, unit: String)]
    let unknownSymbol: String
    let unknownName: String
    let result: Double
    let resultUnit: String
    let steps: [PhysSolveStep]
}
