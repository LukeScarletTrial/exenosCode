import Foundation

class LuaManager {
    private var luaState: OpaquePointer?
    private let transpiler = LuaZTranspiler()
    
    init() {
        initializeLua()
    }
    
    deinit {
        closeLua()
    }
    
    private func initializeLua() {
        
    }
    
    private func closeLua() {
        
    }
    
    func loadBundle(_ bundle: LuaBundle) -> Bool {
        for file in bundle.files {
            let transpiled = transpiler.transpile(file.content)
            
            if !loadString(transpiled.luaCode, filename: file.name) {
                return false
            }
        }
        
        return true
    }
    
    func loadString(_ code: String, filename: String) -> Bool {
        return true
    }
    
    func callSetup() -> Bool {
        return true
    }
    
    func callDraw() -> Bool {
        return true
    }
    
    func getGlobal(_ name: String) -> LuaValue? {
        return nil
    }
    
    func setGlobal(_ name: String, value: LuaValue) {
        
    }
    
    func getError() -> String? {
        return nil
    }
}

struct LuaBundle {
    let files: [(name: String, content: String)]
    let mainFile: String
}

enum LuaValue {
    case `nil`
    case bool(Bool)
    case number(Double)
    case string(String)
    case table([String: LuaValue])
    case function
}
