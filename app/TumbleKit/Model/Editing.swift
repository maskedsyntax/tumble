import CoreGraphics
import Foundation

public enum EditSourceKind: String, Codable, Sendable {
    case camera
    case library
}

public enum StudioRoute: Equatable, Sendable {
    case home
    case camera
    case studio(UUID)
    case finish(UUID)
}

public enum HomeEntryPoint: String, Equatable, Sendable {
    case primary
    case camera
    case filmCard = "film_card"
    case postcardCard = "postcard_card"
}

public enum IntendedFinishFormat: String, Equatable, Sendable {
    case photo
    case postcard
}

/// A launch choice only. Once a draft is created its recipe is the source of
/// truth, so this intent is deliberately never encoded or restored.
public struct HomeEditIntent: Equatable, Sendable {
    public var entryPoint: HomeEntryPoint
    public var initialFilmID: String
    public var intendedFormat: IntendedFinishFormat?

    public init(
        entryPoint: HomeEntryPoint,
        initialFilmID: String,
        intendedFormat: IntendedFinishFormat? = nil
    ) {
        self.entryPoint = entryPoint
        self.initialFilmID = initialFilmID
        self.intendedFormat = intendedFormat
    }

    public var initialRecipe: EditRecipe {
        EditRecipe(
            stockID: initialFilmID,
            frameID: intendedFormat == .postcard
                ? PostcardFrameStyle.classicInstant.rawValue
                : PostcardFrameStyle.none.rawValue
        )
    }
}

public enum CropPreset: String, CaseIterable, Codable, Identifiable, Sendable {
    case original
    case freeform
    case square
    case portrait
    case story

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .original: "Original"
        case .freeform: "Free"
        case .square: "1:1"
        case .portrait: "4:5"
        case .story: "9:16"
        }
    }

    /// Spoken name, since "4:5" reads poorly.
    public var accessibilityName: String {
        switch self {
        case .original: "Original"
        case .freeform: "Free"
        case .square: "Square"
        case .portrait: "4 by 5"
        case .story: "9 by 16"
        }
    }

    public var aspectRatio: Double? {
        switch self {
        case .original, .freeform: nil
        case .square: 1
        case .portrait: 4.0 / 5.0
        case .story: 9.0 / 16.0
        }
    }
}

public struct NormalizedCrop: Codable, Equatable, Sendable {
    public var x: Double
    public var y: Double
    public var width: Double
    public var height: Double

    public static let full = NormalizedCrop(x: 0, y: 0, width: 1, height: 1)

    public init(x: Double, y: Double, width: Double, height: Double) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }

    public var clamped: Self {
        let safeWidth = min(1, max(0.05, width))
        let safeHeight = min(1, max(0.05, height))
        return Self(
            x: min(1 - safeWidth, max(0, x)),
            y: min(1 - safeHeight, max(0, y)),
            width: safeWidth,
            height: safeHeight
        )
    }
}

/// The edit applied to a draft. `crop` is stored in the renderer's
/// coordinate space: normalized, with its origin at the bottom-left of the
/// straightened image (the convention shipped in 3.0). A full crop on an
/// aspect preset means "centered"; any other crop is used as drawn.
/// Pure geometry shared by the renderer and the crop interface, so the
/// preview and the export always agree.
public enum CropGeometry {
    public static let straightenLimit: Double = 45

    public static func clampStraighten(_ degrees: Double) -> Double {
        guard degrees.isFinite else { return 0 }
        return min(straightenLimit, max(-straightenLimit, degrees))
    }

    /// Scale of the largest rectangle with the image's own aspect, centered,
    /// that fits inside the image after rotating it by `degrees`. 1 at 0°.
    public static func inscribedScale(width: Double, height: Double, degrees: Double) -> Double {
        guard width > 0, height > 0 else { return 1 }
        let theta = abs(clampStraighten(degrees)) * .pi / 180
        guard theta > 0 else { return 1 }
        let c = cos(theta)
        let s = sin(theta)
        return min(width / (width * c + height * s), height / (width * s + height * c))
    }

    /// The largest centered crop with `aspect` (width / height) inside an
    /// image whose aspect is `imageAspect`. `nil` aspect means the full frame.
    public static func centeredCrop(aspect: Double?, imageAspect: Double) -> NormalizedCrop {
        guard let aspect, aspect > 0, imageAspect > 0 else { return .full }
        if imageAspect > aspect {
            let width = aspect / imageAspect
            return NormalizedCrop(x: (1 - width) / 2, y: 0, width: width, height: 1)
        }
        let height = imageAspect / aspect
        return NormalizedCrop(x: 0, y: (1 - height) / 2, width: 1, height: height)
    }

    /// The aspect a preset locks the crop to, for an image of `imageAspect`.
    /// Original locks to the image's own shape; Free is unlocked.
    public static func lockedAspect(for preset: CropPreset, imageAspect: Double) -> Double? {
        switch preset {
        case .original: imageAspect
        case .freeform: nil
        case .square, .portrait, .story: preset.aspectRatio
        }
    }

    /// The normalized crop the renderer will use. A full crop on an aspect
    /// preset means the largest centered crop of that aspect.
    public static func effectiveCrop(for recipe: EditRecipe, imageAspect: Double) -> NormalizedCrop {
        switch recipe.cropPreset {
        case .freeform:
            return recipe.crop.clamped
        case .original, .square, .portrait, .story:
            guard recipe.crop != .full else {
                return centeredCrop(
                    aspect: lockedAspect(for: recipe.cropPreset, imageAspect: imageAspect),
                    imageAspect: imageAspect
                )
            }
            return recipe.crop.clamped
        }
    }

    /// The crop rectangle in pixels for an image of `size`, honoring the
    /// "full crop on an aspect preset means centered" rule.
    public static func cropRect(
        for recipe: EditRecipe,
        in size: CGSize
    ) -> CGRect {
        let crop = effectiveCrop(for: recipe, imageAspect: size.width / max(1, size.height))
        return CGRect(
            x: size.width * crop.x,
            y: size.height * crop.y,
            width: size.width * crop.width,
            height: size.height * crop.height
        )
    }
}

public struct EditRecipe: Codable, Equatable, Sendable {
    public var stockID: String
    public var intensity: Double
    public var cropPreset: CropPreset
    public var crop: NormalizedCrop
    public var quarterTurns: Int
    /// Fine rotation in degrees, clockwise, within ±`CropGeometry.straightenLimit`.
    public var straighten: Double
    public var frameID: String
    public var note: String

    public init(
        stockID: String = FilmStockCatalog.defaultStock.id,
        intensity: Double = 1,
        cropPreset: CropPreset = .original,
        crop: NormalizedCrop = .full,
        quarterTurns: Int = 0,
        straighten: Double = 0,
        frameID: String = PostcardFrameStyle.none.rawValue,
        note: String = ""
    ) {
        self.stockID = stockID
        self.intensity = min(1, max(0, intensity))
        self.cropPreset = cropPreset
        self.crop = crop.clamped
        self.quarterTurns = ((quarterTurns % 4) + 4) % 4
        self.straighten = CropGeometry.clampStraighten(straighten)
        self.frameID = frameID
        self.note = PostcardNote.clamp(note)
    }

    /// Drafts saved by earlier versions lack newer keys; every field falls
    /// back to its default so a resumed edit always opens.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            stockID: try container.decodeIfPresent(String.self, forKey: .stockID) ?? FilmStockCatalog.defaultStock.id,
            intensity: try container.decodeIfPresent(Double.self, forKey: .intensity) ?? 1,
            cropPreset: try container.decodeIfPresent(CropPreset.self, forKey: .cropPreset) ?? .original,
            crop: try container.decodeIfPresent(NormalizedCrop.self, forKey: .crop) ?? .full,
            quarterTurns: try container.decodeIfPresent(Int.self, forKey: .quarterTurns) ?? 0,
            straighten: try container.decodeIfPresent(Double.self, forKey: .straighten) ?? 0,
            frameID: try container.decodeIfPresent(String.self, forKey: .frameID) ?? PostcardFrameStyle.none.rawValue,
            note: try container.decodeIfPresent(String.self, forKey: .note) ?? ""
        )
    }

    /// Image aspect (width / height) after quarter turns, for a source of
    /// the given pixel size. Straightening preserves aspect.
    public func orientedAspect(sourceWidth: Double, sourceHeight: Double) -> Double {
        guard sourceWidth > 0, sourceHeight > 0 else { return 1 }
        return quarterTurns % 2 == 0 ? sourceWidth / sourceHeight : sourceHeight / sourceWidth
    }

    public var stock: FilmStock { FilmStockCatalog.resolve(stockID) }
    public var frameStyle: PostcardFrameStyle { PostcardFrameStyle(rawValue: frameID) ?? .none }
}

public struct EditDraft: Codable, Identifiable, Equatable, Sendable {
    public let id: UUID
    public var sourceFile: String
    public var sourceKind: EditSourceKind
    public var capturedAt: Date
    public var recipe: EditRecipe
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        sourceFile: String,
        sourceKind: EditSourceKind,
        capturedAt: Date = Date(),
        recipe: EditRecipe,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.sourceFile = sourceFile
        self.sourceKind = sourceKind
        self.capturedAt = capturedAt
        self.recipe = recipe
        self.updatedAt = updatedAt
    }
}

public enum AccessState: Equatable, Sendable {
    case free(legacyPackIDs: Set<String>)
    case complete

    public func unlocks(_ stock: FilmStock) -> Bool {
        switch self {
        case .complete: true
        case .free(let legacyPackIDs):
            stock.packID == FilmStockCatalog.PackID.core || legacyPackIDs.contains(stock.packID)
        }
    }
}
