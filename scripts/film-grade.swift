//
// The app's grade pipeline, ported filter-for-filter from
// TumbleKit/Filter/TumblePhotoFilter.swift so anything rendered on a Mac -
// App Store screenshots, video stills - shows the look the app actually
// produces. Compiled together with TumbleKit/Filter/FilmStock.swift, which
// supplies the catalog.
//
// One copy, used by every renderer: a second transcription would drift.
//

import AppKit
import CoreImage
import Foundation

let ciContext = CIContext(options: [.useSoftwareRenderer: false])

// MARK: - The grade pipeline (ported from TumblePhotoFilter)

func warmGrade(_ image: CIImage, _ warmth: Double) -> CIImage {
    guard warmth != 0 else { return image }
    return image.applyingFilter("CIColorMatrix", parameters: [
        "inputRVector": CIVector(x: 1.0 + warmth * 0.075, y: warmth * 0.020, z: -warmth * 0.020, w: 0),
        "inputGVector": CIVector(x: warmth * 0.010, y: 1.0 + warmth * 0.020, z: 0, w: 0),
        "inputBVector": CIVector(x: -warmth * 0.045, y: -warmth * 0.010, z: 1.0 - warmth * 0.070, w: 0),
        "inputAVector": CIVector(x: 0, y: 0, z: 0, w: 1),
        "inputBiasVector": CIVector(x: warmth * 0.030, y: warmth * 0.016, z: warmth * -0.010, w: 0),
    ])
}

func monochrome(_ image: CIImage, _ extent: CGRect, _ amount: Double, _ tint: FilmTint) -> CIImage {
    guard amount > 0 else { return image }
    let grey = image.applyingFilter("CIColorControls", parameters: [kCIInputSaturationKey: 0])
    let toned = grey.applyingFilter("CIColorMatrix", parameters: [
        "inputBiasVector": CIVector(x: tint.red, y: tint.green, z: tint.blue, w: 0),
    ])
    let mixed = toned.applyingFilter("CIColorMatrix", parameters: [
        "inputAVector": CIVector(x: 0, y: 0, z: 0, w: amount),
    ])
    return mixed
        .applyingFilter("CISourceOverCompositing", parameters: [kCIInputBackgroundImageKey: image])
        .cropped(to: extent)
}

func tone(_ image: CIImage, _ extent: CGRect, _ tint: FilmTint, _ strength: Double, shadows: Bool) -> CIImage {
    var mask = image.applyingFilter("CIColorControls", parameters: [kCIInputSaturationKey: 0]).cropped(to: extent)
    if shadows { mask = mask.applyingFilter("CIColorInvert") }
    let tinted = image.applyingFilter("CIColorMatrix", parameters: [
        "inputBiasVector": CIVector(x: tint.red * strength, y: tint.green * strength, z: tint.blue * strength, w: 0),
    ])
    return tinted.applyingFilter("CIBlendWithMask", parameters: [
        kCIInputBackgroundImageKey: image,
        kCIInputMaskImageKey: mask,
    ]).cropped(to: extent)
}

func fade(_ image: CIImage, _ amount: Double) -> CIImage {
    guard amount > 0 else { return image }
    return image.applyingFilter("CIToneCurve", parameters: [
        "inputPoint0": CIVector(x: 0.0, y: amount * 0.10),
        "inputPoint1": CIVector(x: 0.25, y: 0.25 + amount * 0.04),
        "inputPoint2": CIVector(x: 0.5, y: 0.5),
        "inputPoint3": CIVector(x: 0.75, y: 0.75 - amount * 0.06),
        "inputPoint4": CIVector(x: 1.0, y: 1.0 - amount * 0.14),
    ])
}

func halation(_ image: CIImage, _ extent: CGRect, _ amount: Double) -> CIImage {
    guard amount > 0 else { return image }
    let mask = image.applyingFilter("CIColorControls", parameters: [
        kCIInputSaturationKey: 0, kCIInputBrightnessKey: -0.50, kCIInputContrastKey: 3.2,
    ]).cropped(to: extent)
    let glow = warmGrade(
        image.clampedToExtent()
            .applyingFilter("CIGaussianBlur", parameters: [kCIInputRadiusKey: max(8, max(extent.width, extent.height) * 0.006)])
            .cropped(to: extent),
        1.2
    ).applyingFilter("CIColorMatrix", parameters: [
        "inputAVector": CIVector(x: 0, y: 0, z: 0, w: amount),
    ])
    return glow
        .applyingFilter("CISourceOverCompositing", parameters: [kCIInputBackgroundImageKey: image])
        .applyingFilter("CIBlendWithMask", parameters: [
            kCIInputBackgroundImageKey: image, kCIInputMaskImageKey: mask,
        ]).cropped(to: extent)
}

func bloom(_ image: CIImage, _ extent: CGRect, _ amount: Double) -> CIImage {
    guard amount > 0 else { return image }
    return image.clampedToExtent()
        .applyingFilter("CIBloom", parameters: [
            kCIInputRadiusKey: max(6, max(extent.width, extent.height) * 0.012),
            kCIInputIntensityKey: amount,
        ]).cropped(to: extent)
}

func grain(_ image: CIImage, _ extent: CGRect, _ amount: Double) -> CIImage {
    guard amount > 0, let noise = CIFilter(name: "CIRandomGenerator")?.outputImage?
        .cropped(to: extent)
        .applyingFilter("CIColorControls", parameters: [
            kCIInputSaturationKey: 0, kCIInputBrightnessKey: 0, kCIInputContrastKey: amount,
        ]) else { return image }
    return noise.applyingFilter("CISoftLightBlendMode", parameters: [
        kCIInputBackgroundImageKey: image,
    ]).cropped(to: extent)
}

func leak(_ image: CIImage, _ extent: CGRect, _ style: LightLeakStyle, _ strength: Double) -> CIImage {
    guard style != .none, strength > 0 else { return image }
    let w = extent.width, h = extent.height
    let s = min(1, max(0, strength))
    var filter: CIFilter?
    switch style {
    case .none:
        return image
    case .cornerWarm:
        filter = CIFilter(name: "CIRadialGradient", parameters: [
            "inputCenter": CIVector(x: w * 0.92, y: h * 0.08),
            "inputRadius0": Double(min(w, h) * 0.05),
            "inputRadius1": Double(max(w, h) * 0.70),
            "inputColor0": CIColor(red: 1.0, green: 0.62, blue: 0.28, alpha: s),
            "inputColor1": CIColor(red: 1.0, green: 0.62, blue: 0.28, alpha: 0),
        ])
    case .edgeRed:
        filter = CIFilter(name: "CILinearGradient", parameters: [
            "inputPoint0": CIVector(x: 0, y: h * 0.5),
            "inputPoint1": CIVector(x: w * 0.34, y: h * 0.5),
            "inputColor0": CIColor(red: 1.0, green: 0.18, blue: 0.12, alpha: s),
            "inputColor1": CIColor(red: 1.0, green: 0.18, blue: 0.12, alpha: 0),
        ])
    case .topFlare:
        filter = CIFilter(name: "CILinearGradient", parameters: [
            "inputPoint0": CIVector(x: w * 0.5, y: h),
            "inputPoint1": CIVector(x: w * 0.5, y: h * 0.55),
            "inputColor0": CIColor(red: 1.0, green: 0.86, blue: 0.62, alpha: s),
            "inputColor1": CIColor(red: 1.0, green: 0.86, blue: 0.62, alpha: 0),
        ])
    }
    guard let wash = filter?.outputImage?.cropped(to: extent) else { return image }
    return wash.applyingFilter("CIScreenBlendMode", parameters: [kCIInputBackgroundImageKey: image]).cropped(to: extent)
}

func dateStamp(_ image: CIImage, _ extent: CGRect, _ on: Bool) -> CIImage {
    guard on, let generator = CIFilter(name: "CITextImageGenerator") else { return image }
    let size = max(10, min(extent.width, extent.height) * 0.045)
    generator.setValue("'96 07 21", forKey: "inputText")
    generator.setValue(size, forKey: "inputFontSize")
    generator.setValue("Menlo-Bold", forKey: "inputFontName")
    generator.setValue(1.0, forKey: "inputScaleFactor")
    guard let raw = generator.outputImage else { return image }
    let amber = raw.applyingFilter("CIColorMatrix", parameters: [
        "inputRVector": CIVector(x: 1.0, y: 0, z: 0, w: 0),
        "inputGVector": CIVector(x: 0, y: 0.62, z: 0, w: 0),
        "inputBVector": CIVector(x: 0, y: 0, z: 0.14, w: 0),
        "inputAVector": CIVector(x: 0, y: 0, z: 0, w: 1),
    ])
    let margin = min(extent.width, extent.height) * 0.045
    let placed = amber.transformed(by: CGAffineTransform(
        translationX: extent.maxX - amber.extent.width - margin,
        y: extent.minY + margin
    ))
    return placed.applyingFilter("CIAdditionCompositing", parameters: [
        kCIInputBackgroundImageKey: image,
    ]).cropped(to: extent)
}

func applyGrade(_ g: FilmGrade, to input: CIImage) -> CIImage {
    let image = input.transformed(by: CGAffineTransform(translationX: -input.extent.origin.x, y: -input.extent.origin.y))
    let extent = image.extent

    var out = image.applyingFilter("CIColorControls", parameters: [
        kCIInputSaturationKey: g.saturation,
        kCIInputContrastKey: g.contrast,
        kCIInputBrightnessKey: g.brightness,
    ])
    out = out.applyingFilter("CIToneCurve", parameters: [
        "inputPoint0": CIVector(x: 0.0, y: g.blackLift),
        "inputPoint1": CIVector(x: 0.22, y: 0.24 + g.blackLift * 0.35),
        "inputPoint2": CIVector(x: 0.52, y: 0.52),
        "inputPoint3": CIVector(x: 0.82, y: 0.80),
        "inputPoint4": CIVector(x: 1.0, y: 0.97),
    ])
    out = warmGrade(out, g.warmth)
    out = monochrome(out, extent, g.monochrome, g.monoTint)
    if g.shadowStrength > 0 { out = tone(out, extent, g.shadowTint, g.shadowStrength, shadows: true) }
    if g.highlightStrength > 0 { out = tone(out, extent, g.highlightTint, g.highlightStrength, shadows: false) }
    out = fade(out, g.fade)
    out = halation(out, extent, g.halation)
    out = bloom(out, extent, g.bloom)
    out = grain(out, extent, g.grain)
    out = out.applyingFilter("CIVignette", parameters: [
        kCIInputIntensityKey: g.vignette,
        kCIInputRadiusKey: max(extent.width, extent.height) * 1.05,
    ])
    out = leak(out, extent, g.leak, g.leakStrength)
    out = dateStamp(out, extent, g.stampsDate)
    return out.cropped(to: extent)
}

