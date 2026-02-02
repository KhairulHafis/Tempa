import AVFoundation
import Vision
import UIKit

/// A reusable service that configures an `AVCaptureSession` and performs Vision body pose detection.
///
/// - Output: Emits normalized joint coordinates (0...1, with y flipped to match UIKit).
/// - Lifecycle: Call `start()` to begin streaming and `stop()` to end.
final class VisionBodyPoseService: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    // Public session to attach to preview layers
    let session = AVCaptureSession()

    private let output = AVCaptureVideoDataOutput()
    private var onUpdate: (([VNHumanBodyPoseObservation.JointName: CGPoint]) -> Void)?

    init(onUpdate: @escaping ([VNHumanBodyPoseObservation.JointName: CGPoint]) -> Void) {
        self.onUpdate = onUpdate
        super.init()
        configureSession()
    }

    deinit {
        stop()
    }

    /// Starts the capture session if not already running.
    func start() {
        guard !session.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.startRunning()
        }
    }

    /// Stops the capture session if running.
    func stop() {
        guard session.isRunning else { return }
        session.stopRunning()
    }

    /// Configures the capture session inputs/outputs and sets orientation/mirroring.
    private func configureSession() {
        session.beginConfiguration()
        defer { session.commitConfiguration() }

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: device) else { return }

        if session.canAddInput(input) { session.addInput(input) }
        if session.canAddOutput(output) {
            output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "vision.body"))
            output.alwaysDiscardsLateVideoFrames = true
            session.addOutput(output)
        }

        if let connection = output.connection(with: .video) {
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = .portrait
            }
            if connection.isVideoMirroringSupported {
                connection.isVideoMirrored = true
            }
        }

        session.sessionPreset = .high
    }

    /// Captures sample buffers and performs Vision body pose detection, yielding normalized joints on the main thread.
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        // Buffer is already portrait and mirrored by AVCaptureConnection; use .up to avoid double mirroring.
        let requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up)
        let request = VNDetectHumanBodyPoseRequest { [weak self] req, _ in
            guard let observations = req.results as? [VNHumanBodyPoseObservation],
                  let first = observations.first else { return }
            do {
                let recognizedPoints = try first.recognizedPoints(.all)
                let joints: [VNHumanBodyPoseObservation.JointName] = [.neck, .leftShoulder, .rightShoulder, .leftWrist, .rightWrist]
                let points = joints.compactMap { joint in
                    recognizedPoints[joint].map { (joint, CGPoint(x: $0.location.x, y: 1 - $0.location.y)) }
                }
                let mapped = Dictionary(uniqueKeysWithValues: points)
                DispatchQueue.main.async { [weak self] in
                    self?.onUpdate?(mapped)
                }
            } catch {
                // Ignore errors silently for now
            }
        }
        try? requestHandler.perform([request])
    }
}
