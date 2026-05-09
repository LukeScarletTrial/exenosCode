import SwiftUI
import SpriteKit

struct SpritePreviewView: View {
    let runtime: SpriteRuntime

    var body: some View {
        SpriteView(scene: runtime.scene)
            .ignoresSafeArea()
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
