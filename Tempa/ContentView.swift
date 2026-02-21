import SwiftUI


struct ContentView: View {
    @EnvironmentObject private var authStore: AuthStore
    @State private var path: [String] = []
    @State private var isSigningOut = false

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 40) {
                Spacer()

                VStack(spacing: 10) {
                    Text("Tempa - Forged in discipline 🔨🏋️‍♀️")
                        .font(AppTheme.Fonts.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .foregroundColor(AppTheme.Colors.textPrimary)

                    if let email = authStore.currentUserEmail {
                        Text("Signed in as \(email)")
                            .font(AppTheme.Fonts.caption)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    Text(getQuoteOfTheDay())
                        .italic()
                        .multilineTextAlignment(.center)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                        .padding(.horizontal)
                }

                VStack(spacing: 20) {
                    NavigationLink("Begin pull-ups", value: "Workout")
                        .font(AppTheme.Fonts.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(AppTheme.Colors.primary)
                        .foregroundColor(AppTheme.Colors.onPrimary)
                        .cornerRadius(12)

                    NavigationLink("Stats", value: "Stats")
                        .font(AppTheme.Fonts.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(AppTheme.Colors.primary)
                        .foregroundColor(AppTheme.Colors.onPrimary)
                        .cornerRadius(12)
                }

                Spacer()
            }
            .padding()
            .background(AppTheme.Colors.background)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task {
                            isSigningOut = true
                            await authStore.signOut()
                            isSigningOut = false
                        }
                    } label: {
                        if isSigningOut {
                            ProgressView()
                        } else {
                            Text("Sign Out")
                        }
                    }
                    .disabled(isSigningOut)
                }
            }

            .navigationDestination(for: String.self) { value in
                if value == "Workout" {
                    WorkoutView(path: $path)
                } else if value == "Stats" {
                    StatsView()
                }
            }
        }
    }

    func getQuoteOfTheDay() -> String {
        let quotes = [
            "Push yourself, because no one else is going to do it for you.",
            "Small steps every day lead to big results.",
            "Your future self is watching what you do today.",
            "You don’t rise to your goals, you fall to your systems.",
            "Confidence is built, not found."
            
        ]
        return quotes.randomElement() ?? ""
    }
}
