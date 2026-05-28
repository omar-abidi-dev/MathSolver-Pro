import Foundation
import AVFoundation
import Vision
import Combine
import CoreImage
import UIKit

// MARK: - Camera Permission Status

enum CameraPermissionStatus {
    case authorized
    case denied
    case notDetermined
    case restricted
}

// MARK: - OCR Result

struct OCRResult {
    let text: String
    let confidence: Float
    let timestamp: Date
}

// MARK: - CameraService

@MainActor
class CameraService: NSObject, ObservableObject {
    // MARK: - Published Properties
    
    @Published var isRunning = false
    @Published var scannedText: String = ""
    @Published var recognizedText: OCRResult?
    @Published var permission: CameraPermissionStatus = .notDetermined
    @Published var isLightingPoor = false
    @Published var lightingLevel: Float = 1.0
    @Published var errorMessage: String?
    @Published var nonMathWarning: String?  // T046: Warning when no math expressions detected
    @Published var permissionRevoked = false  // T047: Flag when permission revoked mid-session
    @Published var capturedPhoto: UIImage?  // T007: Still photo captured from shutter button
    @Published var isCapturing: Bool = false  // T007: Photo capture in progress
    
    // MARK: - AVCapture Setup
    
    private let captureSession = AVCaptureSession()
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    private let videoDataOutput = AVCaptureVideoDataOutput()
    private let photoOutput = AVCapturePhotoOutput()
    private let sessionQueue = DispatchQueue(label: "com.mathsolver.camera.session")
    
    // MARK: - Vision Request
    
    private let requestHandler = VNSequenceRequestHandler()
    
    // MARK: - Lighting Detection
    
    private var lastLightingCheck: Date = Date()
    private let lightingCheckInterval: TimeInterval = 0.5
    
    // MARK: - Singleton
    
    static let shared = CameraService()
    
    override init() {
        super.init()
        checkCameraPermission()
        setupPermissionObserver()  // T047: Start observing permission changes
    }
    
    // MARK: - Permission Change Observation (T047)
    
    private func setupPermissionObserver() {
        // Observe when app returns to foreground to check if permissions changed
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(checkPermissionStatusOnForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
    
    @objc private func checkPermissionStatusOnForeground() {
        let newStatus = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch newStatus {
        case .authorized:
            permission = .authorized
            permissionRevoked = false
        case .denied, .restricted:
            // Permission was revoked during session
            if isRunning {
                stopSession()
                permissionRevoked = true
                DispatchQueue.main.async {
                    self.errorMessage = "Camera permission was revoked. Tap to enter equation manually."
                }
            }
            permission = newStatus == .denied ? .denied : .restricted
        default:
            break
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Permission Handling
    
    func checkCameraPermission() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .authorized:
            permission = .authorized
        case .denied:
            permission = .denied
        case .notDetermined:
            permission = .notDetermined
            requestCameraPermission()
        case .restricted:
            permission = .restricted
        @unknown default:
            permission = .notDetermined
        }
    }
    
    func requestCameraPermission() {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            DispatchQueue.main.async {
                self?.permission = granted ? .authorized : .denied
                if granted {
                    self?.setupCaptureSession()
                }
            }
        }
    }
    
    // MARK: - Camera Setup
    
    func setupCaptureSession() {
        guard permission == .authorized else {
            errorMessage = "Camera permission not granted"
            return
        }
        
        sessionQueue.async { [weak self] in
            self?.configureSession()
        }
    }
    
    private func configureSession() {
        captureSession.beginConfiguration()
        defer { captureSession.commitConfiguration() }
        
        // Set quality preset
        if captureSession.canSetSessionPreset(.high) {
            captureSession.sessionPreset = .high
        }
        
        // Add video input
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            errorMessage = "No camera available"
            return
        }
        
        do {
            let videoInput = try AVCaptureDeviceInput(device: videoDevice)
            if captureSession.canAddInput(videoInput) {
                captureSession.addInput(videoInput)
            }
        } catch {
            errorMessage = "Failed to add video input: \(error.localizedDescription)"
            return
        }
        
        // Add video data output for frame processing
        videoDataOutput.setSampleBufferDelegate(self, queue: sessionQueue)
        videoDataOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        
        if captureSession.canAddOutput(videoDataOutput) {
            captureSession.addOutput(videoDataOutput)
        }
        
        // Add photo output
        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
        }
        
        // Set up video preview layer on main thread
        DispatchQueue.main.async { [weak self] in
            self?.createPreviewLayer()
        }
    }
    
    private func createPreviewLayer() {
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        self.videoPreviewLayer = previewLayer
    }
    
    // MARK: - Start/Stop Session
    
    func startSession() {
        guard permission == .authorized else {
            if permission == .notDetermined {
                requestCameraPermission()
            }
            return
        }
        
        sessionQueue.async { [weak self] in
            if !(self?.captureSession.isRunning ?? false) {
                self?.captureSession.startRunning()
                DispatchQueue.main.async {
                    self?.isRunning = true
                }
            }
        }
    }
    
    func stopSession() {
        sessionQueue.async { [weak self] in
            if self?.captureSession.isRunning ?? false {
                self?.captureSession.stopRunning()
                DispatchQueue.main.async {
                    self?.isRunning = false
                }
            }
        }
    }
    
    // MARK: - Get Preview Layer
    
    func getPreviewLayer() -> AVCaptureVideoPreviewLayer? {
        return videoPreviewLayer
    }
    
    // MARK: - Photo Capture (T008, T009)
    
    /// Triggers a still photo capture from the photoOutput
    func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        isCapturing = true
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    /// Processes a still image (UIImage) through OCR and updates recognizedText
    /// Used by both camera capture button and photo library picker
    func processImage(_ image: UIImage) {
        guard let cgImage = image.cgImage else {
            errorMessage = "Failed to process image"
            return
        }
        
        let ciImage = CIImage(cgImage: cgImage)
        let request = VNRecognizeTextRequest { [weak self] request, error in
            self?.handleOCRResults(request, error: error)
        }
        
        request.recognitionLanguages = ["en"]
        request.usesLanguageCorrection = true
        
        let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        do {
            try handler.perform([request])
        } catch {
            errorMessage = "OCR failed: \(error.localizedDescription)"
        }
    }
    
    private func processOCR(buffer: CMSampleBuffer) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(buffer) else { return }
        
        let request = VNRecognizeTextRequest { [weak self] request, error in
            self?.handleOCRResults(request, error: error)
        }
        
        // Set accurate recognition
        request.recognitionLevel = .accurate
        
        do {
            try requestHandler.perform([request], on: pixelBuffer)
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "OCR failed: \(error.localizedDescription)"
            }
        }
    }
    
    private func handleOCRResults(_ request: VNRequest, error: Error?) {
        guard let results = request.results as? [VNRecognizedTextObservation] else { return }
        
        var fullText = ""
        var totalConfidence: Float = 0
        var observationCount = 0
        
        for observation in results {
            if let candidate = observation.topCandidates(1).first {
                fullText.append(candidate.string)
                fullText.append(" ")
                totalConfidence += observation.confidence
                observationCount += 1
            }
        }
        
        guard !fullText.isEmpty else { return }
        
        let averageConfidence = observationCount > 0 ? totalConfidence / Float(observationCount) : 0
        
        // Post-process the text for math notation
        let processedText = postProcessMathOCR(fullText.trimmingCharacters(in: .whitespaces))
        
        DispatchQueue.main.async {
            self.recognizedText = OCRResult(
                text: processedText,
                confidence: averageConfidence,
                timestamp: Date()
            )
            self.scannedText = processedText
            
            // T046: Check if scanned text contains math expressions
            if !self.containsMathExpressions(processedText) {
                self.nonMathWarning = "No math expressions detected. Please scan an equation or math problem."
            } else {
                self.nonMathWarning = nil
            }
        }
    }
    
    // MARK: - Math-Specific OCR Post-Processing (T027)
    
    private func postProcessMathOCR(_ text: String) -> String {
        var processed = text
        
        // Normalize division symbol
        processed = processed.replacingOccurrences(of: "÷", with: "/")
        processed = processed.replacingOccurrences(of: "\\u{00F7}", with: "/") // Another division char
        
        // Normalize multiplication symbol
        processed = processed.replacingOccurrences(of: "×", with: "*")
        processed = processed.replacingOccurrences(of: "·", with: "*")
        // NOTE: Do NOT replace "x" globally - it destroys variable names in equations like "x = 5" → "* = 5"
        // Context-dependent conversion would require NLP; keeping "x" as-is is safer for equations
        
        // Normalize superscript 2 to ^2
        processed = processed.replacingOccurrences(of: "²", with: "^2")
        processed = processed.replacingOccurrences(of: "x2", with: "x^2") // Heuristic
        processed = processed.replacingOccurrences(of: "y2", with: "y^2")
        processed = processed.replacingOccurrences(of: "z2", with: "z^2")
        
        // Normalize superscript 3+
        processed = processed.replacingOccurrences(of: "³", with: "^3")
        processed = processed.replacingOccurrences(of: "⁴", with: "^4")
        
        // Normalize sqrt symbol
        processed = processed.replacingOccurrences(of: "√", with: "sqrt(")
        // Add closing paren for sqrt - simplistic, may need refinement
        if processed.contains("sqrt(") && !processed.contains("sqrt()") {
            processed = processed.replacingOccurrences(of: "sqrt(", with: "sqrt(")
        }
        
        // Normalize pi
        processed = processed.replacingOccurrences(of: "π", with: "pi")
        
        // Remove common OCR artifacts
        processed = processed.replacingOccurrences(of: "0O", with: "0") // OCR confusion
        processed = processed.replacingOccurrences(of: "O0", with: "0")
        processed = processed.replacingOccurrences(of: "l", with: "1") // Context: at start of number
        
        // Clean up extra spaces
        processed = processed.replacingOccurrences(of: "\\s+", with: "", options: .regularExpression)
        
        return processed
    }
    
    // MARK: - Math Expression Detection (T046)
    
    /// Detects if the scanned text contains mathematical expressions
    /// Returns false if text appears to be purely non-mathematical
    private func containsMathExpressions(_ text: String) -> Bool {
        // Check for math operators and symbols
        let mathPatterns = [
            "\\+",      // Addition
            "-",        // Subtraction (also unary minus)
            "\\*",      // Multiplication
            "/",        // Division
            "\\^",      // Exponentiation
            "=",        // Equals
            "<",        // Less than
            ">",        // Greater than
            "\\(',", "\\)",      // Parentheses
            "\\[", "\\]",      // Brackets
            "\\{", "\\}",      // Braces
            "sin", "cos", "tan", "sec", "csc", "cot",  // Trig functions
            "log", "ln",        // Logarithmic functions
            "sqrt", "√",        // Square root
            "pi", "π",          // Pi
            "e\\b",             // Euler's number
            "x", "y", "z",      // Variables
            "\\d",              // Digits
        ]
        
        // Count how many math-related patterns are found
        var mathPatternCount = 0
        for pattern in mathPatterns {
            do {
                let regex = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)
                let range = NSRange(text.startIndex..<text.endIndex, in: text)
                let matches = regex.numberOfMatches(in: text, options: [], range: range)
                if matches > 0 {
                    mathPatternCount += 1
                }
            } catch {
                continue
            }
        }

        // If we find at least 1 math pattern type, consider it math text
        // This allows detection of simple equations like "x = 5" (has variable + equals)
        return mathPatternCount >= 1
    }
    
    // MARK: - Lighting Detection
    
    private func detectLighting(from buffer: CMSampleBuffer) {
        let now = Date()
        guard now.timeIntervalSince(lastLightingCheck) >= lightingCheckInterval else { return }
        lastLightingCheck = now
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(buffer) else { return }
        
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        
        // Calculate brightness as average luminance
        let extent = ciImage.extent
        let filter = CIFilter(name: "CIAreaAverage", parameters: [kCIInputImageKey: ciImage])
        
        guard let outputImage = filter?.outputImage else { return }
        
        var bitmap = [UInt8](repeating: 0, count: 4)
        context.render(outputImage, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: CGColorSpaceCreateDeviceRGB())
        
        let brightness = Float(bitmap[0]) / 255.0
        
        DispatchQueue.main.async {
            self.lightingLevel = brightness
            self.isLightingPoor = brightness < 0.3 // Threshold for poor lighting
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension CameraService: AVCaptureVideoDataOutputSampleBufferDelegate {
    nonisolated func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        Task { @MainActor in
            processOCR(buffer: sampleBuffer)
            detectLighting(from: sampleBuffer)
        }
    }
}

// MARK: - AVCapturePhotoCaptureDelegate (T008)

extension CameraService: AVCapturePhotoCaptureDelegate {
    nonisolated func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        Task { @MainActor in
            if let error = error {
                self.errorMessage = "Photo capture failed: \(error.localizedDescription)"
                self.isCapturing = false
                return
            }
            
            guard let imageData = photo.fileDataRepresentation(),
                  let uiImage = UIImage(data: imageData) else {
                self.errorMessage = "Failed to convert photo data"
                self.isCapturing = false
                return
            }
            
            self.capturedPhoto = uiImage
            self.isCapturing = false
            
            // Automatically process the captured image through OCR
            self.processImage(uiImage)
        }
    }
}
