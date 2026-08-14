#!/usr/bin/env swift

import AppKit
import CoreGraphics
import Foundation

private let W: CGFloat = 1320
private let H: CGFloat = 2868
private let outputW: CGFloat = 1242
private let outputH: CGFloat = 2688
private let root = URL(fileURLWithPath: CommandLine.arguments[0]).standardizedFileURL.deletingLastPathComponent()
private let repo = root.deletingLastPathComponent()

private enum C {
    static let blue = NSColor(hex: 0x2E4052)
    static let blueDeep = NSColor(hex: 0x172734)
    static let charcoal = NSColor(hex: 0x202D39)
    static let cream = NSColor(hex: 0xF6EFE2)
    static let stock = NSColor(hex: 0xF4ECDA)
    static let ink = NSColor(hex: 0x1E2A34)
    static let gold = NSColor(hex: 0xDFAB68)
}

private struct Header {
    let kicker: String
    let headline: String
    let subhead: String
}

private extension NSColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        self.init(
            calibratedRed: CGFloat((hex >> 16) & 0xff) / 255,
            green: CGFloat((hex >> 8) & 0xff) / 255,
            blue: CGFloat(hex & 0xff) / 255,
            alpha: alpha
        )
    }
}

private func topRect(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat) -> CGRect {
    CGRect(x: x, y: H - y - height, width: width, height: height)
}

private func font(_ name: String, _ size: CGFloat) -> NSFont {
    NSFont(name: name, size: size) ?? .systemFont(ofSize: size)
}

private func text(
    _ value: String,
    rect: CGRect,
    font: NSFont,
    color: NSColor,
    tracking: CGFloat = 0,
    spacing: CGFloat = 0,
    alignment: NSTextAlignment = .left
) {
    let style = NSMutableParagraphStyle()
    style.alignment = alignment
    style.lineSpacing = spacing
    style.lineBreakMode = .byWordWrapping
    NSAttributedString(
        string: value,
        attributes: [
            .font: font,
            .foregroundColor: color,
            .kern: tracking,
            .paragraphStyle: style,
        ]
    ).draw(with: rect, options: [.usesLineFragmentOrigin, .usesFontLeading])
}

private func rounded(_ rect: CGRect, radius: CGFloat, fill: NSColor, stroke: NSColor? = nil, line: CGFloat = 1) {
    let path = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
    fill.setFill()
    path.fill()
    if let stroke {
        stroke.setStroke()
        path.lineWidth = line
        path.stroke()
    }
}

private func background(_ context: CGContext, variant: Int) {
    let space = CGColorSpaceCreateDeviceRGB()
    let bases: [(UInt32, UInt32)] = [
        (0x13232F, 0x30475A), (0x1B2935, 0x40515E), (0x152734, 0x2E4052),
        (0x24313B, 0x43525B), (0x172936, 0x344A5A), (0x202B35, 0x3B4650),
    ]
    let pair = bases[variant % bases.count]
    let gradient = CGGradient(
        colorsSpace: space,
        colors: [NSColor(hex: pair.0).cgColor, NSColor(hex: pair.1).cgColor, C.blueDeep.cgColor] as CFArray,
        locations: [0, 0.56, 1]
    )!
    context.drawLinearGradient(
        gradient,
        start: CGPoint(x: W * 0.2, y: H),
        end: CGPoint(x: W * 0.82, y: 0),
        options: []
    )

    let glow = CGGradient(
        colorsSpace: space,
        colors: [C.gold.withAlphaComponent(0.25).cgColor, C.gold.withAlphaComponent(0).cgColor] as CFArray,
        locations: [0, 1]
    )!
    let centers = [
        CGPoint(x: 1120, y: 2440), CGPoint(x: 180, y: 520), CGPoint(x: 1080, y: 500),
        CGPoint(x: 220, y: 2160), CGPoint(x: 1110, y: 2040), CGPoint(x: 180, y: 520),
    ]
    context.drawRadialGradient(
        glow,
        startCenter: centers[variant % centers.count],
        startRadius: 0,
        endCenter: centers[variant % centers.count],
        endRadius: 760,
        options: []
    )
}

private func header(_ value: Header, index: Int) {
    text(
        "TUMBLE  ·  SLOW CAMERA",
        rect: topRect(88, 70, 800, 38),
        font: font("AvenirNext-DemiBold", 24),
        color: C.gold,
        tracking: 3.1
    )
    text(
        String(format: "%02d / 06", index + 1),
        rect: topRect(1030, 70, 202, 38),
        font: font("AvenirNext-DemiBold", 23),
        color: C.cream.withAlphaComponent(0.56),
        tracking: 2.2,
        alignment: .right
    )
    text(
        value.kicker,
        rect: topRect(88, 136, 1144, 34),
        font: font("AvenirNext-DemiBold", 22),
        color: C.gold,
        tracking: 3.8
    )
    text(
        value.headline,
        rect: topRect(84, 182, 1152, 205),
        font: font("Georgia-Bold", 75),
        color: C.cream,
        tracking: -1.7,
        spacing: -7
    )
    text(
        value.subhead,
        rect: topRect(88, 410, 1110, 102),
        font: font("AvenirNext-Medium", 29),
        color: C.cream.withAlphaComponent(0.74),
        spacing: 5
    )
}

private func image(_ path: URL, in rect: CGRect, radius: CGFloat = 0) throws {
    guard let photo = NSImage(contentsOf: path) else {
        throw NSError(domain: "TumbleMockups", code: 2, userInfo: [NSLocalizedDescriptionKey: "Missing image: \(path.path)"])
    }
    let sourceSize = photo.size
    let sourceAspect = sourceSize.width / sourceSize.height
    let targetAspect = rect.width / rect.height
    var source = CGRect(origin: .zero, size: sourceSize)
    if sourceAspect > targetAspect {
        let width = sourceSize.height * targetAspect
        source.origin.x = (sourceSize.width - width) / 2
        source.size.width = width
    } else {
        let height = sourceSize.width / targetAspect
        source.origin.y = (sourceSize.height - height) / 2
        source.size.height = height
    }

    let context = NSGraphicsContext.current!.cgContext
    context.saveGState()
    if radius > 0 {
        context.addPath(CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil))
        context.clip()
    }
    NSGraphicsContext.current?.imageInterpolation = .high
    photo.draw(in: rect, from: source, operation: .sourceOver, fraction: 1)
    context.restoreGState()
}

private func shadowedCard(_ rect: CGRect, radius: CGFloat, fill: NSColor, stroke: NSColor? = nil) {
    let context = NSGraphicsContext.current!.cgContext
    context.saveGState()
    context.setShadow(offset: CGSize(width: 0, height: -18), blur: 34, color: NSColor.black.withAlphaComponent(0.42).cgColor)
    rounded(rect, radius: radius, fill: fill)
    context.restoreGState()
    rounded(rect, radius: radius, fill: fill, stroke: stroke, line: 2)
}

private enum PreviewTone {
    case natural
    case faded
    case warm
}

private func printCard(
    photo: URL,
    center: CGPoint,
    width: CGFloat,
    rotation: CGFloat,
    caption: String? = nil,
    progress: CGFloat = 1,
    tone: PreviewTone = .natural
) throws {
    let context = NSGraphicsContext.current!.cgContext
    let height = width * 1.18
    let stock = CGRect(x: -width / 2, y: -height / 2, width: width, height: height)
    let margin = width * 0.065
    let photoRect = CGRect(
        x: stock.minX + margin,
        y: stock.minY + width * 0.19,
        width: width - margin * 2,
        height: width - margin * 2
    )

    context.saveGState()
    context.translateBy(x: center.x, y: center.y)
    context.rotate(by: rotation * .pi / 180)
    context.setShadow(offset: CGSize(width: 0, height: -20), blur: 32, color: NSColor.black.withAlphaComponent(0.5).cgColor)
    rounded(stock, radius: width * 0.028, fill: C.stock)
    context.setShadow(offset: .zero, blur: 0, color: nil)
    try image(photo, in: photoRect, radius: width * 0.012)

    if tone != .natural {
        context.saveGState()
        context.addPath(CGPath(roundedRect: photoRect, cornerWidth: width * 0.012, cornerHeight: width * 0.012, transform: nil))
        context.clip()
        switch tone {
        case .natural:
            break
        case .faded:
            context.setBlendMode(.color)
            context.setFillColor(NSColor(hex: 0xB9B4A8, alpha: 0.34).cgColor)
            context.fill(photoRect)
            context.setBlendMode(.screen)
            context.setFillColor(C.cream.withAlphaComponent(0.16).cgColor)
            context.fill(photoRect)
        case .warm:
            context.setBlendMode(.color)
            context.setFillColor(NSColor(hex: 0xD58C52, alpha: 0.25).cgColor)
            context.fill(photoRect)
            context.setBlendMode(.multiply)
            context.setFillColor(NSColor(hex: 0x7D452D, alpha: 0.1).cgColor)
            context.fill(photoRect)
        }
        context.restoreGState()
    }

    if progress < 1 {
        C.cream.withAlphaComponent(0.56).setFill()
        NSBezierPath(rect: photoRect).fill()
        context.saveGState()
        let revealed = CGRect(x: photoRect.minX, y: photoRect.minY, width: photoRect.width, height: photoRect.height * progress)
        context.addRect(revealed)
        context.clip()
        try image(photo, in: photoRect, radius: width * 0.012)
        context.restoreGState()
        let haze = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: [C.cream.withAlphaComponent(0.1).cgColor, C.cream.withAlphaComponent(0.62).cgColor] as CFArray,
            locations: [0, 1]
        )!
        context.saveGState()
        context.addPath(CGPath(roundedRect: photoRect, cornerWidth: width * 0.012, cornerHeight: width * 0.012, transform: nil))
        context.clip()
        context.drawLinearGradient(
            haze,
            start: CGPoint(x: photoRect.midX, y: photoRect.minY),
            end: CGPoint(x: photoRect.midX, y: photoRect.maxY),
            options: []
        )
        context.restoreGState()
    }

    if let caption {
        let captionHeight = width * 0.075
        text(
            caption,
            rect: CGRect(
                x: stock.minX + margin,
                y: stock.minY + width * 0.025,
                width: stock.width - margin * 2,
                height: captionHeight
            ),
            font: font("Georgia-Italic", width * 0.052),
            color: C.ink.withAlphaComponent(0.72),
            alignment: .center
        )
    }
    context.restoreGState()
}

private func pill(_ label: String, rect: CGRect, fill: NSColor, color: NSColor, border: NSColor? = nil) {
    rounded(rect, radius: rect.height / 2, fill: fill, stroke: border, line: 2)
    text(
        label,
        rect: CGRect(x: rect.minX + 14, y: rect.minY + rect.height * 0.22, width: rect.width - 28, height: rect.height * 0.58),
        font: font("AvenirNext-DemiBold", rect.height * 0.27),
        color: color,
        tracking: 1.2,
        alignment: .center
    )
}

private func grain(_ context: CGContext, seed: UInt64) {
    var state = seed
    func random() -> CGFloat {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return CGFloat((state >> 33) & 0xffff) / CGFloat(0xffff)
    }
    for i in 0..<2600 {
        let color = i.isMultiple(of: 2) ? NSColor.white : NSColor.black
        context.setFillColor(color.withAlphaComponent(0.018 + random() * 0.018).cgColor)
        let size: CGFloat = i.isMultiple(of: 7) ? 2 : 1
        context.fill(CGRect(x: random() * W, y: random() * H, width: size, height: size))
    }
}

private func renderCanvas(index: Int, output: String, draw: (CGContext) throws -> Void) throws {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(outputW),
        pixelsHigh: Int(outputH),
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!
    NSGraphicsContext.saveGraphicsState()
    let graphics = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.current = graphics
    let context = graphics.cgContext
    context.interpolationQuality = .high
    context.scaleBy(x: outputW / W, y: outputH / H)
    background(context, variant: index)
    try draw(context)
    grain(context, seed: UInt64(index + 31))
    graphics.flushGraphics()
    NSGraphicsContext.restoreGraphicsState()

    let rgbContext = CGContext(
        data: nil,
        width: Int(outputW),
        height: Int(outputH),
        bitsPerComponent: 8,
        bytesPerRow: Int(outputW) * 4,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.noneSkipLast.rawValue
    )!
    rgbContext.draw(rep.cgImage!, in: CGRect(x: 0, y: 0, width: outputW, height: outputH))
    let rgbRep = NSBitmapImageRep(cgImage: rgbContext.makeImage()!)
    try rgbRep.representation(using: .png, properties: [:])!.write(
        to: root.appendingPathComponent(output),
        options: .atomic
    )
    print("Rendered \(output)")
}

private let originals = (1...6).map { repo.appendingPathComponent("test-images/img\($0)." + ($0 >= 3 && $0 <= 4 ? "jpeg" : "JPG")) }
private let faded = (1...6).map { repo.appendingPathComponent("test-output/faded-instant/img\($0)-faded-instant.jpg") }
private let warm = (1...6).map { repo.appendingPathComponent("test-output/warm-archive/img\($0)-warm-archive.jpg") }
private let archivePhotos = try FileManager.default.contentsOfDirectory(
    at: repo.appendingPathComponent("mockups-appstore/assets/archive"),
    includingPropertiesForKeys: nil
)
.filter { ["jpg", "jpeg"].contains($0.pathExtension.lowercased()) }
.sorted { $0.lastPathComponent < $1.lastPathComponent }

precondition(archivePhotos.count == 18, "The Archive mockup requires 18 unique photographs.")

// 01 — The daily constraint as a tactile film-count poster.
try renderCanvas(index: 0, output: "01-daily-roll.png") { context in
    header(
        Header(
            kicker: "THE DAILY ROLL",
            headline: "12 shots. Make them count.",
            subhead: "A fresh roll every morning — enough to notice, never enough to mindlessly collect."
        ),
        index: 0
    )

    try printCard(photo: faded[0], center: CGPoint(x: 610, y: 1430), width: 890, rotation: -3, caption: "one of twelve")

    let seal = CGRect(x: 845, y: 1380, width: 320, height: 320)
    context.saveGState()
    context.setShadow(offset: CGSize(width: 0, height: -16), blur: 28, color: NSColor.black.withAlphaComponent(0.4).cgColor)
    C.gold.setFill()
    NSBezierPath(ovalIn: seal).fill()
    context.restoreGState()
    C.gold.setFill()
    NSBezierPath(ovalIn: seal).fill()
    text("12", rect: CGRect(x: seal.minX, y: seal.minY + 94, width: seal.width, height: 130), font: font("Georgia-Bold", 104), color: C.ink, tracking: -3, alignment: .center)
    text("SHOTS TODAY", rect: CGRect(x: seal.minX, y: seal.minY + 62, width: seal.width, height: 42), font: font("AvenirNext-DemiBold", 24), color: C.ink.withAlphaComponent(0.82), tracking: 2.4, alignment: .center)

    let strip = topRect(86, 2240, 1148, 250)
    shadowedCard(strip, radius: 28, fill: C.charcoal.withAlphaComponent(0.82), stroke: C.cream.withAlphaComponent(0.12))
    for i in 0..<12 {
        let column = i % 6
        let row = i / 6
        let cell = CGRect(x: strip.minX + 45 + CGFloat(column) * 178, y: strip.maxY - 105 - CGFloat(row) * 92, width: 134, height: 60)
        rounded(cell, radius: 12, fill: i < 4 ? C.gold : C.cream.withAlphaComponent(0.08), stroke: i < 4 ? nil : C.cream.withAlphaComponent(0.18))
        text(String(format: "%02d", i + 1), rect: CGRect(x: cell.minX, y: cell.minY + 13, width: cell.width, height: 34), font: font("AvenirNext-DemiBold", 23), color: i < 4 ? C.ink : C.cream.withAlphaComponent(0.62), tracking: 1.2, alignment: .center)
    }
    text("Four moments taken. Eight still waiting.", rect: topRect(88, 2552, 1144, 52), font: font("Georgia-Italic", 31), color: C.cream.withAlphaComponent(0.76), alignment: .center)
}

// 02 — Shake-to-develop and saved partial progress.
try renderCanvas(index: 1, output: "02-shake-to-develop.png") { context in
    header(
        Header(
            kicker: "SHAKE TO DEVELOP",
            headline: "Shake now. Watch it appear.",
            subhead: "Each print develops the moment you shake it. Leave halfway and it remembers your progress."
        ),
        index: 1
    )

    try printCard(photo: faded[0], center: CGPoint(x: 660, y: 1460), width: 850, rotation: 1.5, caption: "coming into focus", progress: 0.4)

    context.saveGState()
    context.setStrokeColor(C.gold.withAlphaComponent(0.82).cgColor)
    context.setLineWidth(11)
    context.setLineCap(.round)
    let leftMarks = [
        (CGPoint(x: 108, y: 1320), CGPoint(x: 186, y: 1382)),
        (CGPoint(x: 92, y: 1480), CGPoint(x: 185, y: 1510)),
        (CGPoint(x: 116, y: 1635), CGPoint(x: 192, y: 1590)),
    ]
    let rightMarks = [
        (CGPoint(x: 1212, y: 1320), CGPoint(x: 1134, y: 1382)),
        (CGPoint(x: 1228, y: 1480), CGPoint(x: 1135, y: 1510)),
        (CGPoint(x: 1204, y: 1635), CGPoint(x: 1128, y: 1590)),
    ]
    for mark in leftMarks + rightMarks {
        context.move(to: mark.0)
        context.addLine(to: mark.1)
        context.strokePath()
    }
    context.restoreGState()

    pill("40% DEVELOPED  ·  PROGRESS SAVED", rect: topRect(315, 2120, 690, 82), fill: C.gold, color: C.ink)
    let ribbon = topRect(150, 2290, 1020, 150)
    shadowedCard(ribbon, radius: 24, fill: C.stock, stroke: C.gold.withAlphaComponent(0.32))
    text("SHAKE NOW", rect: CGRect(x: ribbon.minX + 35, y: ribbon.minY + 78, width: 270, height: 38), font: font("AvenirNext-DemiBold", 23), color: C.ink, tracking: 2, alignment: .center)
    text("40% SAVED", rect: CGRect(x: ribbon.minX + 375, y: ribbon.minY + 78, width: 270, height: 38), font: font("AvenirNext-DemiBold", 23), color: C.ink, tracking: 2, alignment: .center)
    text("RESUME ANYTIME", rect: CGRect(x: ribbon.minX + 695, y: ribbon.minY + 78, width: 290, height: 38), font: font("AvenirNext-DemiBold", 23), color: C.ink, tracking: 2, alignment: .center)
    text("instant", rect: CGRect(x: ribbon.minX + 35, y: ribbon.minY + 40, width: 270, height: 32), font: font("Georgia-Italic", 22), color: C.ink.withAlphaComponent(0.55), alignment: .center)
    text("automatic", rect: CGRect(x: ribbon.minX + 375, y: ribbon.minY + 40, width: 270, height: 32), font: font("Georgia-Italic", 22), color: C.ink.withAlphaComponent(0.55), alignment: .center)
    text("right where you left it", rect: CGRect(x: ribbon.minX + 695, y: ribbon.minY + 40, width: 290, height: 32), font: font("Georgia-Italic", 22), color: C.ink.withAlphaComponent(0.55), alignment: .center)
    text("Develops now. Remembers later.", rect: topRect(90, 2520, 1140, 70), font: font("Georgia-Italic", 38), color: C.cream.withAlphaComponent(0.82), alignment: .center)
}

// 03 — A tactile drawer, inspired by the app without recreating its screen.
try renderCanvas(index: 2, output: "03-the-drawer.png") { _ in
    header(
        Header(
            kicker: "YOUR DRAWER",
            headline: "Your day. Not a feed.",
            subhead: "A private, on-device Drawer for today’s prints and every daily roll before it."
        ),
        index: 2
    )

    let drawer = topRect(70, 650, 1180, 1760)
    shadowedCard(drawer, radius: 54, fill: NSColor(hex: 0x17232C, alpha: 0.88), stroke: C.gold.withAlphaComponent(0.3))
    rounded(CGRect(x: drawer.minX + 390, y: drawer.maxY - 78, width: 400, height: 48), radius: 10, fill: C.gold.withAlphaComponent(0.18), stroke: C.gold.withAlphaComponent(0.38), line: 2)
    text("TODAY  ·  4 PRINTS", rect: CGRect(x: drawer.minX + 400, y: drawer.maxY - 68, width: 380, height: 28), font: font("AvenirNext-DemiBold", 20), color: C.gold, tracking: 2.2, alignment: .center)

    try printCard(photo: faded[4], center: CGPoint(x: 410, y: 1520), width: 520, rotation: -12)
    try printCard(photo: faded[2], center: CGPoint(x: 810, y: 1580), width: 540, rotation: 11)
    try printCard(photo: faded[5], center: CGPoint(x: 470, y: 1180), width: 550, rotation: -3)
    try printCard(photo: faded[1], center: CGPoint(x: 810, y: 1160), width: 570, rotation: 5)

    let dates = ["YESTERDAY", "JUL 18", "JUL 17"]
    for (i, date) in dates.enumerated() {
        let tab = topRect(110 + CGFloat(i) * 382, 2425, 342, 140)
        rounded(tab, radius: 20, fill: i == 0 ? C.gold : C.stock.withAlphaComponent(0.92), stroke: C.ink.withAlphaComponent(0.16), line: 2)
        text(date, rect: CGRect(x: tab.minX + 20, y: tab.minY + 76, width: tab.width - 40, height: 34), font: font("AvenirNext-DemiBold", 22), color: C.ink, tracking: 1.4, alignment: .center)
        text("daily roll", rect: CGRect(x: tab.minX + 20, y: tab.minY + 40, width: tab.width - 40, height: 30), font: font("Georgia-Italic", 22), color: C.ink.withAlphaComponent(0.62), alignment: .center)
    }
    text("PRIVATE  ·  ON-DEVICE  ·  NO FEED  ·  NO ACCOUNT", rect: topRect(90, 2640, 1140, 54), font: font("AvenirNext-DemiBold", 23), color: C.gold, tracking: 2.4, alignment: .center)
}

// 04 — Real outputs from both integrated filters plus export formats.
try renderCanvas(index: 3, output: "04-memory-filters.png") { _ in
    header(
        Header(
            kicker: "ORIGINAL + TWO MEMORY LOOKS",
            headline: "See the moment three ways.",
            subhead: "Compare the original with a softer Faded Instant finish and a warmer archival glow."
        ),
        index: 3
    )

    try printCard(photo: originals[0], center: CGPoint(x: 230, y: 1610), width: 360, rotation: -5, caption: "Original")
    try printCard(photo: faded[0], center: CGPoint(x: 660, y: 1610), width: 360, rotation: 0, caption: "Faded Instant", tone: .faded)
    try printCard(photo: warm[0], center: CGPoint(x: 1090, y: 1610), width: 360, rotation: 5, caption: "Warm Archive", tone: .warm)

    let left = topRect(86, 2130, 548, 310)
    let right = topRect(686, 2130, 548, 310)
    shadowedCard(left, radius: 30, fill: C.charcoal.withAlphaComponent(0.84), stroke: C.cream.withAlphaComponent(0.13))
    shadowedCard(right, radius: 30, fill: C.stock, stroke: C.gold.withAlphaComponent(0.4))
    try image(faded[0], in: CGRect(x: left.minX + 28, y: left.minY + 32, width: 176, height: 246), radius: 15)
    text("PHOTO", rect: CGRect(x: left.minX + 230, y: left.minY + 162, width: 280, height: 42), font: font("AvenirNext-DemiBold", 25), color: C.gold, tracking: 2.2)
    text("Original ratio", rect: CGRect(x: left.minX + 230, y: left.minY + 112, width: 280, height: 42), font: font("Georgia-Bold", 30), color: C.cream)
    text("Filtered JPEG", rect: CGRect(x: left.minX + 230, y: left.minY + 73, width: 280, height: 34), font: font("AvenirNext-Medium", 22), color: C.cream.withAlphaComponent(0.58))

    let mini = CGRect(x: right.minX + 30, y: right.minY + 34, width: 182, height: 236)
    rounded(mini, radius: 8, fill: C.stock, stroke: C.ink.withAlphaComponent(0.18), line: 2)
    try image(warm[0], in: CGRect(x: mini.minX + 15, y: mini.minY + 54, width: mini.width - 30, height: mini.width - 30), radius: 4)
    text("POSTCARD", rect: CGRect(x: right.minX + 238, y: right.minY + 162, width: 280, height: 42), font: font("AvenirNext-DemiBold", 25), color: C.ink.withAlphaComponent(0.72), tracking: 2.2)
    text("Tumble frame", rect: CGRect(x: right.minX + 238, y: right.minY + 112, width: 280, height: 42), font: font("Georgia-Bold", 30), color: C.ink)
    text("Ready to share", rect: CGRect(x: right.minX + 238, y: right.minY + 73, width: 280, height: 34), font: font("AvenirNext-Medium", 22), color: C.ink.withAlphaComponent(0.58))
    text("Save the photo at its original ratio — or place the filtered image inside a Tumble postcard.", rect: topRect(100, 2530, 1120, 88), font: font("AvenirNext-Medium", 27), color: C.cream.withAlphaComponent(0.7), spacing: 5, alignment: .center)
}

// 05 — Archive represented as physical dated index cards.
try renderCanvas(index: 4, output: "05-full-archive.png") { _ in
    header(
        Header(
            kicker: "FULL ARCHIVE",
            headline: "Every roll. All in one place.",
            subhead: "Recent days stay close. Every older collection remains easy to reach."
        ),
        index: 4
    )

    let dates = ["YESTERDAY", "JUL 18, 2026", "JUL 17, 2026", "JUL 16, 2026", "JUL 15, 2026", "JUL 14, 2026"]
    for i in 0..<dates.count {
        let y = 650 + CGFloat(i) * 330
        let card = topRect(95, y, 1130, 285)
        let context = NSGraphicsContext.current!.cgContext
        context.saveGState()
        context.translateBy(x: card.midX, y: card.midY)
        context.rotate(by: CGFloat(i.isMultiple(of: 2) ? -0.7 : 0.7) * .pi / 180)
        let local = CGRect(x: -card.width / 2, y: -card.height / 2, width: card.width, height: card.height)
        shadowedCard(local, radius: 28, fill: i == 0 ? C.stock : C.charcoal.withAlphaComponent(0.9), stroke: i == 0 ? C.gold.withAlphaComponent(0.5) : C.cream.withAlphaComponent(0.11))
        for j in 0..<3 {
            let thumb = CGRect(x: local.minX + 32 + CGFloat(j) * 174, y: local.minY + 34, width: 150, height: 217)
            try image(archivePhotos[i * 3 + j], in: thumb, radius: 10)
        }
        let ink = i == 0 ? C.ink : C.cream
        text(dates[i], rect: CGRect(x: local.minX + 585, y: local.minY + 150, width: 480, height: 52), font: font("Georgia-Bold", 34), color: ink)
        text("3 developed prints", rect: CGRect(x: local.minX + 585, y: local.minY + 103, width: 480, height: 40), font: font("AvenirNext-Medium", 23), color: ink.withAlphaComponent(0.58))
        text("DAILY ROLL", rect: CGRect(x: local.minX + 585, y: local.minY + 55, width: 480, height: 34), font: font("AvenirNext-DemiBold", 20), color: C.gold, tracking: 2.6)
        context.restoreGState()
    }
}

// 06 — The complete free ritual first; paid tiers are optional roll sizes.
try renderCanvas(index: 5, output: "06-own-it-once.png") { _ in
    header(
        Header(
            kicker: "CHOOSE YOUR ROLL",
            headline: "The full ritual starts free.",
            subhead: "Every tier includes shake-to-develop, both memory looks, the Drawer and full Archive."
        ),
        index: 5
    )

    pill("PRIVATE  ·  ON-DEVICE  ·  NO ACCOUNT  ·  NO CLOUD", rect: topRect(220, 590, 880, 82), fill: C.gold, color: C.ink)

    let free = topRect(78, 735, 1164, 490)
    shadowedCard(free, radius: 42, fill: C.stock, stroke: C.gold.withAlphaComponent(0.68))
    text("FREE", rect: CGRect(x: free.minX + 48, y: free.maxY - 76, width: 240, height: 38), font: font("AvenirNext-DemiBold", 22), color: C.ink.withAlphaComponent(0.6), tracking: 3.1)
    text("12", rect: CGRect(x: free.minX + 45, y: free.minY + 185, width: 270, height: 150), font: font("Georgia-Bold", 118), color: C.ink, tracking: -4)
    text("shots every day", rect: CGRect(x: free.minX + 55, y: free.minY + 145, width: 310, height: 44), font: font("Georgia-Bold", 31), color: C.ink)
    rounded(CGRect(x: free.minX + 390, y: free.minY + 70, width: 3, height: 315), radius: 1, fill: C.ink.withAlphaComponent(0.12))
    text("Complete camera", rect: CGRect(x: free.minX + 445, y: free.minY + 300, width: 650, height: 55), font: font("Georgia-Bold", 39), color: C.ink)
    text("Shake-to-develop  ·  Both memory filters", rect: CGRect(x: free.minX + 445, y: free.minY + 240, width: 650, height: 40), font: font("AvenirNext-Medium", 25), color: C.ink.withAlphaComponent(0.7))
    text("Full Drawer + Archive  ·  Photo + postcard export", rect: CGRect(x: free.minX + 445, y: free.minY + 190, width: 650, height: 40), font: font("AvenirNext-Medium", 25), color: C.ink.withAlphaComponent(0.7))
    pill("FREE FOREVER", rect: CGRect(x: free.minX + 445, y: free.minY + 88, width: 300, height: 62), fill: C.gold, color: C.ink)

    let plus = topRect(78, 1320, 1164, 490)
    shadowedCard(plus, radius: 42, fill: NSColor(hex: 0xE9D8B8), stroke: C.gold.withAlphaComponent(0.62))
    text("PLUS", rect: CGRect(x: plus.minX + 48, y: plus.maxY - 76, width: 240, height: 38), font: font("AvenirNext-DemiBold", 22), color: C.ink.withAlphaComponent(0.6), tracking: 3.1)
    text("72", rect: CGRect(x: plus.minX + 45, y: plus.minY + 185, width: 270, height: 150), font: font("Georgia-Bold", 118), color: C.ink, tracking: -4)
    text("shots every day", rect: CGRect(x: plus.minX + 55, y: plus.minY + 145, width: 310, height: 44), font: font("Georgia-Bold", 31), color: C.ink)
    rounded(CGRect(x: plus.minX + 390, y: plus.minY + 70, width: 3, height: 315), radius: 1, fill: C.ink.withAlphaComponent(0.12))
    text("$5.99 once", rect: CGRect(x: plus.minX + 445, y: plus.minY + 300, width: 650, height: 62), font: font("Georgia-Bold", 46), color: C.ink)
    text("Six rolls every morning  ·  Same developing ritual", rect: CGRect(x: plus.minX + 445, y: plus.minY + 235, width: 650, height: 40), font: font("AvenirNext-Medium", 25), color: C.ink.withAlphaComponent(0.7))
    text("Everything in Free  ·  One purchase, yours to keep", rect: CGRect(x: plus.minX + 445, y: plus.minY + 185, width: 650, height: 40), font: font("AvenirNext-Medium", 25), color: C.ink.withAlphaComponent(0.7))
    pill("MORE ROOM, SAME RITUAL", rect: CGRect(x: plus.minX + 445, y: plus.minY + 88, width: 470, height: 62), fill: C.ink, color: C.stock)

    let unlimited = topRect(78, 1905, 1164, 490)
    shadowedCard(unlimited, radius: 42, fill: C.charcoal.withAlphaComponent(0.94), stroke: C.cream.withAlphaComponent(0.2))
    text("UNLIMITED", rect: CGRect(x: unlimited.minX + 48, y: unlimited.maxY - 76, width: 300, height: 38), font: font("AvenirNext-DemiBold", 22), color: C.cream.withAlphaComponent(0.58), tracking: 3.1)
    text("∞", rect: CGRect(x: unlimited.minX + 45, y: unlimited.minY + 160, width: 280, height: 180), font: font("Georgia-Bold", 140), color: C.gold)
    text("no daily cap", rect: CGRect(x: unlimited.minX + 55, y: unlimited.minY + 145, width: 310, height: 44), font: font("Georgia-Bold", 31), color: C.cream)
    rounded(CGRect(x: unlimited.minX + 390, y: unlimited.minY + 70, width: 3, height: 315), radius: 1, fill: C.cream.withAlphaComponent(0.13))
    text("$11.99 once", rect: CGRect(x: unlimited.minX + 445, y: unlimited.minY + 300, width: 650, height: 62), font: font("Georgia-Bold", 46), color: C.cream)
    text("Shoot as much as you like  ·  Same developing ritual", rect: CGRect(x: unlimited.minX + 445, y: unlimited.minY + 235, width: 650, height: 40), font: font("AvenirNext-Medium", 25), color: C.cream.withAlphaComponent(0.7))
    text("Everything in Free  ·  One purchase, yours to keep", rect: CGRect(x: unlimited.minX + 445, y: unlimited.minY + 185, width: 650, height: 40), font: font("AvenirNext-Medium", 25), color: C.cream.withAlphaComponent(0.7))
    pill("NO LIMIT, STILL TUMBLE", rect: CGRect(x: unlimited.minX + 445, y: unlimited.minY + 88, width: 430, height: 62), fill: C.gold, color: C.ink)

    pill("ONE PURCHASE  ·  NO SUBSCRIPTION  ·  RESTORE ANYTIME", rect: topRect(190, 2505, 940, 82), fill: NSColor.black.withAlphaComponent(0.2), color: C.cream, border: C.cream.withAlphaComponent(0.16))
    text("Pick the roll size that fits your day.", rect: topRect(90, 2650, 1140, 62), font: font("Georgia-Italic", 35), color: C.cream.withAlphaComponent(0.76), alignment: .center)
}
