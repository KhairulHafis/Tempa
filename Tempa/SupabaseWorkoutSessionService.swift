import Foundation

enum SupabaseWorkoutSessionError: LocalizedError {
    case invalidResponse
    case requestFailed(message: String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Received an unexpected response from Supabase."
        case .requestFailed(let message):
            return message
        }
    }
}

final class SupabaseWorkoutSessionService {
    private let configuration: SupabaseConfiguration
    private let urlSession: URLSession
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let dateFormatter = ISO8601DateFormatter()

    init(
        configuration: SupabaseConfiguration? = nil,
        urlSession: URLSession = .shared
    ) throws {
        self.configuration = try configuration ?? SupabaseConfiguration.load()
        self.urlSession = urlSession
        self.dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    }

    func fetchSessions(accessToken: String) async throws -> [WorkoutSession] {
        let url = try buildURL(
            path: "/rest/v1/workout_sessions",
            queryItems: [
                URLQueryItem(name: "select", value: "id,reps_completed,time_taken,date,goal"),
                URLQueryItem(name: "order", value: "date.asc")
            ]
        )

        let request = baseRequest(url: url, method: "GET", accessToken: accessToken)

        let (data, response) = try await urlSession.data(for: request)
        try validate(response: response, data: data)

        do {
            let payload = try decoder.decode([RemoteWorkoutSession].self, from: data)
            return payload.compactMap { item in
                let id = UUID(uuidString: item.id) ?? UUID()
                guard let date = parsedDate(from: item.date) else {
                    return nil
                }

                return WorkoutSession(
                    repsCompleted: item.repsCompleted,
                    timeTaken: item.timeTaken,
                    date: date,
                    goal: item.goal,
                    id: id
                )
            }
        } catch {
            throw SupabaseWorkoutSessionError.invalidResponse
        }
    }

    func upsertSession(_ session: WorkoutSession, accessToken: String) async throws {
        let url = try buildURL(
            path: "/rest/v1/workout_sessions",
            queryItems: [URLQueryItem(name: "on_conflict", value: "id")]
        )

        var request = baseRequest(url: url, method: "POST", accessToken: accessToken)
        request.setValue("resolution=merge-duplicates,return=minimal", forHTTPHeaderField: "Prefer")

        let payload = RemoteWorkoutSession(
            id: session.id.uuidString,
            repsCompleted: session.repsCompleted,
            timeTaken: session.timeTaken,
            date: dateFormatter.string(from: session.date),
            goal: session.goal
        )
        request.httpBody = try encoder.encode(payload)

        let (data, response) = try await urlSession.data(for: request)
        try validate(response: response, data: data)
    }

    private func baseRequest(url: URL, method: String, accessToken: String) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(configuration.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        return request
    }

    private func buildURL(path: String, queryItems: [URLQueryItem] = []) throws -> URL {
        guard var components = URLComponents(url: configuration.baseURL, resolvingAgainstBaseURL: false) else {
            throw SupabaseWorkoutSessionError.invalidResponse
        }

        components.path = path
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }

        guard let url = components.url else {
            throw SupabaseWorkoutSessionError.invalidResponse
        }
        return url
    }

    private func validate(response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SupabaseWorkoutSessionError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let payload = try? decoder.decode(WorkoutSessionErrorResponse.self, from: data)
            let message = payload?.bestMessage ?? "Supabase request failed with status code \(httpResponse.statusCode)."
            throw SupabaseWorkoutSessionError.requestFailed(message: message)
        }
    }

    private func parsedDate(from value: String) -> Date? {
        if let date = dateFormatter.date(from: value) {
            return date
        }

        let fallback = ISO8601DateFormatter()
        fallback.formatOptions = [.withInternetDateTime]
        return fallback.date(from: value)
    }
}

private struct RemoteWorkoutSession: Codable {
    let id: String
    let repsCompleted: Int
    let timeTaken: Int
    let date: String
    let goal: Int

    enum CodingKeys: String, CodingKey {
        case id
        case repsCompleted = "reps_completed"
        case timeTaken = "time_taken"
        case date
        case goal
    }
}

private struct WorkoutSessionErrorResponse: Decodable {
    let message: String?
    let hint: String?
    let details: String?
    let error: String?

    var bestMessage: String? {
        if let message, !message.isEmpty { return message }
        if let details, !details.isEmpty { return details }
        if let hint, !hint.isEmpty { return hint }
        if let error, !error.isEmpty { return error }
        return nil
    }
}
