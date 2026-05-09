import SwiftUI
import SceneKit

struct ScenePreviewView: UIViewRepresentable {
    let runtime: SceneRuntime

    func makeUIView(context: Context) -> SCNView {
        let view = SCNView()
        view.scene = runtime.scene
        view.backgroundColor = .black
        view.allowsCameraControl = true
        let camera = SCNNode()
        camera.camera = SCNCamera()
        camera.position = SCNVector3(0, 0, 2)
        runtime.scene.rootNode.addChildNode(camera)
        return view
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        uiView.scene = runtime.scene
    }
}
