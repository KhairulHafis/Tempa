import Combine
import Foundation
import Security

final class AuthSessionStorage {
    private let service: String
    private let account = "supabase.auth.session"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(service: String = Bundle.main.bundleIdentifier ?? "com.tempa.auth") {
        self.service = service
    }

    func load() -> AuthSession? {
        var query = baseQuery()
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data else {
            return nil
        }

        return try? decoder.decode(AuthSession.self, from: data)
    }

    func save(_ session: AuthSession) {
        guard let data = try? encoder.encode(session) else {
            return
        }

        SecItemDelete(baseQuery() as CFDictionary)

        var query = baseQuery()
        query[kSecValueData as String] = data
        query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly

        SecItemAdd(query as CFDictionary, nil)
    }

    func clear() {
        SecItemDelete(baseQuery() as CFDictionary)
    }

    private func baseQuery() -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }
}

@MainActor
final class AuthStore: ObservableObject {
    @Published private(set) var isLoading = true
    @Published private(set) var isWorking = false
    @Published private(set) var isConfigured = true
    @Published private(set) var session: AuthSession?
    @Published var infoMessage: String?
    @Published var errorMessage: String?

    var isAuthenticated: Bool {
        session != nil
    }

    var currentUserEmail: String? {
        session?.email
    }

    private let authService: SupabaseAuthService?
    private let sessionStorage: AuthSessionStorage

    init(sessionStorage: AuthSessionStorage = AuthSessionStorage()) {
        self.sessionStorage = sessionStorage

        do {
            self.authService = try SupabaseAuthService()
        } catch {
            self.authService = nil
            self.isConfigured = false
            self.errorMessage = error.localizedDescription
            self.isLoading = false
            return
        }

        Task {
            await restoreSession()
        }
    }

    func signIn(email: String, password: String) async {
        guard let authService else {
            errorMessage = "Supabase is not configured."
            return
        }

        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedEmail.isEmpty, !password.isEmpty else {
            errorMessage = "Email and password are required."
            return
        }

        infoMessage = nil
        errorMessage = nil
        isWorking = true
        defer { isWorking = false }

        do {
            let newSession = try await authService.signIn(email: normalizedEmail, password: password)
            persist(session: newSession)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signUp(email: String, password: String) async {
        guard let authService else {
            errorMessage = "Supabase is not configured."
            return
        }

        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedEmail.isEmpty, !password.isEmpty else {
            errorMessage = "Email and password are required."
            return
        }

        infoMessage = nil
        errorMessage = nil
        isWorking = true
        defer { isWorking = false }

        do {
            let result = try await authService.signUp(email: normalizedEmail, password: password)
            switch result {
            case .signedIn(let session):
                persist(session: session)
            case .emailConfirmationRequired:
                infoMessage = "Account created. Check your email to confirm your account, then sign in."
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signOut() async {
        let accessToken = session?.accessToken
        clearSession()

        guard let authService, let accessToken else {
            return
        }

        do {
            try await authService.signOut(accessToken: accessToken)
        } catch {
            // The local session has already been cleared.
        }
    }

    private func restoreSession() async {
        defer {
            isLoading = false
        }

        guard let authService else {
            return
        }

        guard let storedSession = sessionStorage.load() else {
            return
        }

        do {
            if storedSession.isExpired {
                let refreshedSession = try await authService.refreshSession(refreshToken: storedSession.refreshToken)
                persist(session: refreshedSession)
            } else {
                persist(session: storedSession)
            }
        } catch {
            clearSession()
        }
    }

    private func persist(session: AuthSession) {
        self.session = session
        sessionStorage.save(session)
    }

    private func clearSession() {
        session = nil
        sessionStorage.clear()
    }
}
