import SwiftUI

struct AuthView: View {
    enum Mode: String, CaseIterable, Identifiable {
        case signIn = "Sign In"
        case signUp = "Sign Up"

        var id: String { rawValue }

        var buttonTitle: String {
            switch self {
            case .signIn:
                return "Sign In"
            case .signUp:
                return "Create Account"
            }
        }
    }

    @EnvironmentObject private var authStore: AuthStore

    @State private var mode: Mode = .signIn
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""

    private let pageBackground = Color.black
    private let secondaryText = Color.white.opacity(0.8)
    private let fieldBackground = Color(red: 0.14, green: 0.14, blue: 0.16)
    private let borderColor = Color.white.opacity(0.22)

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer(minLength: 0)

                VStack(spacing: 10) {
                    Text("Tempa")
                        .font(AppTheme.Fonts.largeTitleBold)
                        .foregroundColor(.white)

                    Text("Sign in to keep your workout progress tied to your account.")
                        .font(AppTheme.Fonts.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundColor(secondaryText)
                }

                Picker("Mode", selection: $mode) {
                    ForEach(Mode.allCases) { currentMode in
                        Text(currentMode.rawValue).tag(currentMode)
                    }
                }
                .pickerStyle(.segmented)
                .tint(.white)

                VStack(spacing: 14) {
                    TextField("Email", text: $email)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.emailAddress)
                        .padding()
                        .background(fieldBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(borderColor, lineWidth: 1)
                        )
                        .cornerRadius(10)
                        .foregroundColor(.white)

                    SecureField("Password", text: $password)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding()
                        .background(fieldBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(borderColor, lineWidth: 1)
                        )
                        .cornerRadius(10)
                        .foregroundColor(.white)

                    if mode == .signUp {
                        SecureField("Confirm Password", text: $confirmPassword)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .padding()
                            .background(fieldBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(borderColor, lineWidth: 1)
                            )
                            .cornerRadius(10)
                            .foregroundColor(.white)
                    }
                }

                if let infoMessage = authStore.infoMessage {
                    Text(infoMessage)
                        .font(AppTheme.Fonts.caption)
                        .foregroundColor(secondaryText)
                        .multilineTextAlignment(.center)
                }

                if let errorMessage = authStore.errorMessage {
                    Text(errorMessage)
                        .font(AppTheme.Fonts.caption)
                        .foregroundColor(AppTheme.Colors.error)
                        .multilineTextAlignment(.center)
                }

                Button {
                    submit()
                } label: {
                    HStack {
                        if authStore.isWorking {
                            ProgressView()
                                .progressViewStyle(.circular)
                        } else {
                            Text(mode.buttonTitle)
                                .font(AppTheme.Fonts.headline)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .foregroundColor(Color.black)
                    .cornerRadius(12)
                }
                .disabled(authStore.isWorking || !canSubmit)

                if !authStore.isConfigured {
                    Text("Supabase credentials are missing. Add SUPABASE_URL and SUPABASE_ANON_KEY to your app configuration.")
                        .font(AppTheme.Fonts.caption)
                        .foregroundColor(AppTheme.Colors.error)
                        .multilineTextAlignment(.center)
                }

                Spacer()
            }
            .padding()
            .background(pageBackground.ignoresSafeArea())
        }
        .preferredColorScheme(.dark)
    }

    private var canSubmit: Bool {
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        if mode == .signUp {
            return !normalizedEmail.isEmpty && !password.isEmpty && password == confirmPassword
        }

        return !normalizedEmail.isEmpty && !password.isEmpty
    }

    private func submit() {
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        if mode == .signUp, password != confirmPassword {
            authStore.errorMessage = "Passwords do not match."
            return
        }

        Task {
            switch mode {
            case .signIn:
                await authStore.signIn(email: normalizedEmail, password: password)
            case .signUp:
                await authStore.signUp(email: normalizedEmail, password: password)
            }
        }
    }
}
