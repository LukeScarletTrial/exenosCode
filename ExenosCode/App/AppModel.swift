import Foundation

final class AppModel: ObservableObject {
    @Published var sourceCode: String = "" {
        didSet {
            guard !isLoadingFile, let selectedFilePath else { return }
            updateDocument(path: selectedFilePath, content: sourceCode)
            refreshAutocomplete()
        }
    }
    @Published var selectedRenderer: RendererKind = .spriteKit2D
    @Published var engineState: EngineState = .stopped
    @Published var consoleOutput: String = ""
    @Published var projects: [ProjectModel] = []
    @Published var selectedProjectID: UUID?
    @Published var selectedFilePath: String?
    @Published var autocompleteOptions: [String] = []

    let spriteRuntime = SpriteRuntime()
    let sceneRuntime = SceneRuntime()
    let luaManager: LuaManager
    let engineController: EngineController
    private var isLoadingFile = false
    private let autocompleteDictionary: [String] = [
        "function", "end", "if", "then", "else", "elseif", "for", "while", "repeat", "until",
        "local", "return", "math.sin", "math.cos", "math.random", "sprite.add", "setup", "draw"
    ]

    init() {
        luaManager = LuaManager()
        engineController = EngineController(luaManager: luaManager)
        engineController.attachRuntime(spriteRuntime)
        luaManager.registerBindings(with: spriteRuntime)
        projects = ProjectModel.defaultProjects()
        selectedProjectID = nil
        selectedFilePath = nil
        refreshAutocomplete()
    }

    var selectedProject: ProjectModel? {
        guard let selectedProjectID else { return nil }
        return projects.first { $0.id == selectedProjectID }
    }

    var selectedFile: ProjectFileModel? {
        guard let project = selectedProject, let selectedFilePath else { return nil }
        return project.file(at: selectedFilePath)
    }

    var selectedFileIsLua: Bool {
        selectedFile?.kind == .lua
    }

    func openProject(_ projectID: UUID) {
        selectedProjectID = projectID
        guard let project = selectedProject else { return }
        selectedFilePath = project.mainScriptPath
        loadSelectedFileIntoEditor()
    }

    func createProject() {
        let index = projects.count + 1
        let project = ProjectModel.template(named: "Game Project \(index)")
        projects.append(project)
        openProject(project.id)
    }

    func selectFile(path: String) {
        selectedFilePath = path
        loadSelectedFileIntoEditor()
    }

    func runCode() {
        guard let project = selectedProject else { return }
        let runtimeSource = project.documents[project.mainScriptPath] ?? ""
        engineController.stop()
        spriteRuntime.resetScene()
        luaManager.resetState()
        luaManager.registerBindings(with: spriteRuntime)
        do {
            try luaManager.execute(sourceCode: runtimeSource)
            engineController.attachRuntime(selectedRenderer == .spriteKit2D ? spriteRuntime : sceneRuntime)
            engineController.start()
            engineState = .running
            consoleOutput = "Running \(project.name)"
        } catch {
            consoleOutput = error.localizedDescription
            engineState = .stopped
        }
    }

    func applyAutocomplete(_ completion: String) {
        let token = trailingToken(in: sourceCode)
        guard !token.isEmpty else {
            sourceCode += completion
            return
        }
        if let range = sourceCode.range(of: token, options: [.backwards]) {
            sourceCode.replaceSubrange(range, with: completion)
        }
    }

    private func loadSelectedFileIntoEditor() {
        guard let project = selectedProject, let selectedFilePath else { return }
        let newText = project.documents[selectedFilePath] ?? ""
        isLoadingFile = true
        sourceCode = newText
        isLoadingFile = false
        refreshAutocomplete()
    }

    private func updateDocument(path: String, content: String) {
        guard let selectedProjectID,
              let projectIndex = projects.firstIndex(where: { $0.id == selectedProjectID }) else { return }
        projects[projectIndex].documents[path] = content
    }

    private func refreshAutocomplete() {
        let token = trailingToken(in: sourceCode).lowercased()
        guard !token.isEmpty else {
            autocompleteOptions = []
            return
        }
        autocompleteOptions = autocompleteDictionary
            .filter { $0.lowercased().hasPrefix(token) && $0.lowercased() != token }
            .prefix(6)
            .map { $0 }
    }

    private func trailingToken(in text: String) -> String {
        let separators = CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters.subtracting(CharacterSet(charactersIn: "._")))
        let parts = text.components(separatedBy: separators)
        return parts.last ?? ""
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

struct ProjectModel: Identifiable {
    let id: UUID
    var name: String
    var summary: String
    var rootNodes: [ProjectFileModel]
    var documents: [String: String]
    var mainScriptPath: String

    func file(at path: String) -> ProjectFileModel? {
        func search(_ nodes: [ProjectFileModel]) -> ProjectFileModel? {
            for node in nodes {
                if node.path == path { return node }
                if let found = search(node.children) { return found }
            }
            return nil
        }
        return search(rootNodes)
    }

    static func defaultProjects() -> [ProjectModel] {
        [template(named: "Space Blaster"), template(named: "Runner Lab")]
    }

    static func template(named name: String) -> ProjectModel {
        let mainPath = "Scripts/main.lua"
        let files = [
            ProjectFileModel.folder(name: "Scripts", path: "Scripts", children: [
                ProjectFileModel.lua(name: "main.lua", path: mainPath),
                ProjectFileModel.lua(name: "player.lua", path: "Scripts/player.lua"),
                ProjectFileModel.lua(name: "level.lua", path: "Scripts/level.lua")
            ]),
            ProjectFileModel.folder(name: "Assets", path: "Assets", children: [
                ProjectFileModel.asset(name: "ship.png", path: "Assets/ship.png"),
                ProjectFileModel.asset(name: "enemy.png", path: "Assets/enemy.png"),
                ProjectFileModel.asset(name: "theme.wav", path: "Assets/theme.wav")
            ])
        ]
        let mainSource = """
        local t = 0

        function setup()
            sprite.add(180, 240)
            sprite.add(260, 300)
        end

        function draw()
            t = t + 0.016
        end
        """
        let playerSource = """
        local player = {}

        function player.spawn(x, y)
            sprite.add(x, y)
        end

        return player
        """
        let levelSource = """
        local level = {}

        function level.load()
            sprite.add(120, 220)
            sprite.add(320, 220)
        end

        return level
        """
        return ProjectModel(
            id: UUID(),
            name: name,
            summary: "Lua project with scripts and assets",
            rootNodes: files,
            documents: [
                mainPath: mainSource,
                "Scripts/player.lua": playerSource,
                "Scripts/level.lua": levelSource
            ],
            mainScriptPath: mainPath
        )
    }
}

struct ProjectFileModel: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let path: String
    let kind: ProjectFileKind
    var children: [ProjectFileModel]

    static func folder(name: String, path: String, children: [ProjectFileModel]) -> ProjectFileModel {
        ProjectFileModel(name: name, path: path, kind: .folder, children: children)
    }

    static func lua(name: String, path: String) -> ProjectFileModel {
        ProjectFileModel(name: name, path: path, kind: .lua, children: [])
    }

    static func asset(name: String, path: String) -> ProjectFileModel {
        ProjectFileModel(name: name, path: path, kind: .asset, children: [])
    }
}

enum ProjectFileKind {
    case folder
    case lua
    case asset
}
