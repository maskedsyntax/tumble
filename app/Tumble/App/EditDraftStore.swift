import Combine
import Foundation
import TumbleKit

@MainActor
final class EditDraftStore: ObservableObject {
    @Published private(set) var activeDraft: EditDraft?

    private let root: URL
    private let metadataURL: URL
    private let fileIO = DraftFileIO()
    private var persistTask: Task<Void, Never>?

    init(fileManager: FileManager = .default, rootOverride: URL? = nil) {
        let applicationSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        root = rootOverride ?? applicationSupport.appendingPathComponent("TumbleDraft", isDirectory: true)
        metadataURL = root.appendingPathComponent("draft.json")
        try? fileManager.createDirectory(at: root, withIntermediateDirectories: true)
        Self.excludeFromBackup(root)
        activeDraft = Self.load(from: metadataURL)
        cleanupOrphans()
    }

    func create(imageData: Data, source: EditSourceKind, stockID: String) async throws -> EditDraft {
        try await create(imageData: imageData, source: source, recipe: EditRecipe(stockID: stockID))
    }

    /// Replaces the active draft transactionally: the new source and metadata
    /// are durable before the old source is removed. A failed import therefore
    /// leaves the recoverable draft untouched.
    func create(imageData: Data, source: EditSourceKind, recipe: EditRecipe) async throws -> EditDraft {
        guard !imageData.isEmpty else { throw DraftCreationError.emptySource }
        persistTask?.cancel()
        persistTask = nil
        let previousDraft = activeDraft
        let id = UUID()
        let sourceName = "\(id.uuidString)-source.jpg"
        let sourceURL = root.appendingPathComponent(sourceName)
        do {
            try await fileIO.write(imageData, to: sourceURL)
            Self.excludeFromBackup(sourceURL)
            let draft = EditDraft(
                id: id,
                sourceFile: sourceName,
                sourceKind: source,
                recipe: recipe
            )
            try await fileIO.persist(draft, to: metadataURL)
            activeDraft = draft
            if let previousDraft, previousDraft.sourceFile != sourceName {
                await fileIO.removeSource(root.appendingPathComponent(previousDraft.sourceFile))
            }
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
        activeDraft = draft
        persistTask?.cancel()
        let fileIO = fileIO
        let metadataURL = metadataURL
        persistTask = Task {
            try? await Task.sleep(for: .milliseconds(250))
            guard !Task.isCancelled else { return }
            try? await fileIO.persist(draft, to: metadataURL)
        }
    }

    func sourceData(for draft: EditDraft) async -> Data? {
        await fileIO.data(at: root.appendingPathComponent(draft.sourceFile))
    }

    func flush() async {
        persistTask?.cancel()
        persistTask = nil
        guard let activeDraft else { return }
        try? await fileIO.persist(activeDraft, to: metadataURL)
    }

    func discard() async {
        persistTask?.cancel()
        persistTask = nil
        let sourceURL = activeDraft.map { root.appendingPathComponent($0.sourceFile) }
        activeDraft = nil
        await fileIO.discard(sourceURL: sourceURL, metadataURL: metadataURL, root: root)
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

enum DraftCreationError: Error {
    case emptySource
}

private actor DraftFileIO {
    func write(_ data: Data, to url: URL) throws {
        try data.write(to: url, options: [.atomic])
    }

    func data(at url: URL) -> Data? {
        try? Data(contentsOf: url, options: [.mappedIfSafe])
    }

    func persist(_ draft: EditDraft, to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        try encoder.encode(draft).write(to: url, options: [.atomic])
    }

    func removeSource(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }

    func discard(sourceURL: URL?, metadataURL: URL, root: URL) {
        if let sourceURL { try? FileManager.default.removeItem(at: sourceURL) }
        try? FileManager.default.removeItem(at: metadataURL)
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: root,
            includingPropertiesForKeys: nil
        ) else { return }
        for file in files where file.lastPathComponent != metadataURL.lastPathComponent {
            try? FileManager.default.removeItem(at: file)
        }
    }
}
