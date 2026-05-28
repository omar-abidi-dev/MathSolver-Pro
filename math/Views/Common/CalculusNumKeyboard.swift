import SwiftUI

/// Custom numeric keyboard for calculus value input
/// Supports digits, decimal point, scientific notation, and sign toggle
/// Used for approach values, bounds, and other numeric fields in Calculus solver
struct CalculusNumKeyboard: View {
    @Binding var text: String
    var onDone: () -> Void
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]
    
    var body: some View {
        VStack(spacing: 8) {
            // Row 1: 1, 2, 3, ⌫
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(1...3, id: \.self) { num in
                    CalculusKeyboardButton(
                        label: String(num),
                        action: { appendDigit(String(num)) }
                    )
                }
                
                CalculusKeyboardButton(
                    label: "⌫",
                    isAction: true,
                    action: { _ = text.popLast() }
                )
            }
            
            // Row 2: 4, 5, 6, e
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(4...6, id: \.self) { num in
                    CalculusKeyboardButton(
                        label: String(num),
                        action: { appendDigit(String(num)) }
                    )
                }
                
                CalculusKeyboardButton(
                    label: "e",
                    isSpecial: true,
                    action: { appendScientificNotation() }
                )
            }
            
            // Row 3: 7, 8, 9, −
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(7...9, id: \.self) { num in
                    CalculusKeyboardButton(
                        label: String(num),
                        action: { appendDigit(String(num)) }
                    )
                }
                
                CalculusKeyboardButton(
                    label: "−",
                    isSpecial: true,
                    action: { text.append("-") }
                )
            }
            
            // Row 4: ., 0, ±, Done
            LazyVGrid(columns: columns, spacing: 8) {
                CalculusKeyboardButton(
                    label: ".",
                    action: { appendDecimal() }
                )
                
                CalculusKeyboardButton(
                    label: "0",
                    action: { appendDigit("0") }
                )
                
                CalculusKeyboardButton(
                    label: "±",
                    isSpecial: true,
                    action: { toggleSign() }
                )
                
                CalculusKeyboardButton(
                    label: "Done",
                    isAction: true,
                    action: { onDone() }
                )
            }
        }
        .padding(12)
        .background(Color(.systemGray5))
        .cornerRadius(12)
    }
    
    private func appendDigit(_ digit: String) {
        text.append(digit)
    }
    
    private func appendDecimal() {
        // Prevent double decimal in current number token
        let tokens = text.split(separator: "e", omittingEmptySubsequences: false).map(String.init)
        let currentToken = tokens.last ?? ""
        
        if !currentToken.contains(".") {
            text.append(".")
        }
    }
    
    private func appendScientificNotation() {
        // Prevent double 'e' in number
        if !text.contains("e") {
            text.append("e")
        }
    }
    
    private func toggleSign() {
        if text.isEmpty {
            text = "-"
        } else if text.first == "-" {
            text.removeFirst()
        } else {
            text = "-" + text
        }
    }
}

// MARK: - CalculusKeyboardButton Component

private struct CalculusKeyboardButton: View {
    let label: String
    var isSpecial: Bool = false
    var isAction: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(.body, design: .monospaced))
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(buttonBackground)
                .foregroundColor(buttonForeground)
                .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var buttonBackground: Color {
        if isAction {
            return Color.blue.opacity(0.8)
        } else if isSpecial {
            return Color.gray.opacity(0.6)
        } else {
            return Color.white
        }
    }
    
    private var buttonForeground: Color {
        if isAction || isSpecial {
            return Color.white
        } else {
            return Color.black
        }
    }
}

#Preview {
    CalculusNumKeyboard(text: .constant("3.14"), onDone: {})
        .padding()
}
