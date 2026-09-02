import StoreKit
import SwiftUI
import TumbleAnalytics
import TumbleKit

struct CompletePaywallView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    @State private var busy = false
    @State private var message: String?

    private var product: Product? { app.purchases.bundleProduct }

    var body: some View {
        ZStack {
            GraincoreBackground()
            ScrollView {
                VStack(spacing: 22) {
                    Image(systemName: "camera.filters")
                        .font(.system(size: 42, weight: .medium))
                        .foregroundStyle(Palette.gold)
                    Text("Tumble Complete")
                        .font(Typography.display(34))
                        .foregroundStyle(Palette.cream)
                    Text("All fifteen premium films. One payment, yours forever.")
                        .font(Typography.sans(15))
                        .foregroundStyle(Palette.cream.opacity(0.72))
                        .multilineTextAlignment(.center)

                    VStack(alignment: .leading, spacing: 12) {
                        benefit("Ninety-Six", "Disposable colour and hard flash")
                        benefit("Darkroom", "Five hand-printed monochrome looks")
                        benefit("Long Summer", "Leaks, haze and golden light")
                    }
                    .padding(18)
                    .background(.black.opacity(0.22), in: RoundedRectangle(cornerRadius: 22))

                    Button { Task { await buy() } } label: {
                        Group {
                            if busy { ProgressView().tint(Palette.ink) }
                            else { Text("Own every film · \(product?.displayPrice ?? "…")") }
                        }
                        .font(Typography.sans(16, weight: .bold))
                        .foregroundStyle(Palette.ink)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Palette.gold, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .disabled(product == nil || busy)

                    Button("Restore purchases") { Task { await restore() } }
                        .font(Typography.sans(14, weight: .semibold))
                        .foregroundStyle(Palette.cream.opacity(0.72))

                    if let message {
                        Text(message)
                            .font(Typography.sans(13))
                            .foregroundStyle(Palette.cream.opacity(0.72))
                    }
                }
                .padding(.horizontal, 26)
                .padding(.top, 72)
                .padding(.bottom, 36)
            }
            VStack {
                HStack {
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(Palette.cream)
                            .padding(10)
                            .background(.black.opacity(0.28), in: Circle())
                    }
                }
                Spacer()
            }
            .padding(20)
        }
        .task { await app.startStore() }
    }

    private func benefit(_ title: String, _ detail: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill").foregroundStyle(Palette.gold)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(Typography.sans(14, weight: .bold)).foregroundStyle(Palette.cream)
                Text(detail).font(Typography.sans(12)).foregroundStyle(Palette.cream.opacity(0.62))
            }
        }
    }

    private func buy() async {
        guard let product else { return }
        busy = true
        let outcome = await app.purchases.purchase(product)
        app.syncEntitlement()
        busy = false
        if outcome == .completed, app.purchases.accessState == .complete { dismiss() }
        else if outcome != .cancelled { message = "The purchase could not be completed. Try again." }
    }

    private func restore() async {
        busy = true
        let outcome = await app.purchases.restore()
        app.syncEntitlement()
        busy = false
        if outcome == .completed, app.purchases.accessState == .complete { dismiss() }
        else { message = "No Complete purchase was found." }
    }
}
