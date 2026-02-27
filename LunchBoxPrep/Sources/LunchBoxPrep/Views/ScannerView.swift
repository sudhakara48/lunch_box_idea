import SwiftUI

#if os(iOS)
import AVFoundation
import UIKit
#endif

// MARK: - ScannerView

/// Camera-based food scanner screen.
///
/// On iOS: shows a live `AVCaptureVideoPreviewLayer`, overlays detected items
/// with confirm/dismiss buttons, handles camera-denied state, and provides a
/// manual-entry text field at the bottom.
///
/// On macOS: shows a placeholder (AVFoundation camera capture is iOS-only).
///
/// - Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6
public struct ScannerView: View {

    @StateObject private var viewModel: ScannerViewModel

    public init(viewModel: ScannerViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    public var body: some View {
#if os(iOS)
        iOSBody
#else
        macOSPlaceholder
#endif
    }

#if os(iOS)
    // MARK: iOS body

    @ViewBuilder
    private var iOSBody: some View {
        switch viewModel.cameraPermissionStatus {
        case .denied, .restricted:
            CameraPermissionDeniedView()
        default:
            cameraPreviewBody
        }
    }

    private var cameraPreviewBody: some View {
        ZStack(alignment: .bottom) {
            // Live camera preview fills the screen
            CameraPreviewView(viewModel: viewModel)
                .ignoresSafeArea()

            // Detected-item overlay cards
            if !viewModel.detectedItems.isEmpty {
                detectedItemsOverlay
            }

            // Manual entry bar pinned to the bottom
            ManualEntryBar(viewModel: viewModel)
                .padding(.bottom, 8)
        }
        .onAppear { viewModel.startSession() }
        .onDisappear { viewModel.stopSession() }
    }

    private var detectedItemsOverlay: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(viewModel.detectedItems) { item in
                    DetectedItemCard(item: item, viewModel: viewModel)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(.ultraThinMaterial)
    }
#endif

    // MARK: macOS placeholder

    private var macOSPlaceholder: some View {
        VStack(spacing: 16) {
            Image(systemName: "camera.slash")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("Camera not available on this platform")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Camera Permission Denied View

#if os(iOS)
private struct CameraPermissionDeniedView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "camera.fill")
                .font(.system(size: 56))
                .foregroundColor(.secondary)

            Text("Camera Access Required")
                .font(.title2.bold())

            Text("LunchBox Prep needs camera access to scan food items. Please enable it in Settings.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .font(.headline)
            .padding(.horizontal, 32)
            .padding(.vertical, 12)
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Camera Preview (UIViewRepresentable)

private struct CameraPreviewView: UIViewRepresentable {
    let viewModel: ScannerViewModel

    func makeUIView(context: Context) -> CameraPreviewUIView {
        CameraPreviewUIView()
    }

    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {
        uiView.setSession(viewModel.captureSession)
    }
}

/// `UIView` subclass that hosts an `AVCaptureVideoPreviewLayer`.
final class CameraPreviewUIView: UIView {
    private let previewLayer = AVCaptureVideoPreviewLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        previewLayer.videoGravity = .resizeAspectFill
        layer.addSublayer(previewLayer)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer.frame = bounds
    }

    func setSession(_ session: AVCaptureSession?) {
        guard previewLayer.session !== session else { return }
        previewLayer.session = session
    }
}

// MARK: - Detected Item Card

private struct DetectedItemCard: View {
    let item: DetectedItem
    let viewModel: ScannerViewModel

    var body: some View {
        VStack(spacing: 8) {
            Text(item.name)
                .font(.subheadline.bold())
                .lineLimit(2)
                .multilineTextAlignment(.center)

            HStack(spacing: 8) {
                Button {
                    viewModel.confirm(item)
                } label: {
                    Label("Confirm", systemImage: "checkmark")
                        .font(.caption.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }

                Button {
                    viewModel.dismiss(item)
                } label: {
                    Label("Dismiss", systemImage: "xmark")
                        .font(.caption.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.red.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
        }
        .padding(12)
        .background(Color(.systemBackground).opacity(0.9))
        .cornerRadius(12)
        .shadow(radius: 4)
        .frame(minWidth: 140)
    }
}

// MARK: - Manual Entry Bar

private struct ManualEntryBar: View {
    let viewModel: ScannerViewModel
    @State private var text = ""

    var body: some View {
        HStack(spacing: 8) {
            TextField("Add item manually…", text: $text)
                .textFieldStyle(.roundedBorder)
                .submitLabel(.done)
                .onSubmit(addItem)

            Button("Add", action: addItem)
                .font(.headline)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            ? Color.gray.opacity(0.4)
                            : Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
                .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .cornerRadius(14)
        .padding(.horizontal, 16)
    }

    private func addItem() {
        viewModel.addManualItem(name: text)
        text = ""
    }
}
#endif
