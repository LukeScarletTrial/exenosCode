import Foundation
import SpriteKit
import QuartzCore

final class SpriteRuntime: NSObject, RenderRuntime {
    let scene: SpriteScene
    private var displayLink: CADisplayLink?
    private var tickClosure: (() -> Void)?

    override init() {
        scene = SpriteScene(size: CGSize(width: 1024, height: 768))
        scene.scaleMode = .resizeFill
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
        scene.removeAllChildren()
    }

    func addSprite(x: Double, y: Double) {
        let node = SKSpriteNode(color: .white, size: CGSize(width: 48, height: 48))
        node.position = CGPoint(x: x, y: y)
        scene.addChild(node)
    }

    @objc private func onFrame() {
        tickClosure?()
    }
}
