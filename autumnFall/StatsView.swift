import SwiftUI
import Charts
//import Theme
//import WorkoutSessionStore

struct StatsView: View {
    @EnvironmentObject var sessionStore: WorkoutSessionStore

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 📊 Title + Streak
                Text("📊 Your Stats")
                    .font(AppTheme.Fonts.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.Colors.primary)

                Text("🔥 Current Streak: \(sessionStore.calculateStreak()) day\(sessionStore.calculateStreak() == 1 ? "" : "s")")
                    .font(AppTheme.Fonts.headline)
                    .foregroundColor(AppTheme.Colors.primary)

                if sessionStore.sessions.isEmpty {
                    Text("No workout data yet.")
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .padding(.top, 40)
                } else {
                    // 📈 Chart with Dates (showing only recent 4)
                    Chart {
                        ForEach(sessionStore.sessions.suffix(4)) { session in
                            LineMark(
                                x: .value("Date", session.date),
                                y: .value("Reps", session.repsCompleted)
                            )
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(AppTheme.Colors.accent)
                            .symbol(Circle())
                            .lineStyle(StrokeStyle(lineWidth: 2))

                            PointMark(
                                x: .value("Date", session.date),
                                y: .value("Reps", session.repsCompleted)
                            )
                            .annotation(position: .top) {
                                Text(session.date.formatted(.dateTime.day().month(.abbreviated)))
                                    .font(AppTheme.Fonts.caption)
                                    .foregroundColor(AppTheme.Colors.accent)
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

                    // 🗂 History Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("📅 Workout History")
                            .font(AppTheme.Fonts.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(AppTheme.Colors.primary)

                        ForEach(sessionStore.sessions.reversed()) { session in
                            VStack(alignment: .leading, spacing: 6) {
                                Text("🗓 \(session.date.formatted(date: .abbreviated, time: .shortened))")
                                    .fontWeight(.semibold)
                                Text("🏋️ Reps: \(session.repsCompleted) of \(session.goal)")
                                Text("⏱ Time: \(session.timeTaken) seconds")
                                Text("Goal Met: \(session.repsCompleted >= session.goal ? "✅ Yes" : "❌ No")")
                                    .foregroundColor(session.repsCompleted >= session.goal ? AppTheme.Colors.success : AppTheme.Colors.failure)
                            }
                            .foregroundColor(AppTheme.Colors.primary)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(AppTheme.Colors.background)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                        }
                    }
                    .padding(.horizontal)
                }

                Spacer()
            }
            .padding(.top)
        }
        .background(AppTheme.Colors.background.ignoresSafeArea())
    }
}
