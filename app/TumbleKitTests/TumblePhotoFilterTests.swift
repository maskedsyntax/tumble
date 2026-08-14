import Testing
import UIKit
@testable import TumbleKit

struct TumblePhotoFilterTests {
    /// A colourful test frame with distinct shapes, so grade differences show up
    /// as different bytes rather than washing out on a flat fill.
    @MainActor private func sampleData(_ size: CGSize = CGSize(width: 600, height: 600)) -> Data {
        let image = UIGraphicsImageRenderer(size: size).image { ctx in
            let colors = [UIColor(red: 0.55, green: 0.72, blue: 0.88, alpha: 1).cgColor,
                          UIColor(red: 0.20, green: 0.35, blue: 0.45, alpha: 1).cgColor]
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: nil)!
            ctx.cgContext.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: 0, y: size.height), options: [])
            UIColor(red: 0.85, green: 0.35, blue: 0.30, alpha: 1).setFill()
            ctx.cgContext.fill(CGRect(x: 60, y: 380, width: 180, height: 180))
            UIColor(red: 0.95, green: 0.80, blue: 0.45, alpha: 1).setFill()
            ctx.cgContext.fillEllipse(in: CGRect(x: 380, y: 120, width: 140, height: 140))
            UIColor(red: 0.30, green: 0.55, blue: 0.35, alpha: 1).setFill()
            ctx.cgContext.fill(CGRect(x: 360, y: 400, width: 180, height: 160))
        }
        return image.jpegData(compressionQuality: 0.92)!
    }

    // MARK: Catalog rendering

    @Test @MainActor func rendersEveryCatalogStock() {
        let source = sampleData(CGSize(width: 80, height: 48))
        for stock in FilmStockCatalog.all {
            let output = TumblePhotoFilter.renderMemoryPhotoData(
                from: source, grade: stock.grade, capturedAt: Date()
            )
            #expect(output != nil, "\(stock.id) failed to render")
            let rendered = output.flatMap(UIImage.init(data:))
            #expect(rendered != nil)
            if let rendered {
                // Aspect ratio is preserved.
                #expect(abs((rendered.size.width / rendered.size.height) - (80.0 / 48.0)) < 0.05)
            }
        }
    }

    @Test @MainActor func distinctStocksProduceDistinctPixels() {
        let source = sampleData()
        // A spread that exercises colour, monochrome, split-tone and leaks.
        let ids = ["original", "fadedInstant", "warmArchive", "silver", "crossProcess", "lightLeak"]
        let outputs = ids.compactMap { id -> Data? in
            let stock = FilmStockCatalog.resolve(id)
            return TumblePhotoFilter.renderMemoryPhotoData(from: source, grade: stock.grade)
        }
        #expect(outputs.count == ids.count)
        #expect(Set(outputs.map(\.hashValue)).count == ids.count)
    }

    @Test @MainActor func dateStampChangesTheImage() {
        let source = sampleData()
        let stock = FilmStockCatalog.resolve("dateStamp")
        let stamped = TumblePhotoFilter.renderMemoryPhotoData(from: source, grade: stock.grade, capturedAt: Date())
        // Same grade, no date supplied: the stamp stage is skipped, so bytes differ.
        let unstamped = TumblePhotoFilter.renderMemoryPhotoData(from: source, grade: stock.grade, capturedAt: nil)
        #expect(stamped != nil && unstamped != nil)
        #expect(stamped != unstamped)
    }

    // MARK: Legacy delegation

    @Test @MainActor func legacyPresetMatchesResolvedStockGrade() {
        let source = sampleData()
        for preset in TumbleMemoryFilterPreset.allCases {
            let viaPreset = TumblePhotoFilter.renderMemoryPhotoData(from: source, preset: preset)
            let viaGrade = TumblePhotoFilter.renderMemoryPhotoData(from: source, grade: preset.stock.grade)
            #expect(viaPreset == viaGrade, "\(preset.rawValue) preset drifted from its catalog grade")
        }
    }

    // MARK: Preview path

    @Test @MainActor func previewIsDownscaledToMaxDimension() {
        let source = sampleData(CGSize(width: 1200, height: 800))
        let preview = TumblePhotoFilter.renderPreviewImage(
            from: source, grade: FilmStockCatalog.resolve("everyday").grade, maxDimension: 240
        )
        #expect(preview != nil)
        if let preview {
            #expect(max(preview.size.width, preview.size.height) <= 242)
            // Aspect ratio survives the downscale.
            #expect(abs((preview.size.width / preview.size.height) - 1.5) < 0.05)
        }
    }

    @Test @MainActor func previewRendererCachesByPhotoAndStock() {
        let source = sampleData(CGSize(width: 400, height: 400))
        let renderer = FilmPreviewRenderer(capacity: 8)
        let id = UUID()
        let stock = FilmStockCatalog.resolve("goldenHour")

        let first = renderer.preview(photoID: id, stock: stock, source: source, maxDimension: 120)
        // A cache hit must not need the source at all.
        let second = renderer.preview(photoID: id, stock: stock, source: { () -> Data? in
            Issue.record("source read on a cache hit")
            return nil
        }(), maxDimension: 120)

        #expect(first != nil)
        #expect(second === first)
    }
}
