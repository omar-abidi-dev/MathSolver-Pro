import SwiftUI

/// Custom numeric keyboard for physics value input
/// Supports digits, decimal point, scientific notation, and sign toggle
struct PhysicsNumKeyboard: View {
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
                    PhysicsKeyboardButton(
                        label: String(num),
                        action: { appendDigit(String(num)) }
                    )
                }
                
                PhysicsKeyboardButton(
                    label: "⌫",
                    isAction: true,
                    action: { _ = text.popLast() }
                )
            }
            
            // Row 2: 4, 5, 6, e
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(4...6, id: \.self) { num in
                    PhysicsKeyboardButton(
                        label: String(num),
                        action: { appendDigit(String(num)) }
                    )
                }
                
                PhysicsKeyboardButton(
                    label: "e",
                    isSpecial: true,
                    action: { appendScientificNotation() }
                )
            }
            
            // Row 3: 7, 8, 9, −
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(7...9, id: \.self) { num in
                    PhysicsKeyboardButton(
                        label: String(num),
                        action: { appendDigit(String(num)) }
                    )
                }
                
                PhysicsKeyboardButton(
                    label: "−",
                    isSpecial: true,
                    action: { text.append("-") }
                )
            }
            
            // Row 4: ., 0, ±, Done
            LazyVGrid(columns: columns, spacing: 8) {
                PhysicsKeyboardButton(
                    label: ".",
                    action: { appendDecimal() }
                )
                
                PhysicsKeyboardButton(
                    label: "0",
                    action: { appendDigit("0") }
                )
                
                PhysicsKeyboardButton(
                    label: "±",
                    isSpecial: true,
                    action: { toggleSign() }
                )
                
                PhysicsKeyboardButton(
                    label: "Done",
                    isAction: true,
                    action: { onDone() }
                )
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
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

// MARK: - PhysicsKeyboardButton Component

private struct PhysicsKeyboardButton: View {
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
            return Color.orange.opacity(0.8)
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
    VStack {
        TextField("Value", text: .constant(""))
            .font(.system(.title2, design: .monospaced))
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
            .padding()
        
        PhysicsNumKeyboard(text: .constant(""), onDone: {})
            .padding()
        
        Spacer()
    }
    .background(Color(.systemBackground))
}
