import AuthenticationServices
import CryptoKit
@preconcurrency import FirebaseAuth
import FirebaseCore
import Foundation
import GoogleSignIn
import Observation
import RevenueCat
import TumbleKit
import UIKit

enum TumbleAuthProvider: String, CaseIterable, Sendable {
    case apple = "apple.com"
    case google = "google.com"

    var title: String { self == .apple ? "Apple" : "Google" }
}

enum TumbleAuthState: Equatable {
    case signedOut
    case authenticating
    case signedIn(uid: String, displayName: String?, email: String?, providers: Set<String>)
    case failure(String)
}

@MainActor
@Observable
final class AccountCoordinator {
    private(set) var state: TumbleAuthState = .signedOut
    private(set) var isLinkingPurchases = false
    private(set) var remoteEntitlements: Set<String> = []
    private(set) var message: String?

    @ObservationIgnored private var listener: AuthStateDidChangeListenerHandle?
    @ObservationIgnored private var customerTask: Task<Void, Never>?
    @ObservationIgnored private weak var purchases: PurchaseManager?
    @ObservationIgnored private var started = false

    var isSignedIn: Bool {
        if case .signedIn = state { true } else { false }
    }

    var user: User? { Auth.auth().currentUser }

    func start(purchases: PurchaseManager) async {
        self.purchases = purchases
        guard !started else { return }
        started = true
        listener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in await self?.apply(user: user) }
        }
        await apply(user: Auth.auth().currentUser)
    }

    func configureAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = Self.randomNonce()
        request.requestedScopes = [.fullName, .email]
        request.nonce = Self.sha256(nonce)
        UserDefaults.standard.set(nonce, forKey: "tumble.auth.appleNonce")
    }

    func finishApple(_ result: Result<ASAuthorization, Error>, link: Bool = false) async {
        state = .authenticating
        do {
            let authorization = try result.get()
            guard let apple = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let tokenData = apple.identityToken,
                  let token = String(data: tokenData, encoding: .utf8),
                  let nonce = UserDefaults.standard.string(forKey: "tumble.auth.appleNonce") else {
                throw AccountError.invalidAppleCredential
            }
            UserDefaults.standard.removeObject(forKey: "tumble.auth.appleNonce")
            let credential = OAuthProvider.appleCredential(
                withIDToken: token,
                rawNonce: nonce,
                fullName: apple.fullName
            )
            if link, let user = Auth.auth().currentUser {
                _ = try await user.link(with: credential)
            } else {
                _ = try await Auth.auth().signIn(with: credential)
            }
            message = nil
        } catch {
            present(error)
        }
    }

    func signInWithGoogle(link: Bool = false) async {
        state = .authenticating
        do {
            let credential = try await googleCredential()
            if link, let user = Auth.auth().currentUser {
                _ = try await user.link(with: credential)
            } else {
                _ = try await Auth.auth().signIn(with: credential)
            }
            message = nil
        } catch {
            present(error)
        }
    }

    func linkPurchases() async {
        guard isSignedIn else {
            message = "Sign in before linking purchases."
            return
        }
        guard revenueCatConfigured else {
            message = "Purchase linking is unavailable in this build."
            return
        }
        isLinkingPurchases = true
        defer { isLinkingPurchases = false }
        do {
            _ = try await Purchases.shared.syncPurchases()
            try await refreshRemoteEntitlements()
            await purchases?.refreshEntitlements()
            message = "Purchases linked to your Tumble account."
        } catch {
            present(error)
        }
    }

    func purchaseDidComplete() async {
        guard isSignedIn, revenueCatConfigured else { return }
        do {
            _ = try await Purchases.shared.syncPurchases()
            try await refreshRemoteEntitlements()
        } catch {
            message = "Your purchase is safe on this device. Account linking will retry later."
        }
    }

    func signOut() async {
        do {
            customerTask?.cancel()
            customerTask = nil
            applyRemote([])
            if revenueCatConfigured { _ = try await Purchases.shared.logOut() }
            try Auth.auth().signOut()
            GIDSignIn.sharedInstance.signOut()
            message = nil
        } catch {
            present(error)
        }
    }

    func deleteAccount() async {
        guard let user = Auth.auth().currentUser else { return }
        do {
            try await finishDeletion(user)
        } catch {
            message = "For security, sign in again and then retry account deletion."
        }
    }

    func reauthenticateWithGoogleAndDelete() async {
        guard let user = Auth.auth().currentUser else { return }
        state = .authenticating
        do {
            let credential = try await googleCredential()
            _ = try await user.reauthenticate(with: credential)
            try await finishDeletion(user)
        } catch {
            present(error)
        }
    }

    func finishAppleDeletion(_ result: Result<ASAuthorization, Error>) async {
        guard let user = Auth.auth().currentUser else { return }
        state = .authenticating
        do {
            let authorization = try result.get()
            guard let apple = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let tokenData = apple.identityToken,
                  let token = String(data: tokenData, encoding: .utf8),
                  let codeData = apple.authorizationCode,
                  let authorizationCode = String(data: codeData, encoding: .utf8),
                  let nonce = UserDefaults.standard.string(forKey: "tumble.auth.appleNonce") else {
                throw AccountError.invalidAppleCredential
            }
            UserDefaults.standard.removeObject(forKey: "tumble.auth.appleNonce")
            let credential = OAuthProvider.appleCredential(
                withIDToken: token,
                rawNonce: nonce,
                fullName: apple.fullName
            )
            _ = try await user.reauthenticate(with: credential)
            try await Auth.auth().revokeToken(withAuthorizationCode: authorizationCode)
            try await finishDeletion(user)
        } catch {
            present(error)
        }
    }

    func clearMessage() { message = nil }

    private var revenueCatConfigured: Bool {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "REVENUECAT_API_KEY") as? String else { return false }
        return !key.isEmpty && !key.contains("$(")
    }

    private func googleCredential() async throws -> AuthCredential {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw AccountError.googleNotConfigured
        }
        guard let presenter = Self.presentingViewController() else {
            throw AccountError.presentationUnavailable
        }
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presenter)
        guard let idToken = result.user.idToken?.tokenString else {
            throw AccountError.googleTokenMissing
        }
        return GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: result.user.accessToken.tokenString
        )
    }

    private func finishDeletion(_ user: User) async throws {
        customerTask?.cancel()
        customerTask = nil
        try await user.delete()
        if revenueCatConfigured { _ = try? await Purchases.shared.logOut() }
        applyRemote([])
        message = "Your Tumble account was deleted. Store purchases remain restorable."
    }

    private func apply(user: User?) async {
        guard let user else {
            customerTask?.cancel()
            customerTask = nil
            state = .signedOut
            applyRemote([])
            return
        }
        setSignedInState(user)
        guard revenueCatConfigured else { return }
        do {
            _ = try await Purchases.shared.logIn(user.uid)
            try await refreshRemoteEntitlements()
            startCustomerStream()
        } catch {
            message = "Signed in. Cross-platform purchases will refresh when the service is available."
        }
    }

    private func setSignedInState(_ user: User) {
        state = .signedIn(
            uid: user.uid,
            displayName: user.displayName,
            email: user.email,
            providers: Set(user.providerData.map(\.providerID))
        )
    }

    private func startCustomerStream() {
        customerTask?.cancel()
        customerTask = Task { [weak self] in
            for await info in Purchases.shared.customerInfoStream {
                guard !Task.isCancelled else { return }
                self?.consume(info)
            }
        }
    }

    private func refreshRemoteEntitlements() async throws {
        consume(try await Purchases.shared.customerInfo())
    }

    private func consume(_ info: CustomerInfo) {
        applyRemote(Set(info.entitlements.active.keys))
    }

    private func applyRemote(_ identifiers: Set<String>) {
        remoteEntitlements = identifiers
        purchases?.applyRemoteEntitlements(identifiers)
    }

    private func present(_ error: Error) {
        let nsError = error as NSError
        if nsError.domain == AuthErrorDomain,
           nsError.code == AuthErrorCode.accountExistsWithDifferentCredential.rawValue {
            message = "That email already belongs to another sign-in method. Sign in with it first, then link this one in Settings."
        } else if let user = Auth.auth().currentUser {
            setSignedInState(user)
            if !(nsError.domain == ASAuthorizationError.errorDomain &&
                 nsError.code == ASAuthorizationError.canceled.rawValue) {
                message = error.localizedDescription
            }
        } else if nsError.domain == ASAuthorizationError.errorDomain,
                  nsError.code == ASAuthorizationError.canceled.rawValue {
            state = .signedOut
        } else {
            message = error.localizedDescription
            state = .failure(error.localizedDescription)
        }
    }

    private static func randomNonce(length: Int = 32) -> String {
        let alphabet = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remaining = length
        while remaining > 0 {
            var bytes = [UInt8](repeating: 0, count: 16)
            let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
            precondition(status == errSecSuccess)
            for byte in bytes where byte < alphabet.count {
                result.append(alphabet[Int(byte)])
                remaining -= 1
                if remaining == 0 { break }
            }
        }
        return result
    }

    private static func sha256(_ value: String) -> String {
        SHA256.hash(data: Data(value.utf8)).map { String(format: "%02x", $0) }.joined()
    }

    private static func presentingViewController() -> UIViewController? {
        let scene = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
        var controller = scene?.keyWindow?.rootViewController
        while let presented = controller?.presentedViewController { controller = presented }
        return controller
    }
}

private enum AccountError: LocalizedError {
    case invalidAppleCredential, googleNotConfigured, googleTokenMissing, presentationUnavailable

    var errorDescription: String? {
        switch self {
        case .invalidAppleCredential: "Apple did not return a usable credential."
        case .googleNotConfigured: "Google sign-in is not configured in this build."
        case .googleTokenMissing: "Google did not return an identity token."
        case .presentationUnavailable: "The sign-in screen could not be presented."
        }
    }
}
