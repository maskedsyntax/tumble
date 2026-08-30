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

/// The layout is authored in 6.5-inch points and drawn through a scale, so the
/// same composition exports at any of App Store Connect's accepted sizes with
/// live text and shapes rendered at the output resolution rather than resampled.
let W: CGFloat = 1242
let H: CGFloat = 2688

struct Canvas {
    let name: String
    let width: CGFloat
    let height: CGFloat
    /// Where the files land: the primary size at the folder root, others beside
    /// it in their own directory.
    let subdirectory: String?
}

let canvases: [Canvas] = [
    // 6.9-inch is what App Store Connect asks for first; it scales this set
    // down for every smaller device.
    Canvas(name: "6.9-inch", width: 1320, height: 2868, subdirectory: nil),
    Canvas(name: "6.5-inch", width: 1242, height: 2688, subdirectory: "6.5-inch"),
]

let repoRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let screenshotSet = ProcessInfo.processInfo.environment["TUMBLE_SCREENSHOT_SET"] ?? "v3"
let outDir = repoRoot.appendingPathComponent("mockups-appstore-\(screenshotSet)")
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

// The grade pipeline lives in scripts/film-grade.swift, compiled in alongside
// the catalog - see render.sh.

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
    for canvas in canvases { render(number, name, canvas, body) }
}

func render(_ number: Int, _ name: String, _ canvas: Canvas, _ body: () -> Void) {
    // Drawn into an explicit 1x, opaque bitmap: `NSImage.lockFocus` would take
    // the backing scale of whatever display is attached and hand back a 2x
    // image, which is not a size App Store Connect accepts.
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(canvas.width), pixelsHigh: Int(canvas.height),
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    ), let context = NSGraphicsContext(bitmapImageRep: rep) else {
        fatalError("could not allocate the canvas")
    }

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    context.imageInterpolation = .high

    // Cover the whole output, then centre: the two accepted aspect ratios differ
    // by less than half a percent, so the overflow trimmed here is ~3px a side.
    let scale = max(canvas.width / W, canvas.height / H)
    let transform = NSAffineTransform()
    transform.translateX(by: (canvas.width - W * scale) / 2, yBy: (canvas.height - H * scale) / 2)
    transform.scale(by: scale)
    transform.concat()

    background()
    body()
    grainOverlay()
    NSGraphicsContext.restoreGraphicsState()

    // Flatten to opaque RGB. CoreGraphics cannot draw into a 24-bit context, so
    // the page is composed with alpha and the channel dropped here - App Store
    // Connect rejects a screenshot that still carries one.
    guard let drawn = rep.cgImage,
          let rgb = CGContext(
              data: nil, width: Int(canvas.width), height: Int(canvas.height),
              bitsPerComponent: 8, bytesPerRow: 0,
              space: CGColorSpaceCreateDeviceRGB(),
              bitmapInfo: CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.noneSkipLast.rawValue
          )
    else { fatalError("could not flatten the canvas") }
    rgb.draw(drawn, in: CGRect(x: 0, y: 0, width: canvas.width, height: canvas.height))
    guard let flattened = rgb.makeImage(),
          let png = NSBitmapImageRep(cgImage: flattened).representation(using: .png, properties: [:])
    else { fatalError("encode failed") }

    var directory = outDir
    if let subdirectory = canvas.subdirectory {
        directory = outDir.appendingPathComponent(subdirectory)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }
    let file = directory.appendingPathComponent(String(format: "%02d-%@.png", number, name))
    try? png.write(to: file)
    FileHandle.standardOutput.write("  wrote \(canvas.name)/\(file.lastPathComponent)\n".data(using: .utf8)!)
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

    let board = r(margin, 820, W - margin * 2, 470)
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
         r(margin, 1344, W - margin * 2, 60),
         font: font("Georgia-Italic", 34), color: C.cream.withAlphaComponent(0.66), align: .center)

    // The promise, which is the last thing read before the Get button. Laid
    // out as a menu - name left, price right - so the eye can run down the
    // price column alone and see that none of them repeat.
    let tiers: [(String, String, String)] = [
        ("The daily roll", "Twelve shots, every morning", "Free"),
        ("Plus", "72 shots a day", "$5.99"),
        ("Unlimited", "No daily limit at all", "$11.99"),
        ("Film packs", "Five looks each", "$1.99"),
    ]

    let rowHeight: CGFloat = 132
    let panelTop: CGFloat = 1476
    let panelHeight = 128 + rowHeight * CGFloat(tiers.count) + 104
    let panel = r(margin, panelTop, W - margin * 2, panelHeight)

    C.cream.withAlphaComponent(0.05).setFill()
    rounded(panel, 28).fill()
    C.gold.withAlphaComponent(0.32).setStroke()
    let outline = rounded(panel, 28)
    outline.lineWidth = 2
    outline.stroke()

    text("PAY ONCE. NEVER AGAIN.",
         r(margin, panelTop + 46, panel.width, 46),
         font: mono(27), color: C.gold, tracking: 3.2, align: .center)

    let pad: CGFloat = 56
    for (i, row) in tiers.enumerated() {
        let top = panelTop + 128 + CGFloat(i) * rowHeight

        if i > 0 {
            C.cream.withAlphaComponent(0.09).setFill()
            NSBezierPath(rect: r(margin + pad, top - 1, panel.width - pad * 2, 1.5)).fill()
        }

        text(row.0, r(margin + pad, top + 26, panel.width - pad * 2 - 260, 50),
             font: sansBold(35), color: C.cream)
        text(row.1, r(margin + pad, top + 74, panel.width - pad * 2 - 260, 44),
             font: sans(27), color: C.cream.withAlphaComponent(0.55))

        // The price column: gold, right-aligned, one weight heavier than the
        // label so it is the thing that scans.
        text(row.2, r(margin + pad, top + 34, panel.width - pad * 2, 60),
             font: display(38), color: row.2 == "Free" ? C.cream : C.gold,
             tracking: -0.5, align: .right)
    }

    text("No subscriptions. No renewals. Ever.",
         r(margin, panelTop + panelHeight - 78, panel.width, 54),
         font: font("Georgia-Italic", 31), color: C.cream.withAlphaComponent(0.62), align: .center)

    footnote("NO ADS · NO FEED · NO ANALYTICS")
}

// MARK: - v4 — search-first, one idea per frame

enum V4 {
    static let coral = NSColor(hex: 0xC96E58)
    static let teal = NSColor(hex: 0x397A78)
    static let violet = NSColor(hex: 0x675D86)
    static let moss = NSColor(hex: 0x68785E)
    static let rust = NSColor(hex: 0x9A624A)
    static let sky = NSColor(hex: 0x4E7894)
}

func v4Background(_ accent: NSColor) {
    let darkAccent = accent.blended(withFraction: 0.58, of: C.ink) ?? C.blueDeep
    NSGradient(colors: [darkAccent, C.blueDeep, C.ink],
               atLocations: [0, 0.48, 1], colorSpace: .sRGB)?
        .draw(in: CGRect(x: 0, y: 0, width: W, height: H), angle: -90)

    let glow = NSBezierPath(ovalIn: CGRect(x: -W * 0.35, y: H * 0.42, width: W * 1.7, height: H * 0.72))
    NSGradient(starting: accent.withAlphaComponent(0.20), ending: accent.withAlphaComponent(0))?
        .draw(in: glow, relativeCenterPosition: .zero)
}

@discardableResult
func v4Title(_ value: String, size: CGFloat = 112, y: CGFloat = 126) -> CGFloat {
    let lines = value.components(separatedBy: "\n").count
    let lineHeight = size * 1.01
    let height = lineHeight * CGFloat(lines) + 20
    text(value, r(margin, y, W - margin * 2, height),
         font: display(size), color: C.cream, tracking: -2.6, lineHeight: lineHeight)
    return y + height
}

func v4Pill(_ value: String, x: CGFloat, y: CGFloat, width: CGFloat,
            fill: NSColor = C.cream.withAlphaComponent(0.10),
            color: NSColor = C.cream.withAlphaComponent(0.82)) {
    let rect = r(x, y, width, 66)
    fill.setFill()
    rounded(rect, 33).fill()
    text(value, CGRect(x: rect.minX, y: rect.minY + 18, width: rect.width, height: 34),
         font: mono(20), color: color, tracking: 1.8, align: .center)
}

func v4Tile(_ file: String, _ stock: String, at rect: CGRect, radius: CGFloat = 24) {
    shadow(34, 14, 0.32) {
        NSColor.black.setFill()
        rounded(rect, radius).fill()
    }
    let image = portrait(file, stock, size: rect.size)
    NSGraphicsContext.saveGraphicsState()
    rounded(rect, radius).setClip()
    image.draw(in: rect)
    NSGraphicsContext.restoreGraphicsState()
    C.cream.withAlphaComponent(0.18).setStroke()
    let edge = rounded(rect, radius)
    edge.lineWidth = 2
    edge.stroke()
}

func v4TileLabel(_ value: String, rect: CGRect) {
    let bar = CGRect(x: rect.minX + 18, y: rect.minY + 18, width: rect.width - 36, height: 62)
    NSColor.black.withAlphaComponent(0.60).setFill()
    rounded(bar, 31).fill()
    text(value.uppercased(), CGRect(x: bar.minX, y: bar.minY + 17, width: bar.width, height: 34),
         font: mono(20), color: C.cream, tracking: 1.4, align: .center)
}

// 01 — desire first: one large, unmistakably filmic result.
func v4Look() {
    v4Background(V4.coral)
    _ = v4Title("Real film looks.\nStraight from camera.", size: 92)

    let hero = r(104, 520, 1034, 1210)
    let heroImage = print_("06-ocean-overlook.jpg", "warmArchive", side: 1034)
    printCard(heroImage, at: hero, caption: "sunday by the sea", rotation: -1.5)

    let names = [
        ("06-ocean-overlook.jpg", "fadedInstant", "FADED INSTANT"),
        ("06-ocean-overlook.jpg", "silver", "SILVER"),
        ("06-ocean-overlook.jpg", "goldenHour", "GOLDEN HOUR"),
    ]
    let gap: CGFloat = 22
    let tileW = (W - margin * 2 - gap * 2) / 3
    for (i, item) in names.enumerated() {
        let rect = r(margin + CGFloat(i) * (tileW + gap), 1888, tileW, 382)
        v4Tile(item.0, item.1, at: rect, radius: 20)
        v4TileLabel(item.2, rect: rect)
    }

    v4Pill("REAL GRAIN · HALATION · FADED BLACKS", x: 198, y: 2380, width: 846,
           fill: C.gold.withAlphaComponent(0.16), color: C.gold)
}

// 02 — range, shown with fewer and much larger samples than v3.
func v4Looks() {
    v4Background(V4.sky)
    _ = v4Title("One shot.\nTwenty-one looks.", size: 112)

    let items = [
        ("fadedInstant", "Faded Instant"),
        ("disposable", "Disposable"),
        ("silver", "Silver"),
        ("goldenHour", "Golden Hour"),
        ("lightLeak", "Light Leak"),
        ("crossProcess", "Cross Process"),
    ]
    let gapX: CGFloat = 28
    let gapY: CGFloat = 30
    let cellW = (W - margin * 2 - gapX) / 2
    let cellH: CGFloat = 500

    for (i, item) in items.enumerated() {
        let col = CGFloat(i % 2)
        let row = CGFloat(i / 2)
        let rect = r(margin + col * (cellW + gapX), 510 + row * (cellH + gapY), cellW, cellH)
        v4Tile("10-himalayan-road.jpg", item.0, at: rect, radius: 24)
        v4TileLabel(item.1, rect: rect)
    }

    v4Pill("+ 15 MORE ACROSS FOUR PACKS", x: 250, y: 2248, width: 742,
           fill: C.gold.withAlphaComponent(0.16), color: C.gold)
}

// 03 — the interaction no competitor can claim.
func v4Shake() {
    v4Background(C.gold)
    _ = v4Title("Shake it.\nWatch it develop.", size: 112)

    // Oversized step numbers turn the three prints into one kinetic sequence,
    // even when the carousel is viewed as a small search-result thumbnail.
    text("01", r(34, 520, 350, 190), font: display(162),
         color: C.gold.withAlphaComponent(0.20), tracking: -4)
    text("02", r(430, 1050, 360, 190), font: display(162),
         color: C.gold.withAlphaComponent(0.20), tracking: -4)
    text("03", r(850, 1650, 350, 190), font: display(162),
         color: C.gold.withAlphaComponent(0.20), tracking: -4)

    // Use a naturally high-contrast scene and the warmer archive stock here.
    // The former misty source plus Faded Instant grade made even the completed
    // print look unfinished, which weakened the payoff of the interaction.
    let image = print_("01-autumn-trail.jpg", "warmArchive", side: 650)
    let blank = r(42, 620, 530, 636)
    let shaking = r(316, 1070, 620, 744)
    let developed = r(634, 1640, 570, 684)

    // Two offset outlines read as physical motion without inventing a hand or
    // phone that is not part of the app.
    for dx in [-26.0, 26.0] {
        C.cream.withAlphaComponent(0.13).setStroke()
        let echo = rounded(shaking.offsetBy(dx: dx, dy: 0), 12)
        echo.lineWidth = 5
        echo.stroke()
    }

    developingCard(image, at: blank, progress: 0.0, rotation: -9, label: "BLANK")
    developingCard(image, at: shaking, progress: 0.58, rotation: 5, label: "SHAKE")
    developingCard(image, at: developed, progress: 1.0, rotation: -4, label: "DEVELOPED")

    text("wait for it…", r(margin, 2408, W - margin * 2, 90),
         font: hand(66), color: C.gold, align: .center)
}

// 04 — frame the limit as attention, not deprivation.
func v4Roll() {
    v4Background(V4.moss)
    _ = v4Title("Twelve shots.\nMake them count.", size: 112)

    // A contact sheet with sprocket holes makes the quota feel like a physical
    // roll of film rather than an app limit or a settings grid.
    let strip = r(92, 540, W - 184, 1480)
    shadow(54, 24, 0.42) {
        NSColor(hex: 0x111315).setFill()
        rounded(strip, 30).fill()
    }
    C.gold.withAlphaComponent(0.24).setStroke()
    let stripEdge = rounded(strip, 30)
    stripEdge.lineWidth = 3
    stripEdge.stroke()

    for i in 0..<18 {
        let holeY = strip.minY + 34 + CGFloat(i) * ((strip.height - 96) / 17)
        for x in [strip.minX + 18, strip.maxX - 44] {
            NSColor(hex: 0xD5C7A9).withAlphaComponent(0.72).setFill()
            rounded(CGRect(x: x, y: holeY, width: 26, height: 48), 7).fill()
        }
    }

    rotated(around: CGPoint(x: strip.minX + 56, y: strip.midY), degrees: 90) {
        text("TUMBLE · DAILY 12 · COLOR NEGATIVE",
             CGRect(x: strip.minX - 300, y: strip.midY + 22, width: 700, height: 34),
             font: mono(17), color: C.gold.withAlphaComponent(0.60), tracking: 2, align: .center)
    }

    let files = ["16-rainy-park.jpg", "06-ocean-overlook.jpg", "07-coffee-books.jpg",
                 "01-autumn-trail.jpg", "04-city-sunset.jpg"]
    let stocks = ["warmArchive", "fadedInstant", "sepiaPrint", "goldenHour", "crossProcess"]
    let cols = 3
    let gap: CGFloat = 18
    let insetX: CGFloat = 78
    let insetY: CGFloat = 52
    let cellW = (strip.width - insetX * 2 - gap * 2) / 3
    let cellH = (strip.height - insetY * 2 - gap * 3) / 4

    for i in 0..<12 {
        let col = CGFloat(i % cols)
        let row = CGFloat(i / cols)
        let cell = CGRect(x: strip.minX + insetX + col * (cellW + gap),
                          y: strip.maxY - insetY - cellH - row * (cellH + gap),
                          width: cellW, height: cellH)
        if i < files.count {
            v4Tile(files[i], stocks[i], at: cell, radius: 8)
            let badge = CGRect(x: cell.minX + 14, y: cell.maxY - 52, width: 64, height: 36)
            NSColor.black.withAlphaComponent(0.55).setFill()
            rounded(badge, 18).fill()
            text(String(format: "%02d", i + 1), CGRect(x: badge.minX, y: badge.minY + 8, width: badge.width, height: 24),
                 font: mono(16), color: C.cream, align: .center)
        } else {
            NSColor(hex: 0x292B2C).setFill()
            rounded(cell, 8).fill()
            C.gold.withAlphaComponent(0.18).setStroke()
            let cellOutline = rounded(cell, 8)
            cellOutline.lineWidth = 2
            cellOutline.stroke()
            text(String(format: "%02d", i + 1),
                 CGRect(x: cell.minX, y: cell.midY - 18, width: cell.width, height: 40),
                 font: mono(23), color: C.cream.withAlphaComponent(0.34), tracking: 1, align: .center)
        }
    }

    text("Five moments kept.", r(margin, 2080, W - margin * 2, 96),
         font: display(62), color: C.cream, tracking: -1, align: .center)
    text("Seven still waiting.", r(margin, 2172, W - margin * 2, 74),
         font: font("Georgia-Italic", 42), color: C.cream.withAlphaComponent(0.68), align: .center)
    v4Pill("A FRESH ROLL EVERY MORNING", x: 244, y: 2330, width: 754,
           fill: C.gold.withAlphaComponent(0.16), color: C.gold)
}

// 05 — a private collection that feels physical.
func v4Drawer() {
    v4Background(V4.rust)
    _ = v4Title("Your days, kept.\nNever posted.", size: 108)

    // The prints now live inside a visible open drawer rather than floating in
    // space. It makes Tumble's home metaphor land before a word is read.
    let tray = r(58, 560, W - 116, 1700)
    shadow(70, 28, 0.46) {
        NSGradient(colors: [NSColor(hex: 0x5A3C31), NSColor(hex: 0x2B2524)],
                   atLocations: [0, 1], colorSpace: .sRGB)?
            .draw(in: rounded(tray, 34), angle: -90)
    }
    C.gold.withAlphaComponent(0.32).setStroke()
    let trayEdge = rounded(tray, 34)
    trayEdge.lineWidth = 4
    trayEdge.stroke()

    let lip = CGRect(x: tray.minX + 22, y: tray.minY + 24, width: tray.width - 44, height: 110)
    NSColor.black.withAlphaComponent(0.24).setFill()
    rounded(lip, 18).fill()
    let handle = CGRect(x: tray.midX - 150, y: tray.minY + 51, width: 300, height: 46)
    C.gold.withAlphaComponent(0.44).setStroke()
    let handlePath = rounded(handle, 23)
    handlePath.lineWidth = 5
    handlePath.stroke()

    struct Scatter { let file: String; let stock: String; let x: CGFloat; let y: CGFloat; let w: CGFloat; let rot: CGFloat }
    let pile: [Scatter] = [
        Scatter(file: "18-snowy-hills.jpg", stock: "overcast", x: 88, y: 650, w: 480, rot: -9),
        Scatter(file: "12-ocean-foam.jpg", stock: "silver", x: 660, y: 630, w: 490, rot: 8),
        Scatter(file: "08-desert-road.jpg", stock: "sunbleached", x: 355, y: 890, w: 530, rot: 2),
        Scatter(file: "06-ocean-overlook.jpg", stock: "warmArchive", x: 92, y: 1280, w: 500, rot: 7),
        Scatter(file: "05-coastal-cliff.jpg", stock: "goldenHour", x: 656, y: 1280, w: 500, rot: -8),
        Scatter(file: "02-forest-path.jpg", stock: "fadedInstant", x: 350, y: 1620, w: 530, rot: 10),
    ]
    for item in pile {
        let image = print_(item.file, item.stock, side: item.w)
        printCard(image, at: r(item.x, item.y, item.w, item.w * 1.18), rotation: item.rot)
    }

    v4Pill("NO FEED · NO ALGORITHM", x: 278, y: 2376, width: 686,
           fill: C.gold.withAlphaComponent(0.16), color: C.gold)
}

/// AppKit ports of the four shipping postcard styles. They deliberately match
/// ClassicInstantFrame, VintagePostcardFrame, BorderedFilmFrame, and
/// DeckledEdgeFrame rather than showing four recolored copies of one card.
func v4VintagePostcard(_ image: NSImage, at rect: CGRect, rotation: CGFloat) {
    rotated(around: CGPoint(x: rect.midX, y: rect.midY), degrees: rotation) {
        shadow(44, 20, 0.42) {
            C.stock.setFill()
            rounded(rect, 12).fill()
        }
        let pad = rect.width * 0.05
        let side = rect.width - pad * 2
        let photoRect = CGRect(x: rect.minX + pad, y: rect.maxY - pad - side, width: side, height: side)
        image.draw(in: photoRect)
        NSColor.black.withAlphaComponent(0.13).setStroke()
        NSBezierPath(rect: photoRect).stroke()

        let band = CGRect(x: rect.minX + pad, y: rect.minY + pad, width: side, height: photoRect.minY - rect.minY - pad * 1.4)
        text("POST CARD", CGRect(x: band.minX, y: band.maxY - 54, width: band.width * 0.56, height: 48),
             font: display(rect.width * 0.045), color: C.ink.withAlphaComponent(0.72), tracking: 3)
        C.ink.withAlphaComponent(0.26).setFill()
        NSBezierPath(rect: CGRect(x: band.minX, y: band.maxY - 68, width: band.width, height: 1.5)).fill()
        text("wish you were here", CGRect(x: band.minX, y: band.minY + 22, width: band.width * 0.66, height: 70),
             font: hand(rect.width * 0.058), color: C.ink.withAlphaComponent(0.74))

        let stamp = CGRect(x: band.maxX - rect.width * 0.16, y: band.maxY - rect.width * 0.13,
                           width: rect.width * 0.15, height: rect.width * 0.115)
        NSColor.white.withAlphaComponent(0.45).setFill()
        NSBezierPath(rect: stamp).fill()
        C.ink.withAlphaComponent(0.34).setStroke()
        let stampEdge = NSBezierPath(rect: stamp)
        stampEdge.lineWidth = 2
        stampEdge.setLineDash([7, 5], count: 2, phase: 0)
        stampEdge.stroke()
        text("21\nJUL", CGRect(x: stamp.minX, y: stamp.minY + 8, width: stamp.width, height: stamp.height - 12),
             font: mono(rect.width * 0.024), color: C.gold, lineHeight: rect.width * 0.030, align: .center)
    }
}

func v4FilmPostcard(_ file: String, _ stock: String, at rect: CGRect, rotation: CGFloat) {
    rotated(around: CGPoint(x: rect.midX, y: rect.midY), degrees: rotation) {
        shadow(44, 20, 0.42) {
            NSColor(hex: 0xFBF8F1).setFill()
            rounded(rect, 9).fill()
        }
        let pad = rect.width * 0.035
        let photoRect = CGRect(x: rect.minX + pad, y: rect.minY + pad,
                               width: rect.width - pad * 2, height: rect.height - pad * 2)
        portrait(file, stock, size: photoRect.size).draw(in: photoRect)
        NSGradient(starting: NSColor.clear, ending: NSColor.black.withAlphaComponent(0.56))?
            .draw(in: CGRect(x: photoRect.minX, y: photoRect.minY, width: photoRect.width, height: 150), angle: -90)
        text("after the rain", CGRect(x: photoRect.minX + 20, y: photoRect.minY + 30,
                                      width: photoRect.width * 0.62, height: 56),
             font: hand(rect.width * 0.052), color: NSColor.white.withAlphaComponent(0.92))
        text("21 07 26", CGRect(x: photoRect.minX, y: photoRect.minY + 34,
                                width: photoRect.width - 20, height: 44),
             font: mono(rect.width * 0.031), color: C.gold, tracking: 1.5, align: .right)
    }
}

func v4DeckledPath(_ rect: CGRect) -> NSBezierPath {
    let path = NSBezierPath()
    let steps = 22
    func jitter(_ i: Int, _ phase: CGFloat) -> CGFloat {
        sin(CGFloat(i) * 2.17 + phase) * 4 + cos(CGFloat(i) * 0.91 + phase) * 2.5
    }
    path.move(to: CGPoint(x: rect.minX, y: rect.maxY + jitter(0, 0)))
    for i in 0...steps {
        let t = CGFloat(i) / CGFloat(steps)
        path.line(to: CGPoint(x: rect.minX + rect.width * t, y: rect.maxY + jitter(i, 0)))
    }
    for i in 0...steps {
        let t = CGFloat(i) / CGFloat(steps)
        path.line(to: CGPoint(x: rect.maxX + jitter(i, 1.4), y: rect.maxY - rect.height * t))
    }
    for i in 0...steps {
        let t = CGFloat(i) / CGFloat(steps)
        path.line(to: CGPoint(x: rect.maxX - rect.width * t, y: rect.minY + jitter(i, 2.8)))
    }
    for i in 0...steps {
        let t = CGFloat(i) / CGFloat(steps)
        path.line(to: CGPoint(x: rect.minX + jitter(i, 4.2), y: rect.minY + rect.height * t))
    }
    path.close()
    return path
}

func v4DeckledPostcard(_ image: NSImage, at rect: CGRect, rotation: CGFloat) {
    rotated(around: CGPoint(x: rect.midX, y: rect.midY), degrees: rotation) {
        shadow(44, 20, 0.42) {
            NSGradient(colors: [C.stock, NSColor(hex: 0xEDE2C9)],
                       atLocations: [0, 1], colorSpace: .sRGB)?
                .draw(in: rounded(rect, 12), angle: -90)
        }
        let side = rect.width * 0.82
        let photoRect = CGRect(x: rect.midX - side / 2, y: rect.maxY - rect.width * 0.075 - side,
                               width: side, height: side)
        let tear = v4DeckledPath(photoRect)
        NSGraphicsContext.saveGraphicsState()
        tear.setClip()
        image.draw(in: photoRect)
        NSGraphicsContext.restoreGraphicsState()

        for (x, degrees) in [(photoRect.minX + side * 0.03, -14.0), (photoRect.maxX - side * 0.23, 11.0)] {
            let tape = CGRect(x: x, y: photoRect.maxY - 10, width: side * 0.20, height: rect.width * 0.055)
            rotated(around: CGPoint(x: tape.midX, y: tape.midY), degrees: degrees) {
                NSColor.white.withAlphaComponent(0.40).setFill()
                rounded(tape, 3).fill()
            }
        }
        text("keep this one", CGRect(x: rect.minX, y: rect.minY + 38, width: rect.width, height: 70),
             font: hand(rect.width * 0.057), color: C.ink.withAlphaComponent(0.72), align: .center)
    }
}

// 06 — show every real export treatment, not two generic instant prints.
func v4Postcards() {
    v4Background(V4.rust)
    _ = v4Title("Four ways to\nsend the moment.", size: 108)

    let vintageImage = print_("14-quiet-lake.jpg", "sepiaPrint", side: 540)
    v4VintagePostcard(vintageImage, at: r(36, 570, 540, 740), rotation: -8)

    v4FilmPostcard("16-rainy-park.jpg", "warmArchive", at: r(690, 555, 500, 625), rotation: 8)

    let deckledImage = print_("06-ocean-overlook.jpg", "goldenHour", side: 540)
    v4DeckledPostcard(deckledImage, at: r(642, 1450, 550, 650), rotation: 7)

    let classicImage = print_("01-autumn-trail.jpg", "fadedInstant", side: 650)
    printCard(classicImage, at: r(248, 1030, 650, 790), caption: "the long way home", rotation: -3)

    let labels = ["CLASSIC", "VINTAGE", "FILM", "DECKLED"]
    let chipW: CGFloat = 244
    for (i, label) in labels.enumerated() {
        v4Pill(label, x: margin + CGFloat(i) * (chipW + 10), y: 2265, width: chipW,
               fill: i == 0 ? C.gold : C.cream.withAlphaComponent(0.10),
               color: i == 0 ? C.ink : C.cream)
    }
}

// 07 — the category's clearest whitespace: private by architecture.
func v4Private() {
    v4Background(V4.teal)
    _ = v4Title("On your phone.\nNowhere else.", size: 116)

    let device = r(154, 520, 934, 1550)
    NSColor.black.withAlphaComponent(0.40).setFill()
    rounded(device, 86).fill()
    C.cream.withAlphaComponent(0.22).setStroke()
    let deviceEdge = rounded(device, 86)
    deviceEdge.lineWidth = 4
    deviceEdge.stroke()

    let island = CGRect(x: device.midX - 126, y: device.maxY - 72, width: 252, height: 38)
    NSColor.black.withAlphaComponent(0.72).setFill()
    rounded(island, 19).fill()

    let inside: [(String, String, CGFloat, CGFloat, CGFloat, CGFloat)] = [
        ("15-rainy-night.jpg", "flashNight", 220, 680, 360, -7),
        ("06-ocean-overlook.jpg", "warmArchive", 630, 650, 350, 8),
        ("07-coffee-books.jpg", "fadedInstant", 430, 1050, 390, 2),
        ("01-autumn-trail.jpg", "goldenHour", 220, 1420, 350, 7),
        ("05-coastal-cliff.jpg", "overcast", 630, 1430, 350, -8),
    ]
    for item in inside {
        let image = print_(item.0, item.1, side: item.4)
        printCard(image, at: r(item.2, item.3, item.4, item.4 * 1.18), rotation: item.5)
    }

    let badges = ["NO ACCOUNT", "NO CLOUD", "NO FEED"]
    let gap: CGFloat = 18
    let badgeW = (W - margin * 2 - gap * 2) / 3
    for (i, badge) in badges.enumerated() {
        v4Pill(badge, x: margin + CGFloat(i) * (badgeW + gap), y: 2240, width: badgeW,
               fill: C.cream.withAlphaComponent(0.11), color: C.cream)
    }
    text("Your photos stay on device.", r(margin, 2388, W - margin * 2, 70),
         font: font("Georgia-Italic", 34), color: C.cream.withAlphaComponent(0.70), align: .center)
}

// MARK: - Main

try? FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)
FileHandle.standardOutput.write("Rendering Tumble App Store set (\(screenshotSet))\n".data(using: .utf8)!)

if screenshotSet == "v4" {
    page(1, "real-film-looks", v4Look)
    page(2, "twenty-one-looks", v4Looks)
    page(3, "shake-to-develop", v4Shake)
    page(4, "twelve-shots", v4Roll)
    page(5, "private-drawer", v4Drawer)
    page(6, "postcards", v4Postcards)
    page(7, "on-device", v4Private)
} else {
    page(1, "the-look", pageLook)
    page(2, "every-film", pageStocks)
    page(3, "shake-to-develop", pageShake)
    page(4, "postcards", pagePostcards)
    page(5, "the-drawer", pageDrawer)
    page(6, "the-roll", pageRoll)
}

FileHandle.standardOutput.write("Done.\n".data(using: .utf8)!)
