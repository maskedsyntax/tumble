import SwiftUI
import UIKit

/// After the system photo picker has been shown, SwiftUI can present a
/// following full-screen cover with zero safe-area insets even though the
/// window still has them (seen on iOS 26: the top bar slides under the
/// status bar and stops receiving taps). This restores only the missing
/// part of the window's insets, and stands down if SwiftUI reports them
/// correctly.
private struct SafeAreaRepair: ViewModifier {
    @State private var deficit = EdgeInsets()

    func body(content: Content) -> some View {
        content
            .safeAreaPadding(.top, deficit.top)
            .safeAreaPadding(.bottom, deficit.bottom)
            // Measured outside the padding above, so this reads SwiftUI's
            // own insets and the correction cannot feed back into itself.
            .background {
                GeometryReader { proxy in
                    Color.clear
                        .onAppear { update(reported: proxy.safeAreaInsets) }
                        .onChange(of: proxy.safeAreaInsets) { _, insets in update(reported: insets) }
                }
            }
    }

    private func update(reported: EdgeInsets) {
        guard let window = Self.keyWindow else { return }
        let next = EdgeInsets(
            top: max(0, window.safeAreaInsets.top - reported.top),
            leading: 0,
            bottom: max(0, window.safeAreaInsets.bottom - reported.bottom),
            trailing: 0
        )
        if next != deficit { deficit = next }
    }

    private static var keyWindow: UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)
    }
}

extension View {
    /// Apply to the root of a full-screen cover.
    func repairingSafeArea() -> some View {
        modifier(SafeAreaRepair())
    }
}
