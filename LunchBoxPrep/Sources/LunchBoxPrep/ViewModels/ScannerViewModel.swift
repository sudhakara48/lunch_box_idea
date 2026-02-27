import Foundation
import Combine

#if canImport(AVFoundation)
import AVFoundation
#endif

#if canImport(Vision)
import Vision
#endif

#if canImport(QuartzCore)
import QuartzCore
#endif

// MARK: - Platform-agnostic permission status

#if os(iOS)
/// Typealias so the rest of the file can reference `CameraAuthorizationStatus` uniformly.
public typealias CameraAuthorizationStatus = AVAuthorizationStatus
#else
/// On macOS (CI builds) we replicate the raw values of `AVAuthorizationStatus`
/// so the published property compiles without AVFoundation.
@objc public enum CameraAuthorizationStatus: Int {
    case notDetermined = 0
    case restricted    = 1
    case denied        = 2
    case authorized    = 3
}
#endif

// MARK: - ScannerViewModel

/// ViewModel for the Scanner screen.
///
/// Responsibilities:
/// - Manage `AVCaptureSession` lifecycle (`startSession` / `stopSession`)
/// - Request camera permission and publish `cameraPermissionStatus`
/// - Process camera frames through Vision text recognition as a proxy for food detection
/// - Filter detections by `minimumConfidenceThreshold` before surfacing them
/// - Bridge confirmed detections into `InventoryStore`
@MainActor
public final class ScannerViewModel: ObservableObject {

    // MARK: - Published State

    /// Items detected by the scanner that are awaiting user confirmation or dismissal.
    @Published public var detectedItems: [DetectedItem] = []

    /// Current camera authorisation status.
    @Published public var cameraPermissionStatus: CameraAuthorizationStatus

    // MARK: - Configuration

    /// Detections whose confidence is below this threshold are discarded.
    public let minimumConfidenceThreshold: Float = 0.5

    // MARK: - Dependencies

    private let inventoryStore: InventoryStore

    // MARK: - Private — AVCapture / Vision (iOS only)

#if os(iOS)
    @Published public private(set) var captureSession: AVCaptureSession?
    private let sessionQueue = DispatchQueue(label: "com.lunchboxprep.scanner.session")
    private var videoOutput: AVCaptureVideoDataOutput?
    private var textRequest: VNRequest?
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

    /// Requests camera permission (if needed) then starts the capture session.
    public func startSession() {
#if os(iOS)
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            cameraPermissionStatus = .authorized
            startCaptureSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    self.cameraPermissionStatus = granted ? .authorized : .denied
                    if granted { self.startCaptureSession() }
                }
            }
        case .denied, .restricted:
            cameraPermissionStatus = status
        @unknown default:
            cameraPermissionStatus = status
        }
#else
        // macOS stub — no camera access in CI builds
        cameraPermissionStatus = .authorized
#endif
    }

    /// Stops the capture session and releases resources.
    public func stopSession() {
#if os(iOS)
        sessionQueue.async { [weak self] in
            self?.captureSession?.stopRunning()
        }
#endif
    }

    // MARK: - User Actions

    /// Confirms a detected item: creates an `InventoryItem` in the store and removes it from `detectedItems`.
    public func confirm(_ item: DetectedItem) {
        let inventoryItem = InventoryItem(id: UUID(), name: item.name, quantity: "")
        inventoryStore.add(inventoryItem)
        detectedItems.removeAll { $0.id == item.id }
    }

    /// Dismisses a detected item without adding it to the inventory.
    public func dismiss(_ item: DetectedItem) {
        detectedItems.removeAll { $0.id == item.id }
    }

    /// Adds a manually typed food item directly to the inventory.
    ///
    /// - Parameter name: The item name. Whitespace-only or empty strings are ignored.
    public func addManualItem(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let item = InventoryItem(id: UUID(), name: trimmed, quantity: "")
        inventoryStore.add(item)
    }

    // MARK: - Internal: add a detection (used by frame processing and tests)

    /// Adds a `DetectedItem` to `detectedItems` only if its confidence meets the threshold
    /// and no item with the same name is already pending.
    func addDetection(_ item: DetectedItem) {
        guard item.confidence >= minimumConfidenceThreshold else { return }
        guard !detectedItems.contains(where: { $0.name.lowercased() == item.name.lowercased() }) else { return }
        detectedItems.append(item)
    }
}

// MARK: - iOS AVCapture + Vision integration

#if os(iOS)
extension ScannerViewModel {

    private func startCaptureSession() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            let session = AVCaptureSession()
            session.sessionPreset = .high

            guard
                let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                let input = try? AVCaptureDeviceInput(device: device),
                session.canAddInput(input)
            else { return }

            session.addInput(input)

            let output = AVCaptureVideoDataOutput()
            output.videoSettings = [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
            ]
            output.alwaysDiscardsLateVideoFrames = true

            guard session.canAddOutput(output) else { return }
            session.addOutput(output)

            let request = VNClassifyImageRequest { [weak self] request, _ in
                self?.handleClassificationResults(request.results)
            }

            let delegate = SampleBufferDelegate { [weak self] sampleBuffer in
                self?.processSampleBuffer(sampleBuffer)
            }
            output.setSampleBufferDelegate(delegate, queue: self.sessionQueue)

            // Publish session on main actor BEFORE startRunning so the
            // preview layer is connected when frames start arriving
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.sampleBufferDelegate = delegate
                self.videoOutput = output
                self.textRequest = request
                self.captureSession = session
            }

            session.startRunning()
        }
    }

    private func processSampleBuffer(_ sampleBuffer: CMSampleBuffer) {
        guard let request = textRequest else { return }
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        // Throttle: only process one frame per second
        let now = CACurrentMediaTime()
        guard now - lastProcessedTime >= 1.0 else { return }
        lastProcessedTime = now

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        try? handler.perform([request])
    }

    private func handleClassificationResults(_ results: [VNObservation]?) {
        guard let observations = results as? [VNClassificationObservation] else { return }

        // Food-related identifier keywords from the Vision taxonomy
        let foodKeywords = ["food", "fruit", "vegetable", "meat", "bread", "cheese",
                            "egg", "fish", "seafood", "pasta", "rice", "bean", "nut",
                            "dairy", "beverage", "snack", "dessert", "herb", "spice",
                            "grain", "legume", "poultry", "pork", "beef", "lamb"]

        for observation in observations {
            guard observation.confidence >= minimumConfidenceThreshold else { continue }
            let identifier = observation.identifier.lowercased()
            guard foodKeywords.contains(where: { identifier.contains($0) }) else { continue }

            // Clean up the Vision label: "Granny Smith apple" → "Granny Smith Apple"
            let name = observation.identifier
                .replacingOccurrences(of: "_", with: " ")
                .split(separator: ",")
                .first
                .map(String.init)?
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .capitalized ?? observation.identifier

            let detected = DetectedItem(id: UUID(), name: name, confidence: observation.confidence)
            Task { @MainActor [weak self] in
                self?.addDetection(detected)
            }
        }
    }

    private func handleTextRecognitionResults(_ results: [VNObservation]?) {
        guard let observations = results as? [VNRecognizedTextObservation] else { return }

        for observation in observations {
            guard
                let candidate = observation.topCandidates(1).first,
                candidate.confidence >= minimumConfidenceThreshold
            else { continue }

            let text = candidate.string.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { continue }

            let detected = DetectedItem(id: UUID(), name: text, confidence: candidate.confidence)
            Task { @MainActor [weak self] in
                self?.addDetection(detected)
            }
        }
    }
}

// MARK: - Sample buffer delegate helper

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
