// Uses shared Theme and Model abstractions

import SwiftUI
import AVFoundation


struct CameraSetupView: View {
    let reps: Int
    
    @EnvironmentObject var sessionStore: WorkoutSessionStore
    @Binding var path: [String]
    
    @State private var goToSession = false
    
    @State private var isTaken = false
    @State private var capturedImage: UIImage? = nil
    @State private var barPoints: [CGPoint] = []

    var instructionText: String {
        switch barPoints.count {
        case 0: return "📍 Tap the left-end of the bar"
        case 1: return "📍 Now, tap the right-end of the bar"
        case 2: return "✅ Bar set! Tap 'Reset' or 'Continue'"
        default: return ""
        }
    }

    var body: some View {
        ZStack {
            if let image = capturedImage {
                GeometryReader { geo in
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onEnded { value in
                                    if barPoints.count < 2 {
                                        barPoints.append(value.location)
                                    }
                                }
                        )
                        .overlay(
                            ZStack {
                                ForEach(barPoints, id: \.self) { point in
                                    Circle()
                                        .fill(AppTheme.Colors.primary)
                                        .frame(width: 16, height: 16)
                                        .position(point)
                                }
                                if barPoints.count == 2 {
                                    Path { path in
                                        path.move(to: barPoints[0])
                                        path.addLine(to: barPoints[1])
                                    }
                                    .stroke(AppTheme.Colors.primary, lineWidth: 4)
                                }
                            }
                        )
                }
                .ignoresSafeArea()

                VStack {
                    Text(instructionText)
                        .font(AppTheme.Fonts.headline)
                        .padding()
                        .background(AppTheme.Colors.background.opacity(0.7))
                        .foregroundColor(AppTheme.Colors.textPrimary)
                        .cornerRadius(12)
                        .padding(.top, 50)

                    Spacer()

                    if barPoints.count == 2 {
                        HStack(spacing: 20) {
                            Button {
                                barPoints.removeAll()
                            } label: {
                                Text("🔄 Reset")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(AppTheme.Colors.background.opacity(0.7))
                                    .foregroundColor(AppTheme.Colors.textPrimary)
                                    .cornerRadius(10)
                            }

                            Button("✅ Continue") {
                                goToSession = true
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AppTheme.Colors.accent)
                            .foregroundColor(AppTheme.Colors.textOnAccent)
                            .cornerRadius(10)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                }
            } else {
                CameraPreview(isTaken: $isTaken, capturedImage: $capturedImage)
                    .ignoresSafeArea()

                VStack {
                    Spacer()
                    if !isTaken {
                        Button {
                            isTaken = true
                        } label: {
                            Text("📸 Take Photo")
                                .font(AppTheme.Fonts.headline)
                                .padding()
                                .background(AppTheme.Colors.background.opacity(0.7))
                                .foregroundColor(AppTheme.Colors.textPrimary)
                                .cornerRadius(10)
                        }
                        .padding(.bottom, 40)
                    }
                }
            }

            // ✅ NavigationLink outside the condition so it works
            NavigationLink(
                destination: WorkoutSessionView(path: $path, reps: reps, barPoints: barPoints)
                    .environmentObject(sessionStore),
                isActive: $goToSession
            ) {
                EmptyView()
            }
        }
        .background(AppTheme.Colors.background)
    }
}

struct CameraPreview: UIViewRepresentable {
    @Binding var isTaken: Bool
    @Binding var capturedImage: UIImage?

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        context.coordinator.setupSession(for: view)
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        if isTaken && capturedImage == nil {
            context.coordinator.captureFrameMatchingPreview(from: uiView)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(isTaken: $isTaken, capturedImage: $capturedImage)
    }
}

class PreviewView: UIView {
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }

    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }
}

class Coordinator: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    private let session = AVCaptureSession()
    private let output = AVCaptureVideoDataOutput()
    private var previewView: PreviewView?
    private var captureImage = false

    @Binding var isTaken: Bool
    @Binding var capturedImage: UIImage?

    init(isTaken: Binding<Bool>, capturedImage: Binding<UIImage?>) {
        _isTaken = isTaken
        _capturedImage = capturedImage
    }

    func setupSession(for view: PreviewView) {
        previewView = view

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: device) else {
            return
        }

        session.beginConfiguration()
        if session.canAddInput(input) {
            session.addInput(input)
        }

        if session.canAddOutput(output) {
            output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera.frame.queue"))
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
        session.commitConfiguration()

        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        session.startRunning()
    }

    func captureFrameMatchingPreview(from view: PreviewView) {
        self.captureImage = true
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard captureImage,
              let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }

        captureImage = false
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        let context = CIContext()

        if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
            let mirroredImage = UIImage(cgImage: cgImage, scale: UIScreen.main.scale, orientation: .up)

            DispatchQueue.main.async {
                self.capturedImage = mirroredImage
                self.session.stopRunning()
            }
        }
    }
}

