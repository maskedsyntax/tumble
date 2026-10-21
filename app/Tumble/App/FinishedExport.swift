import SwiftUI
import TumbleKit
import UIKit

/// The file Finish saves or shares: the graded photo, mounted in its postcard
/// frame when it has one.
enum FinishedExport {
    @MainActor
    static func render(
        source: Data,
        recipe: EditRecipe,
        frame: PostcardFrameStyle,
        capturedAt: Date,
        seed: UInt64
    ) async -> Data? {
        var filmRecipe = recipe
        filmRecipe.frameID = PostcardFrameStyle.none.rawValue
        filmRecipe.note = ""
        let filmData = await Task.detached(priority: .userInitiated) {
            TumblePhotoFilter.renderEditedPhotoData(
                from: source,
                recipe: filmRecipe,
                capturedAt: capturedAt
            )
        }.value
        guard frame != .none, let filmData, let image = UIImage(data: filmData) else { return filmData }

        let hasNote = !recipe.note.isEmpty
        let width = frame.exportWidth(hasNote: hasNote)
        let content = PostcardFrameView(
            style: frame,
            image: image,
            note: hasNote ? recipe.note : nil,
            capturedAt: capturedAt,
            seed: seed,
            width: width
        )
        .frame(width: width, height: width * frame.renderAspect(hasNote: hasNote))
        .background(Color.white)
        let renderer = ImageRenderer(content: content)
        renderer.scale = 1
        return renderer.uiImage?.jpegData(compressionQuality: 0.92)
    }
}
