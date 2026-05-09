import Foundation

final class AppModel: ObservableObject {
    @Published var sourceCode: String = """
    function setup()
        sprite.add(180, 240)
    end

    function draw()
    end
    """
    @Published var selectedRenderer: RendererKind = .spriteKit2D
    @Published var engineState: EngineState = .stopped
    @Published var consoleOutput: String = ""

    let spriteRuntime = SpriteRuntime()
    let sceneRuntime = SceneRuntime()
    let luaManager: LuaManager
    let engineController: EngineController

    init() {
        luaManager = LuaManager()
        engineController = EngineController(luaManager: luaManager)
        engineController.attachRuntime(spriteRuntime)
        luaManager.registerBindings(with: spriteRuntime)
    }

    func runCode() {
        engineController.stop()
        spriteRuntime.resetScene()
        luaManager.resetState()
        luaManager.registerBindings(with: spriteRuntime)
        do {
            try luaManager.execute(sourceCode: sourceCode)
            engineController.attachRuntime(selectedRenderer == .spriteKit2D ? spriteRuntime : sceneRuntime)
            engineController.start()
            engineState = .running
            consoleOutput = "Running"
        } catch {
            consoleOutput = error.localizedDescription
            engineState = .stopped
        }
    }

    func pauseOrResume() {
        switch engineController.state {
        case .running:
            engineController.pause()
            engineState = .paused
        case .paused:
            engineController.resume()
            engineState = .running
        case .stopped:
            break
        }
    }

    func stop() {
        engineController.stop()
        engineState = .stopped
        consoleOutput = "Stopped"
    }
}

enum RendererKind: String, CaseIterable, Identifiable {
    case spriteKit2D = "2D"
    case sceneKit3D = "3D"

    var id: String { rawValue }
}
