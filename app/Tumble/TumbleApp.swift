import SwiftUI
import SwiftData
import FirebaseCore
import GoogleSignIn
import RevenueCat
import TumbleAnalytics
import TumbleKit
import UIKit

@main
struct TumbleApp: App {
    @Environment(\.scenePhase) private var scenePhase
    init() {
        FirebaseApp.configure()
        if let key = Bundle.main.object(forInfoDictionaryKey: "REVENUECAT_API_KEY") as? String,
           !key.isEmpty,
           !key.contains("$(") {
            Purchases.configure(
                with: Configuration.Builder(withAPIKey: key)
                    .with(purchasesAreCompletedBy: .myApp, storeKitVersion: .storeKit2)
                    .build()
            )
        }
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
            .onOpenURL { url in
                _ = GIDSignIn.sharedInstance.handle(url)
            }
            .onChange(of: scenePhase) { _, phase in
                if phase != .active {
                    Task { await app.drafts.flush() }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didReceiveMemoryWarningNotification)) { _ in
                Task {
                    await PhotoThumbnailRepository.shared.removeAll()
                    await FilmPreviewRenderer.shared.clear()
                }
            }
        }
        .modelContainer(container)
    }
}
