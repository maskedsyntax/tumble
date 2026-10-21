// Tumble 3.1 App Store screenshots.
//
// Compiled together with scripts/film-grade.swift and
// app/TumbleKit/Filter/FilmStock.swift (see render.sh), so every graded
// photograph outside the phone is the look the app actually produces. Phone
// screens are unedited Simulator captures from scripts/capture-app-store-3.1.sh.

import AppKit
import CoreImage
import Foundation
import UniformTypeIdentifiers

// Simulator captures are 6.9-inch (iPhone 17 Pro Max) screens.
let shotW: CGFloat = 1320
let shotH: CGFloat = 2868

// Layout space of the target being rendered. Pages are laid out at a 1320 (or
// 2622 for the header) wide design size and scaled up to the output pixels.
var W: CGFloat = 1320
var H: CGFloat = 2868
var outScale: CGFloat = 1
let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
var outDir = root.appendingPathComponent("screenshots/3.1/final")
let rawDir = root.appendingPathComponent("screenshots/3.1/raw")
let photoDir = root.appendingPathComponent("mockups-appstore-v7/photo-library")
let srgb = CGColorSpace(name: CGColorSpace.sRGB)!

// MARK: - Palette (app/TumbleKit/Theme/Palette.swift)

func rgb(_ hex: UInt32, _ a: CGFloat = 1) -> CGColor {
    CGColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255, alpha: a)
}
let cream = rgb(0xF6EFE2)
let amber = rgb(0xDFAB68)
let amberInk = rgb(0x9A6424)
let ink = rgb(0x1E2A34)
let canvas = rgb(0x0D0E10)
let surface = rgb(0x16181B)
let surfaceRaised = rgb(0x1F2226)

// MARK: - Loading and grading

func cgImage(_ url: URL) -> CGImage {
    guard let src = CGImageSourceCreateWithURL(url as CFURL, nil),
          let img = CGImageSourceCreateImageAtIndex(src, 0, nil) else { fatalError("missing \(url.path)") }
    return img
}
func raw(_ name: String) -> CGImage { cgImage(rawDir.appendingPathComponent(name + ".png")) }

var gradeCache: [String: CGImage] = [:]
func graded(_ photo: String, _ stock: String) -> CGImage {
    let key = photo + "/" + stock
    if let hit = gradeCache[key] { return hit }
    let input = CIImage(contentsOf: photoDir.appendingPathComponent(photo + ".png"))!
    let out = applyGrade(FilmStockCatalog.resolve(stock).grade, to: input)
    let img = ciContext.createCGImage(out, from: out.extent, format: .RGBA8, colorSpace: srgb)!
    gradeCache[key] = img
    return img
}
func stockName(_ id: String) -> String { FilmStockCatalog.resolve(id).name }

// MARK: - Drawing context (top-left origin)

final class Canvas {
    let ctx: CGContext
    init() {
        let pixelH = (H * outScale).rounded()
        ctx = CGContext(data: nil, width: Int((W * outScale).rounded()), height: Int(pixelH), bitsPerComponent: 8,
                        bytesPerRow: 0, space: srgb, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
        ctx.translateBy(x: 0, y: pixelH)
        ctx.scaleBy(x: outScale, y: -outScale)
        ctx.interpolationQuality = .high
        NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: true)
    }

    func image(_ img: CGImage, in r: CGRect) {
        ctx.saveGState()
        ctx.translateBy(x: r.minX, y: r.maxY)
        ctx.scaleBy(x: 1, y: -1)
        ctx.draw(img, in: CGRect(origin: .zero, size: r.size))
        ctx.restoreGState()
    }

    /// Aspect-fill `img` into `r`, cropping the overflow, with an optional
    /// horizontal focus (0 = left, 0.5 = centre, 1 = right).
    func fill(_ img: CGImage, in r: CGRect, focusX: CGFloat = 0.5) {
        let iw = CGFloat(img.width), ih = CGFloat(img.height)
        let s = max(r.width / iw, r.height / ih)
        let dw = iw * s, dh = ih * s
        let dx = r.minX - (dw - r.width) * focusX
        let dy = r.minY - (dh - r.height) / 2
        ctx.saveGState()
        ctx.clip(to: r)
        image(img, in: CGRect(x: dx, y: dy, width: dw, height: dh))
        ctx.restoreGState()
    }

    func rounded(_ r: CGRect, _ radius: CGFloat) -> CGPath {
        CGPath(roundedRect: r, cornerWidth: radius, cornerHeight: radius, transform: nil)
    }

    /// Shadows are specified in bitmap space, which is y-up.
    func shadow(blur: CGFloat, y: CGFloat, alpha: CGFloat) {
        ctx.setShadow(offset: CGSize(width: 0, height: -y * outScale), blur: blur * outScale,
                      color: CGColor(gray: 0, alpha: alpha))
    }

    func rotated(about c: CGPoint, degrees: CGFloat, _ body: () -> Void) {
        ctx.saveGState()
        ctx.translateBy(x: c.x, y: c.y)
        ctx.rotate(by: degrees * .pi / 180)
        ctx.translateBy(x: -c.x, y: -c.y)
        body()
        ctx.restoreGState()
    }

    func output() -> CGImage { ctx.makeImage()! }
}

// MARK: - Type

func serif(_ size: CGFloat, italic: Bool = false, weight: NSFont.Weight = .semibold) -> NSFont {
    var d = NSFont.systemFont(ofSize: size, weight: weight).fontDescriptor.withDesign(.serif)!
    if italic { d = d.withSymbolicTraits(.italic) }
    return NSFont(descriptor: d, size: size)!
}
func sans(_ size: CGFloat, _ weight: NSFont.Weight = .semibold) -> NSFont { .systemFont(ofSize: size, weight: weight) }
func mono(_ size: CGFloat, _ weight: NSFont.Weight = .medium) -> NSFont { .monospacedSystemFont(ofSize: size, weight: weight) }

@discardableResult
func text(_ s: String, _ font: NSFont, _ color: CGColor, x: CGFloat = 0, y: CGFloat, width: CGFloat = W,
          align: NSTextAlignment = .center, kern: CGFloat = 0) -> CGFloat {
    let p = NSMutableParagraphStyle()
    p.alignment = align
    let a = NSAttributedString(string: s, attributes: [
        .font: font, .foregroundColor: NSColor(cgColor: color)!, .kern: kern, .paragraphStyle: p,
    ])
    let h = ceil(a.boundingRect(with: CGSize(width: width, height: 1000), options: [.usesLineFragmentOrigin]).height)
    a.draw(in: CGRect(x: x, y: y, width: width, height: h + 4))
    return h
}
func textWidth(_ s: String, _ font: NSFont, kern: CGFloat = 0) -> CGFloat {
    NSAttributedString(string: s, attributes: [.font: font, .kern: kern]).size().width
}

// MARK: - Shared pieces

enum Backdrop { case graphite, paper, navy }

let grainTile: CGImage = {
    let noise = CIFilter(name: "CIRandomGenerator")!.outputImage!
        .cropped(to: CGRect(x: 0, y: 0, width: W, height: H))
        .applyingFilter("CIColorControls", parameters: [kCIInputSaturationKey: 0])
    return ciContext.createCGImage(noise, from: noise.extent, format: .RGBA8, colorSpace: srgb)!
}()

func backdrop(_ c: Canvas, _ kind: Backdrop, glow: CGPoint) {
    let ctx = c.ctx
    let (top, bottom, glowColor, grainAlpha): (CGColor, CGColor, CGColor, CGFloat) = switch kind {
    case .graphite: (rgb(0x17191C), canvas, rgb(0xDFAB68, 0.20), 0.07)
    case .paper: (rgb(0xF4ECDD), rgb(0xE6D8C0), rgb(0xFFFFFF, 0.55), 0.10)
    case .navy: (rgb(0x223241), rgb(0x121B24), rgb(0xDFAB68, 0.16), 0.07)
    }
    let g = CGGradient(colorsSpace: srgb, colors: [top, bottom] as CFArray, locations: [0, 1])!
    ctx.drawLinearGradient(g, start: .zero, end: CGPoint(x: 0, y: H), options: [])
    let rg = CGGradient(colorsSpace: srgb, colors: [glowColor, glowColor.copy(alpha: 0)!] as CFArray, locations: [0, 1])!
    ctx.drawRadialGradient(rg, startCenter: glow, startRadius: 0, endCenter: glow, endRadius: 1100, options: [])
    ctx.saveGState()
    ctx.setAlpha(grainAlpha)
    ctx.setBlendMode(.overlay)
    c.image(grainTile, in: CGRect(x: 0, y: 0, width: W, height: H))
    ctx.restoreGState()
}

/// Small tracked kicker plus a two-line serif headline; the second line is italic.
func headline(_ kicker: String, _ line1: String, _ line2: String, dark: Bool = true) {
    let fg = dark ? cream : ink
    text(kicker, sans(32, .bold), dark ? amber : amberInk, y: 150, kern: 6)
    text(line1, serif(116), fg, y: 214, kern: -2.5)
    text(line2, serif(116, italic: true, weight: .medium), fg, y: 352, kern: -2.5)
}

/// An iPhone 17 Pro Max-proportioned body around an unedited screen capture.
/// Returns the screen rect so callouts can align with real UI.
@discardableResult
func phone(_ c: Canvas, _ shot: CGImage, x: CGFloat, y: CGFloat, width w: CGFloat) -> CGRect {
    let ctx = c.ctx
    let bezel = w * 0.026
    let screenW = w - bezel * 2
    let screenH = screenW * shotH / shotW
    let body = CGRect(x: x, y: y, width: w, height: screenH + bezel * 2)
    let screen = body.insetBy(dx: bezel, dy: bezel)
    let screenRadius = screenW * 0.128
    let bodyRadius = screenRadius + bezel

    // Side buttons.
    ctx.setFillColor(rgb(0x2A2C30))
    for (yy, hh) in [(0.17, 0.045), (0.245, 0.075), (0.335, 0.075)] {
        ctx.addPath(c.rounded(CGRect(x: x - 5, y: y + body.height * yy, width: 10, height: body.height * hh), 4))
    }
    ctx.addPath(c.rounded(CGRect(x: body.maxX - 5, y: y + body.height * 0.26, width: 10, height: body.height * 0.11), 4))
    ctx.fillPath()

    ctx.saveGState()
    c.shadow(blur: 90, y: 50, alpha: 0.55)
    ctx.setFillColor(rgb(0x0A0A0B))
    ctx.addPath(c.rounded(body, bodyRadius))
    ctx.fillPath()
    ctx.restoreGState()

    // Titanium rim.
    ctx.setLineWidth(5)
    ctx.setStrokeColor(rgb(0x4A4C51))
    ctx.addPath(c.rounded(body.insetBy(dx: 2.5, dy: 2.5), bodyRadius - 2.5))
    ctx.strokePath()
    ctx.setLineWidth(2)
    ctx.setStrokeColor(rgb(0x000000))
    ctx.addPath(c.rounded(body.insetBy(dx: 6, dy: 6), bodyRadius - 6))
    ctx.strokePath()

    ctx.saveGState()
    ctx.addPath(c.rounded(screen, screenRadius))
    ctx.clip()
    c.image(shot, in: screen)
    ctx.restoreGState()

    let islandW = screenW * 0.285, islandH = screenW * 0.084
    ctx.setFillColor(rgb(0x000000))
    ctx.addPath(c.rounded(CGRect(x: screen.midX - islandW / 2, y: screen.minY + screenW * 0.026,
                                 width: islandW, height: islandH), islandH / 2))
    ctx.fillPath()
    return screen
}

/// A cream-bordered print of a graded photograph, captioned with its film.
func filmPrint(_ c: Canvas, _ img: CGImage, center: CGPoint, width w: CGFloat, degrees: CGFloat, caption: String) {
    let border = w * 0.05
    let photoW = w - border * 2
    let photoH = photoW * 1.18
    let h = border + photoH + w * 0.16
    let r = CGRect(x: center.x - w / 2, y: center.y - h / 2, width: w, height: h)
    c.rotated(about: center, degrees: degrees) {
        c.ctx.saveGState()
        c.shadow(blur: 50, y: 26, alpha: 0.5)
        c.ctx.setFillColor(rgb(0xF3ECDF))
        c.ctx.fill(r)
        c.ctx.restoreGState()
        c.fill(img, in: CGRect(x: r.minX + border, y: r.minY + border, width: photoW, height: photoH))
        text(caption.uppercased(), mono(w * 0.05, .semibold), rgb(0x5B5348), x: r.minX, y: r.minY + border + photoH + w * 0.045,
             width: w, kern: 3)
    }
}

/// Lifts the postcard out of a Finish capture: canvas-coloured pixels reachable
/// from the edge of the preview area become transparent, so deckled and
/// bordered edges keep their real shape.
func liftPostcard(_ shot: CGImage) -> CGImage {
    let region = CGRect(x: 0, y: 300, width: 1320, height: 1560)
    let cropped = shot.cropping(to: region)!
    let w = cropped.width, h = cropped.height
    let bctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4, space: srgb,
                         bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    bctx.draw(cropped, in: CGRect(x: 0, y: 0, width: w, height: h))
    // Bitmap memory starts at the top row, matching CGImage cropping rows.
    let px = bctx.data!.bindMemory(to: UInt8.self, capacity: w * h * 4)
    func isBackground(_ i: Int) -> Bool {
        let r = Int(px[i * 4]), g = Int(px[i * 4 + 1]), b = Int(px[i * 4 + 2])
        return max(r, g, b) < 70
    }
    var seen = [Bool](repeating: false, count: w * h)
    var stack: [Int] = []
    for x in 0..<w { stack.append(x); stack.append((h - 1) * w + x) }
    for y in 0..<h { stack.append(y * w); stack.append(y * w + w - 1) }
    while let i = stack.popLast() {
        if seen[i] || !isBackground(i) { continue }
        seen[i] = true
        let x = i % w, y = i / w
        if x > 0 { stack.append(i - 1) }
        if x < w - 1 { stack.append(i + 1) }
        if y > 0 { stack.append(i - w) }
        if y < h - 1 { stack.append(i + w) }
    }
    var minX = w, minY = h, maxX = 0, maxY = 0
    for i in 0..<(w * h) {
        if seen[i] {
            px[i * 4] = 0; px[i * 4 + 1] = 0; px[i * 4 + 2] = 0; px[i * 4 + 3] = 0
        } else {
            let x = i % w, y = i / w
            minX = min(minX, x); maxX = max(maxX, x); minY = min(minY, y); maxY = max(maxY, y)
        }
    }
    let lifted = bctx.makeImage()!
    return lifted.cropping(to: CGRect(x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1))!
}

func card(_ c: Canvas, _ img: CGImage, center: CGPoint, width w: CGFloat, degrees: CGFloat) {
    let h = w * CGFloat(img.height) / CGFloat(img.width)
    let r = CGRect(x: center.x - w / 2, y: center.y - h / 2, width: w, height: h)
    c.rotated(about: center, degrees: degrees) {
        c.ctx.saveGState()
        c.shadow(blur: 46, y: 24, alpha: 0.32)
        c.image(img, in: r)
        c.ctx.restoreGState()
    }
}

/// A magnified slice of the real screen, floated over the phone.
func callout(_ c: Canvas, _ shot: CGImage, sourceY: CGFloat, sourceH: CGFloat, y: CGFloat, width w: CGFloat) {
    let slice = shot.cropping(to: CGRect(x: 0, y: sourceY, width: shotW, height: sourceH))!
    let h = w * sourceH / shotW
    let r = CGRect(x: (W - w) / 2, y: y, width: w, height: h)
    c.ctx.saveGState()
    c.shadow(blur: 70, y: 34, alpha: 0.6)
    c.ctx.setFillColor(surface)
    c.ctx.addPath(c.rounded(r, 44))
    c.ctx.fillPath()
    c.ctx.restoreGState()
    c.ctx.saveGState()
    c.ctx.addPath(c.rounded(r, 44))
    c.ctx.clip()
    c.image(slice, in: r)
    c.ctx.restoreGState()
    c.ctx.setStrokeColor(rgb(0xF6EFE2, 0.14))
    c.ctx.setLineWidth(2)
    c.ctx.addPath(c.rounded(r.insetBy(dx: 1, dy: 1), 43))
    c.ctx.strokePath()
}

func symbolImage(_ name: String?, _ font: NSFont, _ color: CGColor) -> NSImage? {
    guard let name else { return nil }
    return NSImage(systemSymbolName: name, accessibilityDescription: nil)?
        .withSymbolConfiguration(.init(pointSize: font.pointSize, weight: .semibold)
            .applying(.init(paletteColors: [NSColor(cgColor: color)!])))
}
func pillWidth(_ label: String, symbol: String?, font: NSFont) -> CGFloat {
    let icon = symbolImage(symbol, font, cream).map { $0.size.width + 14 } ?? 0
    return textWidth(label, font) + icon + 64
}

@discardableResult
func pill(_ c: Canvas, _ label: String, symbol: String?, center: CGPoint, font: NSFont, fg: CGColor, bg: CGColor,
          stroke: CGColor? = nil, height: CGFloat = 76) -> CGFloat {
    let w = pillWidth(label, symbol: symbol, font: font)
    let r = CGRect(x: center.x - w / 2, y: center.y - height / 2, width: w, height: height)
    c.ctx.setFillColor(bg)
    c.ctx.addPath(c.rounded(r, height / 2))
    c.ctx.fillPath()
    if let stroke {
        c.ctx.setStrokeColor(stroke)
        c.ctx.setLineWidth(2)
        c.ctx.addPath(c.rounded(r.insetBy(dx: 1, dy: 1), height / 2 - 1))
        c.ctx.strokePath()
    }
    var tx = r.minX + 32
    if let sym = symbolImage(symbol, font, fg) {
        let s = sym.size
        sym.draw(in: CGRect(x: tx, y: center.y - s.height / 2, width: s.width, height: s.height), from: .zero,
                 operation: .sourceOver, fraction: 1, respectFlipped: true, hints: nil)
        tx += s.width + 14
    }
    text(label, font, fg, x: tx, y: center.y - font.pointSize * 0.62, width: w, align: .left)
    return w
}

// MARK: - Pages

func heroPage(_ c: Canvas) {
    backdrop(c, .graphite, glow: CGPoint(x: W / 2, y: 1250))
    headline("VINTAGE PHOTO EDITOR", "Your photos,", "on film.")
    filmPrint(c, graded("03-flower-market", "silver"), center: CGPoint(x: 150, y: 1060), width: 420, degrees: -9,
              caption: stockName("silver"))
    filmPrint(c, graded("10-motel-pool", "hazyFlare"), center: CGPoint(x: 150, y: 2200), width: 400, degrees: 6,
              caption: stockName("hazyFlare"))
    phone(c, raw("studio-hero"), x: 215, y: 600, width: 890)
    // In front of the phone, over the photograph's edge, never over controls.
    filmPrint(c, graded("15-concert", "crossProcess"), center: CGPoint(x: 1140, y: 1470), width: 420, degrees: 8,
              caption: stockName("crossProcess"))
    text("21 FILM LOOKS  ·  POSTCARDS  ·  NO SUBSCRIPTION", sans(28, .semibold), rgb(0xF6EFE2, 0.62), y: 2660, kern: 4)
}

func comparePage(_ c: Canvas) {
    backdrop(c, .graphite, glow: CGPoint(x: W / 2, y: 900))
    headline("ORIGINAL  ·  FILM", "Same moment,", "new feeling.")
    let photo = "05-coastal-drive", film = "goldenHour"
    let before = graded(photo, "original"), after = graded(photo, film)
    let r = CGRect(x: 70, y: 590, width: 1180, height: 1590)
    let split = r.minX + r.width * 0.46
    c.ctx.saveGState()
    c.shadow(blur: 80, y: 40, alpha: 0.6)
    c.ctx.setFillColor(canvas)
    c.ctx.addPath(c.rounded(r, 44))
    c.ctx.fillPath()
    c.ctx.restoreGState()
    c.ctx.saveGState()
    c.ctx.addPath(c.rounded(r, 44))
    c.ctx.clip()
    c.fill(after, in: r, focusX: 0.35)
    c.ctx.clip(to: CGRect(x: r.minX, y: r.minY, width: split - r.minX, height: r.height))
    c.fill(before, in: r, focusX: 0.35)
    c.ctx.restoreGState()
    // Divider and handle, styled after the app's compare control.
    c.ctx.setFillColor(cream)
    c.ctx.fill(CGRect(x: split - 3, y: r.minY, width: 6, height: r.height))
    let hc = CGPoint(x: split, y: r.midY)
    c.ctx.saveGState()
    c.shadow(blur: 24, y: 8, alpha: 0.4)
    c.ctx.fillEllipse(in: CGRect(x: hc.x - 46, y: hc.y - 46, width: 92, height: 92))
    c.ctx.restoreGState()
    if let sym = NSImage(systemSymbolName: "chevron.left.chevron.right", accessibilityDescription: nil)?
        .withSymbolConfiguration(.init(pointSize: 34, weight: .bold).applying(.init(paletteColors: [NSColor(cgColor: ink)!]))) {
        sym.draw(in: CGRect(x: hc.x - sym.size.width / 2, y: hc.y - sym.size.height / 2, width: sym.size.width, height: sym.size.height),
                 from: .zero, operation: .sourceOver, fraction: 1, respectFlipped: true, hints: nil)
    }
    pill(c, "ORIGINAL", symbol: nil, center: CGPoint(x: r.minX + 150, y: r.maxY - 70), font: sans(28, .bold),
             fg: cream, bg: rgb(0x000000, 0.55))
    let filmLabel = stockName(film).uppercased()
    let fw = textWidth(filmLabel, sans(28, .bold)) + 64
    pill(c, filmLabel, symbol: nil, center: CGPoint(x: r.maxX - 34 - fw / 2, y: r.maxY - 70), font: sans(28, .bold),
             fg: ink, bg: amber)

    // The same photo across the strip, as in Studio.
    let films = ["original", "fadedInstant", film, "silver", "lightLeak"]
    let tw: CGFloat = 196, th: CGFloat = 245, gap: CGFloat = 30
    var x = (W - (tw * 5 + gap * 4)) / 2
    for id in films {
        let t = CGRect(x: x, y: 2290, width: tw, height: th)
        c.ctx.saveGState()
        c.ctx.addPath(c.rounded(t, 22))
        c.ctx.clip()
        c.fill(graded(photo, id), in: t, focusX: 0.35)
        c.ctx.restoreGState()
        let selected = id == film
        if selected {
            c.ctx.setStrokeColor(amber)
            c.ctx.setLineWidth(6)
            c.ctx.addPath(c.rounded(t.insetBy(dx: -7, dy: -7), 28))
            c.ctx.strokePath()
        }
        text(stockName(id), sans(28, selected ? .bold : .medium), selected ? amber : rgb(0xF6EFE2, 0.72),
             x: t.minX - 20, y: t.maxY + 22, width: tw + 40)
        x += tw + gap
    }
}

func looksPage(_ c: Canvas) {
    backdrop(c, .graphite, glow: CGPoint(x: W / 2, y: 1500))
    headline("21 FILM LOOKS", "Every mood,", "one tap away.")
    let panel = CGRect(x: 56, y: 590, width: W - 112, height: 1756)
    c.ctx.saveGState()
    c.shadow(blur: 70, y: 30, alpha: 0.55)
    c.ctx.setFillColor(rgb(0x121315))
    c.ctx.addPath(c.rounded(panel, 36))
    c.ctx.fillPath()
    c.ctx.restoreGState()
    // Sprocket holes down both edges of the "negative".
    c.ctx.setFillColor(rgb(0x2A2C30))
    var sy = panel.minY + 40
    while sy + 40 < panel.maxY - 20 {
        for sx in [panel.minX + 22, panel.maxX - 22 - 26] {
            c.ctx.addPath(c.rounded(CGRect(x: sx, y: sy, width: 26, height: 38), 7))
        }
        sy += 74
    }
    c.ctx.fillPath()
    let films = ["goldenHour", "silver", "crossProcess",
                 "dateStamp", "fadedInstant", "sepiaPrint",
                 "lightLeak", "charcoal", "poolParty"]
    let left = panel.minX + 86, inner = panel.width - 172, gap: CGFloat = 26
    let tw = (inner - gap * 2) / 3, th = tw * 1.36
    for (i, id) in films.enumerated() {
        let col = CGFloat(i % 3), row = CGFloat(i / 3)
        let t = CGRect(x: left + col * (tw + gap), y: panel.minY + 56 + row * (th + 90), width: tw, height: th)
        c.ctx.saveGState()
        c.ctx.addPath(c.rounded(t, 14))
        c.ctx.clip()
        c.fill(graded("03-flower-market", id), in: t, focusX: 0.45)
        c.ctx.restoreGState()
        text(stockName(id).uppercased(), mono(25, .semibold), amber, x: t.minX - 10, y: t.maxY + 24, width: tw + 20, kern: 2)
    }
    let chips = ["Core", "Ninety-Six", "Darkroom", "Long Summer"]
    let font = sans(31, .semibold)
    let widths = chips.map { textWidth($0, font) + 64 }
    var x = (W - widths.reduce(0, +) - 18 * 3) / 2
    for (label, w) in zip(chips, widths) {
        pill(c, label, symbol: nil, center: CGPoint(x: x + w / 2, y: 2480), font: font, fg: cream,
                 bg: surfaceRaised, stroke: rgb(0xF6EFE2, 0.10))
        x += w + 18
    }
    text("Preview every look on your own photos.", sans(38, .regular), rgb(0xF6EFE2, 0.72), y: 2580)
}

func postcardPage(_ c: Canvas) {
    backdrop(c, .paper, glow: CGPoint(x: W * 0.3, y: 700))
    headline("POSTCARDS", "Send it as", "a postcard.", dark: false)
    card(c, liftPostcard(raw("finish-vintage")), center: CGPoint(x: 190, y: 1080), width: 500, degrees: -10)
    card(c, liftPostcard(raw("finish-bordered")), center: CGPoint(x: 1150, y: 1350), width: 460, degrees: 9)
    card(c, liftPostcard(raw("finish-deckled")), center: CGPoint(x: 165, y: 2240), width: 470, degrees: 7)
    phone(c, raw("finish-classic"), x: 220, y: 600, width: 880)
    text("Four styles and a handwritten note. All free.", sans(38, .medium), rgb(0x1E2A34, 0.78), y: 2650)
}

func amountPage(_ c: Canvas) {
    backdrop(c, .graphite, glow: CGPoint(x: W / 2, y: 1300))
    headline("FILM STRENGTH", "Dial in", "the mood.")
    let shot = raw("studio-amount")
    let screen = phone(c, shot, x: 200, y: 600, width: 920)
    let scale = screen.width / shotW
    let sourceY: CGFloat = 2120, sourceH: CGFloat = 380
    let w: CGFloat = 1220
    let y = screen.minY + sourceY * scale - (w / shotW * sourceH - sourceH * scale) / 2
    callout(c, shot, sourceY: sourceY, sourceH: sourceH, y: y, width: w)
}

func cropPage(_ c: Canvas) {
    backdrop(c, .graphite, glow: CGPoint(x: W / 2, y: 1200))
    headline("CROP & STRAIGHTEN", "Fix the frame,", "right on the photo.")
    let shot = raw("studio-crop")
    let screen = phone(c, shot, x: 200, y: 600, width: 920)
    let scale = screen.width / shotW
    let sourceY: CGFloat = 2046, sourceH: CGFloat = 400
    let w: CGFloat = 1220
    let y = screen.minY + sourceY * scale - (w / shotW * sourceH - sourceH * scale) / 2
    callout(c, shot, sourceY: sourceY, sourceH: sourceH, y: y, width: w)
}

func drawerPage(_ c: Canvas) {
    backdrop(c, .navy, glow: CGPoint(x: W / 2, y: 1250))
    headline("THE DRAWER", "Every print,", "kept.")
    // The screen is already a table of prints; loose ones beside a phone this
    // wide would only cover it.
    phone(c, raw("drawer"), x: 215, y: 600, width: 890)
    text("SHARE AGAIN  ·  REOPEN IN STUDIO  ·  ON YOUR DEVICE", sans(28, .semibold), rgb(0xF6EFE2, 0.62), y: 2660, kern: 4)
}

/// Rows of the paywall capture above its purchase button; screenshots never
/// show the price, so the phone runs off the bottom of the page before it.
let paywallVisibleH: CGFloat = 2250

/// A phone sized so its screen meets the bottom of the page at `visibleH`.
func bleedingPhone(_ c: Canvas, _ shot: CGImage, width w: CGFloat, visibleH: CGFloat) {
    let bezel = w * 0.026
    let scale = (w - bezel * 2) / shotW
    phone(c, shot, x: (W - w) / 2, y: H - visibleH * scale - bezel, width: w)
}

func completePage(_ c: Canvas) {
    backdrop(c, .navy, glow: CGPoint(x: W / 2, y: 1300))
    headline("SIX LOOKS FREE", "Private by design.", "Pay once.")
    bleedingPhone(c, raw("complete"), width: 1180, visibleH: paywallVisibleH)
    privacyPills(c, y: 700)
}

func privacyPills(_ c: Canvas, y: CGFloat) {
    let font = sans(32, .semibold)
    let items: [(String, String)] = [("iphone", "Edits stay on device"), ("checkmark.seal", "No subscription")]
    let widths = items.map { pillWidth($0.1, symbol: $0.0, font: font) }
    var x = (W - widths.reduce(0, +) - 24) / 2
    for (item, w) in zip(items, widths) {
        pill(c, item.1, symbol: item.0, center: CGPoint(x: x + w / 2, y: y), font: font, fg: cream,
             bg: rgb(0xF6EFE2, 0.08), stroke: rgb(0xF6EFE2, 0.16), height: 84)
        x += w + 24
    }
}

// MARK: - Output

let pages: [(String, (Canvas) -> Void)] = [
    ("01-hero", heroPage),
    ("02-compare", comparePage),
    ("03-looks", looksPage),
    ("04-postcard", postcardPage),
    ("05-strength", amountPage),
    ("06-crop", cropPage),
    ("07-drawer", drawerPage),
    ("08-complete", completePage),
]

/// An output set: its design size, pixel scale, directory and pages.
struct Target {
    let width: CGFloat, height: CGFloat, scale: CGFloat
    let dir: String
    let pages: [(String, (Canvas) -> Void)]
}

let targets: [String: Target] = [
    // 6.9-inch iPhone, 1320 × 2868.
    "iphone": Target(width: 1320, height: 2868, scale: 1, dir: "final", pages: pages),
    // iPhone Duo, 2007 × 2853 (render-duo.swift).
    "duo": Target(width: 1320, height: 2853 / (2007 / 1320), scale: 2007 / 1320, dir: "final-duo", pages: duoPages),
    // Product page header and search results, 5244 × 2950 (render-duo.swift).
    "header": Target(width: 2622, height: 1475, scale: 2, dir: "final-header", pages: headerPages),
    // Search results asset, 3840 × 2560 (render-duo.swift).
    "search": Target(width: 1920, height: 1280, scale: 2, dir: "final-search", pages: searchPages),
]

@main
enum RenderScreenshots {
    /// render-screenshots [iphone|duo|header] [page prefix]
    static func main() throws {
        var args = Array(CommandLine.arguments.dropFirst())
        var target = targets["iphone"]!
        if let first = args.first, let named = targets[first] {
            target = named
            args.removeFirst()
        }
        W = target.width
        H = target.height
        outScale = target.scale
        outDir = root.appendingPathComponent("screenshots/3.1/" + target.dir)
        try FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)
        let only = args.first
        for old in (try? FileManager.default.contentsOfDirectory(at: outDir, includingPropertiesForKeys: nil)) ?? []
        where old.pathExtension == "png" && (only == nil || old.lastPathComponent.hasPrefix(only!)) {
            try FileManager.default.removeItem(at: old)
        }
        for (name, draw) in target.pages where only == nil || name.hasPrefix(only!) {
            let c = Canvas()
            draw(c)
            let url = outDir.appendingPathComponent(name + ".png")
            let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
            CGImageDestinationAddImage(dest, c.output(), nil)
            CGImageDestinationFinalize(dest)
            Swift.print("wrote \(outDir.lastPathComponent)/\(name)")
        }
    }
}
