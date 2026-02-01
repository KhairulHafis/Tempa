import SwiftUI
import Foundation

// MARK: - WorkoutSession Model (reuse your existing struct, here for context)

/// Immutable model representing a single workout session.
/// Stores reps completed, duration, date, and the goal at the time of the session.
struct WorkoutSession: Identifiable, Codable {
    let id: UUID
    let repsCompleted: Int
    let timeTaken: Int
    let date: Date
    let goal: Int

    init(repsCompleted: Int, timeTaken: Int, date: Date, goal: Int, id: UUID = UUID()) {
        self.repsCompleted = repsCompleted
        self.timeTaken = timeTaken
        self.date = date
        self.goal = goal
        self.id = id
    }
}

// MARK: - Session Persistence & State

/// Observable store for workout sessions, backed by a `WorkoutSessionRepository`.
/// Publishes session updates and provides basic metrics (e.g., streak calculation).
final class WorkoutSessionStore: ObservableObject {
    @Published private(set) var sessions: [WorkoutSession] = []

    private let repository: WorkoutSessionRepository

    init(repository: WorkoutSessionRepository = UserDefaultsWorkoutSessionRepository()) {
        self.repository = repository
        loadSessions()
    }

    func addSession(_ session: WorkoutSession) {
        sessions.append(session)
        saveSessions()
    }

    func loadSessions() {
        sessions = repository.load()
    }

    private func saveSessions() {
        repository.save(sessions)
    }

    // Calculate streaks or other metrics here
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

