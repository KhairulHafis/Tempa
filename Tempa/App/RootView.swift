import SwiftUI

struct RootView: View {
    @EnvironmentObject private var authStore: AuthStore

    var body: some View {
        Group {
            if authStore.isLoading {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Restoring session...")
                        .font(AppTheme.Fonts.subheadline)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppTheme.Colors.background.ignoresSafeArea())
            } else if authStore.isAuthenticated {
                ContentView()
            } else {
                AuthView()
            }
        }
    }
}
