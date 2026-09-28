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
        ReviewPrompter.shared.recordInstallationIfNeeded()
    }

    @State private var app = AppModel()
    @AppStorage("tumble.hasOnboarded") private var legacyOnboarded = false
    @AppStorage("tumble.v3.hasIntroduced") private var hasIntroducedV3 = false
    @AppStorage("tumble.v3.1.hasIntroduced") private var hasIntroducedStudio = false

    private let container: ModelContainer = {
        do { return try PhotoStore.makeContainer() }
        catch { return try! PhotoStore.makeContainer(inMemory: true) }
    }()

    private var skipOnboarding: Bool {
        ProcessInfo.processInfo.arguments.contains("-skipOnboard")
    }

    private var forceIntroduction: Bool {
        ProcessInfo.processInfo.arguments.contains("-introductionDemo")
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if forceIntroduction {
                    TumbleThreeOnboarding {}
                } else if hasIntroducedStudio || skipOnboarding {
                    StudioHomeView()
                } else if legacyOnboarded || hasIntroducedV3 {
                    TumbleChangedView {
                        withAnimation(.easeInOut(duration: 0.35)) { hasIntroducedStudio = true }
                    }
                } else {
                    TumbleThreeOnboarding {
                        legacyOnboarded = true
                        hasIntroducedV3 = true
                        withAnimation(.easeInOut(duration: 0.35)) { hasIntroducedStudio = true }
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
