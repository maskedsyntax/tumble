import Testing
import CoreVideo
import CoreImage
import SwiftUI
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

    @Test @MainActor func everyFilmRendersAtFullAndReducedIntensityForQACorpus() {
        let capturedAt = Date(timeIntervalSince1970: 1_757_865_600)
        for scene in FilmScene.allCases {
            let source = scene.image(size: 96).jpegData(compressionQuality: 0.9)!
            for stock in FilmStockCatalog.all {
                for intensity in [0.6, 1.0] {
                    let data = TumblePhotoFilter.renderEditedPhotoData(
                        from: source,
                        recipe: EditRecipe(stockID: stock.id, intensity: intensity),
                        capturedAt: capturedAt,
                        maxDimension: 96
                    )
                    #expect(data != nil, "\(scene) / \(stock.id) / \(intensity) failed")
                }
            }
        }
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

    @Test @MainActor func previewRendererCachesByPhotoAndStock() async {
        let source = sampleData(CGSize(width: 400, height: 400))
        let renderer = FilmPreviewRenderer(capacity: 8)
        let id = UUID()
        let stock = FilmStockCatalog.resolve("goldenHour")

        let first = await renderer.preview(photoID: id, stock: stock, source: source, maxDimension: 120)
        // A cache hit must not need the source at all.
        let second = await renderer.preview(
            photoID: id,
            stock: stock,
            source: nil,
            maxDimension: 120
        )

        #expect(first != nil)
        #expect(second === first)
    }

    @Test @MainActor func thumbnailRepositoryDownsamplesAndCachesBySize() async throws {
        let source = sampleData(CGSize(width: 600, height: 400))
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("tumble-thumbnail-\(UUID().uuidString).jpg")
        try source.write(to: url, options: .atomic)
        defer { try? FileManager.default.removeItem(at: url) }

        let repository = PhotoThumbnailRepository(countLimit: 4)
        let first = await repository.image(at: url, cacheKey: url.lastPathComponent, maxPixelSize: 120)
        #expect(first != nil)
        #expect(max(first?.size.width ?? 0, first?.size.height ?? 0) <= 120)

        let cached = await repository.image(at: url, cacheKey: url.lastPathComponent, maxPixelSize: 120)
        #expect(cached === first)
        let differentSize = await repository.image(at: url, cacheKey: url.lastPathComponent, maxPixelSize: 80)
        #expect(differentSize != nil)
        #expect(differentSize !== first)
        #expect(max(differentSize?.size.width ?? 0, differentSize?.size.height ?? 0) <= 80)
    }

    @Test @MainActor func editIntensityEndpointsMatchOriginalAndFilm() {
        let source = sampleData(CGSize(width: 320, height: 220))
        let originalRecipe = EditRecipe(stockID: "crossProcess", intensity: 0)
        let filmRecipe = EditRecipe(stockID: "crossProcess", intensity: 1)
        let original = TumblePhotoFilter.renderEditedPhotoData(from: source, recipe: originalRecipe, capturedAt: .now)
        let film = TumblePhotoFilter.renderEditedPhotoData(from: source, recipe: filmRecipe, capturedAt: .now)
        #expect(original != nil)
        #expect(film != nil)
        #expect(original != film)
    }

    @Test @MainActor func cropRotationAndExportCapUseSharedOrder() {
        let source = sampleData(CGSize(width: 1800, height: 1200))
        let recipe = EditRecipe(stockID: "everyday", cropPreset: .portrait, quarterTurns: 1)
        let data = TumblePhotoFilter.renderEditedPhotoData(from: source, recipe: recipe, capturedAt: .now, maxDimension: 512)
        let image = data.flatMap(UIImage.init(data:))
        #expect(image != nil)
        if let image {
            #expect(max(image.size.width, image.size.height) <= 512)
            #expect(abs(image.size.width / image.size.height - 0.8) < 0.03)
        }
    }

    /// Pixel size of encoded sample data (the renderer draws at screen scale).
    private func pixelSize(_ data: Data) -> CGSize {
        CIImage(data: data)?.extent.size ?? .zero
    }

    @Test @MainActor func unstraightenedFullCropKeepsTheSourceSize() {
        let source = sampleData(CGSize(width: 600, height: 400))
        let data = TumblePhotoFilter.renderEditedPhotoData(
            from: source, recipe: EditRecipe(stockID: "everyday"), capturedAt: .now, maxDimension: 10_000
        )
        let image = data.flatMap(UIImage.init(data:))
        #expect(image?.size == pixelSize(source))
    }

    @Test @MainActor func straightenKeepsAspectAndInscribedSize() {
        let source = sampleData(CGSize(width: 600, height: 400))
        let size = pixelSize(source)
        let recipe = EditRecipe(stockID: "everyday", straighten: 10)
        let data = TumblePhotoFilter.renderEditedPhotoData(from: source, recipe: recipe, capturedAt: .now, maxDimension: 10_000)
        let image = data.flatMap(UIImage.init(data:))
        let scale = CropGeometry.inscribedScale(width: size.width, height: size.height, degrees: 10)
        #expect(image != nil)
        if let image {
            #expect(abs(image.size.width - size.width * scale) <= 4)
            #expect(abs(image.size.height - size.height * scale) <= 4)
        }
    }

    @Test @MainActor func offCenterAspectCropKeepsItsAspect() {
        let source = sampleData(CGSize(width: 1800, height: 1200))
        var crop = CropGeometry.centeredCrop(aspect: 0.8, imageAspect: 1.5)
        crop.x = 0
        let recipe = EditRecipe(stockID: "everyday", cropPreset: .portrait, crop: crop, straighten: -4)
        let data = TumblePhotoFilter.renderEditedPhotoData(from: source, recipe: recipe, capturedAt: .now, maxDimension: 4096)
        let image = data.flatMap(UIImage.init(data:))
        #expect(image != nil)
        if let image {
            #expect(abs(image.size.width / image.size.height - 0.8) < 0.01)
        }
    }

    @Test @MainActor func previewAndExportShareGeometry() {
        let source = sampleData(CGSize(width: 1800, height: 1200))
        var crop = CropGeometry.centeredCrop(aspect: 1, imageAspect: 1.5)
        crop.x = 0.05
        let recipe = EditRecipe(stockID: "everyday", cropPreset: .square, crop: crop, quarterTurns: 1, straighten: 6)
        let export = TumblePhotoFilter.renderEditedPhotoData(from: source, recipe: recipe, capturedAt: .now, maxDimension: 900)
            .flatMap(UIImage.init(data:))
        let preview = TumblePhotoFilter.renderEditedPreview(from: source, recipe: recipe, capturedAt: .now, maxDimension: 900)
        #expect(export != nil && preview != nil)
        if let export, let preview {
            #expect(abs(export.size.width / export.size.height - preview.size.width / preview.size.height) < 0.01)
        }
    }

    @Test @MainActor func secondaryTextMeetsContrastOnEveryDarkSurface() {
        func luminance(_ color: UIColor) -> Double {
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            color.getRed(&r, green: &g, blue: &b, alpha: &a)
            func channel(_ c: CGFloat) -> Double {
                let v = Double(c)
                return v <= 0.03928 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4)
            }
            return 0.2126 * channel(r) + 0.7152 * channel(g) + 0.0722 * channel(b)
        }
        func composite(_ fg: UIColor, alpha: Double, over bg: UIColor) -> UIColor {
            var fr: CGFloat = 0, fgc: CGFloat = 0, fb: CGFloat = 0, fa: CGFloat = 0
            var br: CGFloat = 0, bgc: CGFloat = 0, bb: CGFloat = 0, ba: CGFloat = 0
            fg.getRed(&fr, green: &fgc, blue: &fb, alpha: &fa)
            bg.getRed(&br, green: &bgc, blue: &bb, alpha: &ba)
            let a = CGFloat(alpha)
            return UIColor(red: fr * a + br * (1 - a), green: fgc * a + bgc * (1 - a), blue: fb * a + bb * (1 - a), alpha: 1)
        }
        func contrast(_ a: UIColor, _ b: UIColor) -> Double {
            let la = luminance(a), lb = luminance(b)
            return (max(la, lb) + 0.05) / (min(la, lb) + 0.05)
        }
        let cream = UIColor(Palette.cream)
        for surface in [Palette.canvas, Palette.surface, Palette.surfaceRaised, Palette.blueDeep, Palette.blue] {
            let bg = UIColor(surface)
            #expect(contrast(composite(cream, alpha: Palette.textSecondaryOpacity, over: bg), bg) >= 4.5)
            #expect(contrast(composite(cream, alpha: Palette.textTertiaryOpacity, over: bg), bg) >= 3.0)
        }
    }

    @Test func adaptiveFrameRateFallsBackAndRecoversWithHeadroom() {
        var policy = AdaptiveFrameRatePolicy()
        #expect(policy.targetFPS == 60)

        var change: Int?
        for index in 0..<30 {
            change = policy.record(
                renderDuration: index < 8 ? 0.024 : 0.010,
                thermallyConstrained: false
            ) ?? change
        }
        #expect(change == 30)
        #expect(policy.targetFPS == 30)

        change = nil
        for _ in 0..<300 {
            change = policy.record(renderDuration: 0.010, thermallyConstrained: false) ?? change
        }
        #expect(change == 60)
        #expect(policy.targetFPS == 60)
    }

    @Test func adaptiveFrameRateImmediatelyHonorsThermalPressure() {
        var policy = AdaptiveFrameRatePolicy()
        #expect(policy.record(renderDuration: 0.008, thermallyConstrained: true) == 30)
        #expect(policy.targetFPS == 30)
        #expect(policy.record(renderDuration: 0.008, thermallyConstrained: true) == nil)
    }

    @Test func latestFrameMailboxNeverBuildsABacklog() {
        var mailbox = LatestValueMailbox<Int>()
        let initialSchedule = mailbox.submit(1)
        let replacementSchedule = mailbox.submit(2)
        #expect(initialSchedule)
        #expect(!replacementSchedule)
        let first = mailbox.take()
        #expect(first == 2)

        // A value arriving while the consumer is active replaces the pending
        // slot and does not schedule a competing consumer.
        let inFlightSchedule = mailbox.submit(3)
        let newestSchedule = mailbox.submit(4)
        #expect(!inFlightSchedule)
        #expect(!newestSchedule)
        let newest = mailbox.take()
        let drained = mailbox.take()
        #expect(newest == 4)
        #expect(drained == nil)

        // Once drained, the next frame schedules a new consumer.
        let restartSchedule = mailbox.submit(5)
        #expect(restartSchedule)
        let restarted = mailbox.take()
        #expect(restarted == 5)
    }

    @Test func livePreviewMirroringAndAspectFillPreserveDisplayGeometry() {
        let sourceExtent = CGRect(x: 10, y: 20, width: 120, height: 80)
        let source = CIImage(color: .red).cropped(to: sourceExtent)
        let mirrored = LivePreviewGeometry.mirroredHorizontally(source)
        #expect(mirrored.extent == sourceExtent)

        let displayBounds = CGRect(x: 0, y: 0, width: 180, height: 320)
        let filled = LivePreviewGeometry.aspectFill(mirrored, into: displayBounds)
        #expect(filled.extent == displayBounds)
    }

    @Test func everyCatalogStockBuildsALivePreviewGraph() throws {
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            96,
            128,
            kCVPixelFormatType_32BGRA,
            [kCVPixelBufferIOSurfacePropertiesKey: [:]] as CFDictionary,
            &pixelBuffer
        )
        #expect(status == kCVReturnSuccess)
        let buffer = try #require(pixelBuffer)
        CVPixelBufferLockBaseAddress(buffer, [])
        if let base = CVPixelBufferGetBaseAddress(buffer) {
            memset(base, 127, CVPixelBufferGetDataSize(buffer))
        }
        CVPixelBufferUnlockBaseAddress(buffer, [])

        for stock in FilmStockCatalog.all {
            let output = TumblePhotoFilter.livePreviewImage(
                from: buffer,
                stock: stock,
                maxDimension: 96
            )
            #expect(!output.extent.isEmpty, "\(stock.id) produced an empty live preview")
            #expect(output.extent.width <= 96)
        }
    }
}
