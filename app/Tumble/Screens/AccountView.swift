import AuthenticationServices
import SwiftUI
import TumbleKit

struct AccountView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    @State private var confirmDelete = false
    @State private var showAppleDeletion = false

    var body: some View {
        NavigationStack {
            ZStack {
                GraincoreBackground()
                ScrollView {
                    VStack(spacing: 14) {
                        if case let .signedIn(_, name, email, providers) = app.account.state {
                            accountCard(name: name, email: email, providers: providers)
                        } else {
                            signInCard
                        }
                        privacyCard
                        if let message = app.account.message {
                            Text(message)
                                .font(Typography.sans(13))
                                .foregroundStyle(Palette.cream.opacity(0.72))
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Tumble account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.foregroundStyle(Palette.gold)
                }
            }
            .toolbarBackground(Palette.blueDeep, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .confirmationDialog("Delete your Tumble account?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete account", role: .destructive) {
                if signedInProviders.contains(TumbleAuthProvider.apple.rawValue) {
                    showAppleDeletion = true
                } else {
                    Task { await app.account.reauthenticateWithGoogleAndDelete() }
                }
            }
        } message: {
            Text("This removes your sign-in identity. Photos stay on this device and store purchases remain restorable.")
        }
        .sheet(isPresented: $showAppleDeletion) { appleDeletionSheet }
    }

    private var signInCard: some View {
        VStack(spacing: 14) {
            Text("Carry your films across devices")
                .font(Typography.display(25))
                .foregroundStyle(Palette.cream)
            Text("The camera and Studio never require an account. Sign in only to buy or link film purchases across iOS and Android.")
                .font(Typography.sans(13))
                .foregroundStyle(Palette.cream.opacity(0.66))
                .multilineTextAlignment(.center)

            SignInWithAppleButton(.continue) { request in
                app.account.configureAppleRequest(request)
            } onCompletion: { result in
                Task { await app.account.finishApple(result) }
            }
            .signInWithAppleButtonStyle(.white)
            .frame(height: 50)

            Button { Task { await app.account.signInWithGoogle() } } label: {
                Label("Continue with Google", systemImage: "g.circle.fill")
                    .font(Typography.sans(15, weight: .semibold))
                    .foregroundStyle(Palette.ink)
                    .frame(maxWidth: .infinity).frame(height: 50)
                    .background(Palette.cream, in: RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .background(Palette.charcoalDeep.opacity(0.66), in: RoundedRectangle(cornerRadius: 22))
    }

    private func accountCard(name: String?, email: String?, providers: Set<String>) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(name ?? email ?? "Signed in")
                .font(Typography.display(25)).foregroundStyle(Palette.cream)
            if let email { Text(email).font(Typography.sans(13)).foregroundStyle(Palette.cream.opacity(0.62)) }
            Text("Linked: " + providers.compactMap { TumbleAuthProvider(rawValue: $0)?.title }.sorted().joined(separator: " · "))
                .font(Typography.sans(12, weight: .semibold)).foregroundStyle(Palette.gold)

            Button { Task { await app.account.linkPurchases() } } label: {
                Label(app.account.isLinkingPurchases ? "Linking…" : "Link existing purchases", systemImage: "arrow.triangle.2.circlepath")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent).tint(Palette.gold).foregroundStyle(Palette.ink)
            .disabled(app.account.isLinkingPurchases)

            if !providers.contains(TumbleAuthProvider.apple.rawValue) {
                SignInWithAppleButton(.continue) { request in
                    app.account.configureAppleRequest(request)
                } onCompletion: { result in
                    Task { await app.account.finishApple(result, link: true) }
                }
                .signInWithAppleButtonStyle(.white)
                .frame(height: 48)
            }
            if !providers.contains(TumbleAuthProvider.google.rawValue) {
                Button("Link Google") { Task { await app.account.signInWithGoogle(link: true) } }
                    .buttonStyle(.bordered).tint(Palette.cream)
            }

            Divider().overlay(Palette.cream.opacity(0.14))
            Button("Sign out") { Task { await app.account.signOut() } }
                .foregroundStyle(Palette.cream)
            Button("Delete account", role: .destructive) { confirmDelete = true }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.charcoalDeep.opacity(0.66), in: RoundedRectangle(cornerRadius: 22))
    }

    private var privacyCard: some View {
        Text("Firebase receives your sign-in identity. RevenueCat receives only an opaque account ID and purchase history. Tumble never uploads photo pixels, filenames, drafts, crops, or notes.")
            .font(Typography.sans(12))
            .foregroundStyle(Palette.cream.opacity(0.58))
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.black.opacity(0.22), in: RoundedRectangle(cornerRadius: 18))
    }

    private var signedInProviders: Set<String> {
        guard case let .signedIn(_, _, _, providers) = app.account.state else { return [] }
        return providers
    }

    private var appleDeletionSheet: some View {
        NavigationStack {
            VStack(spacing: 18) {
                Text("Confirm with Apple")
                    .font(Typography.display(30))
                Text("Apple requires a fresh authorization before Tumble can revoke its token and delete your account.")
                    .font(Typography.sans(14))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Palette.cream.opacity(0.7))
                SignInWithAppleButton(.continue) { request in
                    app.account.configureAppleRequest(request)
                } onCompletion: { result in
                    Task {
                        await app.account.finishAppleDeletion(result)
                        if !app.account.isSignedIn { showAppleDeletion = false }
                    }
                }
                .signInWithAppleButtonStyle(.white)
                .frame(height: 50)
            }
            .padding(26)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(GraincoreBackground())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showAppleDeletion = false }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
