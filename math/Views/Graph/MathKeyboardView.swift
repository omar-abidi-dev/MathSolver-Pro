import SwiftUI

/// Custom math keyboard for equation input (Fix 7).
/// 4 rows × 6 columns, anchored to the bottom of the screen.
struct MathKeyboardView: View {
    @Binding var text: String
    var onDone: () -> Void

    private let rows: [[MathKey]] = [
        [.digit("7"), .digit("8"), .digit("9"), .op("÷", "/"),  .paren("("), .paren(")")],
        [.digit("4"), .digit("5"), .digit("6"), .op("×", "*"),  .variable("x"), .variable("y")],
        [.digit("1"), .digit("2"), .digit("3"), .op("−", "-"),  .special("x²", "x^2"), .special("√", "sqrt(")],
        [.digit("0"), .digit("."), .op("+", "+"), .op("=", "="), .delete, .enter],
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar: Clear / Done  (Fix 3)
            HStack {
                Button("Clear") { text = "" }
                    .font(.subheadline.weight(.medium))
                Spacer()
                Button("Done") { onDone() }
                    .font(.subheadline.weight(.medium))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(.secondarySystemGroupedBackground))

            Divider()

            // Key grid
            VStack(spacing: 6) {
                ForEach(0..<rows.count, id: \.self) { r in
                    HStack(spacing: 6) {
                        ForEach(rows[r]) { key in
                            keyButton(key)
                        }
                    }
                }
            }
            .padding(8)
            .background(Color(.systemGray6))
        }
        .frame(height: 280)
    }

    // MARK: - Key button

    @ViewBuilder
    private func keyButton(_ key: MathKey) -> some View {
        Button {
            handle(key)
        } label: {
            Text(key.label)
                .font(.system(.body, design: .monospaced).weight(.semibold))
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(key.background)
                .foregroundStyle(key.foreground)
                .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .strokeBorder(Color(.systemGray4), lineWidth: key.hasBorder ? 0.5 : 0)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(key.accessibilityLabel)
    }

    private func handle(_ key: MathKey) {
        switch key {
        case .digit(let d):   text.append(d)
        case .op(_, let raw): text.append(raw)
        case .paren(let p):   text.append(p)
        case .variable(let v): text.append(v)
        case .special(_, let raw): text.append(raw)
        case .delete:         _ = text.popLast()
        case .enter:          onDone()
        }
    }
}

// MARK: - Key model

enum MathKey: Identifiable {
    case digit(String)
    case op(String, String)      // display, inserted
    case paren(String)
    case variable(String)
    case special(String, String) // display, inserted
    case delete
    case enter

    var id: String { label }

    var label: String {
        switch self {
        case .digit(let d): return d
        case .op(let disp, _): return disp
        case .paren(let p): return p
        case .variable(let v): return v
        case .special(let disp, _): return disp
        case .delete: return "⌫"
        case .enter: return "↵"
        }
    }

    var accessibilityLabel: String {
        switch self {
        case .digit(let d): return d
        case .op(let disp, _): return disp
        case .paren(let p): return p == "(" ? "Left parenthesis" : "Right parenthesis"
        case .variable(let v): return "Variable \(v)"
        case .special(let disp, _): return disp == "x²" ? "x squared" : "Square root"
        case .delete: return "Delete"
        case .enter: return "Done"
        }
    }

    var background: Color {
        switch self {
        case .digit, .paren:     return Color(.systemBackground)
        case .op:                return Color(.systemGray5)
        case .variable, .special: return Color.blue.opacity(0.15)
        case .delete:            return Color(.systemGray5)
        case .enter:             return Color(.systemGray5)
        }
    }

    var foreground: Color {
        switch self {
        case .variable, .special: return .blue
        default: return .primary
        }
    }

    var hasBorder: Bool {
        switch self {
        case .digit, .paren: return true
        default: return false
        }
    }
}

#Preview {
    VStack {
        Spacer()
        MathKeyboardView(text: .constant("2x+1"), onDone: {})
    }
}
