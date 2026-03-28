import SwiftUI

@main
struct XjieApp: App {
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                if authManager.isLoggedIn {
                    MainTabView()
                        .environmentObject(authManager)
                        .environmentObject(networkMonitor)
                } else {
                    LoginView()
                        .environmentObject(authManager)
                        .environmentObject(networkMonitor)
                }

                if showSplash {
                    SplashView { showSplash = false }
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
        }
    }
}
