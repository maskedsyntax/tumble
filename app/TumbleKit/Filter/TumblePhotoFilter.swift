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

    public static func stored(in defaults: UserDefaults = .standard) -> TumbleMemoryFilterPreset {
        defaults.string(forKey: storageKey).flatMap(TumbleMemoryFilterPreset.init(rawValue:)) ?? defaultPreset
    }
}

@MainActor public enum TumblePhotoFilter {
    private struct Parameters {
        let saturation: Double
        let contrast: Double
        let brightness: Double
        let blackLift: Double
        let warmth: Double
        let halation: Double
        let grain: Double
        let vignette: Double
    }

    private static let context = CIContext(options: [
        .workingColorSpace: CGColorSpace(name: CGColorSpace.sRGB) as Any,
        .outputColorSpace: CGColorSpace(name: CGColorSpace.sRGB) as Any,
    ])

    public static func renderMemoryPhotoData(
        from imageData: Data,
        preset: TumbleMemoryFilterPreset,
        compressionQuality: CGFloat = 0.92
    ) -> Data? {
        guard let image = CIImage(data: imageData, options: [.applyOrientationProperty: true]) else {
            return nil
        }
        return renderMemoryPhotoData(from: image, preset: preset, compressionQuality: compressionQuality)
    }

    public static func renderMemoryPhotoData(
        from image: UIImage,
        preset: TumbleMemoryFilterPreset,
        compressionQuality: CGFloat = 0.92
    ) -> Data? {
        guard let ciImage = CIImage(image: image, options: [.applyOrientationProperty: true]) else {
            return nil
        }
        return renderMemoryPhotoData(from: ciImage, preset: preset, compressionQuality: compressionQuality)
    }

    private static func renderMemoryPhotoData(
        from input: CIImage,
        preset: TumbleMemoryFilterPreset,
        compressionQuality: CGFloat
    ) -> Data? {
        let output = applyPreset(preset, to: input)
        let extent = output.extent.integral
        guard let cgImage = context.createCGImage(output, from: extent) else { return nil }

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
            kCGImageDestinationLossyCompressionQuality: compressionQuality,
        ] as CFDictionary)

        guard CGImageDestinationFinalize(destination) else { return nil }
        return data as Data
    }

    private static func applyPreset(_ preset: TumbleMemoryFilterPreset, to input: CIImage) -> CIImage {
        let parameters = parameters(for: preset)
        let image = normalized(input)
        let extent = image.extent

        var current = image.applyingFilter("CIColorControls", parameters: [
            kCIInputSaturationKey: parameters.saturation,
            kCIInputContrastKey: parameters.contrast,
            kCIInputBrightnessKey: parameters.brightness,
        ])

        current = current.applyingFilter("CIToneCurve", parameters: [
            "inputPoint0": CIVector(x: 0.0, y: parameters.blackLift),
            "inputPoint1": CIVector(x: 0.22, y: 0.24 + parameters.blackLift * 0.35),
            "inputPoint2": CIVector(x: 0.52, y: 0.52),
            "inputPoint3": CIVector(x: 0.82, y: 0.80),
            "inputPoint4": CIVector(x: 1.0, y: 0.97),
        ])

        current = warmGrade(current, warmth: parameters.warmth)
        current = addHalation(to: current, extent: extent, amount: parameters.halation)
        current = addGrain(to: current, extent: extent, amount: parameters.grain)
        current = current.applyingFilter("CIVignette", parameters: [
            kCIInputIntensityKey: parameters.vignette,
            kCIInputRadiusKey: max(extent.width, extent.height) * 1.05,
        ])

        return current.cropped(to: extent)
    }

    private static func parameters(for preset: TumbleMemoryFilterPreset) -> Parameters {
        switch preset {
        case .fadedInstant:
            Parameters(
                saturation: 0.80,
                contrast: 0.88,
                brightness: 0.020,
                blackLift: 0.070,
                warmth: 0.65,
                halation: 0.10,
                grain: 0.20,
                vignette: 0.10
            )
        case .warmArchive:
            Parameters(
                saturation: 0.88,
                contrast: 0.90,
                brightness: 0.010,
                blackLift: 0.055,
                warmth: 0.75,
                halation: 0.08,
                grain: 0.16,
                vignette: 0.07
            )
        }
    }

    private static func normalized(_ image: CIImage) -> CIImage {
        image.transformed(by: CGAffineTransform(translationX: -image.extent.origin.x, y: -image.extent.origin.y))
    }

    private static func warmGrade(_ image: CIImage, warmth: Double) -> CIImage {
        image.applyingFilter("CIColorMatrix", parameters: [
            "inputRVector": CIVector(x: 1.0 + warmth * 0.045, y: warmth * 0.012, z: -warmth * 0.012, w: 0),
            "inputGVector": CIVector(x: warmth * 0.006, y: 1.0 + warmth * 0.012, z: 0, w: 0),
            "inputBVector": CIVector(x: -warmth * 0.026, y: -warmth * 0.006, z: 1.0 - warmth * 0.040, w: 0),
            "inputAVector": CIVector(x: 0, y: 0, z: 0, w: 1),
            "inputBiasVector": CIVector(x: warmth * 0.018, y: warmth * 0.010, z: warmth * -0.006, w: 0),
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
}
