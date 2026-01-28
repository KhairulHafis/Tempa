//
//  autumnFallApp.swift
//  autumnFall
//
//  Created by Muhammad Khairul Hafis Bin Hussain on 3/7/25.
//

import SwiftUI

@main
struct autumnFallApp: App {
    @StateObject private var sessionStore = WorkoutSessionStore()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(sessionStore)
        }
    }
}
