import Combine
import Foundation
import TumbleKit

@MainActor
final class EditDraftStore: ObservableObject {
    @Published private(set) var activeDraft: EditDraft?

    private let root: URL
    private let metadataURL: URL

    init(fileManager: FileManager = .default) {
        let applicationSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        root = applicationSupport.appendingPathComponent("TumbleDraft", isDirectory: true)
        metadataURL = root.appendingPathComponent("draft.json")
        try? fileManager.createDirectory(at: root, withIntermediateDirectories: true)
        Self.excludeFromBackup(root)
        activeDraft = Self.load(from: metadataURL)
        cleanupOrphans()
    }

    func create(imageData: Data, source: EditSourceKind, stockID: String) throws -> EditDraft {
        discard()
        let id = UUID()
        let sourceName = "\(id.uuidString)-source.jpg"
        let sourceURL = root.appendingPathComponent(sourceName)
        do {
            try imageData.write(to: sourceURL, options: [.atomic])
            Self.excludeFromBackup(sourceURL)
            let draft = EditDraft(
                id: id,
                sourceFile: sourceName,
                sourceKind: source,
                recipe: EditRecipe(stockID: stockID)
            )
            try persist(draft)
            activeDraft = draft
            return draft
        } catch {
            try? FileManager.default.removeItem(at: sourceURL)
            throw error
        }
    }

    func update(_ recipe: EditRecipe) {
        guard var draft = activeDraft else { return }
        draft.recipe = recipe
        draft.updatedAt = Date()
        try? persist(draft)
        activeDraft = draft
    }

    func sourceData(for draft: EditDraft) -> Data? {
        try? Data(contentsOf: root.appendingPathComponent(draft.sourceFile))
    }

    func discard() {
        if let activeDraft {
            try? FileManager.default.removeItem(at: root.appendingPathComponent(activeDraft.sourceFile))
        }
        try? FileManager.default.removeItem(at: metadataURL)
        activeDraft = nil
        cleanupOrphans()
    }

    private func persist(_ draft: EditDraft) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(draft)
        try data.write(to: metadataURL, options: [.atomic])
    }

    private static func load(from url: URL) -> EditDraft? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(EditDraft.self, from: data)
    }

    private static func excludeFromBackup(_ url: URL) {
        var mutableURL = url
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try? mutableURL.setResourceValues(values)
    }

    private func cleanupOrphans() {
        let keep = activeDraft?.sourceFile
        guard let files = try? FileManager.default.contentsOfDirectory(at: root, includingPropertiesForKeys: nil) else { return }
        for file in files where file.lastPathComponent != metadataURL.lastPathComponent && file.lastPathComponent != keep {
            try? FileManager.default.removeItem(at: file)
        }
    }
}
