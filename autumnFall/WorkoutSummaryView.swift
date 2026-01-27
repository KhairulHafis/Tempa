import SwiftUI

struct WorkoutSummaryView: View {
    let session: WorkoutSession

    var body: some View {
        VStack(spacing: 20) {
            Text("Workout Summary 💪")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.black)

            VStack(spacing: 8) {
                Text("📅 \(session.date.formatted(date: .abbreviated, time: .shortened))")
                Text("🎯 Goal: \(session.goal) reps")
                Text("✅ Completed: \(session.repsCompleted) reps")
                Text("⏱️ Time: \(session.timeTaken) seconds")
                Text(session.repsCompleted >= session.goal ? "🏆 Goal Met!" : "❌ Goal Missed")
                    .font(.headline)
                    .foregroundColor(session.repsCompleted >= session.goal ? .green : .red)
            }
            .foregroundColor(.black)

            Spacer()

            NavigationLink(destination: ContentView()) {
                Label("Back to Home", systemImage: "house")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.brown)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(red: 0.96, green: 0.90, blue: 0.80))
        .navigationBarBackButtonHidden(true)
    }
}
