import Foundation

protocol NodeCommandSink: AnyObject {
    func addSprite(x: Double, y: Double)
}

protocol RenderRuntime: AnyObject, NodeCommandSink {
    func startTicking(_ tick: @escaping () -> Void)
    func stopTicking()
    func resetScene()
}
