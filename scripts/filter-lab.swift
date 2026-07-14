#!/usr/bin/env swift

import AppKit
import CoreGraphics
import CoreImage
import Foundation
import ImageIO
import UniformTypeIdentifiers

struct Preset {
    let slug: String
    let displayName: String
    let saturation: Double
    let contrast: Double
    let brightness: Double
    let blackLift: Double
    let warmth: Double
    let halation: Double
    let grain: Double
    let vignette: Double
}

let presets = [
    Preset(
        slug: "soft-memory",
        displayName: "Soft Memory",
        saturation: 0.88,
        contrast: 0.94,
        brightness: 0.010,
        blackLift: 0.040,
        warmth: 0.45,
        halation: 0.08,
        grain: 0.14,
        vignette: 0.08
    ),
    Preset(
        slug: "faded-instant",
        displayName: "Faded Instant",
        saturation: 0.80,
        contrast: 0.88,
        brightness: 0.020,
        blackLift: 0.070,
        warmth: 0.65,
        halation: 0.10,
        grain: 0.20,
        vignette: 0.10
    ),
    Preset(
        slug: "warm-archive",
        displayName: "Warm Archive",
        saturation: 0.88,
        contrast: 0.90,
        brightness: 0.010,
        blackLift: 0.055,
        warmth: 0.75,
        halation: 0.08,
        grain: 0.16,
        vignette: 0.07
    ),
]

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let inputDirectory = CommandLine.arguments.dropFirst().first.map { URL(fileURLWithPath: $0, relativeTo: root).standardizedFileURL }
    ?? root.appendingPathComponent("test-images", isDirectory: true)
let outputDirectory = root.appendingPathComponent("test-output", isDirectory: true)
let context = CIContext(options: [
    .workingColorSpace: CGColorSpace(name: CGColorSpace.sRGB) as Any,
    .outputColorSpace: CGColorSpace(name: CGColorSpace.sRGB) as Any,
])

func imageURLs(in directory: URL) throws -> [URL] {
    let allowed = Set(["jpg", "jpeg", "png", "heic", "heif"])
    return try FileManager.default.contentsOfDirectory(
        at: directory,
        includingPropertiesForKeys: nil,
        options: [.skipsHiddenFiles]
    )
    .filter { allowed.contains($0.pathExtension.lowercased()) }
    .sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
}

func loadImage(_ url: URL) -> CIImage? {
    CIImage(contentsOf: url, options: [.applyOrientationProperty: true])
}

func normalized(_ image: CIImage) -> CIImage {
    image.transformed(by: CGAffineTransform(translationX: -image.extent.origin.x, y: -image.extent.origin.y))
}

func applyPreset(_ preset: Preset, to input: CIImage) -> CIImage {
    let image = normalized(input)
    let extent = image.extent

    var current = image.applyingFilter("CIColorControls", parameters: [
        kCIInputSaturationKey: preset.saturation,
        kCIInputContrastKey: preset.contrast,
        kCIInputBrightnessKey: preset.brightness,
    ])

    current = current.applyingFilter("CIToneCurve", parameters: [
        "inputPoint0": CIVector(x: 0.0, y: preset.blackLift),
        "inputPoint1": CIVector(x: 0.22, y: 0.24 + preset.blackLift * 0.35),
        "inputPoint2": CIVector(x: 0.52, y: 0.52),
        "inputPoint3": CIVector(x: 0.82, y: 0.80),
        "inputPoint4": CIVector(x: 1.0, y: 0.97),
    ])

    current = warmGrade(current, warmth: preset.warmth)
    current = addHalation(to: current, extent: extent, amount: preset.halation)
    current = addGrain(to: current, extent: extent, amount: preset.grain)
    current = current.applyingFilter("CIVignette", parameters: [
        kCIInputIntensityKey: preset.vignette,
        kCIInputRadiusKey: max(extent.width, extent.height) * 1.05,
    ])

    return current.cropped(to: extent)
}

func warmGrade(_ image: CIImage, warmth: Double) -> CIImage {
    image.applyingFilter("CIColorMatrix", parameters: [
        "inputRVector": CIVector(x: 1.0 + warmth * 0.045, y: warmth * 0.012, z: -warmth * 0.012, w: 0),
        "inputGVector": CIVector(x: warmth * 0.006, y: 1.0 + warmth * 0.012, z: 0, w: 0),
        "inputBVector": CIVector(x: -warmth * 0.026, y: -warmth * 0.006, z: 1.0 - warmth * 0.040, w: 0),
        "inputAVector": CIVector(x: 0, y: 0, z: 0, w: 1),
        "inputBiasVector": CIVector(x: warmth * 0.018, y: warmth * 0.010, z: warmth * -0.006, w: 0),
    ])
}

func addHalation(to image: CIImage, extent: CGRect, amount: Double) -> CIImage {
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

func addGrain(to image: CIImage, extent: CGRect, amount: Double) -> CIImage {
    guard amount > 0 else { return image }

    let noise = CIFilter(name: "CIRandomGenerator")?.outputImage?
        .cropped(to: extent)
        .applyingFilter("CIColorControls", parameters: [
            kCIInputSaturationKey: 0,
            kCIInputBrightnessKey: 0,
            kCIInputContrastKey: amount,
        ])

    guard let noise else { return image }

    return noise.applyingFilter("CISoftLightBlendMode", parameters: [
        kCIInputBackgroundImageKey: image,
    ])
    .cropped(to: extent)
}

func writeJPEG(_ image: CIImage, to url: URL) throws {
    let extent = image.extent.integral
    guard let cgImage = context.createCGImage(image, from: extent) else {
        throw NSError(domain: "FilterLab", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not render image"])
    }

    guard let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.jpeg.identifier as CFString, 1, nil) else {
        throw NSError(domain: "FilterLab", code: 2, userInfo: [NSLocalizedDescriptionKey: "Could not create JPEG destination"])
    }

    CGImageDestinationAddImage(destination, cgImage, [
        kCGImageDestinationLossyCompressionQuality: 0.92,
    ] as CFDictionary)

    if !CGImageDestinationFinalize(destination) {
        throw NSError(domain: "FilterLab", code: 3, userInfo: [NSLocalizedDescriptionKey: "Could not write JPEG"])
    }
}

func makeContactSheet(for sourceURL: URL, original: CIImage, variants: [(Preset, CIImage)], outputURL: URL) throws {
    let tileWidth = 520
    let labelHeight = 44
    let tileHeight = 360
    let columns = variants.count + 1
    let size = CGSize(width: tileWidth * columns, height: tileHeight + labelHeight)

    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(size.width),
        pixelsHigh: Int(size.height),
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        throw NSError(domain: "FilterLab", code: 4, userInfo: [NSLocalizedDescriptionKey: "Could not allocate contact sheet bitmap"])
    }

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    defer { NSGraphicsContext.restoreGraphicsState() }

    NSColor(calibratedWhite: 0.08, alpha: 1).setFill()
    NSRect(origin: .zero, size: size).fill()

    let entries: [(String, CIImage)] = [("Original", normalized(original))] + variants.map { ($0.0.displayName, $0.1) }
    for (index, entry) in entries.enumerated() {
        guard let cgImage = context.createCGImage(entry.1, from: entry.1.extent.integral) else { continue }
        let rect = aspectFitRect(imageSize: CGSize(width: cgImage.width, height: cgImage.height), in: CGRect(x: index * tileWidth, y: labelHeight, width: tileWidth, height: tileHeight))
        NSGraphicsContext.current?.cgContext.draw(cgImage, in: rect)

        let label = "\(entry.0) · \(sourceURL.lastPathComponent)"
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: NSColor(calibratedWhite: 0.92, alpha: 1),
            .font: NSFont.systemFont(ofSize: 16, weight: .semibold),
        ]
        label.draw(in: NSRect(x: index * tileWidth + 16, y: 13, width: tileWidth - 32, height: 24), withAttributes: attributes)
    }

    guard let data = bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.9]) else {
        throw NSError(domain: "FilterLab", code: 4, userInfo: [NSLocalizedDescriptionKey: "Could not render contact sheet"])
    }

    try data.write(to: outputURL, options: .atomic)
}

func aspectFitRect(imageSize: CGSize, in bounds: CGRect) -> CGRect {
    let scale = min(bounds.width / imageSize.width, bounds.height / imageSize.height)
    let width = imageSize.width * scale
    let height = imageSize.height * scale
    return CGRect(
        x: bounds.midX - width / 2,
        y: bounds.midY - height / 2,
        width: width,
        height: height
    )
}

func ensureDirectory(_ url: URL) throws {
    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
}

do {
    try ensureDirectory(outputDirectory)
    try ensureDirectory(outputDirectory.appendingPathComponent("contact-sheets", isDirectory: true))
    for preset in presets {
        try ensureDirectory(outputDirectory.appendingPathComponent(preset.slug, isDirectory: true))
    }

    let sources = try imageURLs(in: inputDirectory)
    guard !sources.isEmpty else {
        print("No images found in \(inputDirectory.path)")
        exit(1)
    }

    for source in sources {
        guard let original = loadImage(source) else {
            print("Skipping unreadable image: \(source.lastPathComponent)")
            continue
        }

        let stem = source.deletingPathExtension().lastPathComponent
        var variants: [(Preset, CIImage)] = []

        for preset in presets {
            let filtered = applyPreset(preset, to: original)
            variants.append((preset, filtered))
            let outputURL = outputDirectory
                .appendingPathComponent(preset.slug, isDirectory: true)
                .appendingPathComponent("\(stem)-\(preset.slug).jpg")
            try writeJPEG(filtered, to: outputURL)
        }

        let sheetURL = outputDirectory
            .appendingPathComponent("contact-sheets", isDirectory: true)
            .appendingPathComponent("\(stem)-comparison.jpg")
        try makeContactSheet(for: source, original: original, variants: variants, outputURL: sheetURL)

        print("Rendered \(source.lastPathComponent)")
    }

    print("Filter lab output: \(outputDirectory.path)")
} catch {
    fputs("Filter lab failed: \(error.localizedDescription)\n", stderr)
    exit(1)
}
