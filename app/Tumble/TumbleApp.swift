import SwiftUI
import SwiftData
import TumbleKit

@main
struct TumbleApp: App {
    @State private var app = AppModel()
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("tumble.hasOnboarded") private var hasOnboarded = false

    private let container: ModelContainer = {
        do { return try PhotoStore.makeContainer() }
        catch { return try! PhotoStore.makeContainer(inMemory: true) }
    }()

    private var skipOnboarding: Bool {
        ProcessInfo.processInfo.arguments.contains("-skipOnboard")
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if hasOnboarded || skipOnboarding {
                    HomeScreen()
                } else {
                    OnboardingScreen {
                        withAnimation(.easeInOut(duration: 0.35)) { hasOnboarded = true }
                    }
                    .transition(.opacity)
                }
            }
            .environment(app)
            .preferredColorScheme(.dark)
            .statusBarHidden()
        }
        .modelContainer(container)
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active: app.enterForeground()   // free the island for dragging
            case .background: app.enterBackground() // show the status Live Activity
            default: break
            }
        }
    }
}
