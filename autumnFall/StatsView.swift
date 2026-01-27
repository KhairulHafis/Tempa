import SwiftUI
import Charts

struct StatsView: View {
    @State private var sessions: [WorkoutSession] = []

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 📊 Title + Streak
                Text("📊 Your Stats")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.black)

                Text("🔥 Current Streak: \(calculateStreak()) day\(calculateStreak() == 1 ? "" : "s")")
                    .font(.headline)
                    .foregroundColor(.black)

                if sessions.isEmpty {
                    Text("No workout data yet.")
                        .foregroundColor(.gray)
                        .padding(.top, 40)
                } else {
                    // 📈 Chart with Dates (showing only recent 4)
                    Chart {
                        ForEach(sessions.suffix(4)) { session in
                            LineMark(
                                x: .value("Date", session.date),
                                y: .value("Reps", session.repsCompleted)
                            )
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(Color.brown)
                            .symbol(Circle())
                            .lineStyle(StrokeStyle(lineWidth: 2))

                            PointMark(
                                x: .value("Date", session.date),
                                y: .value("Reps", session.repsCompleted)
                            )
                            .annotation(position: .top) {
                                Text(session.date.formatted(.dateTime.day().month(.abbreviated)))
                                    .font(.caption2)
                                    .foregroundColor(.brown)
                            }
                        }
                    }
                    .chartXAxis {
                        AxisMarks(values: .automatic(desiredCount: 4)) { value in
                            AxisGridLine()
                            AxisValueLabel {
                                if let date = value.as(Date.self) {
                                    Text(date.formatted(.dateTime.day().month(.abbreviated)))
                                }
                            }
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading)
                    }
                    .frame(height: 200)
                    .padding(.horizontal)

                    .frame(height: 200)
                    .padding(.horizontal)

                    // 🗂 History Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("📅 Workout History")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.black)

                        ForEach(sessions.reversed()) { session in
                            VStack(alignment: .leading, spacing: 6) {
                                Text("🗓 \(session.date.formatted(date: .abbreviated, time: .shortened))")
                                    .fontWeight(.semibold)
                                Text("🏋️ Reps: \(session.repsCompleted) of \(session.goal)")
                                Text("⏱ Time: \(session.timeTaken) seconds")
                                Text("Goal Met: \(session.repsCompleted >= session.goal ? "✅ Yes" : "❌ No")")
                                    .foregroundColor(session.repsCompleted >= session.goal ? .green : .red)
                            }
                            .foregroundColor(.black)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: .gray.opacity(0.1), radius: 4, x: 0, y: 2)
                        }
                    }
                    .padding(.horizontal)
                }

                Spacer()
            }
            .padding(.top)
        }
        .background(Color(red: 0.96, green: 0.90, blue: 0.80).ignoresSafeArea())
        .onAppear { loadSessions() }
    }

    func loadSessions() {
        if let data = UserDefaults.standard.data(forKey: "sessions") {
            if let decoded = try? JSONDecoder().decode([WorkoutSession].self, from: data) {
                sessions = decoded
            }
        }
    }

    func calculateStreak() -> Int {
        let sorted = sessions.sorted { $0.date > $1.date }
        var streak = 0
        var currentDate = Calendar.current.startOfDay(for: Date())

        for session in sorted {
            let sessionDate = Calendar.current.startOfDay(for: session.date)
            if sessionDate == currentDate, session.repsCompleted >= session.goal {
                streak += 1
                currentDate = Calendar.current.date(byAdding: .day, value: -1, to: currentDate)!
            } else if sessionDate == Calendar.current.date(byAdding: .day, value: -1, to: currentDate),
                      session.repsCompleted >= session.goal {
                streak += 1
                currentDate = Calendar.current.date(byAdding: .day, value: -1, to: currentDate)!
            } else {
                break
            }
        }

        return streak
    }
}
