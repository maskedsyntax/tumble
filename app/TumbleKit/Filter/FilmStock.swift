import Foundation

/// A colour bias, applied additively and scaled by whatever strength the stage
/// asks for. Kept as plain doubles so a `FilmGrade` stays a value type with no
/// CoreImage or SwiftUI dependency - the catalog is data, not rendering.
public struct FilmTint: Sendable, Hashable {
    public let red: Double
    public let green: Double
    public let blue: Double

    public init(red: Double, green: Double, blue: Double) {
        self.red = red
        self.green = green
        self.blue = blue
    }

    public static let neutral = FilmTint(red: 0, green: 0, blue: 0)
}

/// Where a light leak enters the frame. Real leaks come from a specific seam in
/// the camera body, so each style is a fixed position rather than a random one.
public enum LightLeakStyle: String, Sendable, Hashable {
    case none
    /// Warm bloom creeping in from the bottom-right, the classic back-door leak.
    case cornerWarm
    /// Hot red band down one edge, like film fogged at the cartridge mouth.
    case edgeRed
    /// Flare washing across the top of the frame.
    case topFlare
}

/// Everything that makes one film stock look different from another.
///
/// Every field defaults to a neutral value, so a stock in the catalog only
/// spells out what it actually changes. That is the point of the type: adding
/// a look is adding data here, never another branch in a `switch`.
public struct FilmGrade: Sendable, Hashable {
    // Base tone - the original four knobs from the v1.1 preset model.
    public var saturation: Double
    public var contrast: Double
    public var brightness: Double
    public var blackLift: Double

    /// Warm/cool push through the colour matrix. Negative goes cool.
    public var warmth: Double

    // Texture.
    public var halation: Double
    public var grain: Double
    public var vignette: Double

    /// 0 leaves colour alone, 1 is fully desaturated toward `monoTint`.
    public var monochrome: Double
    public var monoTint: FilmTint

    /// Pulls the highlights down for a matte, faded top end.
    public var fade: Double

    /// Soft overall glow. Unlike `halation` this is not masked to highlights,
    /// so it reads as a hazy lens rather than film bleed.
    public var bloom: Double

    // Split toning: colour the shadows one way and the highlights another.
    public var shadowTint: FilmTint
    public var shadowStrength: Double
    public var highlightTint: FilmTint
    public var highlightStrength: Double

    public var leak: LightLeakStyle
    public var leakStrength: Double

    /// Burns the capture date into the corner in amber, the way a point-and-
    /// shoot did. Every shared photo carrying it is free advertising.
    public var stampsDate: Bool

    public init(
        saturation: Double = 1.0,
        contrast: Double = 1.0,
        brightness: Double = 0,
        blackLift: Double = 0,
        warmth: Double = 0,
        halation: Double = 0,
        grain: Double = 0,
        vignette: Double = 0,
        monochrome: Double = 0,
        monoTint: FilmTint = .neutral,
        fade: Double = 0,
        bloom: Double = 0,
        shadowTint: FilmTint = .neutral,
        shadowStrength: Double = 0,
        highlightTint: FilmTint = .neutral,
        highlightStrength: Double = 0,
        leak: LightLeakStyle = .none,
        leakStrength: Double = 0,
        stampsDate: Bool = false
    ) {
        self.saturation = saturation
        self.contrast = contrast
        self.brightness = brightness
        self.blackLift = blackLift
        self.warmth = warmth
        self.halation = halation
        self.grain = grain
        self.vignette = vignette
        self.monochrome = monochrome
        self.monoTint = monoTint
        self.fade = fade
        self.bloom = bloom
        self.shadowTint = shadowTint
        self.shadowStrength = shadowStrength
        self.highlightTint = highlightTint
        self.highlightStrength = highlightStrength
        self.leak = leak
        self.leakStrength = leakStrength
        self.stampsDate = stampsDate
    }

    /// A grade that changes nothing. Lets the renderer hand back the original
    /// pixels untouched instead of running a no-op pipeline over them.
    public static let identity = FilmGrade()

    public var isIdentity: Bool { self == .identity }
}

/// One named look, belonging to one pack.
public struct FilmStock: Identifiable, Sendable, Hashable {
    /// Stable and persisted on each `Photo`. Never rename one of these.
    public let id: String
    public let name: String
    /// Short line for the picker, describing the feeling rather than the maths.
    public let blurb: String
    public let packID: String
    public let grade: FilmGrade

    public init(id: String, name: String, blurb: String, packID: String, grade: FilmGrade) {
        self.id = id
        self.name = name
        self.blurb = blurb
        self.packID = packID
        self.grade = grade
    }
}

/// A group of stocks sold - or given away - together. Packs are the content
/// cadence: each new one is a reason to come back, without a subscription.
public struct FilmPack: Identifiable, Sendable, Hashable {
    public let id: String
    public let name: String
    public let blurb: String
    /// `nil` for the free pack; otherwise the StoreKit product to unlock it.
    public let productID: String?

    public init(id: String, name: String, blurb: String, productID: String?) {
        self.id = id
        self.name = name
        self.blurb = blurb
        self.productID = productID
    }

    public var isFree: Bool { productID == nil }
}

/// The library. Adding a look means adding an entry here.
public enum FilmStockCatalog {
    public enum PackID {
        public static let core = "core"
        public static let nineties = "nineties"
        public static let darkroom = "darkroom"
        public static let summer = "summer"
    }

    /// Ids carried over from the v1.1 two-preset model. These strings are
    /// persisted in `UserDefaults` on shipped devices, so they must keep
    /// resolving forever.
    public enum LegacyID {
        public static let fadedInstant = "fadedInstant"
        public static let warmArchive = "warmArchive"
    }

    /// Buys every paid pack at once, for less than the sum of its parts. Not a
    /// pack itself - it owns no stocks, it just unlocks the ones that exist -
    /// so it lives here rather than in `packs`.
    private static let sharedManifest = SharedFilmManifest.load()
    public static let bundleProductID = sharedManifest?.completeProductID ?? "com.tumble.pack.all"

    /// Every product that can unlock the pack, cheapest path first. Ownership of
    /// any one of these is enough.
    public static func unlockProductIDs(for packID: String) -> [String] {
        guard let productID = pack(for: packID)?.productID else { return [] }
        return [productID, bundleProductID]
    }

    /// Every paid product the store should load: the packs plus the bundle.
    public static var allProductIDs: [String] {
        packs.compactMap(\.productID) + [bundleProductID]
    }

    private static let fallbackPacks: [FilmPack] = [
        FilmPack(
            id: PackID.core,
            name: "The Roll",
            blurb: "The everyday stocks, free with the app.",
            productID: nil
        ),
        FilmPack(
            id: PackID.nineties,
            name: "Ninety-Six",
            blurb: "Drugstore disposables, flash and all.",
            productID: "com.tumble.pack.nineties"
        ),
        FilmPack(
            id: PackID.darkroom,
            name: "Darkroom",
            blurb: "Black and white, printed by hand.",
            // Not `.darkroom`: that ID was burned on a draft created as a
            // consumable, and App Store Connect reserves IDs forever.
            productID: "com.tumble.pack.darkroom2"
        ),
        FilmPack(
            id: PackID.summer,
            name: "Long Summer",
            blurb: "Leaks, flares and blown-out afternoons.",
            productID: "com.tumble.pack.summer"
        ),
    ]

    /// Both apps load this versioned resource. The in-code values remain only
    /// as an upgrade-safe fallback if a damaged bundle is ever installed.
    public static let packs: [FilmPack] = sharedManifest?.packs ?? fallbackPacks
    public static let all: [FilmStock] = sharedManifest?.stocks ?? (coreStocks + ninetiesStocks + darkroomStocks + summerStocks)

    // MARK: - Core, free

    private static let coreStocks: [FilmStock] = [
        FilmStock(
            id: "original",
            name: "Original",
            blurb: "Straight off the sensor.",
            packID: PackID.core,
            grade: .identity
        ),
        FilmStock(
            id: LegacyID.fadedInstant,
            name: "Faded Instant",
            blurb: "Milky blacks, muted colour.",
            packID: PackID.core,
            // Unchanged from v1.1 so upgrading prints keep their exact look.
            grade: FilmGrade(
                saturation: 0.62,
                contrast: 0.80,
                brightness: 0.030,
                blackLift: 0.110,
                warmth: 0.30,
                halation: 0.16,
                grain: 0.24,
                vignette: 0.16
            )
        ),
        FilmStock(
            id: LegacyID.warmArchive,
            name: "Warm Archive",
            blurb: "A photo that sat in a shoebox.",
            packID: PackID.core,
            grade: FilmGrade(
                saturation: 1.05,
                contrast: 1.00,
                brightness: -0.005,
                blackLift: 0.030,
                warmth: 1.40,
                halation: 0.12,
                grain: 0.20,
                vignette: 0.22
            )
        ),
        FilmStock(
            id: "overcast",
            name: "Overcast",
            blurb: "Flat grey light, gently cool.",
            packID: PackID.core,
            grade: FilmGrade(
                saturation: 0.86,
                contrast: 0.92,
                brightness: 0.010,
                blackLift: 0.070,
                warmth: -0.45,
                grain: 0.16,
                vignette: 0.10,
                fade: 0.14,
                shadowTint: FilmTint(red: -0.010, green: 0.004, blue: 0.030),
                shadowStrength: 0.7
            )
        ),
        FilmStock(
            id: "sunbleached",
            name: "Sunbleached",
            blurb: "Left too long on the dashboard.",
            packID: PackID.core,
            grade: FilmGrade(
                saturation: 0.74,
                contrast: 0.88,
                brightness: 0.045,
                blackLift: 0.130,
                warmth: 0.85,
                halation: 0.20,
                grain: 0.22,
                vignette: 0.08,
                fade: 0.26,
                highlightTint: FilmTint(red: 0.030, green: 0.018, blue: -0.010),
                highlightStrength: 0.8
            )
        ),
        FilmStock(
            id: "everyday",
            name: "Everyday",
            blurb: "Clean colour, a little grain.",
            packID: PackID.core,
            grade: FilmGrade(
                saturation: 1.08,
                contrast: 1.04,
                blackLift: 0.020,
                warmth: 0.25,
                halation: 0.06,
                grain: 0.12,
                vignette: 0.10
            )
        ),
    ]

    // MARK: - Ninety-Six

    private static let ninetiesStocks: [FilmStock] = [
        FilmStock(
            id: "disposable",
            name: "Disposable",
            blurb: "Twenty-seven exposures, drugstore print.",
            packID: PackID.nineties,
            grade: FilmGrade(
                saturation: 1.18,
                contrast: 1.12,
                brightness: 0.010,
                blackLift: 0.050,
                warmth: 0.70,
                halation: 0.18,
                grain: 0.34,
                vignette: 0.26
            )
        ),
        FilmStock(
            id: "flashNight",
            name: "Flash Night",
            blurb: "Hard flash, black behind it.",
            packID: PackID.nineties,
            grade: FilmGrade(
                saturation: 1.12,
                contrast: 1.30,
                brightness: 0.030,
                blackLift: -0.020,
                warmth: 0.20,
                halation: 0.32,
                grain: 0.30,
                vignette: 0.42,
                bloom: 0.18
            )
        ),
        FilmStock(
            id: "dateStamp",
            name: "Date Stamp",
            blurb: "The orange numbers in the corner.",
            packID: PackID.nineties,
            grade: FilmGrade(
                saturation: 1.14,
                contrast: 1.10,
                blackLift: 0.045,
                warmth: 0.60,
                halation: 0.16,
                grain: 0.30,
                vignette: 0.24,
                stampsDate: true
            )
        ),
        FilmStock(
            id: "poolParty",
            name: "Pool Party",
            blurb: "Chlorine blue, blown highlights.",
            packID: PackID.nineties,
            grade: FilmGrade(
                saturation: 1.24,
                contrast: 1.06,
                brightness: 0.040,
                blackLift: 0.060,
                warmth: -0.55,
                halation: 0.22,
                grain: 0.20,
                vignette: 0.12,
                fade: 0.16,
                highlightTint: FilmTint(red: -0.020, green: 0.010, blue: 0.040),
                highlightStrength: 0.9
            )
        ),
        FilmStock(
            id: "camcorder",
            name: "Camcorder",
            blurb: "Tape hiss, but for a photo.",
            packID: PackID.nineties,
            grade: FilmGrade(
                saturation: 0.94,
                contrast: 1.16,
                brightness: 0.020,
                blackLift: 0.090,
                warmth: -0.20,
                grain: 0.46,
                vignette: 0.30,
                bloom: 0.24,
                shadowTint: FilmTint(red: 0.006, green: 0.020, blue: 0.010),
                shadowStrength: 0.8
            )
        ),
    ]

    // MARK: - Darkroom

    private static let darkroomStocks: [FilmStock] = [
        FilmStock(
            id: "silver",
            name: "Silver",
            blurb: "Neutral black and white.",
            packID: PackID.darkroom,
            grade: FilmGrade(
                contrast: 1.10,
                blackLift: 0.030,
                grain: 0.26,
                vignette: 0.18,
                monochrome: 1.0
            )
        ),
        FilmStock(
            id: "charcoal",
            name: "Charcoal",
            blurb: "Hard contrast, deep blacks.",
            packID: PackID.darkroom,
            grade: FilmGrade(
                contrast: 1.42,
                brightness: -0.020,
                blackLift: -0.030,
                grain: 0.34,
                vignette: 0.34,
                monochrome: 1.0
            )
        ),
        FilmStock(
            id: "sepiaPrint",
            name: "Sepia Print",
            blurb: "Toned brown in the tray.",
            packID: PackID.darkroom,
            grade: FilmGrade(
                contrast: 1.04,
                blackLift: 0.060,
                grain: 0.24,
                vignette: 0.24,
                monochrome: 1.0,
                monoTint: FilmTint(red: 0.055, green: 0.022, blue: -0.030),
                fade: 0.12
            )
        ),
        FilmStock(
            id: "platinum",
            name: "Platinum",
            blurb: "Long, soft, silvery scale.",
            packID: PackID.darkroom,
            grade: FilmGrade(
                contrast: 0.86,
                brightness: 0.025,
                blackLift: 0.120,
                grain: 0.18,
                vignette: 0.12,
                monochrome: 1.0,
                monoTint: FilmTint(red: 0.008, green: 0.010, blue: 0.020),
                fade: 0.22
            )
        ),
        FilmStock(
            id: "newsprint",
            name: "Newsprint",
            blurb: "Coarse, grey, printed cheap.",
            packID: PackID.darkroom,
            grade: FilmGrade(
                contrast: 1.24,
                brightness: 0.015,
                blackLift: 0.080,
                grain: 0.58,
                vignette: 0.16,
                monochrome: 0.94,
                monoTint: FilmTint(red: 0.014, green: 0.012, blue: 0.004),
                fade: 0.10
            )
        ),
    ]

    // MARK: - Long Summer

    private static let summerStocks: [FilmStock] = [
        FilmStock(
            id: "lightLeak",
            name: "Light Leak",
            blurb: "The back door came open.",
            packID: PackID.summer,
            grade: FilmGrade(
                saturation: 1.10,
                contrast: 1.02,
                blackLift: 0.070,
                warmth: 0.75,
                halation: 0.20,
                grain: 0.24,
                vignette: 0.14,
                leak: .cornerWarm,
                leakStrength: 0.85
            )
        ),
        FilmStock(
            id: "goldenHour",
            name: "Golden Hour",
            blurb: "The last twenty minutes of light.",
            packID: PackID.summer,
            grade: FilmGrade(
                saturation: 1.16,
                contrast: 1.00,
                brightness: 0.020,
                blackLift: 0.055,
                warmth: 1.25,
                halation: 0.28,
                grain: 0.16,
                vignette: 0.18,
                bloom: 0.14,
                highlightTint: FilmTint(red: 0.040, green: 0.020, blue: -0.020),
                highlightStrength: 1.0
            )
        ),
        FilmStock(
            id: "fogged",
            name: "Fogged",
            blurb: "Red light got to the roll.",
            packID: PackID.summer,
            grade: FilmGrade(
                saturation: 0.98,
                contrast: 0.94,
                brightness: 0.020,
                blackLift: 0.140,
                warmth: 0.55,
                grain: 0.28,
                vignette: 0.10,
                fade: 0.24,
                leak: .edgeRed,
                leakStrength: 0.7
            )
        ),
        FilmStock(
            id: "crossProcess",
            name: "Cross Process",
            blurb: "Wrong chemistry, right result.",
            packID: PackID.summer,
            grade: FilmGrade(
                saturation: 1.42,
                contrast: 1.28,
                blackLift: 0.040,
                warmth: -0.40,
                halation: 0.14,
                grain: 0.22,
                vignette: 0.26,
                shadowTint: FilmTint(red: -0.020, green: 0.020, blue: 0.050),
                shadowStrength: 1.0,
                highlightTint: FilmTint(red: 0.040, green: 0.030, blue: -0.030),
                highlightStrength: 0.9
            )
        ),
        FilmStock(
            id: "hazyFlare",
            name: "Hazy",
            blurb: "Shot straight into the sun.",
            packID: PackID.summer,
            grade: FilmGrade(
                saturation: 0.92,
                contrast: 0.84,
                brightness: 0.050,
                blackLift: 0.170,
                warmth: 0.65,
                halation: 0.26,
                grain: 0.18,
                fade: 0.34,
                bloom: 0.30,
                leak: .topFlare,
                leakStrength: 0.55
            )
        ),
    ]

    // MARK: - Lookup

    private static let byID: [String: FilmStock] = Dictionary(
        uniqueKeysWithValues: all.map { ($0.id, $0) }
    )

    /// What a shooter gets before they have chosen anything. Matches v1.1's
    /// default so an upgrade never silently regrades existing prints.
    public static let defaultStock: FilmStock = byID[LegacyID.fadedInstant] ?? all[0]

    public static func stock(for id: String?) -> FilmStock? {
        guard let id else { return nil }
        return byID[id]
    }

    /// Always returns something, falling back to the default for ids that no
    /// longer exist (a pack removed, or data written by a newer build).
    public static func resolve(_ id: String?) -> FilmStock {
        stock(for: id) ?? defaultStock
    }

    public static func stocks(in packID: String) -> [FilmStock] {
        all.filter { $0.packID == packID }
    }

    public static func pack(for packID: String) -> FilmPack? {
        packs.first { $0.id == packID }
    }

    /// Stocks grouped in pack order, for a picker that shows its sections in a
    /// stable sequence.
    public static var groupedByPack: [(pack: FilmPack, stocks: [FilmStock])] {
        packs.map { ($0, stocks(in: $0.id)) }
    }

    // MARK: - Storage

    public static let storageKey = "tumble.filmStock"
    /// The v1.1 key, holding a `TumbleMemoryFilterPreset` raw value.
    static let legacyPresetKey = "tumble.memoryFilterPreset"

    /// The shooter's default stock, migrating the v1.1 preference on first
    /// read. Mirrors `PostcardFrameStyle.stored(defaults:)`, which does the
    /// same dance for the pre-frames save toggle.
    public static func stored(in defaults: UserDefaults = .standard) -> FilmStock {
        if let id = defaults.string(forKey: storageKey), let stock = byID[id] {
            return stock
        }
        if let legacy = defaults.string(forKey: legacyPresetKey) {
            let migrated = byID[legacy] ?? defaultStock
            defaults.set(migrated.id, forKey: storageKey)
            defaults.removeObject(forKey: legacyPresetKey)
            return migrated
        }
        return defaultStock
    }
}

private final class FilmManifestBundleToken {}

private struct SharedFilmManifest {
    let completeProductID: String
    let packs: [FilmPack]
    let stocks: [FilmStock]

    static func load() -> Self? {
        let bundle = Bundle(for: FilmManifestBundleToken.self)
        guard let url = bundle.url(forResource: "film-stocks", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              (root["version"] as? NSNumber)?.intValue == 1,
              let complete = root["completeProductID"] as? String,
              let packValues = root["packs"] as? [[String: Any]],
              let stockValues = root["stocks"] as? [[String: Any]] else { return nil }

        let packs = packValues.compactMap { value -> FilmPack? in
            guard let id = value["id"] as? String,
                  let name = value["name"] as? String,
                  let blurb = value["blurb"] as? String else { return nil }
            return FilmPack(id: id, name: name, blurb: blurb, productID: value["legacyProductID"] as? String)
        }
        let stocks = stockValues.compactMap { value -> FilmStock? in
            guard let id = value["id"] as? String,
                  let name = value["name"] as? String,
                  let blurb = value["blurb"] as? String,
                  let packID = value["packID"] as? String,
                  let grade = value["grade"] as? [String: Any] else { return nil }
            return FilmStock(id: id, name: name, blurb: blurb, packID: packID, grade: parseGrade(grade))
        }
        guard packs.count == 4, stocks.count == 21, Set(stocks.map(\.id)).count == stocks.count else { return nil }
        return Self(completeProductID: complete, packs: packs, stocks: stocks)
    }

    private static func parseGrade(_ value: [String: Any]) -> FilmGrade {
        func number(_ key: String, _ fallback: Double) -> Double {
            (value[key] as? NSNumber)?.doubleValue ?? fallback
        }
        func tint(_ key: String) -> FilmTint {
            guard let data = value[key] as? [String: Any] else { return .neutral }
            return FilmTint(
                red: (data["red"] as? NSNumber)?.doubleValue ?? 0,
                green: (data["green"] as? NSNumber)?.doubleValue ?? 0,
                blue: (data["blue"] as? NSNumber)?.doubleValue ?? 0
            )
        }
        return FilmGrade(
            saturation: number("saturation", 1), contrast: number("contrast", 1),
            brightness: number("brightness", 0), blackLift: number("blackLift", 0),
            warmth: number("warmth", 0), halation: number("halation", 0),
            grain: number("grain", 0), vignette: number("vignette", 0),
            monochrome: number("monochrome", 0), monoTint: tint("monoTint"),
            fade: number("fade", 0), bloom: number("bloom", 0),
            shadowTint: tint("shadowTint"), shadowStrength: number("shadowStrength", 0),
            highlightTint: tint("highlightTint"), highlightStrength: number("highlightStrength", 0),
            leak: LightLeakStyle(rawValue: value["leak"] as? String ?? "none") ?? .none,
            leakStrength: number("leakStrength", 0),
            stampsDate: (value["stampsDate"] as? NSNumber)?.boolValue ?? false
        )
    }
}
