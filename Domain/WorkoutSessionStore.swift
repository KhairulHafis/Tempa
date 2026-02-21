import Combine
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
@MainActor
final class WorkoutSessionStore: ObservableObject {
    @Published private(set) var sessions: [WorkoutSession] = []
    @Published private(set) var syncErrorMessage: String?

    private let repository: WorkoutSessionRepository
    private let cloudService: SupabaseWorkoutSessionService?
    private var authStoreCancellable: AnyCancellable?
    private var activeSession: AuthSession?

    init(
        repository: WorkoutSessionRepository = UserDefaultsWorkoutSessionRepository(),
        cloudService: SupabaseWorkoutSessionService? = try? SupabaseWorkoutSessionService()
    ) {
        self.repository = repository
        self.cloudService = cloudService
    }

    /// Binds workout history to auth state. Call once from app startup.
    func bind(to authStore: AuthStore) {
        guard authStoreCancellable == nil else {
            return
        }

        authStoreCancellable = authStore.$session
            .receive(on: DispatchQueue.main)
            .sink { [weak self] authSession in
                self?.handleSessionChange(authSession)
            }
    }

    func addSession(_ session: WorkoutSession) {
        sessions.append(session)
        saveSessionsToCache()

        guard let activeSession,
              let cloudService else {
            return
        }

        let accessToken = activeSession.accessToken
        Task { [weak self] in
            do {
                try await cloudService.upsertSession(session, accessToken: accessToken)
            } catch {
                await MainActor.run {
                    self?.syncErrorMessage = error.localizedDescription
                }
            }
        }
    }

    func refreshFromCloud() async {
        guard let activeSession else {
            return
        }

        await fetchCloudSessions(for: activeSession.userID, accessToken: activeSession.accessToken)
    }

    private func handleSessionChange(_ session: AuthSession?) {
        syncErrorMessage = nil
        activeSession = session

        guard let session else {
            sessions = []
            return
        }

        sessions = repository.load(for: session.userID)
        Task { [weak self] in
            await self?.fetchCloudSessions(for: session.userID, accessToken: session.accessToken)
        }
    }

    private func fetchCloudSessions(for userID: String, accessToken: String) async {
        guard let cloudService else {
            return
        }

        do {
            let fetched = try await cloudService.fetchSessions(accessToken: accessToken)

            // If auth changed while request was in-flight, do not apply stale data.
            guard activeSession?.userID == userID else {
                return
            }

            sessions = fetched
            saveSessionsToCache()
        } catch {
            guard activeSession?.userID == userID else {
                return
            }

            syncErrorMessage = error.localizedDescription
        }
    }

    private func saveSessionsToCache() {
        guard let activeUserID = activeSession?.userID else {
            return
        }

        repository.save(sessions, for: activeUserID)
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
