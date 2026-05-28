import SwiftUI

/// Collapsible Key Points analysis card (Fix 6).
/// Shows y-intercept, x-intercepts, vertex, and intersections for each equation.
struct GraphKeyPointsView: View {
    @ObservedObject var vm: GraphViewModel
    @State private var isExpanded = false

    private let eq1Color = Color.blue
    private let eq2Color = Color.red

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header — tap to expand/collapse
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundStyle(.blue)
                    Text("Key Points")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(14)
            }
            .buttonStyle(.plain)

            if isExpanded {
                Divider().padding(.horizontal, 14)

                HStack(alignment: .top, spacing: 16) {
                    // Equation 1 column
                    if vm.expr1 != nil {
                        column(title: vm.equation1.isEmpty ? "Equation 1" : vm.equation1,
                               color: eq1Color,
                               kp: vm.keyPoints1,
                               showIntersections: false)
                    }

                    // Equation 2 column
                    if vm.expr2 != nil {
                        column(title: vm.equation2.isEmpty ? "Equation 2" : vm.equation2,
                               color: eq2Color,
                               kp: vm.keyPoints2,
                               showIntersections: false)
                    }
                }
                .padding(14)

                // Intersections row (shown once)
                if !vm.intersections.isEmpty {
                    Divider().padding(.horizontal, 14)
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(Array(vm.intersections.enumerated()), id: \.offset) { _, pt in
                            row(dot: .green, label: "Intersection",
                                value: "(\(fmt(pt.x)), \(fmt(pt.y)))")
                        }
                    }
                    .padding(14)
                }
            }
        }
        .background(Color(.secondarySystemGroupedBackground),
                     in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color(.systemGray4), lineWidth: 0.5)
        )
    }

    // MARK: - Column

    @ViewBuilder
    private func column(title: String, color: Color,
                        kp: GraphKeyPoints, showIntersections: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Circle().fill(color).frame(width: 8, height: 8)
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(color)
                    .lineLimit(1)
            }

            if let p = kp.yIntercept {
                row(dot: color, label: "y-intercept",
                    value: "(0, \(fmt(p.y)))")
            }

            if kp.xIntercepts.isEmpty {
                row(dot: color, label: "x-intercept", value: "No real roots")
            } else {
                ForEach(Array(kp.xIntercepts.enumerated()), id: \.offset) { _, pt in
                    row(dot: color, label: "x-intercept",
                        value: "(\(fmt(pt.x)), 0)")
                }
            }

            if let v = kp.vertex {
                row(dot: color, label: "Vertex",
                    value: "(\(fmt(v.x)), \(fmt(v.y)))")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Row

    private func row(dot: Color, label: String, value: String) -> some View {
        HStack(spacing: 6) {
            Circle().fill(dot).frame(width: 6, height: 6)
            Text(label + ":")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption.weight(.medium).monospaced())
                .foregroundStyle(.primary)
                .accessibilityLabel("\(label) \(value)")
        }
    }

    private func fmt(_ v: CGFloat) -> String {
        let d = Double(v)
        if abs(d) < 1e-10 { return "0.00" }
        return String(format: "%.2f", d)
    }
}

#Preview {
    let vm = GraphViewModel()
    GraphKeyPointsView(vm: vm)
        .padding()
}
