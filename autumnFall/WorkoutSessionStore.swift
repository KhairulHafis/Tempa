import SwiftUI
import Foundation

// MARK: - WorkoutSession Model (reuse your existing struct, here for context)
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
class WorkoutSessionStore: ObservableObject {
    @Published private(set) var sessions: [WorkoutSession] = []

    private let storageKey = "sessions"

    init() {
        loadSessions()
    }

    func addSession(_ session: WorkoutSession) {
        sessions.append(session)
        saveSessions()
    }

    func loadSessions() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([WorkoutSession].self, from: data) else {
            sessions = []
            return
        }
        sessions = decoded
    }

    private func saveSessions() {
        guard let encoded = try? JSONEncoder().encode(sessions) else { return }
        UserDefaults.standard.set(encoded, forKey: storageKey)
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
