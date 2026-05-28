import SwiftUI

// MARK: - ScanConfirmView

struct ScanConfirmView: View {
    @State var scannedEquation: String
    @State var confidence: Float = 0.85
    @State var isLoading = false
    @State var errorMessage: String?
    @State var showResults = false
    
    // Custom keyboard support
    @State private var showKeyboard = false
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Confirm Scanned Equation")
                        .font(.headline)
                    
                    Text("Edit the equation if needed, then tap Solve")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                
                // Scanned Text Confidence Indicator
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Recognition Confidence")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            
                            HStack(spacing: 8) {
                                ProgressView(value: Double(confidence))
                                    .tint(confidenceColor)
                                
                                Text("\(Int(confidence * 100))%")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(confidenceColor)
                            }
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Image(systemName: confidenceIcon)
                                .font(.title2)
                                .foregroundColor(confidenceColor)
                            
                            Text(confidenceLabel)
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding(.horizontal, 16)
                
                // Editable Equation Field (T029)
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Equation")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Button(action: { showKeyboard.toggle() }) {
                            HStack(spacing: 8) {
                                Image(systemName: "keyboard")
                                Text(showKeyboard ? "Hide Keyboard" : "Show Keyboard")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(12)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(8)
                        }
                    }
                    
                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $scannedEquation)
                            .font(.system(.body, design: .monospaced))
                            .frame(minHeight: 100)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .onTapGesture {
                                showKeyboard = true
                            }
                        
                        if scannedEquation.isEmpty {
                            Text("Enter or edit equation...")
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.gray)
                                .padding(12)
                                .allowsHitTesting(false)
                        }
                    }
                }
                .padding(.horizontal, 16)
                
                // Suggested Corrections (if confidence is low)
                if confidence < 0.7 {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Low Confidence", systemImage: "exclamationmark.circle")
                            .font(.subheadline)
                            .foregroundColor(.orange)
                        
                        Text("Please review and correct the equation if needed")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(12)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal, 16)
                }
                
                // Error Message
                if let error = errorMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundColor(.red)
                        
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                        
                        Spacer()
                    }
                    .padding(12)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal, 16)
                }
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 12) {
                    // Solve Button (T033 - will connect to solver)
                    Button(action: solveEquation) {
                        HStack(spacing: 8) {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "sparkles.rectangle.stack")
                            }
                            
                            Text(isLoading ? "Solving..." : "Solve Equation")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .disabled(scannedEquation.trimmingCharacters(in: .whitespaces).isEmpty || isLoading)
                    .opacity(scannedEquation.trimmingCharacters(in: .whitespaces).isEmpty || isLoading ? 0.6 : 1.0)
                    
                    // Retry Scan Button (T029)
                    Button(action: { dismiss() }) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.clockwise")
                            Text("Rescan")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.blue)
                        .cornerRadius(8)
                    }
                }
                .padding(16)
                
                // Custom Math Keyboard
                if showKeyboard {
                    MathKeyboard(
                        text: $scannedEquation,
                        onDone: { showKeyboard = false }
                    )
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .transition(.move(edge: .bottom))
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $showResults) {
                ScanResultView(scannedEquation: scannedEquation, confidence: confidence)
            }
        }
    }
    
    // MARK: - Confidence Styling
    
    private var confidenceColor: Color {
        if confidence >= 0.9 {
            return .green
        } else if confidence >= 0.7 {
            return .blue
        } else if confidence >= 0.5 {
            return .orange
        } else {
            return .red
        }
    }
    
    private var confidenceIcon: String {
        if confidence >= 0.9 {
            return "checkmark.circle.fill"
        } else if confidence >= 0.7 {
            return "checkmark.circle"
        } else if confidence >= 0.5 {
            return "exclamationmark.triangle"
        } else {
            return "xmark.circle"
        }
    }
    
    private var confidenceLabel: String {
        if confidence >= 0.9 {
            return "Excellent"
        } else if confidence >= 0.7 {
            return "Good"
        } else if confidence >= 0.5 {
            return "Fair"
        } else {
            return "Poor"
        }
    }
    
    // MARK: - Equation Solving (T033)
    
    private func solveEquation() {
        guard !scannedEquation.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Please enter an equation"
            return
        }
        
        errorMessage = nil
        isLoading = true
        
        // Navigate to ScanResultView to solve and fetch AI explanation (T043)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showResults = true
            isLoading = false
        }
    }
}

#Preview {
    ScanConfirmView(scannedEquation: "sin(x) = 0.5", confidence: 0.92)
}
