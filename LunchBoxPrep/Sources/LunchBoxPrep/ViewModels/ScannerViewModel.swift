import Foundation
import Combine
import OSLog

#if canImport(AVFoundation)
import AVFoundation
#endif

#if canImport(Vision)
import Vision
#endif

#if canImport(QuartzCore)
import QuartzCore
#endif

private let logger = Logger(subsystem: "com.sudhakara.lunchboxprep", category: "ScannerViewModel")

// MARK: - Platform-agnostic permission status

#if os(iOS)
public typealias CameraAuthorizationStatus = AVAuthorizationStatus
#else
@objc public enum CameraAuthorizationStatus: Int {
    case notDetermined = 0
    case restricted    = 1
    case denied        = 2
    case authorized    = 3
}
#endif

// MARK: - ScannerViewModel

@MainActor
public final class ScannerViewModel: ObservableObject {

    // MARK: - Published State

    @Published public var detectedItems: [DetectedItem] = []
    @Published public var cameraPermissionStatus: CameraAuthorizationStatus

    // MARK: - Configuration

    public let minimumConfidenceThreshold: Float = 0.5

    // MARK: - Dependencies

    private let inventoryStore: InventoryStore

#if os(iOS)
    @Published public private(set) var captureSession: AVCaptureSession?
    private let sessionQueue = DispatchQueue(label: "com.lunchboxprep.scanner.session", qos: .userInitiated)
    private var videoOutput: AVCaptureVideoDataOutput?
    private var textRequest: VNRecognizeTextRequest?
    private var lastProcessedTime: Double = 0
    private var sampleBufferDelegate: SampleBufferDelegate?
#endif

    // MARK: - Init

    public init(inventoryStore: InventoryStore) {
        self.inventoryStore = inventoryStore
#if os(iOS)
        self.cameraPermissionStatus = AVCaptureDevice.authorizationStatus(for: .video)
#else
        self.cameraPermissionStatus = .notDetermined
#endif
    }

    // MARK: - Session Lifecycle

    public func startSession() {
#if os(iOS)
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            cameraPermissionStatus = .authorized
            setupAndStartSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    self.cameraPermissionStatus = granted ? .authorized : .denied
                    if granted { self.setupAndStartSession() }
                }
            }
        case .denied, .restricted:
            cameraPermissionStatus = status
        @unknown default:
            cameraPermissionStatus = status
        }
#else
        cameraPermissionStatus = .authorized
#endif
    }

    public func stopSession() {
#if os(iOS)
        sessionQueue.async { [weak self] in
            self?.captureSession?.stopRunning()
            logger.info("Capture session stopped")
        }
#endif
    }

    // MARK: - User Actions

    public func confirm(_ item: DetectedItem) {
        let inventoryItem = InventoryItem(id: UUID(), name: item.name, quantity: "")
        inventoryStore.add(inventoryItem)
        detectedItems.removeAll { $0.id == item.id }
    }

    public func dismiss(_ item: DetectedItem) {
        detectedItems.removeAll { $0.id == item.id }
    }

    public func addManualItem(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let item = InventoryItem(id: UUID(), name: trimmed, quantity: "")
        inventoryStore.add(item)
    }

    func addDetection(_ item: DetectedItem) {
        guard item.confidence >= minimumConfidenceThreshold else { return }
        guard !detectedItems.contains(where: { $0.name.lowercased() == item.name.lowercased() }) else { return }
        detectedItems.append(item)
    }
}

// MARK: - iOS AVCapture + Vision

#if os(iOS)
extension ScannerViewModel {

    /// Builds the AVCaptureSession on the session queue, then publishes it on
    /// the main actor so the preview layer can connect before startRunning().
    private func setupAndStartSession() {
        // If already running, skip
        if captureSession?.isRunning == true { return }

        sessionQueue.async { [weak self] in
            guard let self else { return }

            let session = AVCaptureSession()
            session.beginConfiguration()
            session.sessionPreset = .high

            // Input
            guard
                let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                let input = try? AVCaptureDeviceInput(device: device),
                session.canAddInput(input)
            else {
                logger.error("Failed to create camera input")
                session.commitConfiguration()
                return
            }
            session.addInput(input)

            // Output
            let output = AVCaptureVideoDataOutput()
            output.videoSettings = [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
            ]
            output.alwaysDiscardsLateVideoFrames = true

            guard session.canAddOutput(output) else {
                logger.error("Failed to add video output")
                session.commitConfiguration()
                return
            }
            session.addOutput(output)
            session.commitConfiguration()

            // Vision request
            let request = VNRecognizeTextRequest { [weak self] req, _ in
                self?.handleTextRecognitionResults(req.results)
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            let delegate = SampleBufferDelegate { [weak self] sampleBuffer in
                self?.processSampleBuffer(sampleBuffer)
            }
            output.setSampleBufferDelegate(delegate, queue: self.sessionQueue)

            // Publish session on main actor BEFORE startRunning so the
            // preview layer attaches in time
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.sampleBufferDelegate = delegate
                self.videoOutput = output
                self.textRequest = request
                self.captureSession = session
                logger.info("Capture session published to main actor")

                // Start running after a short delay to let the preview layer attach
                self.sessionQueue.asyncAfter(deadline: .now() + 0.1) {
                    session.startRunning()
                    logger.info("Capture session startRunning called, isRunning=\(session.isRunning)")
                }
            }
        }
    }

    private func processSampleBuffer(_ sampleBuffer: CMSampleBuffer) {
        guard let request = textRequest else { return }
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let now = CACurrentMediaTime()
        guard now - lastProcessedTime >= 1.0 else { return }
        lastProcessedTime = now

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        try? handler.perform([request])
    }

    private func handleTextRecognitionResults(_ results: [VNObservation]?) {
        guard let observations = results as? [VNRecognizedTextObservation] else { return }

        let foodKeywords: Set<String> = [
            "apple", "banana", "orange", "grape", "strawberry", "blueberry", "mango",
            "pineapple", "watermelon", "lemon", "lime", "peach", "pear", "cherry",
            "carrot", "broccoli", "spinach", "lettuce", "tomato", "cucumber", "pepper",
            "onion", "garlic", "potato", "corn", "pea", "bean", "celery", "zucchini",
            "chicken", "beef", "pork", "turkey", "salmon", "tuna", "shrimp", "egg",
            "cheese", "milk", "yogurt", "butter", "cream", "tofu",
            "rice", "pasta", "bread", "noodle", "tortilla", "wrap",
            "almond", "walnut", "cashew", "peanut", "sunflower",
            "avocado", "hummus", "salsa", "mayo", "mustard", "ketchup",
            "sandwich", "salad", "soup", "stew", "curry", "stir", "fry",
            "organic", "fresh", "natural", "whole", "grain", "wheat", "oat"
        ]

        for observation in observations {
            guard
                let candidate = observation.topCandidates(1).first,
                candidate.confidence >= minimumConfidenceThreshold
            else { continue }

            let text = candidate.string.trimmingCharacters(in: .whitespacesAndNewlines)
            guard text.count >= 3 else { continue }

            let lower = text.lowercased()
            guard foodKeywords.contains(where: { lower.contains($0) }) else { continue }

            let detected = DetectedItem(id: UUID(), name: text.capitalized, confidence: candidate.confidence)
            Task { @MainActor [weak self] in
                self?.addDetection(detected)
            }
        }
    }
}

// MARK: - Sample buffer delegate

private final class SampleBufferDelegate: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    private let handler: (CMSampleBuffer) -> Void

    init(handler: @escaping (CMSampleBuffer) -> Void) {
        self.handler = handler
    }

    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        handler(sampleBuffer)
    }
}
#endif
