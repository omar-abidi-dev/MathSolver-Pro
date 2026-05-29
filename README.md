# MathSolver Pro  App: AI-Powered Step-by-Step Mathematics Learning for Every Student 

## Overview
A comprehensive math learning and problem-solving iOS application built with SwiftUI. The app provides interactive tutorials, formula solving, and step-by-step solutions across multiple math domains.

## System Architecture Diagram

<p align="center">
  <img src="assets/System-Architecture-Diagram.png" width="600"/>
</p>

## Architecture

### Core Components

#### 1. Domain Models (`Models/`)
- **MathDomain**: Enum defining supported subject areas (Algebra, Calculus, Trigonometry, etc.)
- **Topic**: Comprehensive topic structure with explanations and examples
- **PhysicsFormula**: Formula catalog with variables, units, and expressions
- **PhysicsSolution & SolutionStep**: detailed step-by-step solutions
- **SolverError**: Unified error handling

#### 2. Math Engine (`Engine/`)

**Base Factory Pattern**
- `MathSolver`: Abstract base factory for creating domain-specific solvers
- Protocol-based architecture for extensibility

**Domain Solvers**
- `AlgebraSolver`: Solves linear/quadratic equations, systems, polynomials
- `CalculusWorkerSolver`: Calculates integrals, derivatives, limits
- `AlgebraEquationSolver`: Specialized equation solving with variable rearrangement
- `EquationSolver`: General equation solving (linear, quadratic)
- `PhysicsSolver`: Physics problem solving with formula catalog and unit conversion

#### 3. Data Providers (`DataProviders/`)
- **CalculusTopicsProvider**: Limits, derivatives, integrals, series
- **AlgebraTopicsProvider**: Polynomials, equations, factoring, functions, rationals
- **TrigonometryTopicsProvider**: Right triangles, unit circle, identities, inverse functions, graphs
- **PreCalculusTopicsProvider**: Exponents, linear/quadratic, polynomial/rational, exponential/logarithmic, sequences

#### 4. Formulas (`Engine/Formulas/`)
- **FormulaCatalog**: 20+ physics formulas across:
  - Kinematics (4 formulas)
  - Forces (4 formulas)
  - Motion & Collisions (2 formulas)
  - Work & Energy (4 formulas)
  - Density & Pressure (2 formulas)

## Key Features

### Algebra Solver
```swift
let solver = AlgebraSolver()
let result = solver.solve(equation: "2x + 3 = 11", variable: "x")
// Returns: x = 4 with solution steps
```

### Physics Formula Solver
```swift
let formula = PhysicsFormula.catalog.first { $0.id == "forces_f_ma" }!
let result = PhysicsSolver.solve(
    formula: formula,
    knownVariables: ["m": 5, "a": 2],
    unknownVariable: "f"
)
// Returns: F = 10 N (Newton) with step-by-step breakdown
```

### Unit Conversion
```swift
let converted = PhysicsSolver.convertUnit(
    value: 1000,
    from: "m",
    to: "km"
)
// Returns: 1.0 km
```

### Topic Learning
```swift
let topic = AlgebraTopicsProvider.topic(withId: "algebra_polynomials")
// Provides comprehensive explanation, examples, and related formulas
```

## Supported Formulas

### Kinematics
- v = u + at
- s = ut + ½at²
- v² = u² + 2as
- s = ½(u + v)t
- v = d/t

### Forces
- F = ma (Newton's Second Law)
- W = mg (Weight)
- f = μN (Friction)
- p = mv (Momentum)
- Impulse: F·t = Δp

### Energy
- KE = ½mv² (Kinetic Energy)
- PE = mgh (Potential Energy)
- W = Fd (Work)
- P = W/t (Power)
- P = Fv (Power alternative)

### Properties
- ρ = m/V (Density)
- P = F/A (Pressure)

## Unit Support

### Length
- km ↔ m ↔ cm

### Velocity
- km/h ↔ m/s

### Mass
- g ↔ kg

### Physics Units
- N (Newtons)
- J (Joules)
- W (Watts)
- Pa (Pascals)
- kg·m/s (momentum)

## Math Topics Covered

### Algebra (5 topics)
1. Polynomials
2. Equations & Inequalities
3. Factoring
4. Functions
5. Rational Expressions

### Calculus (4 topics)
1. Limits
2. Derivatives
3. Integrals
4. Series & Sequences

### Trigonometry (5 topics)
1. Right Triangles
2. Unit Circle
3. Identities
4. Inverse Functions
5. Graphs

### Pre-Calculus (5 topics)
1. Linear & Quadratic Functions
2. Polynomial & Rational Functions
3. Exponents & Logarithms
4. Exponential & Logarithmic Functions
5. Sequences & Series

## Testing

Comprehensive test suite in `mathTests/SolverTests.swift` covering:

### Algebra Tests
- Linear equations (simple, negative results, fractions)
- Systems of equations (2x2)
- Polynomial simplification
- Binomial expansion
- Function evaluation and composition

### Physics Tests
- Kinematic equations (velocity, distance)
- Force equations (F=ma, weight)
- Energy calculations (KE, PE)
- Unit conversions

### Topics Tests
- Topic provider availability
- Topic retrieval by ID
- Example accuracy

### Formula Tests
- Catalog completeness
- Formula uniqueness
- Category coverage

## Error Handling

The architecture provides comprehensive error handling via `SolverError`:
```swift
enum SolverError: LocalizedError {
    case solverFailed(message: String)
    case invalidFormula
    case missingVariables([String])
    case conversionFailed(from: String, to: String)
}
```

## Extensibility

The factory pattern makes it easy to add new solvers:

```swift
// Create a new solver type
class StatisticsSolver: MathSolver {
    override func solve(...) -> Result<Solution, SolverError> {
        // Implementation
    }
}

// Register with factory
let solver = MathSolver.create(for: .statistics)
```

## File Structure
```
math/
├── Models/
│   ├── MathDomain.swift
│   ├── Topic.swift
│   ├── Example.swift
│   ├── PhysicsFormula.swift
│   ├── PhysicsSolution.swift
│   └── SolverError.swift
├── Engine/
│   ├── MathSolver.swift
│   ├── Solvers/
│   │   ├── AlgebraSolver.swift
│   │   ├── CalculusWorkerSolver.swift
│   │   ├── AlgebraEquationSolver.swift
│   │   ├── EquationSolver.swift
│   │   └── PhysicsSolver.swift
│   └── Formulas/
│       └── FormulaCatalog.swift
├── DataProviders/
│   ├── CalculusTopicsProvider.swift
│   ├── AlgebraTopicsProvider.swift
│   ├── TrigonometryTopicsProvider.swift
│   └── PreCalculusTopicsProvider.swift
├── ContentView.swift
└── mathApp.swift

mathTests/
└── SolverTests.swift
```

## Integration with UI

### Displaying Solutions
```swift
@State var solution: PhysicsSolution?

Text(solution?.formattedOutput ?? "Loading...")
```

### Interactive Solver
```swift
TextField("Enter equation", text: $userInput)
Button("Solve") {
    solution = AlgebraSolver().solve(equation: userInput)
}
```

### Topic Navigation
```swift
List(AlgebraTopicsProvider.allTopics) { topic in
    NavigationLink(destination: TopicDetailView(topic: topic)) {
        Text(topic.title)
    }
}
```

## Performance Considerations

- **Factory caching**: Solvers are created on-demand (singleton pattern possible)
- **Formula lookup**: O(1) access via dictionary or O(n) via catalog search
- **Computation**: Complex calculations done on background thread in production
- **Memory**: Topic providers use static computed properties for efficient memory usage

## Future Enhancements

1. **Additional Solvers**
   - Statistics/Probability solver
   - Linear Algebra solver
   - Differential Equations solver

2. **Advanced Features**
   - Graphing calculator
   - Equation verification
   - Step-by-step animation
   - Multi-language support

3. **Data Persistence**
   - Save favorite formulas
   - Problem history
   - Custom notes

4. **AI Integration**
   - Hint system
   - Problem generation
   - Natural language processing

## Contributing

When adding new solvers:
1. Extend `MathSolver` base class
2. Implement required `solve()` method
3. Add corresponding error handling
4. Create comprehensive test suite
5. Update documentation

## License

This project is officially registered and copyrighted.  
Copyright © 2026 Telkom University. All rights reserved.  
Certificate Registration Number: 001247300  

Official Copyright Registration Certificate from Indonesia's Ministry of Law, Registration No. 001247300, valid for 50 years. MathSolver Pro is legally protected intellectual property under Indonesian Law No. 28/2014.

---
**Latest Update**: All core solvers, formula catalog, and topic providers implemented with comprehensive test coverage.
