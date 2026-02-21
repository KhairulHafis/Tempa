import SwiftUI

@main
struct TempaApp: App {
    @StateObject private var sessionStore = WorkoutSessionStore()
    @StateObject private var authStore = AuthStore()
    @State private var didBindStores = false

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(sessionStore)
                .environmentObject(authStore)
                .onAppear {
                    guard !didBindStores else { return }
                    sessionStore.bind(to: authStore)
                    didBindStores = true
                }
        }
    }
}
