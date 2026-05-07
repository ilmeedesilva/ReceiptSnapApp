import SwiftUI

struct ContentView: View {

    @EnvironmentObject private var appState: AppState
    @AppStorage("rs_dark_mode") private var isDarkMode: Bool = false

    var body: some View {
        Group {
            if !appState.hasCompletedOnboarding {
                OnboardingView()
            } else if !appState.isAuthenticated {
                AuthCoordinatorView()
            } else {
                MainTabView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: appState.hasCompletedOnboarding)
        .animation(.easeInOut(duration: 0.3), value: appState.isAuthenticated)
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
