import SwiftUI
import Foundation
//import WorkoutSessionStore

struct WorkoutSummaryView: View {
    let session: WorkoutSession
    @EnvironmentObject private var workoutSessionStore: WorkoutSessionStore
    @Binding var path: [String]

    var body: some View {
        VStack(spacing: 20) {
            Text("Workout Summary 💪")
                .font(AppTheme.Fonts.largeTitleBold)
                .foregroundColor(AppTheme.Colors.textPrimary)

            VStack(spacing: 8) {
                Text("📅 \(session.date.formatted(date: Foundation.Date.FormatStyle.DateStyle.abbreviated, time: Foundation.Date.FormatStyle.TimeStyle.shortened))")
                Text("🎯 Goal: \(session.goal) reps")
                Text("✅ Completed: \(session.repsCompleted) reps")
                Text("⏱️ Time: \(session.timeTaken) seconds")
                Text(session.repsCompleted >= session.goal ? "🏆 Goal Met!" : "❌ Goal Missed")
                    .font(AppTheme.Fonts.headline)
                    .foregroundColor(session.repsCompleted >= session.goal ? AppTheme.Colors.success : AppTheme.Colors.failure)
            }
            .foregroundColor(AppTheme.Colors.textPrimary)

            Spacer()

            Button(action: { path.removeAll() }) {
                Label("Back to Home", systemImage: "house")
                    .font(AppTheme.Fonts.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(AppTheme.Colors.accent)
                    .foregroundColor(AppTheme.Colors.textOnAccent)
                    .cornerRadius(12)
            }
        }
        .padding()
        .background(AppTheme.Colors.backgroundSecondary)
        .navigationBarBackButtonHidden(true)
    }
}
