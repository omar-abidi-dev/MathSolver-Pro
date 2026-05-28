import SwiftUI

/// Custom mathematical keyboard for calculus expression input
struct TextFieldKeyboard: View {
    @Binding var focusedField: CalculusFieldType?
    @Binding var expression: String
    @Binding var variable: String
    @Binding var approachValue: String
    @Binding var lowerBound: String
    @Binding var upperBound: String
    
    let selectedMode: CalculusMode
    let isDefinite: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Function buttons (Row 1)
            HStack(spacing: 8) {
                CalculusKeyButton("sin", action: { insertText("sin(") })
                CalculusKeyButton("cos", action: { insertText("cos(") })
                CalculusKeyButton("tan", action: { insertText("tan(") })
                CalculusKeyButton("log", action: { insertText("log(") })
                CalculusKeyButton("√", action: { insertText("sqrt(") })
            }
            .padding(8)
            
            // Operators (Row 2)
            HStack(spacing: 8) {
                CalculusKeyButton("+", action: { insertText("+") })
                CalculusKeyButton("-", action: { insertText("-") })
                CalculusKeyButton("×", action: { insertText("*") })
                CalculusKeyButton("÷", action: { insertText("/") })
                CalculusKeyButton("^", action: { insertText("^") })
            }
            .padding(8)
            
            // Math symbols (Row 3)
            HStack(spacing: 8) {
                CalculusKeyButton("π", action: { insertText("π") })
                CalculusKeyButton("e", action: { insertText("e") })
                CalculusKeyButton("(", action: { insertText("(") })
                CalculusKeyButton(")", action: { insertText(")") })
                CalculusKeyButton(".", action: { insertText(".") })
            }
            .padding(8)
            
            // Navigation buttons (Row 4)
            HStack(spacing: 8) {
                Button(action: { focusedField = nil }) {
                    Image(systemName: "keyboard.chevron.compact.down")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.gray.opacity(0.3))
                        .foregroundColor(.primary)
                        .cornerRadius(6)
                }
                
                Button(action: { deleteLastCharacter() }) {
                    Image(systemName: "delete.left")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.red.opacity(0.2))
                        .foregroundColor(.red)
                        .cornerRadius(6)
                }
            }
            .padding(8)
        }
        .background(Color(.systemGray6))
    }
    
    private func insertText(_ text: String) {
        guard let focused = focusedField else { return }
        
        switch focused {
        case .expression:
            expression.append(text)
        case .variable:
            variable.append(text)
        case .approachValue:
            approachValue.append(text)
        case .lowerBound:
            lowerBound.append(text)
        case .upperBound:
            upperBound.append(text)
        }
    }
    
    private func deleteLastCharacter() {
        guard let focused = focusedField else { return }
        
        switch focused {
        case .expression:
            if !expression.isEmpty { expression.removeLast() }
        case .variable:
            if !variable.isEmpty { variable.removeLast() }
        case .approachValue:
            if !approachValue.isEmpty { approachValue.removeLast() }
        case .lowerBound:
            if !lowerBound.isEmpty { lowerBound.removeLast() }
        case .upperBound:
            if !upperBound.isEmpty { upperBound.removeLast() }
        }
    }
}

/// Individual keyboard button
struct CalculusKeyButton: View {
    let text: String
    let action: () -> Void
    
    init(_ text: String, action: @escaping () -> Void) {
        self.text = text
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.system(size: 14, weight: .semibold))
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Color.indigo.opacity(0.2))
                .foregroundColor(.indigo)
                .cornerRadius(6)
        }
    }
}

#Preview {
    TextFieldKeyboard(
        focusedField: .constant(.expression),
        expression: .constant(""),
        variable: .constant("x"),
        approachValue: .constant(""),
        lowerBound: .constant(""),
        upperBound: .constant(""),
        selectedMode: .derivatives,
        isDefinite: false
    )
    .padding()
}
