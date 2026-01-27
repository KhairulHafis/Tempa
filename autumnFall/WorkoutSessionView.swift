// Uses shared Theme and Model abstractions

import SwiftUI
import AVFoundation
import Vision
//import WorkoutSessionStore

struct WorkoutSessionView: View {
    @EnvironmentObject var sessionStore: WorkoutSessionStore
    
    let reps: Int
    let barPoints: [CGPoint]

    @State private var repCount = 0
    @State private var timeElapsed = 0
    @State private var timer: Timer?
    @State private var timerStarted = false
    @State private var showCountdown = false
    @State private var countdownValue = 3
    @State private var goingDown = false
    @State private var isRepLocked = false
    @State private var barY: CGFloat = 0
    @State private var showSummary = false
    @State private var startTime: Date?
    @State private var endTime: Date?

    @State private var neckPoint: CGPoint? = nil
    @State private var leftWrist: CGPoint? = nil
    @State private var rightWrist: CGPoint? = nil
    @State private var leftShoulder: CGPoint? = nil
    @State private var rightShoulder: CGPoint? = nil
    @State private var lastShoulderY: CGFloat?

    var body: some View {
        ZStack {
            CameraView(onBodyUpdate: handleBodyUpdate)

            GeometryReader { geo in
                let scaleX = geo.size.width / 390
                let scaleY = geo.size.height / 844
                let yOffset: CGFloat = 0 // alter this value to change the bar y-axis
                let scaledPoints = barPoints.map {
                    CGPoint(x: $0.x * scaleX, y: ($0.y * scaleY) + yOffset)
                }

                if scaledPoints.count == 2 {
                    Path { path in
                        path.move(to: scaledPoints[0])
                        path.addLine(to: scaledPoints[1])
                    }
                    .stroke(wristsAreNearBar() ? AppTheme.Colors.success : AppTheme.Colors.failure, lineWidth: 4)

                    ForEach(scaledPoints, id: \.self) { point in
                        Circle()
                            .fill(AppTheme.Colors.failure)
                            .frame(width: 16, height: 16)
                            .position(point)
                    }

                    Color.clear.onAppear {
                        barY = (scaledPoints[0].y + scaledPoints[1].y) / 2
                    }
                }
            }

            Path { path in
                if let neck = neckPoint, let lShoulder = leftShoulder, let rShoulder = rightShoulder {
                    path.move(to: neck)
                    path.addLine(to: lShoulder)
                    path.move(to: neck)
                    path.addLine(to: rShoulder)
                }
                if let lShoulder = leftShoulder, let lWrist = leftWrist {
                    path.move(to: lShoulder)
                    path.addLine(to: lWrist)
                }
                if let rShoulder = rightShoulder, let rWrist = rightWrist {
                    path.move(to: rShoulder)
                    path.addLine(to: rWrist)
                }
            }
            .stroke(AppTheme.Colors.success, lineWidth: 4)

            if let neck = neckPoint {
                EnlargedPulsingCircle().position(neck)
            }

            if let lw = leftWrist {
                Circle().stroke(AppTheme.Colors.success, lineWidth: 3).frame(width: 20, height: 20).position(lw)
            }
            if let rw = rightWrist {
                Circle().stroke(AppTheme.Colors.success, lineWidth: 3).frame(width: 20, height: 20).position(rw)
            }

            VStack {
                Spacer()
                VStack(spacing: 12) {
                    Button(action: endWorkout) {
                        Text("End Session")
                            .font(AppTheme.Fonts.subheadline)
                            .padding(10)
                            .background(AppTheme.Colors.failure.opacity(0.8))
                            .foregroundColor(Color.white)
                            .cornerRadius(10)
                    }
                    VStack(spacing: 8) {
                        Text("Reps: \(repCount) / \(reps)")
                            .font(AppTheme.Fonts.title.bold())
                            .foregroundColor(Color.white)
                        Text("⏱ \(timeElapsed) sec")
                            .foregroundColor(Color.white)
                    }
                }
                .padding(.bottom, 60)
            }

            if !timerStarted {
                VStack {
                    Text(wristsAreNearBar() ? "Wrist position OK – Starting soon..." : "Align both wrists with the bar to begin")
                        .foregroundColor(Color.white)
                        .padding(10)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(10)
                    if showCountdown {
                        Text("\(countdownValue)")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(Color.white)
                            .padding(.top, 10)
                    }
                }
                .padding(.top, 100)
            }

            NavigationLink(destination: WorkoutSummaryView(session: WorkoutSession(repsCompleted: repCount, timeTaken: timeElapsed, date: startTime ?? Date(), goal: reps)), isActive: $showSummary) {
                EmptyView()
            }
        }
        .ignoresSafeArea()
        .navigationBarBackButtonHidden(true)
        .onDisappear { timer?.invalidate() }
    }

    func startTimer() {
        guard !timerStarted else { return }
        timerStarted = true
        startTime = Date()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in timeElapsed += 1 }
    }

    func startCountdown() {
        showCountdown = true
        countdownValue = 3
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { countdownTimer in
            if countdownValue > 1 {
                countdownValue -= 1
            } else {
                countdownTimer.invalidate()
                showCountdown = false
                startTimer()
            }
        }
    }

    func wristsAreNearBar() -> Bool {
        guard let lw = leftWrist, let rw = rightWrist else { return false }
        let tolerance: CGFloat = 30
        let adjustedBarY = barY + 20
        return abs(lw.y - adjustedBarY) < tolerance && abs(rw.y - adjustedBarY) < tolerance
    }

    func handleBodyUpdate(_ points: [VNHumanBodyPoseObservation.JointName: CGPoint]) {
        neckPoint = points[.neck]
        leftShoulder = points[.leftShoulder]
        rightShoulder = points[.rightShoulder]
        leftWrist = points[.leftWrist]
        rightWrist = points[.rightWrist]

        if wristsAreNearBar() && !timerStarted && !showCountdown {
            startCountdown()
        }

        guard timerStarted else { return }

        if let lY = leftShoulder?.y, let rY = rightShoulder?.y, let nY = neckPoint?.y {
            let avgY = (lY + rY + nY) / 3

            if let lastY = lastShoulderY {
                let velocity = avgY - lastY

                if !goingDown && velocity < -4 && avgY < barY + 40 {
                    goingDown = true
                } else if goingDown && velocity > 4 && avgY > barY + 60 {
                    repCount += 1
                    goingDown = false
                    isRepLocked = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        isRepLocked = false
                    }
                    if repCount == reps {
                        endWorkout()
                    }
                }
            }
            lastShoulderY = avgY
        }
    }

    func endWorkout() {
        timer?.invalidate()
        endTime = Date()
        sessionStore.addSession(WorkoutSession(repsCompleted: repCount, timeTaken: timeElapsed, date: startTime ?? Date(), goal: reps))
        showSummary = true
    }
}

struct EnlargedPulsingCircle: View {
    @State private var animate = false
    var body: some View {
        Circle()
            .stroke(Color.blue, lineWidth: 4)
            .frame(width: 50, height: 50)
            .scaleEffect(animate ? 1.2 : 1.0)
            .opacity(animate ? 0.5 : 1.0)
            .onAppear {
                withAnimation(Animation.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                    animate = true
                }
            }
    }
}

struct CameraView: UIViewRepresentable {
    var onBodyUpdate: ([VNHumanBodyPoseObservation.JointName: CGPoint]) -> Void

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        context.coordinator.setup(for: view)
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onBodyUpdate: onBodyUpdate)
    }

    class Coordinator: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
        private let session = AVCaptureSession()
        private let output = AVCaptureVideoDataOutput()
        private var previewView: PreviewView?
        var onBodyUpdate: ([VNHumanBodyPoseObservation.JointName: CGPoint]) -> Void

        init(onBodyUpdate: @escaping ([VNHumanBodyPoseObservation.JointName: CGPoint]) -> Void) {
            self.onBodyUpdate = onBodyUpdate
        }

        func setup(for view: PreviewView) {
            self.previewView = view
            session.beginConfiguration()

            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
                  let input = try? AVCaptureDeviceInput(device: device) else { return }

            if session.canAddInput(input) { session.addInput(input) }
            if session.canAddOutput(output) {
                output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "vision.body"))
                session.addOutput(output)
            }

            session.commitConfiguration()
            view.videoPreviewLayer.session = session
            view.videoPreviewLayer.videoGravity = .resizeAspectFill
            DispatchQueue.global(qos: .userInitiated).async {
                self.session.startRunning()
            }
        }

        func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
            guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
            let requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .leftMirrored)
            let request = VNDetectHumanBodyPoseRequest { [weak self] req, _ in
                guard let observations = req.results as? [VNHumanBodyPoseObservation],
                      let first = observations.first else { return }
                do {
                    let recognizedPoints = try first.recognizedPoints(.all)
                    let joints: [VNHumanBodyPoseObservation.JointName] = [.neck, .leftShoulder, .rightShoulder, .leftWrist, .rightWrist]
                    let points = joints.compactMap { joint in
                        recognizedPoints[joint].map { (joint, CGPoint(x: $0.location.x * 390, y: (1 - $0.location.y) * 844)) }
                    }
                    let mapped = Dictionary(uniqueKeysWithValues: points)
                    DispatchQueue.main.async {
                        self?.onBodyUpdate(mapped)
                    }
                } catch { return }
            }
            try? requestHandler.perform([request])
        }
    }
}
