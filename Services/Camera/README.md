// Tempa App – Architecture and Codebase Guide

// ## Overview
// This app is organized for scalability and modularity. The codebase is split into clear layers and features, with normalized geometry for camera/Vision data and a unified camera stack.

// ## Project Structure
// - Domain
//   - Core models and pure logic
//   - Files: `WorkoutSessionStore.swift` (contains `WorkoutSession` model), `RepCounter.swift`
// - Persistence
//   - Storage abstractions and implementations
//   - Files: `WorkoutSessionRepository.swift` (protocol), `UserDefaultsWorkoutSessionRepository` (default)
// - Services
//   - Platform integrations and external APIs
//   - Camera
//     - `BodyPoseService-Camera.swift` (`VisionBodyPoseService`)
//     - `PreviewView-Camera.swift` (`PreviewView`)
//     - `CameraView.swift` (SwiftUI wrapper)
// - Features
//   - User-facing screens grouped by function
//   - WorkoutSession
//     - `WorkoutSessionView.swift`
//     - `WorkoutSessionViewModel.swift`
//   - Overlays
//     - `BarOverlayView.swift`
//     - `PoseOverlayView.swift`
//   - CameraSetup
//     - `CameraSetupView.swift`
//   - Workout
//     - `WorkoutView.swift`
//   - Stats
//     - `StatsView.swift`
//   - Summary
//     - `WorkoutSummaryView.swift`
// - Shared
//   - Reusable UI and theme
//   - Components: `EnlargedPulsingCircle.swift`
//   - Theme: `Theme.swift`
// - Tests
//   - `RepCounterTests.swift` (guarded by `#if canImport(Testing)`)

// ## Key Design Choices

// ### Normalized Coordinates
// - Vision outputs are normalized (0...1) with y flipped to match UIKit.
// - `WorkoutSessionViewModel` consumes normalized geometry and performs rep detection.
// - Views denormalize for drawing only (via `GeometryReader`).

// ### Separation of Concerns
// - Services handle platform work (AVCapture + Vision).
// - ViewModel owns session state (timer, countdown, rep counting) and emits `isFinished`.
// - Views remain declarative and compose overlays and camera preview.

// ### Testability
// - `RepCounter` is a pure state machine with unit tests.
// - Persistence is abstracted via `WorkoutSessionRepository` for easy mocking.

// ## Camera Stack
// - `VisionBodyPoseService` (engine)
//   - Configures `AVCaptureSession` and runs `VNDetectHumanBodyPoseRequest`.
//   - Emits normalized joints via a callback.
// - `PreviewView` (screen)
//   - UIKit `UIView` backed by `AVCaptureVideoPreviewLayer`.
// - `CameraView` (bridge)
//   - SwiftUI `UIViewRepresentable` that attaches the service’s session to the preview and forwards updates.

// ## Persistence
// - `WorkoutSessionRepository`
//   - Protocol to abstract persistence.
// - `UserDefaultsWorkoutSessionRepository`
//   - Default local storage implementation.
// - `WorkoutSessionStore`
//   - Observable store that publishes sessions and basic metrics (e.g., streak).

// ## Conventions
// - Access control: Use `final` where types aren’t intended for subclassing. Limit visibility to `private`/`internal` unless needed.
// - Documentation: Public/shared components include doc comments explaining usage and lifecycle.
// - Refactors only: Structural improvements without adding features.

// ## Development Tips
// - Clean build after structural changes: Shift+Cmd+K, then Cmd+B.
// - If you see “ambiguous” or “invalid redeclaration” errors, search for duplicate symbols:
//   - `PreviewView`
//   - `CameraView`
//   - `VisionBodyPoseService`

// ## Running Tests
// - `RepCounterTests.swift` uses the Swift Testing framework and is guarded with `#if canImport(Testing)`.
// - Add it to a test target (Xcode 15+) to run tests.
// - Use Product > Test or the Test navigator.
