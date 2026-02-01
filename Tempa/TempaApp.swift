import SwiftUI

@main
struct TempaApp: App {
    @StateObject private var sessionStore = WorkoutSessionStore()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(sessionStore)
        }
    }
}

