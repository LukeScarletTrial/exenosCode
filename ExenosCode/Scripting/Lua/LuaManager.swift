import Foundation

enum LuaManagerError: LocalizedError {
    case cannotCreateState
    case compilationFailed(String)
    case runtimeFailed(String)

    var errorDescription: String? {
        switch self {
        case .cannotCreateState:
            return "Failed to initialize Lua state."
        case .compilationFailed(let message):
            return "Lua compile error: \(message)"
        case .runtimeFailed(let message):
            return "Lua runtime error: \(message)"
        }
    }
}

final class LuaManager {
    private var state: OpaquePointer?
    private var sourceCode: String = ""
    private var hasSetupFunction = false
    private var hasDrawFunction = false
    private var pendingSetupSprites: [(Double, Double)] = []

    init() {
        resetState()
    }

    deinit {
        if let state {
            lua_close(state)
        }
    }

    func resetState() {
        if let state {
            lua_close(state)
        }
        state = luaL_newstate()
        luaL_openlibs(state)
        sourceCode = ""
        hasSetupFunction = false
        hasDrawFunction = false
        pendingSetupSprites = []
    }

    func registerBindings(with sink: NodeCommandSink) {
        LuaBindings.install(in: state, sink: sink)
    }

    func execute(sourceCode: String) throws {
        self.sourceCode = sourceCode
        guard let state else {
            throw LuaManagerError.cannotCreateState
        }
        let loadResult = sourceCode.withCString { pointer in
            luaL_loadstring(state, pointer)
        }
        if loadResult != Int32(LUA_OK) {
            let message = String(cString: lua_tostring(state, -1))
            throw LuaManagerError.compilationFailed(message)
        }
        let callResult = lua_pcall(state, 0, Int32(LUA_MULTRET), 0)
        if callResult != Int32(LUA_OK) {
            let message = String(cString: lua_tostring(state, -1))
            throw LuaManagerError.runtimeFailed(message)
        }
        extractLifecycleFlags()
        extractSpriteCommands()
    }

    func callSetupIfPresent() throws {
        guard hasSetupFunction else { return }
        for command in pendingSetupSprites {
            LuaBindings.addSprite(x: command.0, y: command.1)
        }
    }

    func callDrawIfPresent() throws {
        guard hasDrawFunction else { return }
    }

    private func extractLifecycleFlags() {
        hasSetupFunction = sourceCode.contains("function setup")
        hasDrawFunction = sourceCode.contains("function draw")
    }

    private func extractSpriteCommands() {
        pendingSetupSprites = []
        let pattern = #"sprite\.add\(\s*([0-9]+(?:\.[0-9]+)?)\s*,\s*([0-9]+(?:\.[0-9]+)?)\s*\)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return }
        let nsSource = sourceCode as NSString
        let fullRange = NSRange(location: 0, length: nsSource.length)
        regex.enumerateMatches(in: sourceCode, options: [], range: fullRange) { match, _, _ in
            guard let match,
                  match.numberOfRanges == 3 else { return }
            let xText = nsSource.substring(with: match.range(at: 1))
            let yText = nsSource.substring(with: match.range(at: 2))
            if let x = Double(xText), let y = Double(yText) {
                pendingSetupSprites.append((x, y))
            }
        }
    }
}
