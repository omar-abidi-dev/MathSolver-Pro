import SwiftUI

/// Custom keyboard view for mathematical equation entry
/// Provides number keys, variable keys, operators, and special functions
struct MathKeyboard: View {
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
            // Row 1: Numbers 1-4 + backspace
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(1...3, id: \.self) { num in
                    KeyboardButton(
                        label: String(num),
                        action: { appendToText(String(num)) }
                    )
                }
                
                KeyboardButton(
                    label: "⌫",
                    isSpecial: true,
                    action: { _ = text.popLast() }
                )
            }
            
            // Row 2: Numbers 5-8 + equals
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(4...6, id: \.self) { num in
                    KeyboardButton(
                        label: String(num),
                        action: { appendToText(String(num)) }
                    )
                }
                
                KeyboardButton(
                    label: "=",
                    isOperator: true,
                    action: { appendToText(" = ") }
                )
            }
            
            // Row 3: Numbers 9-0 + decimal
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(7...9, id: \.self) { num in
                    KeyboardButton(
                        label: String(num),
                        action: { appendToText(String(num)) }
                    )
                }
                
                KeyboardButton(
                    label: ".",
                    action: { appendToText(".") }
                )
            }
            
            // Row 4: Operators
            LazyVGrid(columns: columns, spacing: 8) {
                KeyboardButton(
                    label: "+",
                    isOperator: true,
                    action: { appendToText(" + ") }
                )
                
                KeyboardButton(
                    label: "-",
                    isOperator: true,
                    action: { appendToText(" - ") }
                )
                
                KeyboardButton(
                    label: "×",
                    isOperator: true,
                    action: { appendToText(" × ") }
                )
                
                KeyboardButton(
                    label: "÷",
                    isOperator: true,
                    action: { appendToText(" ÷ ") }
                )
            }
            
            // Row 5: Variables and power
            LazyVGrid(columns: columns, spacing: 8) {
                KeyboardButton(
                    label: "x",
                    isVariable: true,
                    action: { appendToText("x") }
                )
                
                KeyboardButton(
                    label: "y",
                    isVariable: true,
                    action: { appendToText("y") }
                )
                
                KeyboardButton(
                    label: "^",
                    isOperator: true,
                    action: { appendToText("^") }
                )
                
                KeyboardButton(
                    label: "( )",
                    action: { appendToText("(") }
                )
            }
            
            // Row 6: Clear and 0
            LazyVGrid(columns: columns, spacing: 8) {
                KeyboardButton(
                    label: "0",
                    action: { appendToText("0") }
                )
                
                KeyboardButton(
                    label: "C",
                    isSpecial: true,
                    action: { text = "" }
                )
                
                KeyboardButton(
                    label: "(",
                    action: { appendToText("( ") }
                )
                
                KeyboardButton(
                    label: ")",
                    action: { appendToText(" )") }
                )
            }
            
            Divider()
                .padding(.vertical, 4)
            
            // Row 7: Trigonometric functions
            LazyVGrid(columns: columns, spacing: 8) {
                KeyboardButton(
                    label: "sin",
                    isFunction: true,
                    action: { appendToText("sin(") }
                )
                
                KeyboardButton(
                    label: "cos",
                    isFunction: true,
                    action: { appendToText("cos(") }
                )
                
                KeyboardButton(
                    label: "tan",
                    isFunction: true,
                    action: { appendToText("tan(") }
                )
                
                KeyboardButton(
                    label: "π",
                    isFunction: true,
                    action: { appendToText("pi") }
                )
            }
            
            // Row 8: Logarithmic and root functions
            LazyVGrid(columns: columns, spacing: 8) {
                KeyboardButton(
                    label: "log",
                    isFunction: true,
                    action: { appendToText("log(") }
                )
                
                KeyboardButton(
                    label: "ln",
                    isFunction: true,
                    action: { appendToText("ln(") }
                )
                
                KeyboardButton(
                    label: "√",
                    isFunction: true,
                    action: { appendToText("sqrt(") }
                )
                
                KeyboardButton(
                    label: "²",
                    isOperator: true,
                    action: { appendToText("^2") }
                )
            }
            
            // Row 9: Calculus and advanced operators
            LazyVGrid(columns: columns, spacing: 8) {
                KeyboardButton(
                    label: "d/dx",
                    isFunction: true,
                    action: { appendToText("d/dx") }
                )
                
                KeyboardButton(
                    label: "∫",
                    isFunction: true,
                    action: { appendToText("integral") }
                )
                
                KeyboardButton(
                    label: ",",
                    action: { appendToText(", ") }
                )
                
                KeyboardButton(
                    label: "→",
                    action: { appendToText("->") }
                )
            }
            
            // Row 10: Done button
            LazyVGrid(columns: columns, spacing: 8) {
                KeyboardButton(
                    label: "Done",
                    action: { onDone() }
                )
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Color.green.opacity(0.8))
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func appendToText(_ value: String) {
        text.append(value)
    }
}

// MARK: - KeyboardButton Component

private struct KeyboardButton: View {
    let label: String
    var isOperator: Bool = false
    var isVariable: Bool = false
    var isSpecial: Bool = false
    var isFunction: Bool = false
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
        if isSpecial {
            return Color.red.opacity(0.8)
        } else if isFunction {
            return Color.blue.opacity(0.8)
        } else if isOperator {
            return Color.orange.opacity(0.8)
        } else if isVariable {
            return Color.purple.opacity(0.8)
        } else {
            return Color.white
        }
    }
    
    private var buttonForeground: Color {
        if isSpecial || isFunction || isOperator || isVariable {
            return Color.white
        } else {
            return Color.black
        }
    }
}

#Preview {
    VStack {
        TextField("Equation", text: .constant("2x + 5 = 15"))
            .font(.system(.title2, design: .monospaced))
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
            .padding()
        
        MathKeyboard(text: .constant(""), onDone: {})
            .padding()
        
        Spacer()
    }
    .background(Color(.systemBackground))
}
