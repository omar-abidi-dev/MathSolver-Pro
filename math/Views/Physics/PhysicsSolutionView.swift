import SwiftUI

/// Physics solution screen — result card + formula + known values + expandable steps.
struct PhysicsSolutionView: View {
    let result: PhysSolveResult
    @State private var expandedSteps: Set<Int> = [4, 5]   // Steps 4 & 5 expanded by default
    @State private var resultScale: CGFloat = 0.9

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                resultCard
                formulaCard
                knownValuesCard
                stepsSection
            }
            .padding(16)
        }
        .navigationTitle("Solution")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                resultScale = 1.0
            }
        }
    }

    // MARK: - Result card (Fix 6)

    private var resultCard: some View {
        VStack(spacing: 6) {
            Text("Result")
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.8))
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("\(PhysicsEngine.fmt(result.result)) \(result.resultUnit)")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            Text("\(result.unknownName) (\(result.unknownSymbol))")
                .font(.system(size: 15))
                .foregroundStyle(.white.opacity(0.85))
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(
            LinearGradient(colors: [Color.blue, Color.blue.opacity(0.8)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .scaleEffect(resultScale)
    }

    // MARK: - Formula card

    private var formulaCard: some View {
        VStack(spacing: 8) {
            Text("Formula")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(result.formula.name)
                .font(.subheadline.weight(.semibold))
            Text(result.formula.expression)
                .font(.body.monospaced())
                .padding(8)
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .padding(16)
        .background(Color.blue.opacity(0.05),
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // MARK: - Known values card (Fix 5)

    private var knownValuesCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Known Values")
                .font(.headline)

            ForEach(result.knownValues, id: \.symbol) { entry in
                HStack(spacing: 4) {
                    Text(entry.symbol)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                    Text("=")
                        .foregroundStyle(.primary)
                    Text(PhysicsEngine.fmt(entry.value))
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                    Text(entry.unit)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)     // NOT tertiary
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.green.opacity(0.05),
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // MARK: - Solution steps (Fix 4)

    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Solution Steps")
                .font(.headline)

            ForEach(result.steps) { step in
                stepCard(step)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.purple.opacity(0.05),
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func stepCard(_ step: PhysSolveStep) -> some View {
        let isExpanded = expandedSteps.contains(step.number)

        return VStack(spacing: 0) {
            // Header
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    if isExpanded {
                        expandedSteps.remove(step.number)
                    } else {
                        expandedSteps.insert(step.number)
                    }
                }
            } label: {
                HStack(spacing: 10) {
                    Text("\(step.number)")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 28, height: 28)
                        .background(Color.blue)
                        .clipShape(Circle())

                    Text(step.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(12)
                .contentShape(Rectangle())
            }

            // Body
            if isExpanded {
                VStack(alignment: .leading, spacing: 6) {
                    Divider()
                    ForEach(step.lines, id: \.self) { line in
                        Text(line)
                            .font(.subheadline.monospaced())
                            .foregroundStyle(.primary)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Color(.systemGray5), lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview {
    let sampleFormula = PhysicsFormula.catalog.first!
    let sampleResult = PhysSolveResult(
        formula: sampleFormula,
        knownValues: [
            (symbol: "u", name: "Initial Velocity", value: 6.0, unit: "m/s"),
            (symbol: "a", name: "Acceleration", value: 6.0, unit: "m/s²"),
            (symbol: "t", name: "Time", value: 8.0, unit: "s"),
        ],
        unknownSymbol: "v",
        unknownName: "Final Velocity",
        result: 54.0,
        resultUnit: "m/s",
        steps: [
            PhysSolveStep(number: 1, title: "Identify the Formula",
                         lines: ["Final Velocity: v = u + at"], expandedByDefault: false),
            PhysSolveStep(number: 2, title: "List Known Values",
                         lines: ["u = 6.00 m/s", "a = 6.00 m/s²", "t = 8.00 s"], expandedByDefault: false),
            PhysSolveStep(number: 3, title: "Rearrange for v",
                         lines: ["Formula is already solved for v"], expandedByDefault: false),
            PhysSolveStep(number: 4, title: "Substitute Values",
                         lines: ["v = 6.00 + (6.00 × 8.00)", "v = 6.00 + 48.00", "v = 54.00"],
                         expandedByDefault: true),
            PhysSolveStep(number: 5, title: "Calculate Result",
                         lines: ["v = 54.00 m/s"], expandedByDefault: true),
        ]
    )

    NavigationStack {
        PhysicsSolutionView(result: sampleResult)
    }
}

