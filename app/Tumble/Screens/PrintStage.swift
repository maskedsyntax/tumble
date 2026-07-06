import SwiftUI
import TumbleKit

/// Routes a tapped print to the right full-screen stage: undeveloped shots go
/// to the develop table; developed ones open in detail where you can riffle
/// through the rest of the pile.
struct PrintStage: View {
    let photo: Photo
    let developed: [Photo]

    var body: some View {
        if photo.isDeveloped {
            PrintDetailView(developed: developed, start: photo)
        } else {
            DevelopView(photo: photo)
        }
    }
}
