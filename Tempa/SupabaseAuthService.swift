import Foundation

struct AuthSession: Codable {
    let accessToken: String
    let refreshToken: String
    let expiresAt: Date
    let userID: String
    let email: String?

    var isExpired: Bool {
        Date() >= expiresAt.addingTimeInterval(-30)
    }
}

enum SignUpResult {
    case signedIn(AuthSession)
    case emailConfirmationRequired
}

enum SupabaseAuthError: LocalizedError {
    case invalidResponse
    case missingSession
    case requestFailed(message: String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Received an unexpected response from Supabase."
        case .missingSession:
            return "Supabase did not return a valid session."
        case .requestFailed(let message):
            return message
        }
    }
}

final class SupabaseAuthService {
    private let configuration: SupabaseConfiguration
    private let urlSession: URLSession
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    init(
        configuration: SupabaseConfiguration? = nil,
        urlSession: URLSession = .shared
    ) throws {
        self.configuration = try configuration ?? SupabaseConfiguration.load()
        self.urlSession = urlSession
    }

    func signIn(email: String, password: String) async throws -> AuthSession {
        let url = try buildURL(path: "/auth/v1/token", queryItems: [URLQueryItem(name: "grant_type", value: "password")])
        var request = baseRequest(url: url, method: "POST")
        request.httpBody = try encoder.encode(["email": email, "password": password])

        let response: TokenResponse = try await perform(request: request, responseType: TokenResponse.self)
        return session(from: response)
    }

    func signUp(email: String, password: String) async throws -> SignUpResult {
        let url = try buildURL(path: "/auth/v1/signup")
        var request = baseRequest(url: url, method: "POST")
        request.httpBody = try encoder.encode(["email": email, "password": password])

        let response: SignUpResponse = try await perform(request: request, responseType: SignUpResponse.self)
        guard let accessToken = response.accessToken,
              let refreshToken = response.refreshToken,
              let expiresIn = response.expiresIn,
              let user = response.user else {
            return .emailConfirmationRequired
        }

        let expiresAt: Date
        if let rawExpiresAt = response.expiresAt {
            expiresAt = Date(timeIntervalSince1970: TimeInterval(rawExpiresAt))
        } else {
            expiresAt = Date().addingTimeInterval(TimeInterval(expiresIn))
        }

        return .signedIn(
            AuthSession(
                accessToken: accessToken,
                refreshToken: refreshToken,
                expiresAt: expiresAt,
                userID: user.id,
                email: user.email
            )
        )
    }

    func refreshSession(refreshToken: String) async throws -> AuthSession {
        let url = try buildURL(path: "/auth/v1/token", queryItems: [URLQueryItem(name: "grant_type", value: "refresh_token")])
        var request = baseRequest(url: url, method: "POST")
        request.httpBody = try encoder.encode(["refresh_token": refreshToken])

        let response: TokenResponse = try await perform(request: request, responseType: TokenResponse.self)
        return session(from: response)
    }

    func signOut(accessToken: String) async throws {
        let url = try buildURL(path: "/auth/v1/logout")
        var request = baseRequest(url: url, method: "POST")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = Data()

        let (_, response) = try await urlSession.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SupabaseAuthError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw SupabaseAuthError.requestFailed(message: "Sign out failed with status code \(httpResponse.statusCode).")
        }
    }

    private func session(from response: TokenResponse) -> AuthSession {
        let expiration: Date
        if let rawExpiresAt = response.expiresAt {
            expiration = Date(timeIntervalSince1970: TimeInterval(rawExpiresAt))
        } else {
            expiration = Date().addingTimeInterval(TimeInterval(response.expiresIn))
        }

        return AuthSession(
            accessToken: response.accessToken,
            refreshToken: response.refreshToken,
            expiresAt: expiration,
            userID: response.user.id,
            email: response.user.email
        )
    }

    private func baseRequest(url: URL, method: String) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(configuration.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(configuration.anonKey)", forHTTPHeaderField: "Authorization")
        return request
    }

    private func buildURL(path: String, queryItems: [URLQueryItem] = []) throws -> URL {
        guard var components = URLComponents(url: configuration.baseURL, resolvingAgainstBaseURL: false) else {
            throw SupabaseAuthError.invalidResponse
        }

        components.path = path
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }

        guard let url = components.url else {
            throw SupabaseAuthError.invalidResponse
        }

        return url
    }

    private func perform<Response: Decodable>(request: URLRequest, responseType: Response.Type) async throws -> Response {
        let (data, response) = try await urlSession.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SupabaseAuthError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let payload = try? decoder.decode(ErrorResponse.self, from: data)
            let message = payload?.bestMessage ?? "Supabase request failed with status code \(httpResponse.statusCode)."
            throw SupabaseAuthError.requestFailed(message: message)
        }

        do {
            return try decoder.decode(Response.self, from: data)
        } catch {
            throw SupabaseAuthError.invalidResponse
        }
    }
}

private struct UserResponse: Decodable {
    let id: String
    let email: String?
}

private struct TokenResponse: Decodable {
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int
    let expiresAt: Int?
    let user: UserResponse

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case expiresAt = "expires_at"
        case user
    }
}

private struct SignUpResponse: Decodable {
    let accessToken: String?
    let refreshToken: String?
    let expiresIn: Int?
    let expiresAt: Int?
    let user: UserResponse?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case expiresAt = "expires_at"
        case user
    }
}

private struct ErrorResponse: Decodable {
    let message: String?
    let msg: String?
    let errorDescription: String?
    let error: String?

    enum CodingKeys: String, CodingKey {
        case message
        case msg
        case errorDescription = "error_description"
        case error
    }

    var bestMessage: String? {
        if let message, !message.isEmpty { return message }
        if let msg, !msg.isEmpty { return msg }
        if let errorDescription, !errorDescription.isEmpty { return errorDescription }
        if let error, !error.isEmpty { return error }
        return nil
    }
}
