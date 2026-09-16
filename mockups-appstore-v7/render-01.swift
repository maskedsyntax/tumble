#!/usr/bin/env swift

import AppKit
import Foundation

// The app surface below is an untouched Simulator capture. This renderer only
// removes the iOS status bar and places the capture on the marketing canvas.

private let W: CGFloat = 1320
private let H: CGFloat = 2868
private let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
private let sourceDirectory = root.appendingPathComponent("mockups-appstore-v7/source")
private let outputDirectory = root.appendingPathComponent("mockups-appstore-v7")

private struct Page {
    let source: String
    let output: String
    let firstLine: String
    let emphasis: String
}

private let pages = [
    Page(source: "01-camera-party.png", output: "01-shoot-real-film.png",
         firstLine: "Shoot with", emphasis: "real film."),
    Page(source: "02-film-looks.png", output: "02-twenty-one-looks.png",
         firstLine: "Twenty-one", emphasis: "film looks."),
    Page(source: "03-crop.png", output: "03-fine-tune.png",
         firstLine: "Fine-tune", emphasis: "every frame."),
    Page(source: "04-postcard.png", output: "04-postcard.png",
         firstLine: "Make it a", emphasis: "postcard."),
    Page(source: "05-original.png", output: "05-before-after.png",
         firstLine: "See the", emphasis: "difference."),
    Page(source: "06-photo-picker.png", output: "06-import-any-photo.png",
         firstLine: "Camera roll,", emphasis: "meet film."),
]

private enum C {
    static let paperTop = NSColor(hex: 0xF2EBDD)
    static let paper = NSColor(hex: 0xE9E0D2)
    static let paperBottom = NSColor(hex: 0xD9CCBA)
    static let ink = NSColor(hex: 0x302B27)
    static let blue = NSColor(hex: 0x2E4052)
}

private extension NSColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        self.init(srgbRed: CGFloat((hex >> 16) & 0xff) / 255,
                  green: CGFloat((hex >> 8) & 0xff) / 255,
                  blue: CGFloat(hex & 0xff) / 255,
                  alpha: alpha)
    }
}

private func r(_ x: CGFloat, _ top: CGFloat, _ width: CGFloat, _ height: CGFloat) -> CGRect {
    CGRect(x: x, y: H - top - height, width: width, height: height)
}

private func font(_ name: String, _ size: CGFloat, _ weight: NSFont.Weight = .regular) -> NSFont {
    NSFont(name: name, size: size) ?? NSFont.systemFont(ofSize: size, weight: weight)
}

private func text(_ value: String, _ frame: CGRect, font: NSFont, color: NSColor, tracking: CGFloat) {
    NSAttributedString(string: value, attributes: [
        .font: font,
        .foregroundColor: color,
        .kern: tracking,
    ]).draw(in: frame)
}

private func rounded(_ frame: CGRect, _ radius: CGFloat) -> NSBezierPath {
    NSBezierPath(roundedRect: frame, xRadius: radius, yRadius: radius)
}

private func drawPaper() {
    NSGradient(colors: [C.paperTop, C.paper, C.paperBottom],
               atLocations: [0, 0.68, 1], colorSpace: .sRGB)?
        .draw(in: CGRect(x: 0, y: 0, width: W, height: H), angle: -76)
    var seed: UInt64 = 0x544D424C4507
    func random() -> CGFloat {
        seed = seed &* 6364136223846793005 &+ 1442695040888963407
        return CGFloat((seed >> 33) & 0x7fff) / CGFloat(0x7fff)
    }
    for _ in 0..<3200 {
        (random() > 0.5 ? NSColor.black : NSColor.white)
            .withAlphaComponent(0.012 + random() * 0.016).setFill()
        NSBezierPath(rect: CGRect(x: random() * W, y: random() * H, width: 1.3, height: 1.3)).fill()
    }
}

private func render(_ page: Page) {
    guard let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil,
                                        pixelsWide: Int(W), pixelsHigh: Int(H),
                                        bitsPerSample: 8, samplesPerPixel: 4,
                                        hasAlpha: true, isPlanar: false,
                                        colorSpaceName: .deviceRGB,
                                        bytesPerRow: 0, bitsPerPixel: 0),
          let context = NSGraphicsContext(bitmapImageRep: bitmap),
          let screenshot = NSImage(contentsOf: sourceDirectory.appendingPathComponent(page.source)) else {
        fatalError("Could not create renderer")
    }
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    context.imageInterpolation = .high

    drawPaper()
    text(page.firstLine, r(72, 64, 1176, 126),
         font: font("Georgia-Bold", 96, .bold), color: C.ink, tracking: -3.2)
    text(page.emphasis, r(72, 166, 1176, 132),
         font: font("Georgia-BoldItalic", 100, .bold), color: C.ink, tracking: -3.5)

    let cardWidth: CGFloat = 1168
    let scale = cardWidth / 1206
    let statusBarCrop: CGFloat = 120
    let card = r(76, 430, cardWidth, (2622 - statusBarCrop) * scale)

    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowBlurRadius = 42
    shadow.shadowOffset = NSSize(width: 0, height: -18)
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.26)
    shadow.set()
    C.blue.setFill()
    rounded(card, 54).fill()
    NSGraphicsContext.restoreGraphicsState()

    NSGraphicsContext.saveGraphicsState()
    rounded(card, 54).setClip()
    screenshot.draw(in: card,
                    from: CGRect(x: 0, y: 0, width: 1206, height: 2622 - statusBarCrop),
                    operation: .sourceOver,
                    fraction: 1)
    NSGraphicsContext.restoreGraphicsState()

    C.ink.withAlphaComponent(0.16).setStroke()
    let edge = rounded(card, 54)
    edge.lineWidth = 2
    edge.stroke()

    NSGraphicsContext.restoreGraphicsState()
    guard let data = bitmap.representation(using: .png, properties: [:]) else {
        fatalError("Could not encode PNG")
    }
    let output = outputDirectory.appendingPathComponent(page.output)
    try! data.write(to: output)
    print("wrote \(Int(W))x\(Int(H)) \(output.path)")
}

pages.forEach(render)
