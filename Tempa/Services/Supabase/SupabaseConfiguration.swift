import Foundation

enum SupabaseConfigurationError: LocalizedError {
    case missingURL
    case invalidURL
    case missingAnonKey

    var errorDescription: String? {
        switch self {
        case .missingURL:
            return "Missing SUPABASE_URL configuration."
        case .invalidURL:
            return "SUPABASE_URL is not a valid URL."
        case .missingAnonKey:
            return "Missing SUPABASE_ANON_KEY configuration."
        }
    }

    var recoverySuggestion: String? {
        "Set SUPABASE_URL and SUPABASE_ANON_KEY in your Xcode scheme environment variables or Info.plist."
    }
}

struct SupabaseConfiguration {
    let baseURL: URL
    let anonKey: String

    static func load(bundle: Bundle = .main) throws -> SupabaseConfiguration {
        let environment = ProcessInfo.processInfo.environment

        let rawURL = environment["SUPABASE_URL"]
            ?? bundle.object(forInfoDictionaryKey: "SUPABASE_URL") as? String
        guard let rawURL, !rawURL.isEmpty else {
            throw SupabaseConfigurationError.missingURL
        }

        guard let baseURL = URL(string: rawURL) else {
            throw SupabaseConfigurationError.invalidURL
        }

        let anonKey = environment["SUPABASE_ANON_KEY"]
            ?? bundle.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String
        guard let anonKey, !anonKey.isEmpty else {
            throw SupabaseConfigurationError.missingAnonKey
        }

        return SupabaseConfiguration(baseURL: baseURL, anonKey: anonKey)
    }
}
