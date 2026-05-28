import XCTest
@testable import math

// MARK: - Physics Solver Tests

class PhysicsSolverTests: XCTestCase {
    
    // MARK: - Kinematic Equations
    
    func testKinematicEquation_FindFinalVelocity() {
        let formula = PhysicsFormula.catalog.first { $0.id == "kinematic_v_uat" }!
        let knownVariables: [String: Double] = [
            "u": 5,
            "a": 2,
            "t": 3
        ]
        
        let result = PhysicsSolver.solve(
            formula: formula,
            knownVariables: knownVariables,
            unknownVariable: "v"
        )
        
        switch result {
        case .success(let solution):
            XCTAssertEqual(solution.result, 11.0, accuracy: 0.001) // v = 5 + 2(3) = 11
            XCTAssertEqual(solution.unknownVariable, "v")
        case .failure:
            XCTFail("Should solve kinematic equation")
        }
    }
    
    func testKinematicEquation_FindDistance() {
        let formula = PhysicsFormula.catalog.first { $0.id == "kinematic_s_ut_at2" }!
        let knownVariables: [String: Double] = [
            "u": 0,
            "a": 10,
            "t": 2
        ]
        
        let result = PhysicsSolver.solve(
            formula: formula,
            knownVariables: knownVariables,
            unknownVariable: "s"
        )
        
        switch result {
        case .success(let solution):
            XCTAssertEqual(solution.result, 20.0, accuracy: 0.001) // s = 0 + 0.5(10)(4) = 20
        case .failure:
            XCTFail("Should solve distance equation")
        }
    }
    
    // MARK: - Force Equations
    
    func testForceEquation_FindForce() {
        let formula = PhysicsFormula.catalog.first { $0.id == "forces_f_ma" }!
        let knownVariables: [String: Double] = [
            "m": 5,
            "a": 2
        ]
        
        let result = PhysicsSolver.solve(
            formula: formula,
            knownVariables: knownVariables,
            unknownVariable: "f"
        )
        
        switch result {
        case .success(let solution):
            XCTAssertEqual(solution.result, 10.0, accuracy: 0.001) // F = 5 × 2 = 10 N
        case .failure:
            XCTFail("Should solve force equation")
        }
    }
    
    func testWeightEquation() {
        let formula = PhysicsFormula.catalog.first { $0.id == "forces_w_mg" }!
        let knownVariables: [String: Double] = [
            "m": 10,
            "g": 9.8
        ]
        
        let result = PhysicsSolver.solve(
            formula: formula,
            knownVariables: knownVariables,
            unknownVariable: "w"
        )
        
        switch result {
        case .success(let solution):
            XCTAssertEqual(solution.result, 98.0, accuracy: 0.001)
        case .failure:
            XCTFail("Should solve weight equation")
        }
    }
    
    // MARK: - Energy Equations
    
    func testKineticEnergy() {
        let formula = PhysicsFormula.catalog.first { $0.id == "energy_ke" }!
        let knownVariables: [String: Double] = [
            "m": 2,
            "v": 5
        ]
        
        let result = PhysicsSolver.solve(
            formula: formula,
            knownVariables: knownVariables,
            unknownVariable: "ke"
        )
        
        switch result {
        case .success(let solution):
            XCTAssertEqual(solution.result, 25.0, accuracy: 0.001) // KE = 0.5(2)(25) = 25 J
        case .failure:
            XCTFail("Should solve kinetic energy equation")
        }
    }
    
    func testPotentialEnergy() {
        let formula = PhysicsFormula.catalog.first { $0.id == "energy_pe" }!
        let knownVariables: [String: Double] = [
            "m": 10,
            "g": 9.8,
            "h": 5
        ]
        
        let result = PhysicsSolver.solve(
            formula: formula,
            knownVariables: knownVariables,
            unknownVariable: "pe"
        )
        
        switch result {
        case .success(let solution):
            XCTAssertEqual(solution.result, 490.0, accuracy: 0.001) // PE = 10(9.8)(5) = 490 J
        case .failure:
            XCTFail("Should solve potential energy equation")
        }
    }
    
    // MARK: - Unit Conversions
    
    func testUnitConversion_MetersToKilometers() {
        let result = PhysicsSolver.convertUnit(value: 1000, from: "m", to: "km")
        XCTAssertEqual(result, 1.0, accuracy: 0.001)
    }
    
    func testUnitConversion_KmhToMs() {
        let result = PhysicsSolver.convertUnit(value: 36, from: "km/h", to: "m/s")
        XCTAssertEqual(result, 10.0, accuracy: 0.001)
    }
    
    func testUnitConversion_GramsToKilograms() {
        let result = PhysicsSolver.convertUnit(value: 500, from: "g", to: "kg")
        XCTAssertEqual(result, 0.5, accuracy: 0.001)
    }
    
    func testUnitConversion_InvalidConversion() {
        let result = PhysicsSolver.convertUnit(value: 100, from: "meters", to: "celsius")
        XCTAssertNil(result)
    }
}

// MARK: - Topics Provider Tests

class TopicsProviderTests: XCTestCase {
    
    func testAlgebraTopicsProvider() {
        let allTopics = AlgebraTopicsProvider.allTopics
        XCTAssertEqual(allTopics.count, 5)
        XCTAssertEqual(allTopics[0].id, "algebra_polynomials")
    }
    
    func testCalculusTopicsProvider() {
        let allTopics = CalculusTopicsProvider.allTopics
        XCTAssertEqual(allTopics.count, 4)
        XCTAssertEqual(allTopics[0].id, "calculus_limits")
    }
    
    func testTrigonometryTopicsProvider() {
        let allTopics = TrigonometryTopicsProvider.allTopics
        XCTAssertEqual(allTopics.count, 5)
        XCTAssertEqual(allTopics[0].id, "trig_right_triangles")
    }
    
    func testPreCalculusTopicsProvider() {
        let allTopics = PreCalculusTopicsProvider.allTopics
        XCTAssertEqual(allTopics.count, 5)
        XCTAssert(allTopics.map { $0.category }.allSatisfy { $0 == .preCalculus })
    }
    
    func testTopicRetrieval() {
        let topic = AlgebraTopicsProvider.topic(withId: "algebra_polynomials")
        XCTAssertNotNil(topic)
        XCTAssertEqual(topic?.title, "Polynomials")
    }
}

// MARK: - Formula Catalog Tests

class FormulaCatalogTests: XCTestCase {
    
    func testCatalogCount() {
        let catalog = PhysicsFormula.catalog
        XCTAssertGreaterThan(catalog.count, 10)
    }
    
    func testCatalogHasKinematicFormulas() {
        let catalog = PhysicsFormula.catalog
        let kinematicFormulas = catalog.filter { $0.domain == .kinematics }
        XCTAssertGreaterThan(kinematicFormulas.count, 0)
    }
    
    func testCatalogHasEnergyFormulas() {
        let catalog = PhysicsFormula.catalog
        let energyFormulas = catalog.filter { $0.domain == .energy }
        XCTAssertGreaterThan(energyFormulas.count, 0)
    }
    
    func testFormulaNamesUnique() {
        let catalog = PhysicsFormula.catalog
        let names = catalog.map { $0.name }
        let uniqueNames = Set(names)
        XCTAssertEqual(names.count, uniqueNames.count)
    }
}
