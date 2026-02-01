import SwiftUI
import AVFoundation
import Vision

/// A SwiftUI wrapper that displays a live camera preview and publishes body joint updates via Vision.
///
/// Usage:
/// ```swift
/// CameraView(onBodyUpdate: { joints in
///     // consume normalized joints (0...1)
/// })
/// ```
///
/// Lifecycle: Starts the capture session when attached to a `PreviewView` and stops it when dismantled.
struct CameraView: UIViewRepresentable {
    var onBodyUpdate: ([VNHumanBodyPoseObservation.JointName: CGPoint]) -> Void

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        context.coordinator.attach(to: view)
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {}

    static func dismantleUIView(_ uiView: PreviewView, coordinator: Coordinator) {
        coordinator.stop()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onBodyUpdate: onBodyUpdate)
    }

    /// Coordinates the camera service lifecycle and connects the session to the `PreviewView`.
    final class Coordinator {
        private let service: VisionBodyPoseService

        init(onBodyUpdate: @escaping ([VNHumanBodyPoseObservation.JointName: CGPoint]) -> Void) {
            self.service = VisionBodyPoseService(onUpdate: onBodyUpdate)
        }

        /// Attaches the camera session to the preview and starts streaming.
        func attach(to view: PreviewView) {
            view.videoPreviewLayer.session = service.session
            view.videoPreviewLayer.videoGravity = .resizeAspectFill
            service.start()
        }

        /// Stops the camera session.
        func stop() {
            service.stop()
        }
    }
}
