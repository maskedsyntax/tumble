// iPhone Duo screenshots, the product page header and the search results
// asset for Tumble 3.1.
//
// Compiled with render.swift, whose helpers these pages share. Duo pages use a
// 1320 × 1876 design space (the Duo's 2007 × 2853 portrait screen); they carry
// the same story and the same unedited 6.9-inch captures as the iPhone set, in
// a shorter frame with the photographs given more room beside the phone. The
// header is a 2622 × 1475 design rendered at 2× to 5244 × 2950, the one size
// App Store Connect accepts for both the header and the search results asset.

import CoreGraphics

// MARK: - iPhone Duo

/// Phone width that fills the space between the headline and the footer.
let duoPhoneWidth: CGFloat = 560
let duoPhoneX = (1320 - duoPhoneWidth) / 2

func duoHeroPage(_ c: Canvas) {
    backdrop(c, .graphite, glow: CGPoint(x: W / 2, y: 1000))
    headline("VINTAGE PHOTO EDITOR", "Your photos,", "on film.")
    filmPrint(c, graded("03-flower-market", "silver"), center: CGPoint(x: 205, y: 860), width: 360, degrees: -9,
              caption: stockName("silver"))
    filmPrint(c, graded("10-motel-pool", "hazyFlare"), center: CGPoint(x: 200, y: 1450), width: 350, degrees: 6,
              caption: stockName("hazyFlare"))
    filmPrint(c, graded("08-sidewalk-cafe", "fadedInstant"), center: CGPoint(x: 1125, y: 1500), width: 340, degrees: -6,
              caption: stockName("fadedInstant"))
    phone(c, raw("studio-hero"), x: duoPhoneX, y: 550, width: duoPhoneWidth)
    filmPrint(c, graded("15-concert", "crossProcess"), center: CGPoint(x: 1100, y: 930), width: 360, degrees: 8,
              caption: stockName("crossProcess"))
    text("21 FILM LOOKS  ·  POSTCARDS  ·  NO SUBSCRIPTION", sans(28, .semibold), rgb(0xF6EFE2, 0.62), y: 1790, kern: 4)
}

func duoComparePage(_ c: Canvas) {
    backdrop(c, .graphite, glow: CGPoint(x: W / 2, y: 800))
    headline("ORIGINAL  ·  FILM", "Same moment,", "new feeling.")
    let photo = "05-coastal-drive", film = "goldenHour"
    let before = graded(photo, "original"), after = graded(photo, film)
    let r = CGRect(x: 70, y: 560, width: 1180, height: 900)
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
    c.ctx.setFillColor(cream)
    c.ctx.fill(CGRect(x: split - 3, y: r.minY, width: 6, height: r.height))
    let hc = CGPoint(x: split, y: r.midY)
    c.ctx.saveGState()
    c.shadow(blur: 24, y: 8, alpha: 0.4)
    c.ctx.fillEllipse(in: CGRect(x: hc.x - 46, y: hc.y - 46, width: 92, height: 92))
    c.ctx.restoreGState()
    if let sym = symbolImage("chevron.left.chevron.right", sans(34, .bold), ink) {
        sym.draw(in: CGRect(x: hc.x - sym.size.width / 2, y: hc.y - sym.size.height / 2, width: sym.size.width, height: sym.size.height),
                 from: .zero, operation: .sourceOver, fraction: 1, respectFlipped: true, hints: nil)
    }
    pill(c, "ORIGINAL", symbol: nil, center: CGPoint(x: r.minX + 150, y: r.maxY - 70), font: sans(28, .bold),
         fg: cream, bg: rgb(0x000000, 0.55))
    let filmLabel = stockName(film).uppercased()
    let fw = textWidth(filmLabel, sans(28, .bold)) + 64
    pill(c, filmLabel, symbol: nil, center: CGPoint(x: r.maxX - 34 - fw / 2, y: r.maxY - 70), font: sans(28, .bold),
         fg: ink, bg: amber)

    let films = ["original", "fadedInstant", film, "silver", "lightLeak"]
    let tw: CGFloat = 196, th: CGFloat = 210, gap: CGFloat = 30
    var x = (W - (tw * 5 + gap * 4)) / 2
    for id in films {
        let t = CGRect(x: x, y: 1540, width: tw, height: th)
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

func duoLooksPage(_ c: Canvas) {
    backdrop(c, .graphite, glow: CGPoint(x: W / 2, y: 1100))
    headline("21 FILM LOOKS", "Every mood,", "one tap away.")
    let panel = CGRect(x: 56, y: 560, width: W - 112, height: 900)
    c.ctx.saveGState()
    c.shadow(blur: 70, y: 30, alpha: 0.55)
    c.ctx.setFillColor(rgb(0x121315))
    c.ctx.addPath(c.rounded(panel, 36))
    c.ctx.fillPath()
    c.ctx.restoreGState()
    c.ctx.setFillColor(rgb(0x2A2C30))
    var sy = panel.minY + 40
    while sy + 40 < panel.maxY - 20 {
        for sx in [panel.minX + 22, panel.maxX - 22 - 26] {
            c.ctx.addPath(c.rounded(CGRect(x: sx, y: sy, width: 26, height: 38), 7))
        }
        sy += 74
    }
    c.ctx.fillPath()
    let films = ["goldenHour", "silver", "crossProcess", "dateStamp",
                 "fadedInstant", "sepiaPrint", "lightLeak", "charcoal"]
    let left = panel.minX + 86, inner = panel.width - 172, gap: CGFloat = 26
    let tw = (inner - gap * 3) / 4, th = tw * 1.36
    for (i, id) in films.enumerated() {
        let col = CGFloat(i % 4), row = CGFloat(i / 4)
        let t = CGRect(x: left + col * (tw + gap), y: panel.minY + 56 + row * (th + 90), width: tw, height: th)
        c.ctx.saveGState()
        c.ctx.addPath(c.rounded(t, 14))
        c.ctx.clip()
        c.fill(graded("03-flower-market", id), in: t, focusX: 0.45)
        c.ctx.restoreGState()
        text(stockName(id).uppercased(), mono(23, .semibold), amber, x: t.minX - 14, y: t.maxY + 24, width: tw + 28, kern: 2)
    }
    let chips = ["Core", "Ninety-Six", "Darkroom", "Long Summer"]
    let font = sans(31, .semibold)
    let widths = chips.map { textWidth($0, font) + 64 }
    var x = (W - widths.reduce(0, +) - 18 * 3) / 2
    for (label, w) in zip(chips, widths) {
        pill(c, label, symbol: nil, center: CGPoint(x: x + w / 2, y: 1580), font: font, fg: cream,
             bg: surfaceRaised, stroke: rgb(0xF6EFE2, 0.10))
        x += w + 18
    }
    text("Preview every look on your own photos.", sans(38, .regular), rgb(0xF6EFE2, 0.72), y: 1680)
}

func duoPostcardPage(_ c: Canvas) {
    backdrop(c, .paper, glow: CGPoint(x: W * 0.3, y: 600))
    headline("POSTCARDS", "Send it as", "a postcard.", dark: false)
    card(c, liftPostcard(raw("finish-vintage")), center: CGPoint(x: 210, y: 900), width: 400, degrees: -10)
    card(c, liftPostcard(raw("finish-bordered")), center: CGPoint(x: 1095, y: 1080), width: 340, degrees: 9)
    card(c, liftPostcard(raw("finish-deckled")), center: CGPoint(x: 200, y: 1480), width: 380, degrees: 7)
    phone(c, raw("finish-classic"), x: duoPhoneX, y: 550, width: duoPhoneWidth)
    text("Four styles and a handwritten note. All free.", sans(38, .medium), rgb(0x1E2A34, 0.78), y: 1780)
}

/// The phone with a magnified slice of its own controls floated over it.
func duoToolPage(_ c: Canvas, kicker: String, line1: String, line2: String, shotName: String,
                 sourceY: CGFloat, sourceH: CGFloat) {
    backdrop(c, .graphite, glow: CGPoint(x: W / 2, y: 1050))
    headline(kicker, line1, line2)
    let shot = raw(shotName)
    let width: CGFloat = 590
    let screen = phone(c, shot, x: (W - width) / 2, y: 550, width: width)
    let scale = screen.width / shotW
    let w: CGFloat = 1220
    let y = screen.minY + sourceY * scale - (w / shotW * sourceH - sourceH * scale) / 2
    callout(c, shot, sourceY: sourceY, sourceH: sourceH, y: y, width: w)
}

func duoAmountPage(_ c: Canvas) {
    duoToolPage(c, kicker: "FILM STRENGTH", line1: "Dial in", line2: "the mood.", shotName: "studio-amount",
                sourceY: 2120, sourceH: 380)
}

func duoCropPage(_ c: Canvas) {
    duoToolPage(c, kicker: "CROP & STRAIGHTEN", line1: "Fix the frame,", line2: "right on the photo.",
                shotName: "studio-crop", sourceY: 2046, sourceH: 400)
}

func duoDrawerPage(_ c: Canvas) {
    backdrop(c, .navy, glow: CGPoint(x: W / 2, y: 1000))
    headline("THE DRAWER", "Every print,", "kept.")
    filmPrint(c, graded("14-picnic", "sunbleached"), center: CGPoint(x: 210, y: 900), width: 360, degrees: -8,
              caption: stockName("sunbleached"))
    filmPrint(c, graded("11-night-train", "silver"), center: CGPoint(x: 1110, y: 960), width: 350, degrees: 7,
              caption: stockName("silver"))
    phone(c, raw("drawer"), x: duoPhoneX, y: 550, width: duoPhoneWidth)
    filmPrint(c, graded("07-rooftop-birthday", "dateStamp"), center: CGPoint(x: 1120, y: 1500), width: 340, degrees: -5,
              caption: stockName("dateStamp"))
    text("SHARE AGAIN  ·  REOPEN IN STUDIO  ·  ON YOUR DEVICE", sans(28, .semibold), rgb(0xF6EFE2, 0.62), y: 1790, kern: 4)
}

func duoCompletePage(_ c: Canvas) {
    backdrop(c, .navy, glow: CGPoint(x: W / 2, y: 1100))
    headline("SIX LOOKS FREE", "Private by design.", "Pay once.")
    bleedingPhone(c, raw("complete"), width: 700, visibleH: paywallVisibleH)
    privacyPills(c, y: 625)
}

let duoPages: [(String, (Canvas) -> Void)] = [
    ("01-hero", duoHeroPage),
    ("02-compare", duoComparePage),
    ("03-looks", duoLooksPage),
    ("04-postcard", duoPostcardPage),
    ("05-strength", duoAmountPage),
    ("06-crop", duoCropPage),
    ("07-drawer", duoDrawerPage),
    ("08-complete", duoCompletePage),
]

// MARK: - Product page header and search results

/// Studio between fanned prints, with no type: App Store draws the app's name
/// and icon over the header, and crops the search results placement to 3:2,
/// so everything that matters sits in the centre.
func headerPage(_ c: Canvas) {
    backdrop(c, .graphite, glow: CGPoint(x: W / 2, y: H * 0.55))
    let prints: [(String, String, CGFloat, CGFloat, CGFloat)] = [
        ("03-flower-market", "silver", 520, 800, -12),
        ("06-rainy-crosswalk", "warmArchive", 860, 700, -5),
        ("10-motel-pool", "hazyFlare", 1762, 700, 5),
        ("15-concert", "crossProcess", 2102, 800, 12),
    ]
    for (photo, stock, x, y, deg) in prints {
        filmPrint(c, graded(photo, stock), center: CGPoint(x: x, y: y), width: 440, degrees: deg,
                  caption: stockName(stock))
    }
    phone(c, raw("studio-hero"), x: (W - 520) / 2, y: 170, width: 520)
}

let headerPages: [(String, (Canvas) -> Void)] = [
    ("header-search", headerPage),
]

/// One idea that survives a search results thumbnail: the same photograph
/// before and after a film, full bleed, with no phone and no small type.
func searchResultsPage(_ c: Canvas) {
    let photo = "05-coastal-drive", film = "goldenHour"
    let r = CGRect(x: 0, y: 0, width: W, height: H)
    let split = W * 0.46
    c.fill(graded(photo, film), in: r)
    c.ctx.saveGState()
    c.ctx.clip(to: CGRect(x: 0, y: 0, width: split, height: H))
    c.fill(graded(photo, "original"), in: r)
    c.ctx.restoreGState()
    c.ctx.setFillColor(cream)
    c.ctx.fill(CGRect(x: split - 4, y: 0, width: 8, height: H))
    let hc = CGPoint(x: split, y: H / 2)
    c.ctx.saveGState()
    c.shadow(blur: 30, y: 10, alpha: 0.45)
    c.ctx.fillEllipse(in: CGRect(x: hc.x - 64, y: hc.y - 64, width: 128, height: 128))
    c.ctx.restoreGState()
    if let sym = symbolImage("chevron.left.chevron.right", sans(48, .bold), ink) {
        sym.draw(in: CGRect(x: hc.x - sym.size.width / 2, y: hc.y - sym.size.height / 2, width: sym.size.width, height: sym.size.height),
                 from: .zero, operation: .sourceOver, fraction: 1, respectFlipped: true, hints: nil)
    }
    let font = sans(46, .bold), pillH: CGFloat = 104
    let originalW = textWidth("ORIGINAL", font) + 64
    pill(c, "ORIGINAL", symbol: nil, center: CGPoint(x: 64 + originalW / 2, y: H - 64 - pillH / 2), font: font,
         fg: cream, bg: rgb(0x000000, 0.55), height: pillH)
    let filmLabel = stockName(film).uppercased()
    let filmW = textWidth(filmLabel, font) + 64
    pill(c, filmLabel, symbol: nil, center: CGPoint(x: W - 64 - filmW / 2, y: H - 64 - pillH / 2), font: font,
         fg: ink, bg: amber, height: pillH)
}

let searchPages: [(String, (Canvas) -> Void)] = [
    ("search-results", searchResultsPage),
]
