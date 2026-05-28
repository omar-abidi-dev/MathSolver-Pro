import SwiftUI

/// Physics formula catalog browser
struct FormulaCatalogView: View {
    @Binding var selection: String?
    @Binding var selectedDomain: PhysicsDomain
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(PhysicsDomain.allCases, id: \.self) { domain in
                    Section(header: Text(domain.rawValue)) {
                        ForEach(PhysicsFormula.catalog.filter { $0.domain == domain }, id: \.id) { formula in
                            NavigationLink(destination: FormulaDetailView(formula: formula, selection: $selection, selectedDomain: $selectedDomain)) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(formula.name)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    
                                    Text(formula.expression)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                        .lineLimit(1)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Formula Catalog")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Formula Detail View

struct FormulaDetailView: View {
    let formula: PhysicsFormula
    @Binding var selection: String?
    @Binding var selectedDomain: PhysicsDomain
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Formula Display
                VStack(alignment: .leading, spacing: 8) {
                    Text("Formula")
                        .font(.headline)
                    
                    Text(formula.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text(formula.expression)
                        .font(.system(.body, design: .monospaced))
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                // Variables Display
                VStack(alignment: .leading, spacing: 12) {
                    Text("Variables")
                        .font(.headline)
                    
                    VStack(spacing: 8) {
                        ForEach(formula.variables, id: \.symbol) { variable in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(variable.symbol)
                                        .font(.system(.body, design: .monospaced))
                                        .fontWeight(.bold)
                                    
                                    Text("—")
                                        .foregroundColor(.gray)
                                    
                                    Text(variable.name)
                                        .fontWeight(.semibold)
                                    
                                    Spacer()
                                    
                                    Text(variable.unit)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                
                                Text(variable.description)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(6)
                        }
                    }
                }
                
                // Solve Button
                Button(action: selectFormula) {
                    HStack {
                        Image(systemName: "bolt.fill")
                        Text("Solve with this formula")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                
                Spacer()
            }
            .padding(16)
        }
        .navigationTitle("Formula Details")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func selectFormula() {
        selection = formula.id
        selectedDomain = formula.domain
        dismiss()
    }
}

#Preview {
    FormulaCatalogView(
        selection: .constant(nil),
        selectedDomain: .constant(.kinematics)
    )
}
