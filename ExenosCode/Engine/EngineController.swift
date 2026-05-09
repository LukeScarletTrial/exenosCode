import Foundation

final class EngineController {
    private(set) var state: EngineState = .stopped
    private let luaManager: LuaManager
    private var runtime: RenderRuntime?
    private var hasRunSetup = false

    init(luaManager: LuaManager) {
        self.luaManager = luaManager
    }

    func attachRuntime(_ runtime: RenderRuntime) {
        self.runtime = runtime
    }

    func start() {
        guard let runtime else { return }
        state = .running
        hasRunSetup = false
        runtime.startTicking { [weak self] in
            self?.frameTick()
        }
    }

    func pause() {
        guard state == .running else { return }
        state = .paused
    }

    func resume() {
        guard state == .paused else { return }
        state = .running
    }

    func stop() {
        runtime?.stopTicking()
        state = .stopped
        hasRunSetup = false
    }

    private func frameTick() {
        guard state == .running else { return }
        do {
            if !hasRunSetup {
                try luaManager.callSetupIfPresent()
                hasRunSetup = true
            }
            try luaManager.callDrawIfPresent()
        } catch {
            stop()
        }
    }
}
