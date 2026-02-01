import SwiftUI
import Vision
import CoreGraphics

/// View model that manages a workout session’s lifecycle.
///
/// Responsibilities:
/// - Tracks time elapsed and rep count
/// - Starts a countdown when wrists align with the bar
/// - Consumes normalized (0...1) pose inputs and bar geometry
/// - Emits `isFinished` when the goal rep count is reached
///
/// Usage:
/// - Call `handleBodyUpdate(_:)` with normalized joints from the camera pipeline.
/// - The view observes published properties to render state.
/// - Call `stop()` to cancel timers and clean up when the view disappears.
@MainActor
final class WorkoutSessionViewModel: ObservableObject {
    // Goal
    let goalReps: Int

    // Geometry (normalized 0...1)
    @Published var barY: CGFloat = 0

    // Session state
    @Published var repCount = 0
    @Published var timeElapsed = 0
    @Published var timerStarted = false
    @Published var showCountdown = false
    @Published var countdownValue = 3
    @Published var isFinished = false

    // Tracked joints
    @Published var neckPoint: CGPoint? = nil
    @Published var leftWrist: CGPoint? = nil
    @Published var rightWrist: CGPoint? = nil
    @Published var leftShoulder: CGPoint? = nil
    @Published var rightShoulder: CGPoint? = nil

    // Internals
    private var timerTask: Task<Void, Never>?
    private var countdownTask: Task<Void, Never>?
    private let clock = ContinuousClock()
    private(set) var startTime: Date?

    private var repCounter = RepCounter()
    private let repConfig = RepDetectionConfig()

    private let wristTolerance: CGFloat = 0.036
    private let wristBarYOffset: CGFloat = 0.024

    init(goalReps: Int) {
        self.goalReps = goalReps
    }

    // MARK: - Public API

    /// Cancels any active countdown/timer tasks and resets `timerStarted`.
    func stop() {
        timerTask?.cancel()
        timerTask = nil
        countdownTask?.cancel()
        countdownTask = nil
        timerStarted = false
    }

    /// Starts the session timer using Swift Concurrency. Safe to call once; subsequent calls are ignored.
    func startTimer() {
        guard !timerStarted else { return }
        timerStarted = true
        startTime = Date()
        timerTask = Task { [weak self] in
            guard let self = self else { return }
            while !Task.isCancelled {
                try? await clock.sleep(for: Duration.seconds(1))
                if Task.isCancelled { break }
                self.timeElapsed += 1
            }
        }
    }

    /// Begins a 3-second countdown using Swift Concurrency, then starts the timer.
    func startCountdown() {
        guard !timerStarted && !showCountdown else { return }
        showCountdown = true
        countdownValue = 3
        countdownTask?.cancel()
        countdownTask = Task { [weak self] in
            guard let self = self else { return }
            while !Task.isCancelled {
                try? await clock.sleep(for: Duration.seconds(1))
                if Task.isCancelled { break }
                if self.countdownValue > 1 {
                    self.countdownValue -= 1
                } else {
                    self.showCountdown = false
                    self.startTimer()
                    break
                }
            }
        }
    }

    /// Returns true when both wrists are within a small normalized tolerance of the bar y-position.
    func wristsAreNearBar() -> Bool {
        guard let lw = leftWrist, let rw = rightWrist else { return false }
        let adjustedBarY = barY + wristBarYOffset
        return abs(lw.y - adjustedBarY) < wristTolerance && abs(rw.y - adjustedBarY) < wristTolerance
    }

    /// Consumes normalized joints (0...1), updates pose state, and advances rep detection.
    /// When the goal rep count is reached, sets `isFinished` and stops timers.
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
            if repCounter.update(avgY: avgY, barY: barY, config: repConfig) {
                repCount += 1
                if repCount == goalReps {
                    isFinished = true
                    stop()
                }
            }
        }
    }

    var startDate: Date? { startTime }
}

