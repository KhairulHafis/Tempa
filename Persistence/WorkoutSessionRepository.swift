import Foundation

/// Abstraction for persisting and loading workout sessions.
/// Provide a custom implementation to change storage (e.g., SwiftData, files, CloudKit).
protocol WorkoutSessionRepository {
    func load() -> [WorkoutSession]
    func save(_ sessions: [WorkoutSession])
}

/// Default repository implementation backed by `UserDefaults` for simple local persistence.
final class UserDefaultsWorkoutSessionRepository: WorkoutSessionRepository {
    private let storageKey = "sessions"

    func load() -> [WorkoutSession] {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([WorkoutSession].self, from: data) else {
            return []
        }
        return decoded
    }

    func save(_ sessions: [WorkoutSession]) {
        guard let encoded = try? JSONEncoder().encode(sessions) else { return }
        UserDefaults.standard.set(encoded, forKey: storageKey)
    }
}
