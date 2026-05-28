import SwiftUI

/// Physics solver input screen.
struct PhysicsSolverView: View {
    @StateObject private var vm = PhysicsViewModel()
    @State private var activeField: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 16) {
                        domainPicker
                        formulaRow
                        formulaPreview
                        unknownPicker
                        knownValuesSection
                        errorBanner
                        solveButton
                    }
                    .padding(16)
                }

                if activeField != nil {
                    keyboardBar
                }
            }
            .navigationTitle("Physics Solver")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $vm.showFormulaPicker) {
                PhysicsFormulaPickerView(vm: vm)
            }
            .navigationDestination(isPresented: $vm.showSolution) {
                if let result = vm.solveResult {
                    PhysicsSolutionView(result: result)
                }
            }
        }
    }

    // MARK: - Domain picker

    private var domainPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Domain")
                .font(.headline)

            Picker("Domain", selection: Binding(
                get: { vm.selectedDomain },
                set: { vm.selectDomain($0) }
            )) {
                ForEach(PhysicsDomain.allCases, id: \.self) { d in
                    Text(d.rawValue).tag(d)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    // MARK: - Formula picker row (Fix 1)

    private var formulaRow: some View {
        Button { vm.showFormulaPicker = true } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Formula")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(vm.selectedFormula?.name ?? "Select…")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                }
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(14)
            .background(Color(.secondarySystemGroupedBackground),
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color.blue.opacity(0.2), lineWidth: 1)
            )
        }
    }

    // MARK: - Formula preview card (Fix 2)

    @ViewBuilder
    private var formulaPreview: some View {
        if let formula = vm.selectedFormula {
            VStack(spacing: 6) {
                Text(formula.name)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(formula.expression)
                    .font(.title3.monospaced().weight(.semibold))
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(Color.blue.opacity(0.06),
                        in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    // MARK: - Unknown variable picker

    @ViewBuilder
    private var unknownPicker: some View {
        if let formula = vm.selectedFormula {
            VStack(alignment: .leading, spacing: 8) {
                Text("Solve for")
                    .font(.headline)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(formula.variables) { v in
                            Button {
                                vm.selectUnknown(v.symbol)
                            } label: {
                                Text("\(v.name) (\(v.symbol))")
                                    .font(.subheadline.weight(.medium))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(
                                        vm.selectedUnknown == v.symbol
                                            ? Color.blue
                                            : Color(.tertiarySystemGroupedBackground)
                                    )
                                    .foregroundStyle(
                                        vm.selectedUnknown == v.symbol ? .white : .primary
                                    )
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Known values

    @ViewBuilder
    private var knownValuesSection: some View {
        if !vm.inputVariables.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Known Values")
                    .font(.headline)

                ForEach(vm.inputVariables) { variable in
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(variable.name) (\(variable.symbol))")
                            .font(.subheadline.weight(.medium))

                        HStack(spacing: 8) {
                            let value = vm.fieldValues[variable.symbol] ?? ""
                            Text(value.isEmpty ? "Value" : value)
                                .font(.body.monospaced())
                                .foregroundStyle(value.isEmpty ? .tertiary : .primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                                .onTapGesture { activeField = variable.symbol }

                            if !variable.unit.isEmpty {
                                Text(variable.unit)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(12)
                        .background(Color(.secondarySystemGroupedBackground),
                                    in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .strokeBorder(activeField == variable.symbol ? Color.blue : Color.clear, lineWidth: 2)
                        )

                        Text(variable.description)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        }
    }

    // MARK: - Error banner

    @ViewBuilder
    private var errorBanner: some View {
        if let error = vm.errorMessage {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                Text(error)
                    .font(.subheadline)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(Color.red.opacity(0.08),
                        in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }

    // MARK: - Solve button

    private var solveButton: some View {
        Button(action: vm.solve) {
            HStack(spacing: 8) {
                Image(systemName: "bolt.fill")
                Text("Solve")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(Color.blue)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .disabled(vm.selectedFormula == nil || vm.selectedUnknown == nil)
        .opacity(vm.selectedFormula == nil ? 0.5 : 1)
    }

    // MARK: - Custom keyboard bar

    private var keyboardBar: some View {
        VStack(spacing: 0) {
            Divider()

            HStack(spacing: 12) {
                Button("Next") { advanceFocus() }
                    .font(.subheadline.weight(.medium))
                Spacer()
                if let sym = activeField,
                   let v = vm.inputVariables.first(where: { $0.symbol == sym }) {
                    Text("\(v.name) (\(v.symbol))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Done") { activeField = nil }
                    .font(.subheadline.weight(.medium))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(.secondarySystemGroupedBackground))

            PhysicsNumKeyboard(
                text: Binding(
                    get: { vm.fieldValues[activeField ?? ""] ?? "" },
                    set: { vm.fieldValues[activeField ?? ""] = $0 }
                ),
                onDone: { activeField = nil }
            )
        }
        .transition(.move(edge: .bottom))
        .animation(.easeInOut(duration: 0.25), value: activeField)
    }

    // MARK: - Focus helpers

    private func advanceFocus() {
        let vars = vm.inputVariables
        guard let current = activeField,
              let idx = vars.firstIndex(where: { $0.symbol == current }) else { return }
        let next = vars.index(after: idx)
        if next < vars.endIndex {
            activeField = vars[next].symbol
        } else {
            activeField = nil
        }
    }
}

#Preview {
    PhysicsSolverView()
}
