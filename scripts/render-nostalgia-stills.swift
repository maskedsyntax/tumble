import AppKit
import CoreImage
import Foundation
import UniformTypeIdentifiers

@main
enum NostalgiaStills {
    static func writeJPEG(_ image: CIImage, to url: URL) throws {
        let extent = image.extent.integral
        guard let cgImage = ciContext.createCGImage(image, from: extent),
              let destination = CGImageDestinationCreateWithURL(
                  url as CFURL,
                  UTType.jpeg.identifier as CFString,
                  1,
                  nil
              ) else {
            throw NSError(domain: "NostalgiaStills", code: 1)
        }
        CGImageDestinationAddImage(destination, cgImage, [
            kCGImageDestinationLossyCompressionQuality: 0.94,
        ] as CFDictionary)
        guard CGImageDestinationFinalize(destination) else {
            throw NSError(domain: "NostalgiaStills", code: 2)
        }
    }

    static func main() throws {
        guard CommandLine.arguments.count == 3 else {
            fputs("usage: render-nostalgia-stills <raw-dir> <output-dir>\n", stderr)
            exit(64)
        }

        let fileManager = FileManager.default
        let rawDirectory = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
        let outputDirectory = URL(fileURLWithPath: CommandLine.arguments[2], isDirectory: true)
        try fileManager.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

        let sourceURLs = try fileManager.contentsOfDirectory(
            at: rawDirectory,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ).filter { ["jpg", "jpeg", "png"].contains($0.pathExtension.lowercased()) }
         .sorted { $0.lastPathComponent < $1.lastPathComponent }

        for sourceURL in sourceURLs {
            guard let original = CIImage(contentsOf: sourceURL, options: [.applyOrientationProperty: true]) else {
                fputs("skip unreadable image: \(sourceURL.path)\n", stderr)
                continue
            }

            let stem = sourceURL.deletingPathExtension().lastPathComponent
            let originalURL = outputDirectory.appendingPathComponent("\(stem)--original.jpg")
            try writeJPEG(applyGrade(.identity, to: original), to: originalURL)

            for stock in FilmStockCatalog.all where !stock.grade.isIdentity {
                let url = outputDirectory.appendingPathComponent("\(stem)--\(stock.id).jpg")
                try writeJPEG(applyGrade(stock.grade, to: original), to: url)
            }
        }

        print("Rendered \(sourceURLs.count) sources through \(FilmStockCatalog.all.count - 1) film looks.")
    }
}
