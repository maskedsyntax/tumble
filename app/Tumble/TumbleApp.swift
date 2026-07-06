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
            CameraScreen()
                .environment(app)
                .preferredColorScheme(.dark)
                .statusBarHidden()
        }
        .modelContainer(container)
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { app.refresh() }
        }
    }
}
