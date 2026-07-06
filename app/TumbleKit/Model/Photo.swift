import Foundation
import SwiftData

/// A single shot. Stored as SwiftData metadata; the pixels live on disk in the
/// shared container (see `PhotoStore`). A photo starts life *undeveloped* —
/// blank and face-down in the Drawer — until the shooter shakes it to life.
@Model
public final class Photo {
    /// Stable identity, also used to name the image files on disk.
    public var id: UUID = UUID()
    public var capturedAt: Date = Date()

    /// False until shake-to-develop finishes; controls the blank face-down state.
    public var isDeveloped: Bool = false
    /// 0…1 develop progress, persisted so a half-shaken print resumes where it was.
    public var developProgress: Double = 0

    /// File names within the shared images directory.
    public var rawImageName: String?
    public var developedImageName: String?

    /// Drawer placement, generated once at capture so the scatter is stable
    /// across launches (never a grid). Percent offsets + rotation in degrees.
    public var scatterX: Double = 0
    public var scatterY: Double = 0
    public var rotation: Double = 0

    public var caption: String?
    /// Where the shot came from: the app or the lock-screen extension.
    public var source: String = PhotoSource.app.rawValue

    public init(
        id: UUID = UUID(),
        capturedAt: Date = Date(),
        source: PhotoSource = .app
    ) {
        self.id = id
        self.capturedAt = capturedAt
        self.source = source.rawValue
        let scatter = Photo.randomScatter()
        self.scatterX = scatter.x
        self.scatterY = scatter.y
        self.rotation = scatter.rotation
    }

    /// A loose, hand-tossed placement in the drawer area (percent offsets,
    /// gentle rotation) — echoes the site's `DrawerMockup` scatter.
    static func randomScatter() -> (x: Double, y: Double, rotation: Double) {
        (
            x: Double.random(in: 2...52),
            y: Double.random(in: 2...70),
            rotation: Double.random(in: -12...12)
        )
    }
}

public enum PhotoSource: String, Sendable {
    case app
    case lockscreen
}

public extension Photo {
    /// How aged the print looks, 0 (fresh) → 1 (fully warmed/faded), mapped
    /// over `agingSpan`. Purely a function of elapsed time — no stored state,
    /// so prints visibly warm as the days pass.
    static let agingSpan: TimeInterval = 60 * 60 * 24 * 30 // ~30 days

    func ageFraction(now: Date = Date()) -> Double {
        let elapsed = now.timeIntervalSince(capturedAt)
        return min(1, max(0, elapsed / Photo.agingSpan))
    }
}
