import Foundation

/// Abstraction for persisting and loading workout sessions.
/// Provide a custom implementation to change storage (e.g., SwiftData, files, CloudKit).
protocol WorkoutSessionRepository {
    func load(for userID: String) -> [WorkoutSession]
    func save(_ sessions: [WorkoutSession], for userID: String)
}

/// Default repository implementation backed by `UserDefaults` for simple local persistence.
final class UserDefaultsWorkoutSessionRepository: WorkoutSessionRepository {
    private let storageKeyPrefix = "sessions"
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func load(for userID: String) -> [WorkoutSession] {
        guard let data = userDefaults.data(forKey: storageKey(for: userID)),
              let decoded = try? JSONDecoder().decode([WorkoutSession].self, from: data) else {
            return []
        }
        return decoded
    }

    func save(_ sessions: [WorkoutSession], for userID: String) {
        guard let encoded = try? JSONEncoder().encode(sessions) else { return }
        userDefaults.set(encoded, forKey: storageKey(for: userID))
    }

    private func storageKey(for userID: String) -> String {
        "\(storageKeyPrefix).\(userID)"
    }
}
