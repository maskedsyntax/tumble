//
// Renders the stills the Remotion film needs: one photograph through every
// film stock the video shows, plus the ungraded original for before/after.
//
// The looks in the video are therefore the app's real looks - same catalog,
// same pipeline - rather than CSS approximations that drift the moment a
// grade is tuned.
//
//   ./scripts/render-video-looks.sh   (named *-main.swift: it runs top-level code)
//

import AppKit
import CoreImage
import Foundation

let repo = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let outDir = repo.appendingPathComponent("video/public/looks")
try? FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

/// Square, because every print in the app is square.
let side: CGFloat = 1000

struct Source {
    let slug: String
    let file: String
}

/// The hero photograph carries the look beats; the others fill the Drawer.
let sources: [Source] = [
    Source(slug: "hero", file: "mockups-appstore/assets/archive/04-city-sunset.jpg"),
    Source(slug: "trail", file: "mockups-appstore/assets/archive/01-autumn-trail.jpg"),
    Source(slug: "steps", file: "mockups-appstore/assets/archive/09-misty-steps.jpg"),
    Source(slug: "lake", file: "mockups-appstore/assets/archive/14-quiet-lake.jpg"),
    Source(slug: "cliff", file: "mockups-appstore/assets/archive/05-coastal-cliff.jpg"),
    Source(slug: "road", file: "mockups-appstore/assets/archive/10-himalayan-road.jpg"),
    Source(slug: "foam", file: "mockups-appstore/assets/archive/12-ocean-foam.jpg"),
    Source(slug: "snow", file: "mockups-appstore/assets/archive/18-snowy-hills.jpg"),
]

/// Every stock the film cycles through, in the order it shows them.
let heroStocks = [
    "original", "fadedInstant", "warmArchive", "disposable", "flashNight",
    "silver", "charcoal", "sepiaPrint", "goldenHour", "lightLeak",
    "crossProcess", "camcorder", "overcast", "sunbleached", "hazy",
    "dateStamp", "poolParty", "platinum", "newsprint", "fogged", "everyday",
]

/// Stocks used for the supporting prints, one each.
let supporting: [String: String] = [
    "trail": "fadedInstant",
    "steps": "overcast",
    "lake": "sepiaPrint",
    "cliff": "goldenHour",
    "road": "warmArchive",
    "foam": "silver",
    "snow": "sunbleached",
]

func squareCrop(_ image: CIImage) -> CIImage {
    let e = image.extent
    let s = min(e.width, e.height)
    let crop = image.cropped(to: CGRect(x: e.midX - s / 2, y: e.midY - s / 2, width: s, height: s))
    let scaled = crop
        .transformed(by: CGAffineTransform(translationX: -crop.extent.origin.x, y: -crop.extent.origin.y))
        .transformed(by: CGAffineTransform(scaleX: side / s, y: side / s))
    return scaled
}

func write(_ image: CIImage, to url: URL) {
    guard let cg = ciContext.createCGImage(image, from: image.extent) else { return }
    let rep = NSBitmapImageRep(cgImage: cg)
    guard let data = rep.representation(using: .jpeg, properties: [.compressionFactor: 0.92]) else { return }
    try? data.write(to: url)
}

var written = 0
for source in sources {
    guard let raw = CIImage(contentsOf: repo.appendingPathComponent(source.file)) else {
        FileHandle.standardError.write("missing \(source.file)\n".data(using: .utf8)!)
        continue
    }
    let square = squareCrop(raw)

    if source.slug == "hero" {
        for id in heroStocks {
            let stock = FilmStockCatalog.resolve(id)
            let graded = applyGrade(stock.grade, to: square)
            write(graded, to: outDir.appendingPathComponent("hero-\(id).jpg"))
            written += 1
        }
    } else if let id = supporting[source.slug] {
        let graded = applyGrade(FilmStockCatalog.resolve(id).grade, to: square)
        write(graded, to: outDir.appendingPathComponent("\(source.slug).jpg"))
        written += 1
    }
}

FileHandle.standardOutput.write("Wrote \(written) stills to video/public/looks\n".data(using: .utf8)!)
