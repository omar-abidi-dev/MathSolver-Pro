import SwiftUI

/// Equation Grapher — main screen.
struct GraphView: View {
    @StateObject private var vm = GraphViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 16) {
                        // Subtitle (Fix 2)
                        Text("Plot up to 2 equations and analyze key points")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16)
                            .padding(.top, 4)

                        // Input card or collapsed bar (Fix 8)
                        if vm.isInputCollapsed {
                            collapsedBar
                        } else {
                            inputCard
                        }

                        // Graph canvas with legend overlay
                        GeometryReader { geo in
                            ZStack {
                                GraphCanvasView(vm: vm)
                                GraphLegendView(vm: vm, canvasSize: geo.size)
                            }
                        }
                        .frame(height: vm.isInputCollapsed ? 420 : 300)
                        .padding(.horizontal, 16)

                        // Key points (Fix 6)
                        if vm.expr1 != nil || vm.expr2 != nil {
                            GraphKeyPointsView(vm: vm)
                                .padding(.horizontal, 16)
                        }
                    }
                    .padding(.bottom, 16)
                }

                // Custom math keyboard (Fix 3 & 7)
                if vm.activeField != nil {
                    MathKeyboardView(
                        text: Binding(
                            get: {
                                vm.activeField == 1 ? vm.equation1 : vm.equation2
                            },
                            set: {
                                if vm.activeField == 1 { vm.equation1 = $0 }
                                else { vm.equation2 = $0 }
                            }
                        ),
                        onDone: {
                            vm.activeField = nil
                            vm.graph()
                        }
                    )
                    .transition(.move(edge: .bottom))
                }
            }
            .animation(.easeInOut(duration: 0.25), value: vm.activeField)
            .navigationTitle("Equation Grapher")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Input card (expanded state)

    private var inputCard: some View {
        VStack(spacing: 12) {
            // Equation 1 (Fix 9-A: colored dot)
            equationField(index: 1,
                          label: "Equation 1",
                          color: .blue,
                          text: $vm.equation1,
                          placeholder: "e.g. 2x + 1")

            // Equation 2 (Fix 9-A: colored dot)
            equationField(index: 2,
                          label: "Equation 2 (optional)",
                          color: .red,
                          text: $vm.equation2,
                          placeholder: "e.g. x^2")

            // Error banner
            if let error = vm.errorMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundStyle(.red)
                    Text(error).font(.caption)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
                .background(Color.red.opacity(0.08),
                            in: RoundedRectangle(cornerRadius: 6, style: .continuous))
            }

            // Action buttons
            HStack(spacing: 12) {
                Button(action: vm.graph) {
                    HStack {
                        Image(systemName: "chart.xyaxis.line")
                        Text("Graph")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }

                Button(action: vm.animate) {
                    HStack {
                        Image(systemName: vm.isAnimating ? "hourglass" : "play.circle.fill")
                        Text(vm.isAnimating ? "Animating…" : "Animate")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(Color.green)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .disabled(vm.isAnimating)
                .opacity(vm.isAnimating ? 0.6 : 1)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground),
                     in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .padding(.horizontal, 16)
    }

    // MARK: - Equation field (Fix 3 — no Show Keyboard button; Fix 9-A — dot)

    private func equationField(index: Int, label: String,
                               color: Color, text: Binding<String>,
                               placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Circle().fill(color).frame(width: 8, height: 8)
                Text(label)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 8) {
                let value = text.wrappedValue
                Text(value.isEmpty ? placeholder : value)
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(value.isEmpty ? .tertiary : .primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .onTapGesture { vm.activeField = index }
            }
            .padding(12)
            .background(Color(.systemBackground),
                        in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(vm.activeField == index ? color : Color(.systemGray4),
                                  lineWidth: vm.activeField == index ? 2 : 0.5)
            )
        }
    }

    // MARK: - Collapsed bar (Fix 8)

    private var collapsedBar: some View {
        Button { vm.expandInput() } label: {
            HStack(spacing: 12) {
                Text(vm.equation1.isEmpty ? "—" : vm.equation1)
                    .font(.subheadline.monospaced())
                    .foregroundStyle(.blue)
                    .lineLimit(1)

                if !vm.equation2.isEmpty {
                    Text("|").foregroundStyle(.secondary)
                    Text(vm.equation2)
                        .font(.subheadline.monospaced())
                        .foregroundStyle(.red)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "pencil")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(14)
            .background(Color(.secondarySystemGroupedBackground),
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
    }
}

#Preview {
    GraphView()
}
