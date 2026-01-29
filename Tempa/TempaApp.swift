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

//Test to see if I can pull from new GIT url
