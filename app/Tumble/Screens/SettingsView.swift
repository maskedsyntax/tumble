import SwiftUI
import TumbleKit

/// Settings. Leads with Tumble's promise — on-device, no account, no cloud —
/// and offers the one-time unlocks and restore. Deliberately tiny.
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppModel.self) private var app
    @State private var showPaywall = false

    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var body: some View {
        ZStack {
            GraincoreBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Tumble").font(Typography.display(34)).foregroundStyle(Palette.cream)
                        Text("A slower camera you can actually own.")
                            .font(Typography.sans(14)).foregroundStyle(Palette.cream.opacity(0.7))
                    }

                    promise

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Your roll").kicker()
                        Text(app.roll.isUnlimited ? "Unlimited shots" : "\(app.roll.quota ?? 12) shots a day")
                            .font(Typography.display(20)).foregroundStyle(Palette.cream)
                        if app.purchases.entitlement != .unlimited {
                            Button { showPaywall = true } label: {
                                Text("Own more")
                                    .font(Typography.sans(15, weight: .semibold)).foregroundStyle(Palette.ink)
                                    .padding(.horizontal, 20).padding(.vertical, 10)
                                    .background(Palette.gold, in: Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                        Button("Restore purchases") {
                            Task { await app.purchases.restore(); app.syncEntitlement() }
                        }
                        .font(Typography.sans(14, weight: .semibold))
                        .foregroundStyle(Palette.cream.opacity(0.8))
                    }

                    Text("Version \(version) · Made for shooting, not scrolling.")
                        .font(Typography.sans(11)).foregroundStyle(Palette.cream.opacity(0.4))
                }
                .padding(24).padding(.top, 20)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            closeButton
        }
        .sheet(isPresented: $showPaywall) { PaywallView().environment(app) }
    }

    private var promise: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("On-device. Photos never leave your phone.", systemImage: "iphone")
            Label("No account. No sign-up, no email.", systemImage: "person.crop.circle.badge.xmark")
            Label("No cloud. Nothing is uploaded, ever.", systemImage: "icloud.slash")
        }
        .font(Typography.sans(14))
        .foregroundStyle(Palette.cream.opacity(0.85))
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 16).fill(Palette.cream.opacity(0.05)))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Palette.cream.opacity(0.12)))
    }

    private var closeButton: some View {
        VStack {
            HStack {
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .semibold)).foregroundStyle(Palette.cream)
                        .padding(10).background(.black.opacity(0.28), in: Circle())
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
        .padding(.horizontal, 20).padding(.top, 6)
    }
}
