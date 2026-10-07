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
                        if case let .signedIn(_, name, email, providers) = app.account.state,
                           !DebugLaunch.previewsSignedOutAccount {
                            accountCard(name: name, email: email, providers: providers)
                        } else {
                            signInCard
                        }
                        privacyCard
                        if let message = app.account.message {
                            Text(message)
                                .font(Typography.caption)
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
        VStack(spacing: 20) {
            VStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Palette.printStock)
                        .frame(width: 58, height: 70)
                        .rotationEffect(.degrees(-9))
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Palette.gold.opacity(0.80))
                        .frame(width: 58, height: 70)
                        .rotationEffect(.degrees(8))
                    Image(systemName: "person.crop.circle.fill.badge.checkmark")
                        .font(.system(size: 34, weight: .medium))
                        .foregroundStyle(Palette.ink)
                }
                .frame(height: 78)

                Text("Optional Tumble account")
                    .trackedLabel()
                    .foregroundStyle(Palette.amber)
                Text("Keep your films with you")
                    .font(Typography.heroTitle)
                    .foregroundStyle(Palette.cream)
                Text("Sign in to carry purchases between iOS and Android. Taking photos and using Studio never needs an account.")
                    .font(Typography.caption)
                    .foregroundStyle(Palette.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(spacing: 11) {
                SignInWithAppleButton(.signIn) { request in
                    app.account.configureAppleRequest(request)
                } onCompletion: { result in
                    Task { await app.account.finishApple(result) }
                }
                .signInWithAppleButtonStyle(.white)
                .frame(height: 52)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                Button { Task { await app.account.signInWithGoogle() } } label: {
                    HStack(spacing: 10) {
                        GoogleLogo()
                            .frame(width: 22, height: 22)
                        Text("Sign in with Google")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .foregroundStyle(Color.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .disabled(isAuthenticating)

            if isAuthenticating {
                HStack(spacing: 9) {
                    ProgressView().tint(Palette.gold)
                    Text("Opening secure sign-in…")
                        .font(Typography.captionEmphasized)
                        .foregroundStyle(Palette.textSecondary)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
        .background(Palette.charcoalDeep.opacity(0.72), in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(Palette.cream.opacity(0.08))
        }
    }

    private func accountCard(name: String?, email: String?, providers: Set<String>) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(name ?? email ?? "Signed in")
                .font(Typography.title).foregroundStyle(Palette.cream)
            if let email { Text(email).font(Typography.caption).foregroundStyle(Palette.textSecondary) }
            Text("Linked: " + providers.compactMap { TumbleAuthProvider(rawValue: $0)?.title }.sorted().joined(separator: " · "))
                .font(Typography.captionEmphasized).foregroundStyle(Palette.gold)

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
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Palette.gold)
            VStack(alignment: .leading, spacing: 4) {
                Text("Your photos stay private")
                    .font(Typography.captionEmphasized)
                    .foregroundStyle(Palette.cream)
                Text("Sign-in links purchase access only. Tumble never uploads photo pixels, filenames, drafts, crops, or notes.")
                    .font(Typography.caption)
                    .foregroundStyle(Palette.textSecondary)
            }
        }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.black.opacity(0.22), in: RoundedRectangle(cornerRadius: 18))
    }

    private var isAuthenticating: Bool {
        if case .authenticating = app.account.state { return true }
        return false
    }

    private var signedInProviders: Set<String> {
        guard case let .signedIn(_, _, _, providers) = app.account.state else { return [] }
        return providers
    }

    private var appleDeletionSheet: some View {
        NavigationStack {
            VStack(spacing: 18) {
                Text("Confirm with Apple")
                    .font(Typography.heroTitle)
                Text("Apple requires a fresh authorization before Tumble can revoke its token and delete your account.")
                    .font(Typography.body)
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

/// The official multicolor mark ships inside GoogleSignIn's resource bundle.
/// We use only that mark and let Tumble own the surrounding button so the two
/// providers share one visual system instead of stacking two incompatible SDK
/// button styles.
private struct GoogleLogo: View {
    private static let image: UIImage? = {
        guard let bundleURL = Bundle.main.url(
            forResource: "GoogleSignIn_GoogleSignIn",
            withExtension: "bundle"
        ), let resources = Bundle(url: bundleURL) else { return nil }
        return UIImage(named: "google", in: resources, compatibleWith: nil)
    }()

    var body: some View {
        if let image = Self.image {
            Image(uiImage: image)
                .resizable()
                .interpolation(.high)
                .scaledToFit()
        } else {
            Color.clear
        }
    }
}
