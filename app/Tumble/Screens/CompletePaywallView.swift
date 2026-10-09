import StoreKit
import SwiftUI
import TumbleAnalytics
import TumbleKit

struct CompletePaywallView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    @State private var busy = false
    @State private var message: String?
    @State private var showAccount = false
    var source: String = "settings"
    var onUnlocked: (() -> Void)? = nil
    var onClose: (() -> Void)? = nil

    private var product: Product? { app.purchases.bundleProduct }
    private var isComplete: Bool { app.purchases.accessState == .complete }

    var body: some View {
        ZStack {
            GraincoreBackground()
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    IconButton("xmark", accessibilityLabel: "Close") { close() }
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)

                ScrollView {
                    VStack(spacing: 22) {
                        VStack(spacing: 8) {
                            Text("One purchase · Yours forever")
                                .trackedLabel()
                                .foregroundStyle(Palette.amber)
                            Text("Tumble Complete")
                                .font(Typography.largeTitle)
                                .foregroundStyle(Palette.textPrimary)
                                .accessibilityAddTraits(.isHeader)
                            Text("Preview every film on your own photos. Unlock fifteen more looks with one payment.")
                                .font(Typography.body)
                                .foregroundStyle(Palette.textSecondary)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        HStack(spacing: 10) {
                            CompletePreviewTile(stockID: "disposable", scene: .blueHourRooftop)
                            CompletePreviewTile(stockID: "silver", scene: .warmPortrait)
                            CompletePreviewTile(stockID: "goldenHour", scene: .beachMorning)
                        }

                        VStack(alignment: .leading, spacing: 14) {
                            benefit("Ninety-Six", "Disposable color and hard flash")
                            benefit("Darkroom", "Five hand-printed monochrome looks")
                            benefit("Long Summer", "Leaks, haze and golden light")
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(18)
                        .background(Palette.blueDeep.opacity(0.72), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Palette.hairline))
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                    .padding(.bottom, 20)
                }
                .scrollIndicators(.hidden)

                purchaseArea
            }
        }
        .task {
            await app.startStore()
            TumbleAnalytics.shared.capture(.paywallViewed(type: "complete", source: source, packID: nil, remainingShots: nil))
        }
        .sheet(isPresented: $showAccount) { AccountView().environment(app) }
    }

    private var purchaseArea: some View {
        VStack(spacing: 10) {
            if let message {
                Text(message)
                    .font(Typography.caption)
                    .foregroundStyle(Palette.textSecondary)
                    .multilineTextAlignment(.center)
            }
            Button { Task { await buy() } } label: {
                Group {
                    if busy { ProgressView().tint(Palette.ink) }
                    else if isComplete { Text("Tumble Complete is unlocked") }
                    else { Text("Own every film · \(product?.displayPrice ?? "…")") }
                }
            }
            .buttonStyle(PrimaryButtonStyle(height: 54))
            .disabled(product == nil || busy || isComplete)

            Text("One-time purchase · No subscription")
                .font(Typography.caption)
                .foregroundStyle(Palette.textSecondary)

            Button("Restore or link purchases") { Task { await restore() } }
                .font(Typography.headline)
                .foregroundStyle(Palette.textPrimary)
                .frame(minHeight: EditorChromeMetrics.minimumHitTarget)
                .disabled(busy)
        }
        .padding(.horizontal, 24)
        .padding(.top, 14)
        .padding(.bottom, 8)
        .background(
            LinearGradient(
                colors: [Palette.blueDeep.opacity(0), Palette.blueDeep.opacity(0.9)],
                startPoint: .top,
                endPoint: .center
            )
            .ignoresSafeArea(edges: .bottom)
        )
    }

    private func benefit(_ title: String, _ detail: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 18))
                .foregroundStyle(Palette.amber)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(Typography.headline).foregroundStyle(Palette.textPrimary)
                Text(detail).font(Typography.caption).foregroundStyle(Palette.textSecondary)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func buy() async {
        guard app.account.isSignedIn else {
            message = "Sign in to buy once and keep your films on every device you use."
            showAccount = true
            return
        }
        guard let product else { return }
        busy = true
        TumbleAnalytics.shared.capture(.purchaseStarted(productID: product.id, productType: "complete", source: source))
        let outcome = await app.purchases.purchase(product)
        app.syncEntitlement()
        if outcome == .completed { await app.account.purchaseDidComplete() }
        busy = false
        TumbleAnalytics.shared.capture(.purchaseFinished(productID: product.id, productType: "complete", source: source, outcome: outcome.rawValue))
        if outcome == .completed, app.purchases.accessState == .complete {
            onUnlocked?()
            close()
        }
        else if outcome != .cancelled { message = "The purchase could not be completed. Try again." }
    }

    private func restore() async {
        guard app.account.isSignedIn else {
            message = "Sign in first so restored purchases can be linked to your Tumble account."
            showAccount = true
            return
        }
        busy = true
        let outcome = await app.purchases.restore()
        app.syncEntitlement()
        if outcome == .completed { await app.account.linkPurchases() }
        busy = false
        TumbleAnalytics.shared.capture(.restoreFinished(source: source, outcome: outcome.rawValue, entitlement: app.purchases.accessState == .complete ? "complete" : "free"))
        if outcome == .completed, app.purchases.accessState == .complete {
            onUnlocked?()
            close()
        }
        else { message = "No Complete purchase was found." }
    }

    private func close() {
        if let onClose { onClose() }
        else { dismiss() }
    }
}

private struct CompletePreviewTile: View {
    let stockID: String
    let scene: FilmScene
    @State private var image: UIImage?

    private var stock: FilmStock { FilmStockCatalog.resolve(stockID) }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Color.clear
                .aspectRatio(3 / 4, contentMode: .fit)
                .overlay {
                    if let image { Image(uiImage: image).resizable().scaledToFill() }
                    else { Palette.blueDeep.overlay(ProgressView().tint(Palette.amber)) }
                }
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Palette.hairline))
            Text(stock.name)
                .font(Typography.captionEmphasized)
                .foregroundStyle(Palette.textPrimary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .task {
            #if DEBUG
            let captureSource = DebugLaunch.demoImageData.flatMap(UIImage.init(data:))
            #else
            let captureSource: UIImage? = nil
            #endif
            let source = captureSource ?? UIImage(named: "onboarding-editorial") ?? scene.image(size: 420)
            let chosenStock = stock
            image = await Task.detached(priority: .utility) {
                TumblePhotoFilter.renderLivePreview(from: source, stock: chosenStock, maxDimension: 420)
            }.value
        }
    }
}
