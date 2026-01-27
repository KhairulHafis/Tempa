import SwiftUI


struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 40) {
                Spacer()

                VStack(spacing: 10) {
                    Text("autumnFall – Strength in every season 🍂")
                        .font(AppTheme.Fonts.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .foregroundColor(AppTheme.Colors.textPrimary)

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
                        .background(AppTheme.Colors.accent)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                        .cornerRadius(12)
                }

                Spacer()
            }
            .padding()
            .background(AppTheme.Colors.background)

            .navigationDestination(for: String.self) { value in
                if value == "Workout" {
                    WorkoutView()
                } else if value == "Stats" {
                    StatsView()
                }
            }
        }
        .environmentObject(WorkoutSessionStore())
    }

    func getQuoteOfTheDay() -> String {
        let quotes = [
            "Push yourself, because no one else is going to do it for you.",
            "Small steps every day lead to big results.",
            "Autumn shows us how beautiful change can be 🍁"
        ]
        return quotes.randomElement() ?? ""
    }
}

