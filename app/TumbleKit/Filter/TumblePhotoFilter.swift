import CoreGraphics
import CoreImage
import Foundation
import ImageIO
import UIKit
import UniformTypeIdentifiers

public enum TumbleMemoryFilterPreset: String, CaseIterable, Identifiable, Sendable {
    case fadedInstant
    case warmArchive

    public static let storageKey = "tumble.memoryFilterPreset"
    public static let defaultPreset: TumbleMemoryFilterPreset = .fadedInstant

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .fadedInstant: "Faded Instant"
        case .warmArchive: "Warm Archive"
        }
    }

    public var exportLabel: String {
        switch self {
        case .fadedInstant: "faded instant"
        case .warmArchive: "warm archive"
        }
    }

    /// The catalog stock this legacy preset maps to. The v1.1 ids were carried
    /// forward verbatim, so this always resolves.
    public var stock: FilmStock {
        FilmStockCatalog.resolve(rawValue)
    }

    public static func stored(in defaults: UserDefaults = .standard) -> TumbleMemoryFilterPreset {
        defaults.string(forKey: storageKey).flatMap(TumbleMemoryFilterPreset.init(rawValue:)) ?? defaultPreset
    }
}

public enum TumblePhotoFilter {
    public static let maximumExportLongEdge: CGFloat = 4096
    private static let context = CIContext(options: [
        .workingColorSpace: CGColorSpace(name: CGColorSpace.sRGB) as Any,
        .outputColorSpace: CGColorSpace(name: CGColorSpace.sRGB) as Any,
    ])

    // MARK: - Grade-based rendering (primary API)

    /// Renders a `FilmGrade` over encoded image data and returns JPEG bytes.
    /// `capturedAt` feeds the date stamp; pass the print's capture date so the
    /// stamped numbers match the shot.
    public static func renderMemoryPhotoData(
        from imageData: Data,
        grade: FilmGrade,
        capturedAt: Date? = nil,
        compressionQuality: CGFloat = 0.92
    ) -> Data? {
        guard let image = CIImage(data: imageData, options: [.applyOrientationProperty: true]) else {
            return nil
        }
        return encode(applyGrade(grade, to: image, capturedAt: capturedAt), quality: compressionQuality)
    }

    public static func renderMemoryPhotoData(
        from image: UIImage,
        grade: FilmGrade,
        capturedAt: Date? = nil,
        compressionQuality: CGFloat = 0.92
    ) -> Data? {
        guard let ciImage = CIImage(image: image, options: [.applyOrientationProperty: true]) else {
            return nil
        }
        return encode(applyGrade(grade, to: ciImage, capturedAt: capturedAt), quality: compressionQuality)
    }

    /// Convenience: render a named stock.
    public static func renderMemoryPhotoData(
        from imageData: Data,
        stock: FilmStock,
        capturedAt: Date? = nil,
        compressionQuality: CGFloat = 0.92
    ) -> Data? {
        renderMemoryPhotoData(from: imageData, grade: stock.grade, capturedAt: capturedAt, compressionQuality: compressionQuality)
    }

    /// A downscaled preview for the look picker, where a grid of thumbnails must
    /// regrade in real time. The source is scaled to `maxDimension` on its long
    /// edge *before* the pipeline runs, so a look costs the same whether the
    /// original is 12 megapixels or one. Returns a `UIImage` ready to show.
    public static func renderPreviewImage(
        from imageData: Data,
        grade: FilmGrade,
        capturedAt: Date? = nil,
        maxDimension: CGFloat = 320
    ) -> UIImage? {
        guard let image = CIImage(data: imageData, options: [.applyOrientationProperty: true]) else {
            return nil
        }
        let scaled = downscaled(image, maxDimension: maxDimension)
        let output = applyGrade(grade, to: scaled, capturedAt: capturedAt)
        let extent = output.extent.integral
        guard !extent.isEmpty, let cgImage = context.createCGImage(output, from: extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }

    /// The Tumble 3 editing contract. Orientation is read from the encoded
    /// source, then rotation/crop are applied before the film is blended over
    /// the original. The same method drives Studio previews and final exports.
    public static func renderEditedPhotoData(
        from imageData: Data,
        recipe: EditRecipe,
        capturedAt: Date,
        maxDimension: CGFloat = maximumExportLongEdge,
        compressionQuality: CGFloat = 0.92
    ) -> Data? {
        guard let input = CIImage(data: imageData, options: [.applyOrientationProperty: true]) else { return nil }
        let prepared = prepare(input, recipe: recipe)
        let graded = applyGrade(recipe.stock.grade, to: prepared, capturedAt: capturedAt)
        let blended = dissolve(original: prepared, graded: graded, amount: recipe.intensity)
        return encode(downscaled(blended, maxDimension: maxDimension), quality: compressionQuality)
    }

    public static func renderEditedPreview(
        from imageData: Data,
        recipe: EditRecipe,
        capturedAt: Date,
        maxDimension: CGFloat = 1024
    ) -> UIImage? {
        guard let data = renderEditedPhotoData(
            from: imageData,
            recipe: recipe,
            capturedAt: capturedAt,
            maxDimension: maxDimension,
            compressionQuality: 0.86
        ) else { return nil }
        return UIImage(data: data)
    }

    public static func renderLivePreview(
        from image: UIImage,
        stock: FilmStock,
        intensity: Double = 1,
        capturedAt: Date = Date(),
        maxDimension: CGFloat = 960
    ) -> UIImage? {
        guard let data = image.jpegData(compressionQuality: 0.72) else { return nil }
        return renderEditedPreview(
            from: data,
            recipe: EditRecipe(stockID: stock.id, intensity: intensity),
            capturedAt: capturedAt,
            maxDimension: maxDimension
        )
    }

    private static func downscaled(_ image: CIImage, maxDimension: CGFloat) -> CIImage {
        let longEdge = max(image.extent.width, image.extent.height)
        guard longEdge > maxDimension, longEdge > 0 else { return image }
        let scale = maxDimension / longEdge
        return image.applyingFilter("CILanczosScaleTransform", parameters: [
            kCIInputScaleKey: scale,
            kCIInputAspectRatioKey: 1.0,
        ])
    }

    private static func prepare(_ input: CIImage, recipe: EditRecipe) -> CIImage {
        let rotated: CIImage = switch recipe.quarterTurns {
        case 1: input.oriented(.right)
        case 2: input.oriented(.down)
        case 3: input.oriented(.left)
        default: input
        }
        let image = normalized(rotated)
        let extent = image.extent
        let cropRect: CGRect
        if recipe.cropPreset == .freeform {
            let crop = recipe.crop.clamped
            cropRect = CGRect(
                x: extent.minX + extent.width * crop.x,
                y: extent.minY + extent.height * crop.y,
                width: extent.width * crop.width,
                height: extent.height * crop.height
            )
        } else if let aspect = recipe.cropPreset.aspectRatio {
            let sourceAspect = extent.width / extent.height
            if sourceAspect > aspect {
                let width = extent.height * aspect
                cropRect = CGRect(x: extent.midX - width / 2, y: extent.minY, width: width, height: extent.height)
            } else {
                let height = extent.width / aspect
                cropRect = CGRect(x: extent.minX, y: extent.midY - height / 2, width: extent.width, height: height)
            }
        } else {
            cropRect = extent
        }
        return normalized(image.cropped(to: cropRect.integral))
    }

    private static func dissolve(original: CIImage, graded: CIImage, amount: Double) -> CIImage {
        let fraction = min(1, max(0, amount))
        guard fraction > 0 else { return original }
        guard fraction < 1 else { return graded }
        return CIFilter(
            name: "CIDissolveTransition",
            parameters: [
                kCIInputImageKey: original,
                kCIInputTargetImageKey: graded,
                kCIInputTimeKey: fraction,
            ]
        )?.outputImage?.cropped(to: original.extent) ?? graded
    }

    // MARK: - Legacy preset API (delegates through the catalog)

    public static func renderMemoryPhotoData(
        from imageData: Data,
        preset: TumbleMemoryFilterPreset,
        compressionQuality: CGFloat = 0.92
    ) -> Data? {
        renderMemoryPhotoData(from: imageData, grade: preset.stock.grade, compressionQuality: compressionQuality)
    }

    public static func renderMemoryPhotoData(
        from image: UIImage,
        preset: TumbleMemoryFilterPreset,
        compressionQuality: CGFloat = 0.92
    ) -> Data? {
        renderMemoryPhotoData(from: image, grade: preset.stock.grade, compressionQuality: compressionQuality)
    }

    // MARK: - Encoding

    private static func encode(_ output: CIImage, quality: CGFloat) -> Data? {
        let extent = output.extent.integral
        guard !extent.isEmpty, let cgImage = context.createCGImage(output, from: extent) else { return nil }

        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            data,
            UTType.jpeg.identifier as CFString,
            1,
            nil
        ) else {
            return nil
        }

        CGImageDestinationAddImage(destination, cgImage, [
            kCGImageDestinationLossyCompressionQuality: quality,
        ] as CFDictionary)

        guard CGImageDestinationFinalize(destination) else { return nil }
        return data as Data
    }

    // MARK: - Pipeline

    /// The full grade pipeline. Every stage is a no-op when its grade fields sit
    /// at their neutral defaults, so the ordering here is also the ordering the
    /// two legacy presets ran in v1.1 - a base-only grade renders identically.
    private static func applyGrade(_ grade: FilmGrade, to input: CIImage, capturedAt: Date?) -> CIImage {
        let image = normalized(input)
        let extent = image.extent

        // Base tone: saturation / contrast / brightness, then the black-lift curve.
        var current = image.applyingFilter("CIColorControls", parameters: [
            kCIInputSaturationKey: grade.saturation,
            kCIInputContrastKey: grade.contrast,
            kCIInputBrightnessKey: grade.brightness,
        ])

        current = current.applyingFilter("CIToneCurve", parameters: [
            "inputPoint0": CIVector(x: 0.0, y: grade.blackLift),
            "inputPoint1": CIVector(x: 0.22, y: 0.24 + grade.blackLift * 0.35),
            "inputPoint2": CIVector(x: 0.52, y: 0.52),
            "inputPoint3": CIVector(x: 0.82, y: 0.80),
            "inputPoint4": CIVector(x: 1.0, y: 0.97),
        ])

        current = warmGrade(current, warmth: grade.warmth)
        current = monochrome(current, extent: extent, amount: grade.monochrome, tint: grade.monoTint)
        current = splitTone(current, extent: extent, grade: grade)
        current = fade(current, amount: grade.fade)

        // Texture and light, in the order light hits real film.
        current = addHalation(to: current, extent: extent, amount: grade.halation)
        current = addBloom(to: current, extent: extent, amount: grade.bloom)
        current = addGrain(to: current, extent: extent, amount: grade.grain)
        current = current.applyingFilter("CIVignette", parameters: [
            kCIInputIntensityKey: grade.vignette,
            kCIInputRadiusKey: max(extent.width, extent.height) * 1.05,
        ])
        current = addLeak(to: current, extent: extent, style: grade.leak, strength: grade.leakStrength)
        current = stampDate(on: current, extent: extent, when: capturedAt, if: grade.stampsDate)

        return current.cropped(to: extent)
    }

    private static func normalized(_ image: CIImage) -> CIImage {
        image.transformed(by: CGAffineTransform(translationX: -image.extent.origin.x, y: -image.extent.origin.y))
    }

    private static func warmGrade(_ image: CIImage, warmth: Double) -> CIImage {
        guard warmth != 0 else { return image }
        return image.applyingFilter("CIColorMatrix", parameters: [
            "inputRVector": CIVector(x: 1.0 + warmth * 0.075, y: warmth * 0.020, z: -warmth * 0.020, w: 0),
            "inputGVector": CIVector(x: warmth * 0.010, y: 1.0 + warmth * 0.020, z: 0, w: 0),
            "inputBVector": CIVector(x: -warmth * 0.045, y: -warmth * 0.010, z: 1.0 - warmth * 0.070, w: 0),
            "inputAVector": CIVector(x: 0, y: 0, z: 0, w: 1),
            "inputBiasVector": CIVector(x: warmth * 0.030, y: warmth * 0.016, z: warmth * -0.010, w: 0),
        ])
    }

    /// Desaturate toward a grey with a small colour bias, mixed back over the
    /// original by `amount` so a stock can sit anywhere between full colour and
    /// a fully toned print.
    private static func monochrome(_ image: CIImage, extent: CGRect, amount: Double, tint: FilmTint) -> CIImage {
        guard amount > 0 else { return image }

        let grey = image.applyingFilter("CIColorControls", parameters: [kCIInputSaturationKey: 0])
        let toned = grey.applyingFilter("CIColorMatrix", parameters: [
            "inputBiasVector": CIVector(x: tint.red, y: tint.green, z: tint.blue, w: 0),
        ])
        // Carry the mix fraction in alpha, then lay it over the colour original.
        let mixed = toned.applyingFilter("CIColorMatrix", parameters: [
            "inputAVector": CIVector(x: 0, y: 0, z: 0, w: amount),
        ])
        return mixed
            .applyingFilter("CISourceOverCompositing", parameters: [kCIInputBackgroundImageKey: image])
            .cropped(to: extent)
    }

    /// Split toning: colour the shadows one way and the highlights another, each
    /// masked by luminance so the tint lands only where it should.
    private static func splitTone(_ image: CIImage, extent: CGRect, grade: FilmGrade) -> CIImage {
        var out = image
        if grade.shadowStrength > 0 {
            out = tone(out, extent: extent, tint: grade.shadowTint, strength: grade.shadowStrength, inShadows: true)
        }
        if grade.highlightStrength > 0 {
            out = tone(out, extent: extent, tint: grade.highlightTint, strength: grade.highlightStrength, inShadows: false)
        }
        return out
    }

    private static func tone(_ image: CIImage, extent: CGRect, tint: FilmTint, strength: Double, inShadows: Bool) -> CIImage {
        var mask = image.applyingFilter("CIColorControls", parameters: [kCIInputSaturationKey: 0]).cropped(to: extent)
        if inShadows {
            mask = mask.applyingFilter("CIColorInvert")
        }
        let tinted = image.applyingFilter("CIColorMatrix", parameters: [
            "inputBiasVector": CIVector(x: tint.red * strength, y: tint.green * strength, z: tint.blue * strength, w: 0),
        ])
        return tinted.applyingFilter("CIBlendWithMask", parameters: [
            kCIInputBackgroundImageKey: image,
            kCIInputMaskImageKey: mask,
        ])
        .cropped(to: extent)
    }

    /// Matte fade: raise the black floor and pull the white ceiling down, for the
    /// low-contrast, milky top end of aged prints.
    private static func fade(_ image: CIImage, amount: Double) -> CIImage {
        guard amount > 0 else { return image }
        return image.applyingFilter("CIToneCurve", parameters: [
            "inputPoint0": CIVector(x: 0.0, y: amount * 0.10),
            "inputPoint1": CIVector(x: 0.25, y: 0.25 + amount * 0.04),
            "inputPoint2": CIVector(x: 0.5, y: 0.5),
            "inputPoint3": CIVector(x: 0.75, y: 0.75 - amount * 0.06),
            "inputPoint4": CIVector(x: 1.0, y: 1.0 - amount * 0.14),
        ])
    }

    private static func addHalation(to image: CIImage, extent: CGRect, amount: Double) -> CIImage {
        guard amount > 0 else { return image }

        let mask = image
            .applyingFilter("CIColorControls", parameters: [
                kCIInputSaturationKey: 0,
                kCIInputBrightnessKey: -0.50,
                kCIInputContrastKey: 3.2,
            ])
            .cropped(to: extent)

        let glow = warmGrade(
            image.clampedToExtent()
                .applyingFilter("CIGaussianBlur", parameters: [kCIInputRadiusKey: max(8, max(extent.width, extent.height) * 0.006)])
                .cropped(to: extent),
            warmth: 1.2
        )
        .applyingFilter("CIColorMatrix", parameters: [
            "inputRVector": CIVector(x: 1, y: 0, z: 0, w: 0),
            "inputGVector": CIVector(x: 0, y: 1, z: 0, w: 0),
            "inputBVector": CIVector(x: 0, y: 0, z: 1, w: 0),
            "inputAVector": CIVector(x: 0, y: 0, z: 0, w: amount),
            "inputBiasVector": CIVector(x: 0, y: 0, z: 0, w: 0),
        ])

        return glow.applyingFilter("CISourceOverCompositing", parameters: [
            kCIInputBackgroundImageKey: image,
        ])
        .applyingFilter("CIBlendWithMask", parameters: [
            kCIInputBackgroundImageKey: image,
            kCIInputMaskImageKey: mask,
        ])
        .cropped(to: extent)
    }

    /// Soft, unmasked glow across the whole frame - a hazy lens rather than the
    /// highlight-only bleed of `halation`.
    private static func addBloom(to image: CIImage, extent: CGRect, amount: Double) -> CIImage {
        guard amount > 0 else { return image }
        return image
            .clampedToExtent()
            .applyingFilter("CIBloom", parameters: [
                kCIInputRadiusKey: max(6, max(extent.width, extent.height) * 0.012),
                kCIInputIntensityKey: amount,
            ])
            .cropped(to: extent)
    }

    private static func addGrain(to image: CIImage, extent: CGRect, amount: Double) -> CIImage {
        guard amount > 0 else { return image }

        guard let noise = CIFilter(name: "CIRandomGenerator")?.outputImage?
            .cropped(to: extent)
            .applyingFilter("CIColorControls", parameters: [
                kCIInputSaturationKey: 0,
                kCIInputBrightnessKey: 0,
                kCIInputContrastKey: amount,
            ]) else {
            return image
        }

        return noise.applyingFilter("CISoftLightBlendMode", parameters: [
            kCIInputBackgroundImageKey: image,
        ])
        .cropped(to: extent)
    }

    /// A light leak: a coloured wash entering from a fixed seam, screened over
    /// the frame so it adds light rather than replacing it.
    private static func addLeak(to image: CIImage, extent: CGRect, style: LightLeakStyle, strength: Double) -> CIImage {
        guard style != .none, strength > 0 else { return image }
        guard let leak = leakImage(style, extent: extent, strength: strength) else { return image }
        return leak
            .applyingFilter("CIScreenBlendMode", parameters: [kCIInputBackgroundImageKey: image])
            .cropped(to: extent)
    }

    private static func leakImage(_ style: LightLeakStyle, extent: CGRect, strength: Double) -> CIImage? {
        let w = extent.width
        let h = extent.height
        let s = min(1, max(0, strength))

        switch style {
        case .none:
            return nil

        case .cornerWarm:
            // Warm bloom from the bottom-right corner.
            let colour = CIColor(red: 1.0, green: 0.62, blue: 0.28, alpha: s)
            return CIFilter(name: "CIRadialGradient", parameters: [
                "inputCenter": CIVector(x: w * 0.92, y: h * 0.08),
                "inputRadius0": Double(min(w, h) * 0.05),
                "inputRadius1": Double(max(w, h) * 0.70),
                "inputColor0": colour,
                "inputColor1": CIColor(red: 1.0, green: 0.62, blue: 0.28, alpha: 0),
            ])?.outputImage?.cropped(to: extent)

        case .edgeRed:
            // Hot red band down the left edge, fading inward.
            let colour = CIColor(red: 1.0, green: 0.18, blue: 0.12, alpha: s)
            return CIFilter(name: "CILinearGradient", parameters: [
                "inputPoint0": CIVector(x: 0, y: h * 0.5),
                "inputPoint1": CIVector(x: w * 0.34, y: h * 0.5),
                "inputColor0": colour,
                "inputColor1": CIColor(red: 1.0, green: 0.18, blue: 0.12, alpha: 0),
            ])?.outputImage?.cropped(to: extent)

        case .topFlare:
            // Warm flare washing down from the top of the frame.
            let colour = CIColor(red: 1.0, green: 0.86, blue: 0.62, alpha: s)
            return CIFilter(name: "CILinearGradient", parameters: [
                "inputPoint0": CIVector(x: w * 0.5, y: h),
                "inputPoint1": CIVector(x: w * 0.5, y: h * 0.55),
                "inputColor0": colour,
                "inputColor1": CIColor(red: 1.0, green: 0.86, blue: 0.62, alpha: 0),
            ])?.outputImage?.cropped(to: extent)
        }
    }

    /// Burns the capture date into the bottom-right corner in amber, the way a
    /// point-and-shoot did. Sized to the frame so it reads at any resolution.
    private static func stampDate(on image: CIImage, extent: CGRect, when: Date?, if shouldStamp: Bool) -> CIImage {
        guard shouldStamp, let when else { return image }

        let text = Self.dateStampFormatter.string(from: when)
        let fontSize = max(10, min(extent.width, extent.height) * 0.045)
        guard let generator = CIFilter(name: "CITextImageGenerator") else { return image }
        generator.setValue(text, forKey: "inputText")
        generator.setValue(fontSize, forKey: "inputFontSize")
        generator.setValue("Menlo-Bold", forKey: "inputFontName")
        generator.setValue(1.0, forKey: "inputScaleFactor")
        guard let rawText = generator.outputImage else { return image }

        // Tint the white glyphs amber and give them a faint glow, the way the
        // LED read-out bled onto the emulsion.
        let amber = rawText.applyingFilter("CIColorMatrix", parameters: [
            "inputRVector": CIVector(x: 1.0, y: 0, z: 0, w: 0),
            "inputGVector": CIVector(x: 0, y: 0.62, z: 0, w: 0),
            "inputBVector": CIVector(x: 0, y: 0, z: 0.14, w: 0),
            "inputAVector": CIVector(x: 0, y: 0, z: 0, w: 1),
        ])

        let glyphs = amber.extent
        let margin = min(extent.width, extent.height) * 0.045
        let tx = extent.maxX - glyphs.width - margin
        let ty = extent.minY + margin
        let placed = amber.transformed(by: CGAffineTransform(translationX: tx, y: ty))
        let glow = placed
            .applyingFilter("CIGaussianBlur", parameters: [kCIInputRadiusKey: fontSize * 0.18])
            .cropped(to: extent)

        // Screen the soft glow over the print, then lay the sharp glyphs on top.
        let lit = glow.applyingFilter("CIScreenBlendMode", parameters: [kCIInputBackgroundImageKey: image])
        return placed
            .applyingFilter("CISourceOverCompositing", parameters: [kCIInputBackgroundImageKey: lit])
            .cropped(to: extent)
    }

    private static let dateStampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy'  'M'  'd"
        return formatter
    }()
}
