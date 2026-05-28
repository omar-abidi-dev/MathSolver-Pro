import SwiftUI
import Combine

@MainActor
final class PhysicsViewModel: ObservableObject {

    // MARK: - Published state

    @Published var selectedDomain: PhysicsDomain = .kinematics
    @Published var selectedFormulaID: String?
    @Published var fieldValues: [String: String] = [:]   // symbol → text
    @Published var selectedUnknown: String?
    @Published var errorMessage: String?
    @Published var solveResult: PhysSolveResult?
    @Published var showFormulaPicker = false
    @Published var showSolution = false

    // MARK: - Derived

    var domainFormulas: [PhysicsFormula] {
        PhysicsFormula.formulas(for: selectedDomain)
    }

    var selectedFormula: PhysicsFormula? {
        guard let id = selectedFormulaID else { return nil }
        return PhysicsFormula.catalog.first { $0.id == id }
    }

    /// Variables that the user can enter values for (everything except the unknown)
    var inputVariables: [PhysicsVariable] {
        guard let formula = selectedFormula else { return [] }
        return formula.variables.filter { $0.symbol != selectedUnknown }
    }

    // MARK: - Init

    init() {
        // Auto-select the first formula of the default domain
        selectedFormulaID = domainFormulas.first?.id
        if let f = selectedFormula {
            selectedUnknown = f.defaultUnknown
        }
    }

    // MARK: - Actions

    func selectDomain(_ domain: PhysicsDomain) {
        selectedDomain = domain
        let formulas = domainFormulas
        selectedFormulaID = formulas.first?.id
        fieldValues = [:]
        errorMessage = nil
        solveResult = nil
        if let f = selectedFormula {
            selectedUnknown = f.defaultUnknown
        } else {
            selectedUnknown = nil
        }
    }

    func selectFormula(_ id: String) {
        selectedFormulaID = id
        fieldValues = [:]
        errorMessage = nil
        solveResult = nil
        if let f = selectedFormula {
            selectedUnknown = f.defaultUnknown
        }
    }

    func selectUnknown(_ symbol: String) {
        selectedUnknown = symbol
        // Remove any value entered for the newly-selected unknown
        fieldValues.removeValue(forKey: symbol)
        errorMessage = nil
    }

    func solve() {
        errorMessage = nil
        solveResult = nil

        guard let formula = selectedFormula else {
            errorMessage = "Select a formula"
            return
        }
        guard let unknown = selectedUnknown else {
            errorMessage = "Select a variable to solve for"
            return
        }

        // Parse field values
        var parsed: [String: Double] = [:]
        for v in formula.variables where v.symbol != unknown {
            let text = (fieldValues[v.symbol] ?? "").trimmingCharacters(in: .whitespaces)
            if text.isEmpty {
                errorMessage = "Enter a value for \(v.name) (\(v.symbol))"
                return
            }
            guard let num = Double(text), num.isFinite else {
                errorMessage = "Invalid number for \(v.symbol): \"\(text)\""
                return
            }
            parsed[v.symbol] = num
        }

        guard let result = PhysicsEngine.solve(
            formula: formula,
            knownValues: parsed,
            unknownSymbol: unknown
        ) else {
            errorMessage = "Could not compute — check your values"
            return
        }

        solveResult = result
        showSolution = true
    }
}
