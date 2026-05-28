import SwiftUI

/// Bottom-sheet listing formulas for the selected domain.
/// Shows name, expression, and checkmark on the current selection.
struct PhysicsFormulaPickerView: View {
    @ObservedObject var vm: PhysicsViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(vm.domainFormulas) { formula in
                Button {
                    vm.selectFormula(formula.id)
                    dismiss()
                } label: {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(formula.name)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)
                            Text(formula.expression)
                                .font(.footnote.monospaced())
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if formula.id == vm.selectedFormulaID {
                            Image(systemName: "checkmark")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.blue)
                        }
                    }
                    .padding(.vertical, 4)
                    .contentShape(Rectangle())
                }
            }
            .navigationTitle("\(vm.selectedDomain.rawValue) Formulas")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

#Preview {
    PhysicsFormulaPickerView(vm: PhysicsViewModel())
}
