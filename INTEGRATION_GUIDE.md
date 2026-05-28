# Math App - UI Integration Guide

## Overview
This guide explains how to integrate the math solvers and educational content with SwiftUI views.

## ViewModel Architecture

### BaseSolverViewModel
```swift
class BaseSolverViewModel: ObservableObject {
    @Published var input: String = ""
    @Published var solution: PhysicsSolution?
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false
    
    func solve() {
        isLoading = true
        // Perform solving on background thread
        DispatchQueue.global().async {
            // Solving logic
            DispatchQueue.main.async {
                self.isLoading = false
            }
        }
    }
}
```

## Core Views

### 1. Algebra Solver View
```swift
struct AlgebraSolverView: View {
    @StateObject private var viewModel = AlgebraSolverViewModel()
    
    var body: some View {
        VStack {
            TextField("Enter equation", text: $viewModel.input)
                .textFieldStyle(.roundedBorder)
            
            Button("Solve") {
                viewModel.solve()
            }
            .disabled(viewModel.input.isEmpty)
            
            if let solution = viewModel.solution {
                SolutionDisplayView(solution: solution)
            }
            
            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
            }
        }
        .padding()
    }
}
```

### 2. Physics Solver View
```swift
struct PhysicsSolverView: View {
    @State private var selectedFormula: PhysicsFormula?
    @State private var knownVariables: [String: Double] = [:]
    @State private var unknownVariable: String = ""
    @State private var solution: PhysicsSolution?
    
    var body: some View {
        VStack {
            // Formula selector
            Picker("Select Formula", selection: $selectedFormula) {
                ForEach(PhysicsFormula.catalog, id: \.id) { formula in
                    Text(formula.name).tag(formula as PhysicsFormula?)
                }
            }
            
            // Variable inputs
            if let formula = selectedFormula {
                ForEach(formula.variables, id: \.symbol) { variable in
                    VariableInputField(
                        symbol: variable.symbol,
                        unit: variable.unit,
                        value: Binding(
                            get: { knownVariables[variable.symbol] ?? 0 },
                            set: { knownVariables[variable.symbol] = $0 }
                        )
                    )
                }
                
                // Unknown variable picker
                Picker("Solve for", selection: $unknownVariable) {
                    ForEach(formula.variables, id: \.symbol) { variable in
                        Text("\(variable.symbol) (\(variable.unit))").tag(variable.symbol)
                    }
                }
                
                // Solve button
                Button("Solve") {
                    let result = PhysicsSolver.solve(
                        formula: formula,
                        knownVariables: knownVariables,
                        unknownVariable: unknownVariable
                    )
                    
                    switch result {
                    case .success(let sol):
                        solution = sol
                    case .failure(let error):
                        // Handle error
                    }
                }
            }
            
            if let solution = solution {
                SolutionDisplayView(solution: solution)
            }
        }
        .padding()
    }
}

struct VariableInputField: View {
    let symbol: String
    let unit: String
    @Binding var value: Double
    
    var body: some View {
        HStack {
            Text("\(symbol):")
                .font(.headline)
            
            TextField("Value", value: $value, format: .number)
                .textFieldStyle(.roundedBorder)
            
            Text(unit)
                .foregroundColor(.gray)
        }
    }
}
```

### 3. Solution Display View
```swift
struct SolutionDisplayView: View {
    let solution: PhysicsSolution
    @State private var expandedSteps: Set<Int> = []
    
    var body: some View {
        VStack(alignment: .leading) {
            // Formula header
            VStack(alignment: .leading) {
                Text(solution.formula.name)
                    .font(.headline)
                Text(solution.formula.expression)
                    .font(.caption)
                    .monospaced()
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
            
            // Known variables
            VStack(alignment: .leading) {
                Text("Known Variables")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                ForEach(Array(solution.knownVariables), id: \.key) { symbol, data in
                    HStack {
                        Text(symbol)
                        Spacer()
                        Text("\(String(format: "%.2f", data.value)) \(data.unit)")
                            .monospaced()
                    }
                }
            }
            .padding()
            
            // Solution steps
            VStack(alignment: .leading) {
                Text("Solution Steps")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                ForEach(solution.steps, id: \.stepNumber) { step in
                    DisclosureGroup(
                        "Step \(step.stepNumber): \(step.description)",
                        isExpanded: Binding(
                            get: { expandedSteps.contains(step.stepNumber) },
                            set: { isExpanded in
                                if isExpanded {
                                    expandedSteps.insert(step.stepNumber)
                                } else {
                                    expandedSteps.remove(step.stepNumber)
                                }
                            }
                        )
                    ) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(step.explanation)
                                .font(.caption)
                            
                            Text(step.resultEquation)
                                .font(.caption)
                                .monospaced()
                                .padding(8)
                                .background(Color(.systemGray6))
                                .cornerRadius(4)
                        }
                    }
                }
            }
            .padding()
            
            // Final result
            VStack(alignment: .leading) {
                Text("Result")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                HStack {
                    Text("\(solution.unknownVariable) =")
                        .font(.headline)
                    
                    Text("\(String(format: "%.4f", solution.result)) \(solution.resultUnit)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(Color(.systemGreen).opacity(0.1))
            .cornerRadius(8)
        }
        .padding()
    }
}
```

### 4. Topics Browser View
```swift
struct TopicsBrowserView: View {
    let domain: MathDomain
    @State private var selectedTopic: Topic?
    
    var topics: [Topic] {
        switch domain {
        case .algebra:
            return AlgebraTopicsProvider.allTopics
        case .calculus:
            return CalculusTopicsProvider.allTopics
        case .trigonometry:
            return TrigonometryTopicsProvider.allTopics
        case .preCalculus:
            return PreCalculusTopicsProvider.allTopics
        default:
            return []
        }
    }
    
    var body: some View {
        NavigationView {
            List(topics, id: \.id) { topic in
                NavigationLink(destination: TopicDetailView(topic: topic)) {
                    VStack(alignment: .leading) {
                        Text(topic.title)
                            .font(.headline)
                        Text(topic.description)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle(domain.rawValue)
        }
    }
}

struct TopicDetailView: View {
    let topic: Topic
    @State private var expandedSections: Set<String> = []
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Title
                Text(topic.title)
                    .font(.title)
                    .fontWeight(.bold)
                
                // Description
                Text(topic.description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Divider()
                
                // Explanation
                DisclosureGroup(
                    "Explanation",
                    isExpanded: Binding(
                        get: { expandedSections.contains("explanation") },
                        set: { if $0 { expandedSections.insert("explanation") } else { expandedSections.remove("explanation") } }
                    )
                ) {
                    Text(topic.explanation)
                        .font(.body)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                
                // Examples
                DisclosureGroup(
                    "Examples (\(topic.examples.count))",
                    isExpanded: Binding(
                        get: { expandedSections.contains("examples") },
                        set: { if $0 { expandedSections.insert("examples") } else { expandedSections.remove("examples") } }
                    )
                ) {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(topic.examples, id: \.title) { example in
                            ExampleCardView(example: example)
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle(topic.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ExampleCardView: View {
    let example: Example
    @State private var showSolution = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(example.title)
                .font(.subheadline)
                .fontWeight(.bold)
            
            Text(example.description)
                .font(.caption)
                .monospaced()
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(4)
            
            Button(action: { showSolution.toggle() }) {
                HStack {
                    Image(systemName: showSolution ? "chevron.up" : "chevron.down")
                    Text("Show Solution")
                }
                .font(.caption)
            }
            
            if showSolution {
                Text(example.solution)
                    .font(.caption)
                    .padding(8)
                    .background(Color(.systemGreen).opacity(0.1))
                    .cornerRadius(4)
            }
        }
        .padding()
        .border(Color.gray.opacity(0.3), width: 1)
        .cornerRadius(8)
    }
}
```

### 5. Unit Converter View
```swift
struct UnitConverterView: View {
    @State private var inputValue: Double = 1
    @State private var selectedFromUnit: String = "m"
    @State private var selectedToUnit: String = "km"
    @State private var convertedValue: Double?
    
    let unitPairs = [
        ("km", "m"),
        ("m", "km"),
        ("km/h", "m/s"),
        ("m/s", "km/h"),
        ("g", "kg"),
        ("kg", "g"),
        ("cm", "m"),
        ("m", "cm")
    ]
    
    var body: some View {
        VStack {
            HStack {
                VStack {
                    TextField("Value", value: $inputValue, format: .number)
                        .textFieldStyle(.roundedBorder)
                    
                    Picker("From", selection: $selectedFromUnit) {
                        ForEach(unitPairs.map { $0.0 }, id: \.self) { unit in
                            Text(unit).tag(unit)
                        }
                    }
                }
                
                VStack {
                    if let converted = convertedValue {
                        Text(String(format: "%.4f", converted))
                            .font(.headline)
                            .padding()
                    } else {
                        Text("—")
                    }
                    
                    Picker("To", selection: $selectedToUnit) {
                        ForEach(unitPairs.map { $0.1 }, id: \.self) { unit in
                            Text(unit).tag(unit)
                        }
                    }
                }
            }
            
            Button("Convert") {
                convertedValue = PhysicsSolver.convertUnit(
                    value: inputValue,
                    from: selectedFromUnit,
                    to: selectedToUnit
                )
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
```

## ContentView Integration

```swift
struct ContentView: View {
    @State private var selectedTab: Int = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }
                .tag(0)
            
            // Solvers
            SolversTabView()
                .tabItem {
                    Label("Solvers", systemImage: "function")
                }
                .tag(1)
            
            // Topics
            TopicsTabView()
                .tabItem {
                    Label("Topics", systemImage: "book")
                }
                .tag(2)
            
            // Converter
            UnitConverterView()
                .tabItem {
                    Label("Convert", systemImage: "arrow.left.arrow.right")
                }
                .tag(3)
        }
    }
}

struct SolversTabView: View {
    @State private var selectedSolver: Int = 0
    
    var body: some View {
        TabView(selection: $selectedSolver) {
            AlgebraSolverView()
                .tag(0)
            
            PhysicsSolverView()
                .tag(1)
            
            CalculusSolverView()
                .tag(2)
        }
        .tabViewStyle(.page)
    }
}

struct TopicsTabView: View {
    var body: some View {
        NavigationView {
            List {
                NavigationLink("Algebra", destination: TopicsBrowserView(domain: .algebra))
                NavigationLink("Calculus", destination: TopicsBrowserView(domain: .calculus))
                NavigationLink("Trigonometry", destination: TopicsBrowserView(domain: .trigonometry))
                NavigationLink("Pre-Calculus", destination: TopicsBrowserView(domain: .preCalculus))
            }
            .navigationTitle("Topics")
        }
    }
}
```

## State Management Best Practices

1. **Use @StateObject for ObservableObject**: Ensures proper lifecycle
2. **Background threads for solving**: Use DispatchQueue.global() for heavy computation
3. **Combine with async/await**: Modern approach for future updates
4. **Error handling**: Always provide user-friendly error messages

## Performance Optimization

1. **Lazy loading**: Use LazyVStack for long lists
2. **Memoization**: Cache formula lookups
3. **Debouncing**: Delay solving until user finishes typing
4. **Accessibility**: Add VoiceOver support for blind users

## Testing Views

```swift
#Preview {
    AlgebraSolverView()
}

#Preview {
    PhysicsSolverView()
}

#Preview {
    TopicDetailView(topic: AlgebraTopicsProvider.topic(withId: "algebra_polynomials")!)
}
```

---

This integration guide provides a complete foundation for connecting the math solvers to the SwiftUI interface.
