import SwiftUI
import Charts
//import Theme
//import WorkoutSessionStore

/// Displays charts and workout history using data from `WorkoutSessionStore`.
///
/// Shows a recent reps line chart and a list of past sessions with goal completion status.
struct StatsView: View {
    @EnvironmentObject var sessionStore: WorkoutSessionStore
    private let chartBlue = Color.blue

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

                if let syncErrorMessage = sessionStore.syncErrorMessage {
                    Text("Cloud sync issue: \(syncErrorMessage)")
                        .font(AppTheme.Fonts.caption)
                        .foregroundColor(AppTheme.Colors.error)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

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
                            .foregroundStyle(chartBlue)
                            .symbol(Circle())
                            .lineStyle(StrokeStyle(lineWidth: 2))

                            PointMark(
                                x: .value("Date", session.date),
                                y: .value("Reps", session.repsCompleted)
                            )
                            .annotation(position: .top) {
                                Text(session.date.formatted(.dateTime.day().month(.abbreviated)))
                                    .font(AppTheme.Fonts.caption)
                                    .foregroundColor(chartBlue)
                            }
                        }
                    }
                    .chartXAxis {
                        AxisMarks(values: .automatic(desiredCount: 4)) { value in
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 1))
                                .foregroundStyle(Color.black)
                            AxisValueLabel {
                                if let date = value.as(Date.self) {
                                    Text(date.formatted(.dateTime.day().month(.abbreviated)))
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading) {
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 1))
                                .foregroundStyle(Color.black)
                            AxisValueLabel()
                                .foregroundStyle(Color.red)
                        }
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
