import SwiftUI
import SwiftData
import TumbleAnalytics
import TumbleKit

@main
struct TumbleApp: App {
    init() {
        TumbleAnalytics.shared.configure(.mainApp)
    }

    @State private var app = AppModel()
    @AppStorage("tumble.hasOnboarded") private var legacyOnboarded = false
    @AppStorage("tumble.v3.hasIntroduced") private var hasIntroducedV3 = false

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
                if hasIntroducedV3 || skipOnboarding {
                    CameraWorkspace()
                } else if legacyOnboarded {
                    TumbleChangedView {
                        withAnimation(.easeInOut(duration: 0.35)) { hasIntroducedV3 = true }
                    }
                } else {
                    TumbleThreeOnboarding {
                        legacyOnboarded = true
                        withAnimation(.easeInOut(duration: 0.35)) { hasIntroducedV3 = true }
                    }
                    .transition(.opacity)
                }
            }
            .environment(app)
            .preferredColorScheme(.dark)
        }
        .modelContainer(container)
    }
}
