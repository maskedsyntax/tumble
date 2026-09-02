import Foundation

public enum EditSourceKind: String, Codable, Sendable {
    case camera
    case library
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

public struct EditRecipe: Codable, Equatable, Sendable {
    public var stockID: String
    public var intensity: Double
    public var cropPreset: CropPreset
    public var crop: NormalizedCrop
    public var quarterTurns: Int
    public var frameID: String
    public var note: String

    public init(
        stockID: String = FilmStockCatalog.defaultStock.id,
        intensity: Double = 1,
        cropPreset: CropPreset = .original,
        crop: NormalizedCrop = .full,
        quarterTurns: Int = 0,
        frameID: String = PostcardFrameStyle.none.rawValue,
        note: String = ""
    ) {
        self.stockID = stockID
        self.intensity = min(1, max(0, intensity))
        self.cropPreset = cropPreset
        self.crop = crop.clamped
        self.quarterTurns = ((quarterTurns % 4) + 4) % 4
        self.frameID = frameID
        self.note = PostcardNote.clamp(note)
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
