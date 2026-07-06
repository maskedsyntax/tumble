import SwiftUI
import SwiftData
import TumbleKit

@main
struct TumbleApp: App {
    @State private var app = AppModel()
    @Environment(\.scenePhase) private var scenePhase

    private let container: ModelContainer = {
        do { return try PhotoStore.makeContainer() }
        catch { return try! PhotoStore.makeContainer(inMemory: true) }
    }()

    var body: some Scene {
        WindowGroup {
            HomeScreen()
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
