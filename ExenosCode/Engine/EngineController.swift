import Foundation
import SwiftUI

class EngineController: ObservableObject {
    @Published var isRunning = false
    @Published var currentRenderer: RendererType = .twoD
    @Published var frameRate: Int = 60
    private var luaManager: LuaManager?
    private var timer: Timer?
    
    enum RendererType {
        case twoD
        case threeD
    }
    
    func start(project: Project) {
        guard !isRunning else { return }
        
        luaManager = LuaManager()
        
        let bundle = createBundle(from: project)
        if luaManager?.loadBundle(bundle) == true {
            luaManager?.callSetup()
            
            isRunning = true
            startRenderLoop()
        }
    }
    
    func stop() {
        isRunning = false
        timer?.invalidate()
        timer = nil
        luaManager = nil
    }
    
    private func startRenderLoop() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / Double(frameRate), repeats: true) { _ in
            self.luaManager?.callDraw()
        }
    }
    
    private func createBundle(from project: Project) -> LuaBundle {
        let transpiler = LuaZTranspiler()
        var files: [(name: String, content: String)] = []
        var mainFile = "main.luaz"
        
        for file in project.files where file.fileType == .luaz || file.fileType == .lua {
            let content: String
            if file.fileType == .luaz {
                let transpiled = transpiler.transpile(file.content)
                content = transpiled.luaCode
            } else {
                content = file.content
            }
            files.append((name: file.name, content: content))
            
            if file.name == "main.luaz" || file.name == "main.lua" {
                mainFile = file.name
            }
        }
        
        return LuaBundle(files: files, mainFile: mainFile)
    }
    
    func setRenderer(_ renderer: RendererType) {
        currentRenderer = renderer
    }
    
    func getVariable(_ name: String) -> LuaValue? {
        return luaManager?.getGlobal(name)
    }
    
    func setVariable(_ name: String, value: LuaValue) {
        luaManager?.setGlobal(name, value: value)
    }
}
