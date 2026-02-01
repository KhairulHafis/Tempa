import AVFoundation
import UIKit

/// A UIView backed by `AVCaptureVideoPreviewLayer`, suitable for displaying a camera feed.
/// Assign an `AVCaptureSession` to `videoPreviewLayer.session` and set `videoGravity` as needed.
final class PreviewView: UIView {
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }

    // Use `AVCaptureVideoPreviewLayer` as the backing layer to render camera frames.
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }
}

