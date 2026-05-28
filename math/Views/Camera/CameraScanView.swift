import SwiftUI
import AVFoundation
import PhotosUI  // T011: For PhotosPicker

// MARK: - Camera Preview Wrapper

struct CameraPreviewView: UIViewRepresentable {
    let cameraService: CameraService
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        
        if let previewLayer = cameraService.getPreviewLayer() {
            previewLayer.frame = view.bounds
            previewLayer.videoGravity = .resizeAspectFill
            view.layer.addSublayer(previewLayer)
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if let previewLayer = cameraService.getPreviewLayer() {
            previewLayer.frame = uiView.bounds
        }
    }
}

// MARK: - CameraScanView

struct CameraScanView: View {
    @StateObject var cameraService = CameraService.shared
    @State private var showPermissionDenied = false
    @State private var showManualInput = false
    @State private var scannedEquation: String?
    @State private var selectedPhotoItem: PhotosPickerItem?  // T011: Photo library selection
    @State private var isProcessingUpload = false  // T011: Upload processing
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // Background
            Color.black.ignoresSafeArea()
            
            // Permission Denied State (T030)
            if cameraService.permission == .denied {
                VStack(spacing: 20) {
                    Image(systemName: "camera.slash")
                        .font(.system(size: 60))
                        .foregroundColor(.red)
                    
                    Text("Camera Access Denied")
                        .font(.headline)
                    
                    Text("Go to Settings and enable camera access for this app to scan equations.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                    
                    HStack(spacing: 12) {
                        Button(action: { dismiss() }) {
                            Text("Cancel")
                                .frame(maxWidth: .infinity)
                                .padding(12)
                                .background(Color.gray)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        
                        Button(action: openSettings) {
                            Text("Open Settings")
                                .frame(maxWidth: .infinity)
                                .padding(12)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
            // Permission Not Determined - Show Request (T030)
            else if cameraService.permission == .notDetermined {
                VStack(spacing: 20) {
                    Image(systemName: "camera")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Camera Permission Needed")
                        .font(.headline)
                    
                    Text("MathSolver Pro needs camera access to scan and solve your math equations from paper or whiteboards.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                    
                    Button(action: { cameraService.requestCameraPermission() }) {
                        Text("Allow Camera Access")
                            .frame(maxWidth: .infinity)
                            .padding(12)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
            // Main Camera View
            else if cameraService.permission == .authorized {
                VStack(spacing: 0) {
                    // Camera Preview (T028)
                    ZStack(alignment: .center) {
                        CameraPreviewView(cameraService: cameraService)
                            .ignoresSafeArea()
                        
                        // Scan Reticle
                        VStack {
                            HStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.yellow, lineWidth: 2)
                                    .frame(width: 80, height: 80)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        
                        // Low-Light Guidance Overlay (T031)
                        if cameraService.isLightingPoor {
                            VStack(spacing: 12) {
                                Image(systemName: "lightbulb.slash")
                                    .font(.system(size: 40))
                                    .foregroundColor(.yellow)
                                
                                Text("Poor Lighting")
                                    .font(.headline)
                                
                                Text("Move to a brighter location or use manual input instead")
                                    .font(.caption)
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(.gray)
                                
                                Button(action: { showManualInput = true }) {
                                    Text("Enter Manually")
                                        .foregroundColor(.white)
                                        .padding(8)
                                        .background(Color.blue)
                                        .cornerRadius(6)
                                }
                            }
                            .padding(20)
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(12)
                            .padding(20)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        }
                        
                        // Real-time Text Overlay (T028)
                        if let recognized = cameraService.recognizedText {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Recognized Text")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                        
                                        Text(recognized.text)
                                            .font(.subheadline)
                                            .foregroundColor(.white)
                                            .lineLimit(2)
                                        
                                        HStack(spacing: 4) {
                                            Image(systemName: "checkmark.circle")
                                                .font(.caption)
                                            
                                            Text("\(Int(recognized.confidence * 100))% confidence")
                                                .font(.caption2)
                                        }
                                        .foregroundColor(.green)
                                    }
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        scannedEquation = recognized.text
                                    }) {
                                        Image(systemName: "checkmark")
                                            .font(.system(.title3, design: .rounded))
                                            .frame(width: 40, height: 40)
                                            .background(Color.green)
                                            .foregroundColor(.white)
                                            .cornerRadius(20)
                                    }
                                }
                                .padding(12)
                                .background(Color.black.opacity(0.8))
                                .cornerRadius(8)
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                        }
                    }
                    
                    // Controls (T012: Added PhotosPicker)
                    HStack(spacing: 16) {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.system(.title2, design: .rounded))
                                .frame(width: 44, height: 44)
                                .background(Color.gray)
                                .foregroundColor(.white)
                                .cornerRadius(22)
                        }
                        
                        Spacer()
                        
                        // Shutter button for manual photo capture
                        Button(action: {
                            cameraService.capturePhoto()
                        }) {
                            Image(systemName: "camera.fill")
                                .font(.system(.title2, design: .rounded))
                                .frame(width: 60, height: 60)
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(30)
                        }
                        
                        Spacer()
                        
                        // Photo library upload button (T012)
                        PhotosPicker(selection: $selectedPhotoItem, matching: .images, label: {
                            Image(systemName: "photo.fill")
                                .font(.system(.title2, design: .rounded))
                                .frame(width: 44, height: 44)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(22)
                        })
                        
                        Button(action: { showManualInput = true }) {
                            Image(systemName: "keyboard")
                                .font(.system(.title2, design: .rounded))
                                .frame(width: 44, height: 44)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(22)
                        }
                        
                        Button(action: { cameraService.stopSession(); cameraService.startSession() }) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(.title2, design: .rounded))
                                .frame(width: 44, height: 44)
                                .background(Color.gray)
                                .foregroundColor(.white)
                                .cornerRadius(22)
                        }
                    }
                    .padding(16)
                    .background(Color.black)
                }
            }
            
            // Header
            HStack {
                Text("Scan Equation")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
            }
            .padding(16)
            .background(Color.black.opacity(0.5))
        }
        .onAppear {
            cameraService.setupCaptureSession()
            cameraService.startSession()
        }
        .onDisappear {
            cameraService.stopSession()
        }
        .sheet(isPresented: $showManualInput) {
            ManualEquationInputSheet(isPresented: $showManualInput, scannedEquation: $scannedEquation)
        }
        .navigationDestination(isPresented: Binding(
            get: { scannedEquation != nil },
            set: { if !$0 { scannedEquation = nil } }
        )) {
            if let equation = scannedEquation {
                ScanConfirmView(
                    scannedEquation: equation,
                    confidence: cameraService.recognizedText?.confidence ?? 0.5
                )
            }
        }
        // Photo picker onChange handler (T012)
        .onChange(of: selectedPhotoItem) { _, newValue in
            if let newValue = newValue {
                isProcessingUpload = true
                Task {
                    do {
                        if let data = try await newValue.loadTransferable(type: Data.self),
                           let uiImage = UIImage(data: data) {
                            cameraService.processImage(uiImage)
                        } else {
                            cameraService.errorMessage = "Failed to load image from library"
                        }
                    } catch {
                        cameraService.errorMessage = "Failed to load image: \(error.localizedDescription)"
                    }
                    isProcessingUpload = false
                    selectedPhotoItem = nil  // Clear selection for next photo
                }
            }
        }
    }
    
    private func openSettings() {
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsURL)
        }
    }
}

// MARK: - Manual Input Sheet Helper

struct ManualEquationInputSheet: View {
    @Binding var isPresented: Bool
    @Binding var scannedEquation: String?
    @State private var manualInput = ""
    
    // Custom keyboard support
    @State private var showKeyboard = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                HStack {
                    Text("Enter Equation")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
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
                .padding(.horizontal)
                .padding(.top, 16)
                
                TextField("e.g., 2x + 5 = 15", text: $manualInput)
                    .font(.system(.body, design: .monospaced))
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .padding(.horizontal)
                    .onTapGesture {
                        showKeyboard = true
                    }
                
                Spacer()
                
                // Custom Math Keyboard
                if showKeyboard {
                    MathKeyboard(
                        text: $manualInput,
                        onDone: { showKeyboard = false }
                    )
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .transition(.move(edge: .bottom))
                }
                
                Button(action: {
                    if !manualInput.isEmpty {
                        scannedEquation = manualInput
                        isPresented = false
                    }
                }) {
                    Text("Confirm")
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding()
                .disabled(manualInput.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

#Preview {
    CameraScanView()
}
