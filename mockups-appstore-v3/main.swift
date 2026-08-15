#!/usr/bin/env swift
//
// Tumble App Store screenshots, v3 - the look-first set.
//
// Every frame is drawn here rather than captured, but nothing in it is
// invented: the photographs run through the *real* grade pipeline, ported
// filter-for-filter from TumbleKit/Filter/TumblePhotoFilter.swift, using the
// real catalog data from FilmStock.swift (compiled in alongside this file). A
// look on these pages is the look the app produces.
//
// Named main.swift because it runs top-level code; ./mockups-appstore-v3/render.sh
// compiles it together with the app's real catalog and runs it.

import AppKit
import CoreGraphics
import CoreImage
import CoreText
import Foundation

// MARK: - Canvas

let W: CGFloat = 1242
let H: CGFloat = 2688

let repoRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let outDir = repoRoot.appendingPathComponent("mockups-appstore-v3")
let photoDir = repoRoot.appendingPathComponent("mockups-appstore/assets/archive")

enum C {
    static let ink = NSColor(hex: 0x141F28)
    static let blueDeep = NSColor(hex: 0x172734)
    static let blue = NSColor(hex: 0x2E4052)
    static let cream = NSColor(hex: 0xF6EFE2)
    static let stock = NSColor(hex: 0xF4ECDA)
    static let gold = NSColor(hex: 0xDFAB68)
    static let amber = NSColor(hex: 0xE0A94F)
}

extension NSColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        self.init(
            srgbRed: CGFloat((hex >> 16) & 0xff) / 255,
            green: CGFloat((hex >> 8) & 0xff) / 255,
            blue: CGFloat(hex & 0xff) / 255,
            alpha: alpha
        )
    }
}

/// Rect measured from the top-left, the way the layout is designed.
func r(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> CGRect {
    CGRect(x: x, y: H - y - h, width: w, height: h)
}

// MARK: - Type

let caveat: String = {
    let url = repoRoot.appendingPathComponent("app/TumbleKit/Fonts/Caveat.ttf")
    CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
    return "Caveat-Regular"
}()

func font(_ name: String, _ size: CGFloat) -> NSFont {
    NSFont(name: name, size: size) ?? .systemFont(ofSize: size)
}

func display(_ size: CGFloat) -> NSFont { font("Georgia-Bold", size) }
func sans(_ size: CGFloat) -> NSFont { font("AvenirNext-Medium", size) }
func sansBold(_ size: CGFloat) -> NSFont { font("AvenirNext-DemiBold", size) }
func mono(_ size: CGFloat) -> NSFont { font("Menlo-Bold", size) }
func hand(_ size: CGFloat) -> NSFont { font(caveat, size) }

@discardableResult
func text(
    _ value: String,
    _ rect: CGRect,
    font f: NSFont,
    color: NSColor,
    tracking: CGFloat = 0,
    lineHeight: CGFloat? = nil,
    align: NSTextAlignment = .left
) -> CGFloat {
    let style = NSMutableParagraphStyle()
    style.alignment = align
    if let lineHeight {
        style.minimumLineHeight = lineHeight
        style.maximumLineHeight = lineHeight
    }
    var attrs: [NSAttributedString.Key: Any] = [
        .font: f, .foregroundColor: color, .paragraphStyle: style,
    ]
    if tracking != 0 { attrs[.kern] = tracking }
    let string = NSAttributedString(string: value, attributes: attrs)
    string.draw(in: rect)
    return string.boundingRect(with: CGSize(width: rect.width, height: .greatestFiniteMagnitude),
                               options: [.usesLineFragmentOrigin]).height
}

// MARK: - Shapes

func rounded(_ rect: CGRect, _ radius: CGFloat) -> NSBezierPath {
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
}

func shadow(_ blur: CGFloat, _ dy: CGFloat, _ alpha: CGFloat, _ body: () -> Void) {
    NSGraphicsContext.saveGraphicsState()
    let s = NSShadow()
    s.shadowBlurRadius = blur
    s.shadowOffset = NSSize(width: 0, height: -dy)
    s.shadowColor = NSColor.black.withAlphaComponent(alpha)
    s.set()
    body()
    NSGraphicsContext.restoreGraphicsState()
}

func rotated(around point: CGPoint, degrees: CGFloat, _ body: () -> Void) {
    NSGraphicsContext.saveGraphicsState()
    let t = NSAffineTransform()
    t.translateX(by: point.x, yBy: point.y)
    t.rotate(byDegrees: degrees)
    t.translateX(by: -point.x, yBy: -point.y)
    t.concat()
    body()
    NSGraphicsContext.restoreGraphicsState()
}

// MARK: - The grade pipeline (ported from TumblePhotoFilter)

let ciContext = CIContext(options: [.useSoftwareRenderer: false])

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

// MARK: - Photographs

var photoCache: [String: CIImage] = [:]

func photo(_ name: String) -> CIImage {
    if let cached = photoCache[name] { return cached }
    let url = photoDir.appendingPathComponent(name)
    guard let image = CIImage(contentsOf: url) else {
        fatalError("missing photograph: \(url.path)")
    }
    photoCache[name] = image
    return image
}

/// A square crop, graded, at drawing resolution.
func print_(_ name: String, _ stockID: String, side: CGFloat) -> NSImage {
    let source = photo(name)
    let e = source.extent
    let s = min(e.width, e.height)
    let square = source.cropped(to: CGRect(x: e.midX - s / 2, y: e.midY - s / 2, width: s, height: s))
    let scale = (side * 2) / s
    let sized = square
        .transformed(by: CGAffineTransform(translationX: -square.extent.origin.x, y: -square.extent.origin.y))
        .transformed(by: CGAffineTransform(scaleX: scale, y: scale))
    let graded = applyGrade(FilmStockCatalog.resolve(stockID).grade, to: sized)
    guard let cg = ciContext.createCGImage(graded, from: graded.extent) else {
        fatalError("could not render \(name)")
    }
    return NSImage(cgImage: cg, size: NSSize(width: side, height: side))
}

/// A portrait crop for full-bleed use.
func portrait(_ name: String, _ stockID: String, size: CGSize) -> NSImage {
    let source = photo(name)
    let e = source.extent
    let targetRatio = size.width / size.height
    var cropW = e.width, cropH = e.width / targetRatio
    if cropH > e.height { cropH = e.height; cropW = e.height * targetRatio }
    let crop = source.cropped(to: CGRect(x: e.midX - cropW / 2, y: e.midY - cropH / 2, width: cropW, height: cropH))
    let scale = (size.width * 2) / cropW
    let sized = crop
        .transformed(by: CGAffineTransform(translationX: -crop.extent.origin.x, y: -crop.extent.origin.y))
        .transformed(by: CGAffineTransform(scaleX: scale, y: scale))
    let graded = applyGrade(FilmStockCatalog.resolve(stockID).grade, to: sized)
    guard let cg = ciContext.createCGImage(graded, from: graded.extent) else {
        fatalError("could not render \(name)")
    }
    return NSImage(cgImage: cg, size: size)
}

// MARK: - Page furniture

func background(warmGlow: Bool = true) {
    NSGradient(colors: [C.blue, C.blueDeep, C.ink],
               atLocations: [0, 0.55, 1],
               colorSpace: .sRGB)?
        .draw(in: CGRect(x: 0, y: 0, width: W, height: H), angle: -90)

    if warmGlow {
        // Radial, and drawn inside an oval so it fades out instead of ending on
        // a straight edge.
        let glow = NSBezierPath(ovalIn: CGRect(x: -W * 0.45, y: H * 0.30, width: W * 1.9, height: H * 0.86))
        NSGradient(starting: C.gold.withAlphaComponent(0.13), ending: C.gold.withAlphaComponent(0))?
            .draw(in: glow, relativeCenterPosition: .zero)
    }
}

/// A whisper of grain over the whole page, so the composition sits on film too.
func grainOverlay() {
    guard let noise = CIFilter(name: "CIRandomGenerator")?.outputImage?
        .cropped(to: CGRect(x: 0, y: 0, width: W, height: H))
        .applyingFilter("CIColorControls", parameters: [
            kCIInputSaturationKey: 0, kCIInputContrastKey: 0.55, kCIInputBrightnessKey: -0.08,
        ]),
        let cg = ciContext.createCGImage(noise, from: CGRect(x: 0, y: 0, width: W, height: H))
    else { return }
    NSImage(cgImage: cg, size: NSSize(width: W, height: H))
        .draw(in: CGRect(x: 0, y: 0, width: W, height: H),
              from: .zero, operation: .softLight, fraction: 0.30)
}

let margin: CGFloat = 88

func header(kicker: String, headline: String, sub: String? = nil, headlineSize: CGFloat = 100) {
    text(kicker, r(margin, 132, W - margin * 2, 34),
         font: mono(24), color: C.gold, tracking: 4.5)

    let lines = headline.components(separatedBy: "\n").count
    let lh = headlineSize * 1.06
    text(headline, r(margin, 190, W - margin * 2, lh * CGFloat(lines) + 20),
         font: display(headlineSize), color: C.cream, tracking: -2.2, lineHeight: lh)

    if let sub {
        let y = 190 + lh * CGFloat(lines) + 26
        text(sub, r(margin, y, W - margin * 2 - 40, 130),
             font: sans(33), color: C.cream.withAlphaComponent(0.70), lineHeight: 45)
    }
}

func footnote(_ value: String) {
    text(value, r(margin, H - 150, W - margin * 2, 40),
         font: mono(23), color: C.cream.withAlphaComponent(0.42), tracking: 2.6, align: .center)
}

/// A developed print: cream stock, photo inset, optional handwritten caption.
func printCard(_ image: NSImage?, at rect: CGRect, caption: String? = nil, rotation: CGFloat = 0, blank: Bool = false) {
    let centre = CGPoint(x: rect.midX, y: rect.midY)
    rotated(around: centre, degrees: rotation) {
        shadow(48, 22, 0.42) {
            C.stock.setFill()
            rounded(rect, 10).fill()
        }
        let pad = rect.width * 0.055
        let photoSide = rect.width - pad * 2
        let photoRect = CGRect(x: rect.minX + pad, y: rect.maxY - pad - photoSide, width: photoSide, height: photoSide)

        if blank {
            NSColor(hex: 0xE7DFCC).setFill()
            NSBezierPath(rect: photoRect).fill()
        } else if let image {
            image.draw(in: photoRect)
        }
        NSColor.black.withAlphaComponent(0.10).setStroke()
        let edge = NSBezierPath(rect: photoRect)
        edge.lineWidth = 2
        edge.stroke()

        if let caption {
            let band = CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: rect.minY.distance(to: photoRect.minY))
            text(caption,
                 CGRect(x: band.minX, y: band.minY + band.height * 0.16, width: band.width, height: band.height * 0.7),
                 font: hand(rect.width * 0.085), color: NSColor(hex: 0x3B3730), align: .center)
        }
    }
}

// MARK: - Pages

func page(_ number: Int, _ name: String, _ body: () -> Void) {
    // Drawn into an explicit 1x, opaque bitmap: `NSImage.lockFocus` would take
    // the backing scale of whatever display is attached and hand back a 2x
    // image, which is not a size App Store Connect accepts.
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(W), pixelsHigh: Int(H),
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    ), let canvas = NSGraphicsContext(bitmapImageRep: rep) else {
        fatalError("could not allocate the canvas")
    }

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = canvas
    canvas.imageInterpolation = .high
    background()
    body()
    grainOverlay()
    NSGraphicsContext.restoreGraphicsState()

    // Flatten to opaque RGB. CoreGraphics cannot draw into a 24-bit context, so
    // the page is composed with alpha and the channel dropped here - App Store
    // Connect rejects a screenshot that still carries one.
    guard let drawn = rep.cgImage,
          let rgb = CGContext(
              data: nil, width: Int(W), height: Int(H),
              bitsPerComponent: 8, bytesPerRow: 0,
              space: CGColorSpaceCreateDeviceRGB(),
              bitmapInfo: CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.noneSkipLast.rawValue
          )
    else { fatalError("could not flatten the canvas") }
    rgb.draw(drawn, in: CGRect(x: 0, y: 0, width: W, height: H))
    guard let flattened = rgb.makeImage(),
          let png = NSBitmapImageRep(cgImage: flattened).representation(using: .png, properties: [:])
    else { fatalError("encode failed") }

    let file = outDir.appendingPathComponent(String(format: "%02d-%@.png", number, name))
    try? png.write(to: file)
    FileHandle.standardOutput.write("  wrote \(file.lastPathComponent)\n".data(using: .utf8)!)
}

/// A print mid-develop: the image rising out of blank stock.
func developingCard(_ image: NSImage, at rect: CGRect, progress: CGFloat, rotation: CGFloat, label: String) {
    let centre = CGPoint(x: rect.midX, y: rect.midY)
    rotated(around: centre, degrees: rotation) {
        shadow(44, 20, 0.42) {
            C.stock.setFill()
            rounded(rect, 10).fill()
        }
        let pad = rect.width * 0.055
        let side = rect.width - pad * 2
        let photoRect = CGRect(x: rect.minX + pad, y: rect.maxY - pad - side, width: side, height: side)

        NSColor(hex: 0xE7DFCC).setFill()
        NSBezierPath(rect: photoRect).fill()
        if progress > 0 {
            image.draw(in: photoRect, from: .zero, operation: .sourceOver, fraction: progress)
        }
        NSColor.black.withAlphaComponent(0.10).setStroke()
        let edge = NSBezierPath(rect: photoRect)
        edge.lineWidth = 2
        edge.stroke()

        let band = CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: photoRect.minY - rect.minY)
        text(label, CGRect(x: band.minX, y: band.minY + band.height * 0.30, width: band.width, height: band.height * 0.6),
             font: mono(rect.width * 0.055), color: NSColor(hex: 0x8A8579), tracking: 2, align: .center)
    }
}

func chip(_ label: String, at rect: CGRect, filled: Bool) {
    if filled {
        C.gold.setFill()
        rounded(rect, rect.height / 2).fill()
    } else {
        C.cream.withAlphaComponent(0.22).setStroke()
        let path = rounded(rect, rect.height / 2)
        path.lineWidth = 2
        path.stroke()
    }
    text(label, CGRect(x: rect.minX, y: rect.minY + rect.height * 0.24, width: rect.width, height: rect.height * 0.7),
         font: sansBold(rect.height * 0.40), color: filled ? C.ink : C.cream.withAlphaComponent(0.82),
         tracking: 0.6, align: .center)
}

// MARK: 01 - the look

func pageLook() {
    header(
        kicker: "REAL FILM · ON DEVICE",
        headline: "Not a filter.\nA film stock.",
        sub: "Grain, halation and faded blacks — baked into the photo, not\nsmeared on top of it.",
        headlineSize: 104
    )

    // Sized to its contents: padding, a square photo, then the caption band.
    let cardWidth = W - margin * 2
    let cardPad = cardWidth * 0.055
    let card = r(margin, 620, cardWidth, cardPad + (cardWidth - cardPad * 2) + 232)
    let pad = card.width * 0.055
    let side = card.width - pad * 2
    let photoRect = CGRect(x: card.minX + pad, y: card.maxY - pad - side, width: side, height: side)

    shadow(60, 26, 0.45) {
        C.stock.setFill()
        rounded(card, 12).fill()
    }

    let raw = portrait("04-city-sunset.jpg", "original", size: CGSize(width: side, height: side))
    let graded = portrait("04-city-sunset.jpg", "warmArchive", size: CGSize(width: side, height: side))

    let splitX = photoRect.minX + photoRect.width * 0.42
    NSGraphicsContext.saveGraphicsState()
    NSBezierPath(rect: CGRect(x: photoRect.minX, y: photoRect.minY, width: splitX - photoRect.minX, height: photoRect.height)).setClip()
    raw.draw(in: photoRect)
    NSGraphicsContext.restoreGraphicsState()

    NSGraphicsContext.saveGraphicsState()
    NSBezierPath(rect: CGRect(x: splitX, y: photoRect.minY, width: photoRect.maxX - splitX, height: photoRect.height)).setClip()
    graded.draw(in: photoRect)
    NSGraphicsContext.restoreGraphicsState()

    // The seam, and what sits on either side of it.
    C.gold.setFill()
    NSBezierPath(rect: CGRect(x: splitX - 1.5, y: photoRect.minY, width: 3, height: photoRect.height)).fill()

    func tag(_ value: String, centeredAt x: CGFloat, width: CGFloat) {
        let box = CGRect(x: x - width / 2, y: photoRect.minY + 26, width: width, height: 52)
        NSColor.black.withAlphaComponent(0.55).setFill()
        rounded(box, 26).fill()
        text(value, CGRect(x: box.minX, y: box.minY + 13, width: box.width, height: 34),
             font: mono(21), color: C.cream, tracking: 2.2, align: .center)
    }
    tag("BEFORE", centeredAt: (photoRect.minX + splitX) / 2, width: 210)
    tag("TUMBLE", centeredAt: (splitX + photoRect.maxX) / 2, width: 210)

    NSColor.black.withAlphaComponent(0.10).setStroke()
    let edge = NSBezierPath(rect: photoRect)
    edge.lineWidth = 2
    edge.stroke()

    text("warm archive", CGRect(x: card.minX, y: card.minY + 58, width: card.width, height: 96),
         font: hand(76), color: NSColor(hex: 0x3B3730), align: .center)

    // A hint of the shelf, so the page promises more than one look.
    let stripY: CGFloat = 2010
    text("THE SAME SHOT, FOUR OTHER WAYS",
         r(margin, stripY - 54, W - margin * 2, 40),
         font: mono(23), color: C.cream.withAlphaComponent(0.50), tracking: 3, align: .center)

    let swatchIDs = ["disposable", "silver", "goldenHour", "crossProcess"]
    let swatchGap: CGFloat = 18
    let swatch = (W - margin * 2 - swatchGap * 3) / 4
    for (i, id) in swatchIDs.enumerated() {
        let rect = r(margin + CGFloat(i) * (swatch + swatchGap), stripY, swatch, swatch)
        let image = print_("04-city-sunset.jpg", id, side: swatch)
        NSGraphicsContext.saveGraphicsState()
        rounded(rect, 12).setClip()
        image.draw(in: rect)
        NSGraphicsContext.restoreGraphicsState()
        C.cream.withAlphaComponent(0.14).setStroke()
        let border = rounded(rect, 12)
        border.lineWidth = 2
        border.stroke()
    }

    footnote("EVERY SHOT · EVERY EXPORT")
}

// MARK: 02 - the library

func pageStocks() {
    header(
        kicker: "TWENTY-ONE FILM STOCKS",
        headline: "One shot.\nEvery film.",
        sub: "Pick the look when the print develops — and see it on your own\nphoto before you choose.",
        headlineSize: 104
    )

    let ids = ["fadedInstant", "disposable", "silver", "goldenHour", "crossProcess",
               "sepiaPrint", "flashNight", "lightLeak", "camcorder"]
    let gap: CGFloat = 20
    let cell = (W - margin * 2 - gap * 2) / 3

    for (i, id) in ids.enumerated() {
        let col = CGFloat(i % 3), row = CGFloat(i / 3)
        let x = margin + col * (cell + gap)
        let y: CGFloat = 760 + row * (cell + 74)
        let rect = r(x, y, cell, cell)

        let image = print_("10-himalayan-road.jpg", id, side: cell)
        shadow(20, 8, 0.35) {
            NSColor.black.setFill()
            rounded(rect, 12).fill()
        }
        NSGraphicsContext.saveGraphicsState()
        rounded(rect, 12).setClip()
        image.draw(in: rect)
        NSGraphicsContext.restoreGraphicsState()

        C.cream.withAlphaComponent(0.14).setStroke()
        let border = rounded(rect, 12)
        border.lineWidth = 2
        border.stroke()

        text(FilmStockCatalog.resolve(id).name,
             r(x, y + cell + 14, cell, 40),
             font: sansBold(25), color: C.cream.withAlphaComponent(0.80), align: .center)
    }

    let strip = r(margin, 2210, W - margin * 2, 132)
    C.cream.withAlphaComponent(0.06).setFill()
    rounded(strip, 22).fill()
    text("+ 12 MORE ACROSS FOUR PACKS",
         CGRect(x: strip.minX, y: strip.minY + 74, width: strip.width, height: 40),
         font: mono(25), color: C.gold, tracking: 3, align: .center)
    text("The everyday stocks are free. Packs are one-time unlocks.",
         CGRect(x: strip.minX, y: strip.minY + 26, width: strip.width, height: 42),
         font: sans(27), color: C.cream.withAlphaComponent(0.62), align: .center)

    footnote("NO SUBSCRIPTIONS")
}

// MARK: 03 - shake to develop

func pageShake() {
    header(
        kicker: "THE PART YOU WAIT FOR",
        headline: "Shake it.\nWatch it come up.",
        sub: "Fresh prints land blank. The image rises as you shake — the way\nit used to.",
        headlineSize: 100
    )

    // The three prints step down the page in the order it happens; motion arcs
    // were tried here and only read as stray marks behind the cards.
    // One print, three moments - stepping down the page in the order it happens.
    let image = print_("09-misty-steps.jpg", "fadedInstant", side: 470)
    developingCard(image, at: r(64, 760, 392, 470), progress: 0.0, rotation: -8, label: "BLANK")
    developingCard(image, at: r(396, 1052, 430, 516), progress: 0.45, rotation: 4, label: "SHAKING")
    developingCard(image, at: r(700, 1392, 470, 564), progress: 1.0, rotation: -3, label: "DEVELOPED")

    let note = r(margin, 2076, W - margin * 2, 150)
    C.cream.withAlphaComponent(0.06).setFill()
    rounded(note, 22).fill()
    text("Reduce Motion on? Press and hold instead.",
         CGRect(x: note.minX, y: note.minY + 54, width: note.width, height: 50),
         font: sans(30), color: C.cream.withAlphaComponent(0.72), align: .center)

    footnote("NOTHING DEVELOPS WITHOUT YOU")
}

// MARK: 04 - postcards

func pagePostcards() {
    header(
        kicker: "POSTCARD FRAMES",
        headline: "Made to be\nsent, not scrolled.",
        sub: "Mount a print in one of four finishes, write on it by hand, and save\nthe whole keepsake.",
        headlineSize: 94
    )

    // The one behind: a sepia print tilted away, top-right.
    let back = r(600, 700, 520, 614)
    let backImage = print_("14-quiet-lake.jpg", "sepiaPrint", side: 520)
    printCard(backImage, at: back, rotation: 8)

    // The hero: classic instant with a handwritten note, overlapping it.
    let front = r(72, 940, 720, 906)
    let frontImage = print_("01-autumn-trail.jpg", "fadedInstant", side: 720)
    printCard(frontImage, at: front, caption: "the long way home", rotation: -4)

    // A postmark, so the postcard idea lands without a caption explaining it.
    let mark = r(846, 1520, 230, 230)
    rotated(around: CGPoint(x: mark.midX, y: mark.midY), degrees: -12) {
        C.gold.withAlphaComponent(0.80).setStroke()
        let ring = NSBezierPath(ovalIn: mark)
        ring.lineWidth = 5
        ring.setLineDash([13, 10], count: 2, phase: 0)
        ring.stroke()
        text("TUMBLE", CGRect(x: mark.minX, y: mark.midY + 4, width: mark.width, height: 44),
             font: mono(26), color: C.gold, tracking: 2, align: .center)
        text("21 JUL", CGRect(x: mark.minX, y: mark.midY - 44, width: mark.width, height: 40),
             font: mono(22), color: C.gold.withAlphaComponent(0.82), tracking: 2, align: .center)
    }

    let row = r(margin, 2190, W - margin * 2, 120)
    let names = ["Classic", "Vintage", "Film", "Deckled"]
    let chipW = (row.width - 30) / 4
    for (i, name) in names.enumerated() {
        chip(name, at: CGRect(x: row.minX + CGFloat(i) * (chipW + 10), y: row.minY + 30, width: chipW, height: 72),
             filled: i == 0)
    }

    footnote("SAVED STRAIGHT TO PHOTOS")
}

// MARK: 05 - the drawer

func pageDrawer() {
    header(
        kicker: "YOUR DRAWER",
        headline: "A pile of prints.\nNot a grid.",
        sub: "Home is a scattered stack that ages over time — grain, vignette,\na little patina.",
        headlineSize: 96
    )

    struct Scatter { let file: String; let stock: String; let x: CGFloat; let y: CGFloat; let w: CGFloat; let rot: CGFloat }
    let pile: [Scatter] = [
        Scatter(file: "18-snowy-hills.jpg", stock: "overcast", x: 70, y: 780, w: 430, rot: -11),
        Scatter(file: "12-ocean-foam.jpg", stock: "silver", x: 640, y: 720, w: 470, rot: 8),
        Scatter(file: "08-desert-road.jpg", stock: "sunbleached", x: 330, y: 1080, w: 500, rot: 3),
        Scatter(file: "15-rainy-night.jpg", stock: "flashNight", x: 60, y: 1420, w: 450, rot: 6),
        Scatter(file: "05-coastal-cliff.jpg", stock: "goldenHour", x: 620, y: 1500, w: 490, rot: -7),
        Scatter(file: "02-forest-path.jpg", stock: "fadedInstant", x: 300, y: 1760, w: 430, rot: 12),
    ]
    for p in pile {
        let image = print_(p.file, p.stock, side: p.w)
        printCard(image, at: r(p.x, p.y, p.w, p.w * 1.18), rotation: p.rot)
    }

    footnote("ON DEVICE · NO ACCOUNT · NO CLOUD")
}

// MARK: 06 - the roll, and the price

func pageRoll() {
    header(
        kicker: "TWELVE A DAY",
        headline: "A roll that\nruns out.",
        sub: "Twelve shots, fresh every morning. Knowing the number is what\nmakes you look before you press.",
        headlineSize: 100
    )

    let board = r(margin, 780, W - margin * 2, 470)
    C.cream.withAlphaComponent(0.06).setFill()
    rounded(board, 28).fill()

    let cols: CGFloat = 4, rows: CGFloat = 3
    let gap: CGFloat = 18
    let inset: CGFloat = 40
    let cw = (board.width - inset * 2 - gap * (cols - 1)) / cols
    let ch = (board.height - inset * 2 - gap * (rows - 1)) / rows
    for i in 0..<12 {
        let col = CGFloat(i % 4), row = CGFloat(i / 4)
        let cell = CGRect(x: board.minX + inset + col * (cw + gap),
                          y: board.maxY - inset - ch - row * (ch + gap),
                          width: cw, height: ch)
        let used = i < 5
        if used {
            C.gold.setFill()
            rounded(cell, 12).fill()
        } else {
            C.cream.withAlphaComponent(0.10).setFill()
            rounded(cell, 12).fill()
        }
        text(String(format: "%02d", i + 1),
             CGRect(x: cell.minX, y: cell.minY + cell.height * 0.28, width: cell.width, height: 44),
             font: mono(28), color: used ? C.ink : C.cream.withAlphaComponent(0.45), tracking: 1.4, align: .center)
    }

    text("Five taken. Seven still waiting.",
         r(margin, 1300, W - margin * 2, 60),
         font: font("Georgia-Italic", 34), color: C.cream.withAlphaComponent(0.66), align: .center)

    // The promise, which is the reason to tap Get.
    let panel = r(margin, 1440, W - margin * 2, 700)
    C.cream.withAlphaComponent(0.05).setFill()
    rounded(panel, 28).fill()
    C.gold.withAlphaComponent(0.30).setStroke()
    let outline = rounded(panel, 28)
    outline.lineWidth = 2
    outline.stroke()

    text("PAY ONCE. NEVER AGAIN.",
         CGRect(x: panel.minX, y: panel.maxY - 96, width: panel.width, height: 46),
         font: mono(27), color: C.gold, tracking: 3.2, align: .center)

    let rows2: [(String, String)] = [
        ("Free", "12 shots a day, forever"),
        ("Plus · $5.99", "72 shots a day, one-time"),
        ("Unlimited · $11.99", "No daily limit, one-time"),
        ("Film packs · $1.99", "Five looks each, one-time"),
    ]
    for (i, entry) in rows2.enumerated() {
        let y = panel.maxY - 190 - CGFloat(i) * 118
        text(entry.0, CGRect(x: panel.minX + 54, y: y, width: panel.width - 108, height: 50),
             font: sansBold(34), color: C.cream)
        text(entry.1, CGRect(x: panel.minX + 54, y: y - 44, width: panel.width - 108, height: 44),
             font: sans(27), color: C.cream.withAlphaComponent(0.58))
        if i < rows2.count - 1 {
            C.cream.withAlphaComponent(0.10).setFill()
            NSBezierPath(rect: CGRect(x: panel.minX + 54, y: y - 62, width: panel.width - 108, height: 1.5)).fill()
        }
    }

    footnote("NO ADS · NO FEED · NO ANALYTICS")
}

// MARK: - Main

try? FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)
FileHandle.standardOutput.write("Rendering Tumble App Store set (v3)\n".data(using: .utf8)!)

page(1, "the-look", pageLook)
page(2, "every-film", pageStocks)
page(3, "shake-to-develop", pageShake)
page(4, "postcards", pagePostcards)
page(5, "the-drawer", pageDrawer)
page(6, "the-roll", pageRoll)

FileHandle.standardOutput.write("Done.\n".data(using: .utf8)!)
