import AppKit
import Foundation

let W: CGFloat = 1080
let H: CGFloat = 1350

let root = FileManager.default.currentDirectoryPath
let outDir = root + "/marketing/instagram/intro-carousel/output"
let texturePath = root + "/marketing/instagram/intro-carousel/assets/tumble-paper-texture.png"
let logoPath = root + "/logo.png"
let gradedDir = root + "/marketing/ads/nostalgia-memory/graded"

extension NSColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        self.init(
            calibratedRed: CGFloat((hex >> 16) & 0xff) / 255,
            green: CGFloat((hex >> 8) & 0xff) / 255,
            blue: CGFloat(hex & 0xff) / 255,
            alpha: alpha
        )
    }
}

enum C {
    static let ink = NSColor(hex: 0x141F28)
    static let navy = NSColor(hex: 0x172734)
    static let blue = NSColor(hex: 0x2E4052)
    static let cream = NSColor(hex: 0xF6EFE2)
    static let stock = NSColor(hex: 0xF4ECDA)
    static let gold = NSColor(hex: 0xDFAB68)
    static let coral = NSColor(hex: 0xC96E58)
    static let teal = NSColor(hex: 0x397A78)
    static let moss = NSColor(hex: 0x68785E)
    static let rust = NSColor(hex: 0x9A624A)
}

func image(_ path: String) -> NSImage {
    guard let value = NSImage(contentsOfFile: path) else {
        fatalError("Missing image: \(path)")
    }
    return value
}

let texture = image(texturePath)
let logo = image(logoPath)

func graded(_ file: String) -> NSImage { image(gradedDir + "/" + file) }

func tr(_ x: CGFloat, _ top: CGFloat, _ width: CGFloat, _ height: CGFloat) -> CGRect {
    CGRect(x: x, y: H - top - height, width: width, height: height)
}

func rounded(_ rect: CGRect, _ radius: CGFloat) -> NSBezierPath {
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
}

func display(_ size: CGFloat) -> NSFont {
    NSFont(name: "Georgia-Bold", size: size) ?? .boldSystemFont(ofSize: size)
}

func serifItalic(_ size: CGFloat) -> NSFont {
    NSFont(name: "Georgia-Italic", size: size) ?? .systemFont(ofSize: size)
}

func sans(_ size: CGFloat, bold: Bool = false) -> NSFont {
    let name = bold ? "AvenirNext-DemiBold" : "AvenirNext-Medium"
    return NSFont(name: name, size: size) ?? (bold ? .boldSystemFont(ofSize: size) : .systemFont(ofSize: size))
}

func mono(_ size: CGFloat) -> NSFont {
    NSFont(name: "Menlo-Bold", size: size) ?? .monospacedSystemFont(ofSize: size, weight: .bold)
}

func drawText(
    _ value: String,
    _ rect: CGRect,
    font: NSFont,
    color: NSColor = C.cream,
    align: NSTextAlignment = .left,
    lineHeight: CGFloat? = nil,
    tracking: CGFloat = 0
) {
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = align
    if let lineHeight {
        paragraph.minimumLineHeight = lineHeight
        paragraph.maximumLineHeight = lineHeight
    }
    (value as NSString).draw(in: rect, withAttributes: [
        .font: font,
        .foregroundColor: color,
        .paragraphStyle: paragraph,
        .kern: tracking
    ])
}

func aspectFill(_ value: NSImage, in rect: CGRect, radius: CGFloat = 0, alpha: CGFloat = 1) {
    let source = value.size
    let targetRatio = rect.width / rect.height
    let sourceRatio = source.width / source.height
    var crop = CGRect(origin: .zero, size: source)
    if sourceRatio > targetRatio {
        let cropWidth = source.height * targetRatio
        crop.origin.x = (source.width - cropWidth) / 2
        crop.size.width = cropWidth
    } else {
        let cropHeight = source.width / targetRatio
        crop.origin.y = (source.height - cropHeight) / 2
        crop.size.height = cropHeight
    }
    NSGraphicsContext.saveGraphicsState()
    if radius > 0 { rounded(rect, radius).addClip() }
    value.draw(in: rect, from: crop, operation: .sourceOver, fraction: alpha,
               respectFlipped: false, hints: [.interpolation: NSImageInterpolation.high])
    NSGraphicsContext.restoreGraphicsState()
}

func rotate(_ degrees: CGFloat, around point: CGPoint, draw: () -> Void) {
    NSGraphicsContext.saveGraphicsState()
    let transform = NSAffineTransform()
    transform.translateX(by: point.x, yBy: point.y)
    transform.rotate(byDegrees: degrees)
    transform.translateX(by: -point.x, yBy: -point.y)
    transform.concat()
    draw()
    NSGraphicsContext.restoreGraphicsState()
}

func withShadow(_ blur: CGFloat = 24, y: CGFloat = -10, alpha: CGFloat = 0.40, draw: () -> Void) {
    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(alpha)
    shadow.shadowBlurRadius = blur
    shadow.shadowOffset = NSSize(width: 0, height: y)
    shadow.set()
    draw()
    NSGraphicsContext.restoreGraphicsState()
}

func background(accent: NSColor) {
    aspectFill(texture, in: CGRect(x: 0, y: 0, width: W, height: H))
    accent.withAlphaComponent(0.13).setFill()
    NSBezierPath(rect: CGRect(x: 0, y: 0, width: W, height: H)).fill()
    let topGlow = NSGradient(starting: accent.withAlphaComponent(0.24), ending: .clear)
    topGlow?.draw(in: NSBezierPath(ovalIn: CGRect(x: -140, y: H - 460, width: W + 280, height: 610)), relativeCenterPosition: .zero)
    let fade = NSGradient(colors: [.clear, C.ink.withAlphaComponent(0.30)])
    fade?.draw(in: CGRect(x: 0, y: 0, width: W, height: 560), angle: -90)
}

func kicker(_ value: String, top: CGFloat = 68) {
    drawText(value.uppercased(), tr(72, top, 920, 34), font: mono(19), color: C.gold, tracking: 3.2)
}

func pageNumber(_ number: Int) {
    drawText(String(format: "%02d / 06", number), tr(824, 72, 184, 28), font: mono(16),
             color: C.cream.withAlphaComponent(0.48), align: .right, tracking: 1.2)
}

func title(_ value: String, top: CGFloat = 130, size: CGFloat = 76, width: CGFloat = 930) {
    let lines = CGFloat(value.components(separatedBy: "\n").count)
    drawText(value, tr(72, top, width, lines * size * 1.05 + 18), font: display(size),
             color: C.cream, lineHeight: size * 1.02, tracking: -1.8)
}

func pill(_ value: String, _ rect: CGRect, fill: NSColor? = nil, color: NSColor = C.cream) {
    let bg = fill ?? C.cream.withAlphaComponent(0.10)
    bg.setFill()
    rounded(rect, rect.height / 2).fill()
    drawText(value.uppercased(), CGRect(x: rect.minX + 14, y: rect.minY + (rect.height - 26) / 2,
                                        width: rect.width - 28, height: 28),
             font: mono(15), color: color, align: .center, tracking: 1.4)
}

func printCard(_ photo: NSImage, rect: CGRect, rotation: CGFloat = 0, caption: String? = nil, faded: CGFloat = 0) {
    rotate(rotation, around: CGPoint(x: rect.midX, y: rect.midY)) {
        withShadow {
            C.stock.setFill()
            rounded(rect, 12).fill()
        }
        let pad = rect.width * 0.055
        let bottom = caption == nil ? rect.width * 0.12 : rect.width * 0.21
        let photoRect = CGRect(x: rect.minX + pad, y: rect.minY + bottom,
                               width: rect.width - pad * 2, height: rect.height - bottom - pad)
        aspectFill(photo, in: photoRect, radius: 3)
        if faded > 0 {
            C.stock.withAlphaComponent(faded).setFill()
            NSBezierPath(rect: photoRect).fill()
        }
        if let caption {
            drawText(caption, CGRect(x: rect.minX + 14, y: rect.minY + 18,
                                    width: rect.width - 28, height: bottom - 26),
                     font: serifItalic(rect.width * 0.055), color: C.ink.withAlphaComponent(0.80), align: .center)
        }
    }
}

func tile(_ photo: NSImage, rect: CGRect, label: String? = nil, radius: CGFloat = 14) {
    withShadow(16, y: -6, alpha: 0.28) {
        C.ink.setFill()
        rounded(rect, radius).fill()
    }
    aspectFill(photo, in: rect, radius: radius)
    C.cream.withAlphaComponent(0.16).setStroke()
    let edge = rounded(rect, radius)
    edge.lineWidth = 1.5
    edge.stroke()
    if let label {
        let bar = CGRect(x: rect.minX + 10, y: rect.minY + 10, width: rect.width - 20, height: 38)
        NSColor.black.withAlphaComponent(0.62).setFill()
        rounded(bar, 19).fill()
        drawText(label.uppercased(), CGRect(x: bar.minX + 8, y: bar.minY + 10, width: bar.width - 16, height: 20),
                 font: mono(11), color: C.cream, align: .center, tracking: 0.8)
    }
}

func slide1() {
    background(accent: C.coral)
    let iconRect = tr(72, 58, 86, 86)
    aspectFill(logo, in: iconRect, radius: 20)
    drawText("TUMBLE", tr(180, 79, 300, 34), font: mono(21), color: C.cream, tracking: 4)
    pageNumber(1)
    title("A slower camera\nyou can own.", top: 190, size: 86)
    drawText("Twelve shots a day. Shake to develop.\nPrivate on iPhone.", tr(76, 390, 900, 88),
             font: sans(29), color: C.cream.withAlphaComponent(0.78), lineHeight: 39)

    let dinner = graded("01-after-dinner--warmArchive.jpg")
    let birthday = graded("03-birthday--goldenHour.jpg")
    let pool = graded("05-pool--fadedInstant.jpg")
    printCard(birthday, rect: tr(54, 590, 400, 490), rotation: -9)
    printCard(pool, rect: tr(632, 574, 390, 478), rotation: 9)
    printCard(dinner, rect: tr(308, 515, 485, 600), rotation: -1.5, caption: "after dinner")

    pill("PRIVATE IPHONE FILM CAMERA", tr(72, 1211, 640, 58), fill: C.gold.withAlphaComponent(0.16), color: C.gold)
    drawText("SWIPE →", tr(800, 1228, 208, 28), font: mono(16), color: C.cream.withAlphaComponent(0.62), align: .right, tracking: 2)
}

func slide2() {
    background(accent: C.moss)
    kicker("01 · THE DAILY ROLL")
    pageNumber(2)
    title("Twelve shots.\nMake them count.", top: 124, size: 77)
    drawText("A fresh roll every morning.", tr(75, 318, 820, 44), font: sans(28), color: C.cream.withAlphaComponent(0.72))

    let strip = tr(70, 410, 940, 720)
    withShadow(32, y: -12, alpha: 0.46) {
        NSColor(hex: 0x111315).setFill()
        rounded(strip, 26).fill()
    }
    C.gold.withAlphaComponent(0.22).setStroke()
    let stripEdge = rounded(strip, 26)
    stripEdge.lineWidth = 2
    stripEdge.stroke()

    let photos = [
        graded("01-after-dinner--warmArchive.jpg"),
        graded("02-parking-lot--flashNight.jpg"),
        graded("03-birthday--fadedInstant.jpg"),
        graded("04-bicycle--goldenHour.jpg"),
        graded("05-pool--poolParty.jpg")
    ]
    let gap: CGFloat = 16
    let inset: CGFloat = 48
    let cellW = (strip.width - inset * 2 - gap * 2) / 3
    let cellH = (strip.height - 76 - gap * 3) / 4
    for i in 0..<12 {
        let col = CGFloat(i % 3)
        let row = CGFloat(i / 3)
        let rect = CGRect(x: strip.minX + inset + col * (cellW + gap),
                          y: strip.maxY - 38 - cellH - row * (cellH + gap),
                          width: cellW, height: cellH)
        if i < photos.count {
            tile(photos[i], rect: rect, radius: 7)
        } else {
            NSColor(hex: 0x292B2C).setFill()
            rounded(rect, 7).fill()
            C.gold.withAlphaComponent(0.18).setStroke()
            let edge = rounded(rect, 7)
            edge.lineWidth = 1.5
            edge.stroke()
            drawText(String(format: "%02d", i + 1), CGRect(x: rect.minX, y: rect.midY - 13, width: rect.width, height: 28),
                     font: mono(16), color: C.cream.withAlphaComponent(0.32), align: .center)
        }
    }
    pill("12 FREE SHOTS · EVERY DAY", tr(206, 1190, 668, 58), fill: C.gold.withAlphaComponent(0.16), color: C.gold)
}

func slide3() {
    background(accent: C.gold)
    kicker("02 · THE RITUAL")
    pageNumber(3)
    title("Shake it.\nWatch it develop.", top: 124, size: 79)
    drawText("Fresh prints start blank. Give the phone a shake.", tr(75, 322, 930, 44),
             font: sans(27), color: C.cream.withAlphaComponent(0.72))

    let final = graded("04-bicycle--warmArchive.jpg")
    let cardTop: CGFloat = 490
    let cardW: CGFloat = 300
    let cardH: CGFloat = 420
    let xs: [CGFloat] = [40, 390, 740]
    let progresses: [CGFloat] = [0.94, 0.48, 0]
    let labels = ["BLANK", "SHAKE", "DEVELOPED"]
    let rotations: [CGFloat] = [-5, 4, -3]
    for i in 0..<3 {
        drawText(String(format: "%02d", i + 1), tr(xs[i], 424, cardW, 48), font: display(38),
                 color: C.gold.withAlphaComponent(0.42), align: .center)
        printCard(final, rect: tr(xs[i], cardTop, cardW, cardH), rotation: rotations[i], faded: progresses[i])
        pill(labels[i], tr(xs[i] + 48, 942, cardW - 96, 48),
             fill: i == 2 ? C.gold : C.cream.withAlphaComponent(0.10),
             color: i == 2 ? C.ink : C.cream)
    }
    drawText("wait for it…", tr(72, 1090, 936, 72), font: serifItalic(48), color: C.gold, align: .center)
    drawText("The little pause is part of the picture.", tr(72, 1172, 936, 44), font: sans(25),
             color: C.cream.withAlphaComponent(0.66), align: .center)
}

func slide4() {
    background(accent: C.teal)
    kicker("03 · THE FILM")
    pageNumber(4)
    title("One shot.\nTwenty-one looks.", top: 124, size: 79)

    let variants: [(String, String)] = [
        ("04-bicycle--fadedInstant.jpg", "Faded Instant"),
        ("04-bicycle--disposable.jpg", "Disposable"),
        ("04-bicycle--silver.jpg", "Silver"),
        ("04-bicycle--goldenHour.jpg", "Golden Hour"),
        ("04-bicycle--lightLeak.jpg", "Light Leak"),
        ("04-bicycle--crossProcess.jpg", "Cross Process")
    ]
    let gapX: CGFloat = 22
    let gapY: CGFloat = 20
    let cellW = (W - 144 - gapX) / 2
    let cellH: CGFloat = 228
    for (i, item) in variants.enumerated() {
        let col = CGFloat(i % 2)
        let row = CGFloat(i / 2)
        let rect = tr(72 + col * (cellW + gapX), 390 + row * (cellH + gapY), cellW, cellH)
        tile(graded(item.0), rect: rect, label: item.1, radius: 16)
    }
    pill("4 FILM PACKS · LOOK BAKED INTO EVERY EXPORT", tr(120, 1174, 840, 58),
         fill: C.gold.withAlphaComponent(0.16), color: C.gold)
}

func slide5() {
    background(accent: C.rust)
    kicker("04 · THE DRAWER")
    pageNumber(5)
    title("Your days, kept.\nNever posted.", top: 124, size: 76)

    let tray = tr(68, 400, 944, 690)
    withShadow(38, y: -14, alpha: 0.48) {
        let gradient = NSGradient(colors: [NSColor(hex: 0x5A3C31), NSColor(hex: 0x2B2524)])
        gradient?.draw(in: rounded(tray, 30), angle: -90)
    }
    C.gold.withAlphaComponent(0.32).setStroke()
    let edge = rounded(tray, 30)
    edge.lineWidth = 3
    edge.stroke()
    let lip = CGRect(x: tray.minX + 20, y: tray.minY + 18, width: tray.width - 40, height: 62)
    NSColor.black.withAlphaComponent(0.28).setFill()
    rounded(lip, 15).fill()
    C.gold.withAlphaComponent(0.34).setStroke()
    let handle = rounded(CGRect(x: tray.midX - 114, y: tray.minY + 36, width: 228, height: 26), 13)
    handle.lineWidth = 3
    handle.stroke()

    let items: [(NSImage, CGRect, CGFloat)] = [
        (graded("03-birthday--fadedInstant.jpg"), tr(96, 470, 320, 390), -8),
        (graded("02-parking-lot--flashNight.jpg"), tr(648, 468, 322, 394), 8),
        (graded("05-pool--poolParty.jpg"), tr(372, 438, 352, 430), 1),
        (graded("01-after-dinner--warmArchive.jpg"), tr(140, 728, 340, 414), 7),
        (graded("04-bicycle--goldenHour.jpg"), tr(590, 716, 350, 426), -7)
    ]
    for item in items { printCard(item.0, rect: item.1, rotation: item.2) }

    let badgeY: CGFloat = 1165
    let badgeW: CGFloat = 276
    for (i, value) in ["NO ACCOUNT", "NO CLOUD", "NO FEED"].enumerated() {
        pill(value, tr(72 + CGFloat(i) * (badgeW + 54), badgeY, badgeW, 54))
    }
    drawText("Your photos stay on device.", tr(72, 1250, 936, 38), font: serifItalic(27),
             color: C.cream.withAlphaComponent(0.68), align: .center)
}

func slide6() {
    background(accent: C.coral)
    pageNumber(6)
    let iconRect = tr(430, 94, 220, 220)
    aspectFill(logo, in: iconRect, radius: 48)
    drawText("TUMBLE", tr(72, 342, 936, 42), font: mono(25), color: C.gold, align: .center, tracking: 5)
    drawText("Make ordinary moments\nfeel worth keeping.", tr(70, 420, 940, 190), font: display(68),
             color: C.cream, align: .center, lineHeight: 76, tracking: -1.5)
    drawText("A private film camera for iPhone.\nFree to start. One-time unlocks. No subscriptions.",
             tr(128, 650, 824, 92), font: sans(26), color: C.cream.withAlphaComponent(0.74),
             align: .center, lineHeight: 38)

    let cta = tr(220, 805, 640, 88)
    C.gold.setFill()
    rounded(cta, 44).fill()
    drawText("DOWNLOAD ON THE APP STORE", CGRect(x: cta.minX + 24, y: cta.minY + 31, width: cta.width - 48, height: 30),
             font: mono(17), color: C.ink, align: .center, tracking: 1.4)
    drawText("gettumbleapp.com", tr(72, 930, 936, 42), font: sans(25, bold: true), color: C.cream, align: .center)

    let featureY: CGFloat = 1032
    let featureW: CGFloat = 214
    let labels = ["12 / DAY", "SHAKE", "21 LOOKS", "ON DEVICE"]
    for (i, value) in labels.enumerated() {
        pill(value, tr(72 + CGFloat(i) * (featureW + 26), featureY, featureW, 54),
             fill: C.cream.withAlphaComponent(0.10))
    }
    drawText("wait for it.", tr(72, 1184, 936, 64), font: serifItalic(44), color: C.gold, align: .center)
}

func render(_ number: Int, name: String, draw: () -> Void) {
    let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(W),
        pixelsHigh: Int(H),
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!
    NSGraphicsContext.saveGraphicsState()
    let context = NSGraphicsContext(bitmapImageRep: bitmap)!
    NSGraphicsContext.current = context
    context.imageInterpolation = .high
    draw()
    NSGraphicsContext.restoreGraphicsState()
    let url = URL(fileURLWithPath: outDir).appendingPathComponent(String(format: "%02d-%@.png", number, name))
    try! bitmap.representation(using: .png, properties: [:])!.write(to: url)
    print("Rendered \(url.path)")
}

try FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)
render(1, name: "meet-tumble", draw: slide1)
render(2, name: "twelve-shots", draw: slide2)
render(3, name: "shake-to-develop", draw: slide3)
render(4, name: "twenty-one-looks", draw: slide4)
render(5, name: "private-drawer", draw: slide5)
render(6, name: "download", draw: slide6)
