import Foundation
import PostHog
import TumbleKit

public enum AnalyticsRuntime: Sendable {
    case mainApp
    case captureExtension
}

public enum AnalyticsScreen: String, Sendable, CaseIterable {
    case onboardingWelcome = "onboarding_welcome"
    case onboardingCapture = "onboarding_capture"
    case onboardingDevelop = "onboarding_develop"
    case onboardingPayoff = "onboarding_payoff"
    case onboardingPremium = "onboarding_premium"
    case drawer
    case camera
    case develop
    case printDetail = "print_detail"
    case postcardStudio = "postcard_studio"
    case collection
    case archive
    case rollPaywall = "roll_paywall"
    case filmPackPaywall = "film_pack_paywall"
}

public enum AnalyticsEvent: Sendable {
    case onboardingStarted
    case onboardingStepCompleted(step: String)
    case onboardingCompleted(path: String, tier: String)
    case photoCaptured(source: String, remainingAfter: Int?)
    case photoDeveloped(source: String, method: String, filmStockID: String)
    case photoRemoved(state: String)
    case filmStockSelected(filmStockID: String, packID: String)
    case postcardFrameSelected(frameStyle: String, scope: String)
    case photoSaved(format: String, frameStyle: String, photoCount: Int)
    case photoSaveFailed(reason: String, format: String, photoCount: Int)
    case paywallViewed(type: String, source: String, packID: String?, remainingShots: Int?)
    case purchaseStarted(productID: String, productType: String, source: String)
    case purchaseFinished(productID: String, productType: String, source: String, outcome: String)
    case restoreFinished(source: String, outcome: String, entitlement: String)
    case permissionResponded(permission: String, outcome: String, context: String)

    public var name: String {
        switch self {
        case .onboardingStarted: "onboarding_started"
        case .onboardingStepCompleted: "onboarding_step_completed"
        case .onboardingCompleted: "onboarding_completed"
        case .photoCaptured: "photo_captured"
        case .photoDeveloped: "photo_developed"
        case .photoRemoved: "photo_removed"
        case .filmStockSelected: "film_stock_selected"
        case .postcardFrameSelected: "postcard_frame_selected"
        case .photoSaved: "photo_saved"
        case .photoSaveFailed: "photo_save_failed"
        case .paywallViewed: "paywall_viewed"
        case .purchaseStarted: "purchase_started"
        case .purchaseFinished: "purchase_finished"
        case .restoreFinished: "restore_finished"
        case .permissionResponded: "permission_responded"
        }
    }

    public var properties: [String: Any] {
        switch self {
        case .onboardingStarted:
            [:]
        case .onboardingStepCompleted(let step):
            ["step": step]
        case .onboardingCompleted(let path, let tier):
            ["path": path, "tier": tier]
        case .photoCaptured(let source, let remainingAfter):
            compact(["source": source, "remaining_after": remainingAfter])
        case .photoDeveloped(let source, let method, let filmStockID):
            ["source": source, "method": method, "film_stock_id": filmStockID]
        case .photoRemoved(let state):
            ["state": state]
        case .filmStockSelected(let filmStockID, let packID):
            ["film_stock_id": filmStockID, "pack_id": packID]
        case .postcardFrameSelected(let frameStyle, let scope):
            ["frame_style": frameStyle, "scope": scope]
        case .photoSaved(let format, let frameStyle, let photoCount):
            ["format": format, "frame_style": frameStyle, "photo_count": photoCount]
        case .photoSaveFailed(let reason, let format, let photoCount):
            ["reason": reason, "format": format, "photo_count": photoCount]
        case .paywallViewed(let type, let source, let packID, let remainingShots):
            compact(["type": type, "source": source, "pack_id": packID, "remaining_shots": remainingShots])
        case .purchaseStarted(let productID, let productType, let source):
            ["product_id": productID, "product_type": productType, "source": source]
        case .purchaseFinished(let productID, let productType, let source, let outcome):
            ["product_id": productID, "product_type": productType, "source": source, "outcome": outcome]
        case .restoreFinished(let source, let outcome, let entitlement):
            ["source": source, "outcome": outcome, "entitlement": entitlement]
        case .permissionResponded(let permission, let outcome, let context):
            ["permission": permission, "outcome": outcome, "context": context]
        }
    }

    private func compact(_ values: [String: Any?]) -> [String: Any] {
        values.reduce(into: [:]) { result, pair in
            if let value = pair.value { result[pair.key] = value }
        }
    }
}

@MainActor
public final class TumbleAnalytics {
    public static let shared = TumbleAnalytics()

    public static let schemaVersion = 1
    public static let consentKey = "tumble.analytics.enabled"
    public static let forbiddenPropertyFragments = [
        "caption", "filename", "photo_id", "image_data", "raw_image", "developed_image", "free_text"
    ]

    private var configured = false
    private var entitlement = Entitlement.free.rawValue
    private var currentScreen: AnalyticsScreen?
    private var buildChannel = "unknown"
    private var requestedRuntime: AnalyticsRuntime = .mainApp
    private weak var requestedBundle: Bundle?

    private init() {}

    public var isEnabled: Bool {
        let defaults = AppGroup.defaults
        guard defaults.object(forKey: Self.consentKey) != nil else { return false }
        return defaults.bool(forKey: Self.consentKey)
    }

    public func configure(_ runtime: AnalyticsRuntime, bundle: Bundle = .main) {
        requestedRuntime = runtime
        requestedBundle = bundle
        guard !configured else { return }
        guard isEnabled else { return }

        let environment = ProcessInfo.processInfo.environment
        guard let token = configuredValue("POSTHOG_PROJECT_TOKEN", environment: environment, bundle: bundle),
              let host = configuredValue("POSTHOG_HOST", environment: environment, bundle: bundle)
        else {
#if DEBUG
            print("TumbleAnalytics: POSTHOG_PROJECT_TOKEN/POSTHOG_HOST are not configured; analytics is disabled.")
#endif
            return
        }

        buildChannel = Self.resolveBuildChannel(bundle: bundle, environment: environment)
        let config = PostHogConfig(projectToken: token, host: host)
        config.appGroupIdentifier = AppGroup.identifier
        config.optOut = !isEnabled
        config.personProfiles = .identifiedOnly
        config.captureScreenViews = false
        config.captureApplicationLifecycleEvents = runtime == .mainApp
        config.sendFeatureFlagEvent = false
        config.preloadFeatureFlags = false
        config.surveys = false
        config.capturePushNotificationSubscriptions = false
        config.capturePushNotificationOpened = false
        config.captureElementInteractions = false
        config.rageClickConfig.enabled = false
        config.errorTrackingConfig.autoCapture = runtime == .mainApp

        if runtime == .mainApp {
            config.sessionReplay = true
            config.sessionReplayConfig.maskAllTextInputs = true
            config.sessionReplayConfig.maskAllImages = true
            config.sessionReplayConfig.maskAllSandboxedViews = true
            config.sessionReplayConfig.captureLogs = false
            config.sessionReplayConfig.captureNetworkTelemetry = false
            config.sessionReplayConfig.screenshotMode = true
            config.sessionReplayConfig.screenshotModeBackgroundCapture = false
            config.sessionReplayConfig.throttleDelay = 1
            config.sessionReplayConfig.sampleRate = NSNumber(value: 0.10)
        } else {
            config.enableSwizzling = false
            config.sessionReplay = false
        }

        let configuredBuildChannel = buildChannel
        config.setBeforeSend { event in
            event.properties["schema_version"] = Self.schemaVersion
            event.properties["build_channel"] = configuredBuildChannel
            if !event.event.hasPrefix("$") {
                for key in event.properties.keys where Self.isForbiddenProperty(key) {
                    event.properties.removeValue(forKey: key)
                }
            }
            return event
        }

        PostHogSDK.shared.setup(config)
        configured = true
    }

    public func updateEntitlement(_ entitlement: Entitlement) {
        self.entitlement = entitlement.rawValue
    }

    public func capture(_ event: AnalyticsEvent) {
        guard configured, isEnabled else { return }
        var properties = event.properties
        properties["schema_version"] = Self.schemaVersion
        properties["build_channel"] = buildChannel
        properties["entitlement"] = entitlement
        if let currentScreen { properties["source_screen"] = currentScreen.rawValue }
        PostHogSDK.shared.capture(event.name, properties: properties)
    }

    public func screen(_ screen: AnalyticsScreen) {
        currentScreen = screen
        guard configured, isEnabled else { return }
        PostHogSDK.shared.screen(screen.rawValue, properties: [
            "schema_version": Self.schemaVersion,
            "build_channel": buildChannel,
            "entitlement": entitlement,
        ])
    }

    public func setEnabled(_ enabled: Bool) {
        AppGroup.defaults.set(enabled, forKey: Self.consentKey)
        if enabled {
            if configured {
                PostHogSDK.shared.optIn()
            } else {
                configure(requestedRuntime, bundle: requestedBundle ?? .main)
            }
        } else if configured {
            PostHogSDK.shared.optOut()
            PostHogSDK.shared.reset()
        }
    }

    public func pauseReplay() {
        guard configured, isEnabled else { return }
        PostHogSDK.shared.stopSessionRecording()
    }

    public func resumeReplay() {
        guard configured, isEnabled else { return }
        PostHogSDK.shared.startSessionRecording()
    }

    public static func isForbiddenProperty(_ key: String) -> Bool {
        let normalized = key.lowercased()
        return forbiddenPropertyFragments.contains { normalized.contains($0) }
    }

    public static func resolveBuildChannel(bundle: Bundle, environment: [String: String]) -> String {
        if let override = environment["TUMBLE_BUILD_CHANNEL"], !override.isEmpty { return override }
#if DEBUG
        return "debug"
#else
        if bundle.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt" { return "testflight" }
        return "app_store"
#endif
    }

    private func configuredValue(_ key: String, environment: [String: String], bundle: Bundle) -> String? {
        let value = environment[key] ?? bundle.object(forInfoDictionaryKey: key) as? String
        guard let value, !value.isEmpty, !value.hasPrefix("$(") else { return nil }
        return value
    }
}
