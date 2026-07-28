import Foundation
import CoreGraphics

/// The frame a developed print is mounted in when saved to the Photos
/// library. `none` saves the filtered photo at its original ratio.
public enum PostcardFrameStyle: String, CaseIterable, Identifiable, Sendable {
    case none
    case classicInstant
    case vintagePostcard
    case borderedFilm
    case deckledEdge

    public static let storageKey = "tumble.postcardFrameStyle"
    /// The pre-frames boolean preference; migrated on first read.
    static let legacyIncludesFrameKey = "tumble.saveIncludesPostcardFrame"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .none: return "No Frame"
        case .classicInstant: return "Classic Instant"
        case .vintagePostcard: return "Vintage Postcard"
        case .borderedFilm: return "Bordered Film"
        case .deckledEdge: return "Deckled Edge"
        }
    }

    /// Short label for the frame picker, where space is tight and every
    /// option's label must render at the same size.
    public var shortName: String {
        switch self {
        case .none: return "No Frame"
        case .classicInstant: return "Classic"
        case .vintagePostcard: return "Vintage"
        case .borderedFilm: return "Film"
        case .deckledEdge: return "Deckled"
        }
    }

    public var tagline: String {
        switch self {
        case .none: return "Just the photo, original ratio."
        case .classicInstant: return "The Tumble print, cream stock and all."
        case .vintagePostcard: return "Stamp box, postmark, and room to write."
        case .borderedFilm: return "Full-bleed with a burnt-in date stamp."
        case .deckledEdge: return "Torn paper edge, taped to the page."
        }
    }

    /// Approximate height/width ratio of the rendered frame, so previews and
    /// thumbnails can be sized to fit instead of clipped.
    public var aspect: CGFloat {
        switch self {
        case .none: return 1.0
        case .classicInstant: return 1.16
        case .vintagePostcard: return 1.37
        case .borderedFilm: return 1.25
        case .deckledEdge: return 1.2
        }
    }

    /// The stored preference, migrating the old "save as postcard" toggle:
    /// on -> Classic Instant, off/never set -> no frame.
    public static func stored(defaults: UserDefaults = .standard) -> Self {
        if let raw = defaults.string(forKey: storageKey),
           let style = Self(rawValue: raw) {
            return style
        }
        if defaults.object(forKey: legacyIncludesFrameKey) != nil {
            let migrated: Self = defaults.bool(forKey: legacyIncludesFrameKey) ? .classicInstant : .none
            defaults.set(migrated.rawValue, forKey: storageKey)
            defaults.removeObject(forKey: legacyIncludesFrameKey)
            return migrated
        }
        return .none
    }
}

/// Rules for the handwritten note scribbled on a postcard frame.
public enum PostcardNote {
    /// Hard cap - past this the note crowds the frame and looks bad.
    public static let maxLength = 60

    /// Trim to the limit and collapse newlines (notes render on one line).
    public static func clamp(_ text: String) -> String {
        let flattened = text.replacingOccurrences(of: "\n", with: " ")
        return String(flattened.prefix(maxLength))
    }
}
