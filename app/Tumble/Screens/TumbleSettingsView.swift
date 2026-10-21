import SwiftUI
import TumbleAnalytics
import TumbleKit

struct TumbleSettingsView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    @State private var analyticsEnabled = false
    @State private var showAccount = false
    @State private var showComplete = false
    var onReplayIntroduction: (() -> Void)? = nil

    private var showsUpgrade: Bool {
        if DebugLaunch.previewsFreeSettings { return true }
        return app.purchases.accessState != .complete
    }

    var body: some View {
        NavigationStack {
            ZStack {
                GraincoreBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        if showsUpgrade {
                            Button { showComplete = true } label: { upgradeCard }
                                .buttonStyle(.plain)
                        }

                        settingsSection("Account") {
                            Button { showAccount = true } label: {
                                settingRow(
                                    "Tumble account",
                                    detail: app.account.isSignedIn ? "Signed in · purchases stay connected" : "Optional · only needed for purchases",
                                    icon: "person.crop.circle"
                                )
                            }
                            .buttonStyle(.plain)
                        }

                        settingsSection("Privacy") {
                            settingCard {
                                Toggle(isOn: Binding(
                                    get: { analyticsEnabled },
                                    set: { value in
                                        analyticsEnabled = value
                                        TumbleAnalytics.shared.setEnabled(value)
                                    }
                                )) {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text("Share anonymous diagnostics")
                                            .font(Typography.headline)
                                        Text("Crash reports and masked usage events. Photo pixels are never included.")
                                            .font(Typography.caption)
                                            .foregroundStyle(Palette.textSecondary)
                                    }
                                }
                                .tint(Palette.amber)
                            }

                            Link(destination: URL(string: "https://gettumbleapp.com/privacy")!) {
                                settingRow("Privacy policy", detail: "Read how Tumble handles your data", icon: "lock.shield")
                            }
                        }

                        settingsSection("Help") {
                            if let onReplayIntroduction {
                                Button {
                                    dismiss()
                                    onReplayIntroduction()
                                } label: {
                                    settingRow("Try the introduction again", detail: "Explore films and the postcard finish", icon: "sparkles.rectangle.stack")
                                }
                                .buttonStyle(.plain)
                            }
                            Link(destination: URL(string: "mailto:aftaab@aftaab.dev?subject=Tumble%203")!) {
                                settingRow("Contact support", detail: "Questions, feedback, or a problem", icon: "envelope")
                            }
                        }

                        Text("Tumble \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "3.1")")
                            .font(Typography.caption)
                            .foregroundStyle(Palette.textTertiary)
                            .padding(.top, 8)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() }.foregroundStyle(Palette.gold) }
            }
            .toolbarBackground(Palette.blueDeep, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .onAppear { analyticsEnabled = TumbleAnalytics.shared.isEnabled }
        .sheet(isPresented: $showComplete) { CompletePaywallView().environment(app) }
        .sheet(isPresented: $showAccount) { AccountView().environment(app) }
    }

    private var upgradeCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(Palette.amber.opacity(0.16))
                Image(systemName: "camera.filters")
                    .font(.system(size: 21, weight: .semibold))
                    .foregroundStyle(Palette.amber)
            }
            .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 3) {
                Text("Tumble Complete")
                    .trackedLabel()
                    .foregroundStyle(Palette.amber)
                Text("Unlock every film")
                    .font(Typography.title)
                    .foregroundStyle(Palette.textPrimary)
                Text("15 additional films · pay once")
                    .font(Typography.caption)
                    .foregroundStyle(Palette.textSecondary)
            }
            Spacer(minLength: 8)
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Palette.ink)
                .frame(width: 30, height: 30)
                .background(Palette.amber, in: Circle())
        }
        .padding(16)
        .background(Palette.surfaceRaised.opacity(0.92), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Palette.amber.opacity(0.28))
        }
        .accessibilityElement(children: .combine)
    }

    private func settingsSection<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .trackedLabel()
                .foregroundStyle(Palette.textSecondary)
                .padding(.horizontal, 4)
                .accessibilityAddTraits(.isHeader)
            VStack(spacing: 8, content: content)
        }
    }

    private func settingCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .foregroundStyle(Palette.textPrimary)
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.surfaceRaised.opacity(0.92), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Palette.hairline))
    }

    private func settingRow(_ title: String, detail: String, icon: String) -> some View {
        settingCard {
            HStack(spacing: 13) {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Palette.amber)
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 3) {
                    Text(title).font(Typography.headline)
                    Text(detail).font(Typography.caption).foregroundStyle(Palette.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Palette.textTertiary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
