import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 40) {
                Spacer()

                VStack(spacing: 10) {
                    Text("autumnFall – Strength in every season 🍂")
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.black)

                    Text(getQuoteOfTheDay())
                        .italic()
                        .multilineTextAlignment(.center)
                        .foregroundColor(.black)
                        .padding(.horizontal)
                }

                VStack(spacing: 20) {
                    NavigationLink("Begin pull-ups", value: "Workout")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.brown)
                        .foregroundColor(.white)
                        .cornerRadius(12)

                    NavigationLink("Stats", value: "Stats")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.yellow)
                        .foregroundColor(.black)
                        .cornerRadius(12)
                }

                Spacer()
            }
            .padding()
            .background(Color(red: 0.96, green: 0.90, blue: 0.80))

            .navigationDestination(for: String.self) { value in
                if value == "Workout" {
                    WorkoutView()
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
            "Autumn shows us how beautiful change can be 🍁"
        ]
        return quotes.randomElement() ?? ""
    }
}

