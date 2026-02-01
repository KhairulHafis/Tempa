// Uses shared Theme and Model abstractions

import SwiftUI
import Vision
//import WorkoutSessionStore

/// Composes the live camera preview, bar and pose overlays, and the session view model.
///
/// Responsibilities:
/// - Displays the camera feed and overlays normalized pose data
/// - Binds UI to `WorkoutSessionViewModel` state (reps, timer, countdown)
/// - Persists a completed `WorkoutSession` to the store and navigates to summary
struct WorkoutSessionView: View {
    @EnvironmentObject var sessionStore: WorkoutSessionStore
    @Binding var path: [String]

    let reps: Int
    let barPoints: [CGPoint]

    @StateObject private var viewModel: WorkoutSessionViewModel
    @State private var showSummary = false

    init(path: Binding<[String]>, reps: Int, barPoints: [CGPoint]) {
        self._path = path
        self.reps = reps
        self.barPoints = barPoints
        _viewModel = StateObject(wrappedValue: WorkoutSessionViewModel(goalReps: reps))
    }

    var body: some View {
        ZStack {
            CameraView(onBodyUpdate: viewModel.handleBodyUpdate)

            BarOverlayView(
                barPoints: barPoints,
                color: viewModel.wristsAreNearBar() ? AppTheme.Colors.success : AppTheme.Colors.failure,
                onBarYUpdate: { normalized in viewModel.barY = normalized }
            )

            PoseOverlayView(
                neck: viewModel.neckPoint,
                leftShoulder: viewModel.leftShoulder,
                rightShoulder: viewModel.rightShoulder,
                leftWrist: viewModel.leftWrist,
                rightWrist: viewModel.rightWrist
            )

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
                        Text("Reps: \(viewModel.repCount) / \(reps)")
                            .font(AppTheme.Fonts.title.bold())
                            .foregroundColor(Color.white)
                        Text("⏱ \(viewModel.timeElapsed) sec")
                            .foregroundColor(Color.white)
                    }
                }
                .padding(.bottom, 60)
            }

            if !viewModel.timerStarted {
                VStack {
                    Text(viewModel.wristsAreNearBar() ? "Wrist position OK – Starting soon..." : "Align both wrists with the bar to begin")
                        .foregroundColor(Color.white)
                        .padding(10)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(10)
                    if viewModel.showCountdown {
                        Text("\(viewModel.countdownValue)")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(Color.white)
                            .padding(.top, 10)
                    }
                }
                .padding(.top, 100)
            }

            NavigationLink(
                destination: WorkoutSummaryView(
                    session: WorkoutSession(
                        repsCompleted: viewModel.repCount,
                        timeTaken: viewModel.timeElapsed,
                        date: viewModel.startDate ?? Date(),
                        goal: reps
                    ),
                    path: $path
                ),
                isActive: $showSummary
            ) {
                EmptyView()
            }
        }
        .ignoresSafeArea()
        .navigationBarBackButtonHidden(true)
        .onDisappear {
            viewModel.stop()
        }
        .onChange(of: viewModel.isFinished) { finished in
            if finished { endWorkout() }
        }
    }

    func endWorkout() {
        viewModel.stop()
        sessionStore.addSession(WorkoutSession(repsCompleted: viewModel.repCount, timeTaken: viewModel.timeElapsed, date: viewModel.startDate ?? Date(), goal: reps))
        showSummary = true
    }
}

