import Foundation
import SceneKit
import QuartzCore

final class SceneRuntime: NSObject, RenderRuntime {
    let scene: SCNScene
    private var displayLink: CADisplayLink?
    private var tickClosure: (() -> Void)?

    override init() {
        scene = SCNScene()
        super.init()
    }

    func startTicking(_ tick: @escaping () -> Void) {
        tickClosure = tick
        stopTicking()
        let link = CADisplayLink(target: self, selector: #selector(onFrame))
        if #available(iOS 15.0, *) {
            link.preferredFrameRateRange = CAFrameRateRange(minimum: 60, maximum: 60, preferred: 60)
        } else {
            link.preferredFramesPerSecond = 60
        }
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    func stopTicking() {
        displayLink?.invalidate()
        displayLink = nil
    }

    func resetScene() {
        scene.rootNode.childNodes.forEach { $0.removeFromParentNode() }
    }

    func addSprite(x: Double, y: Double) {
        let geometry = SCNPlane(width: 0.1, height: 0.1)
        geometry.firstMaterial?.diffuse.contents = UIColor.white
        let node = SCNNode(geometry: geometry)
        node.position = SCNVector3(Float(x / 100.0), Float(y / 100.0), 0)
        scene.rootNode.addChildNode(node)
    }

    @objc private func onFrame() {
        tickClosure?()
    }
}
