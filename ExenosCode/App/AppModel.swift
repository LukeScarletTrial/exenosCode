import Foundation
import SwiftUI

class AppModel: ObservableObject {
    @Published var projects: [Project] = []
    @Published var currentProject: Project?
    @Published var recentProjects: [Project] = []
    @Published var isRunning: Bool = false
    @Published var activeFile: ProjectFile?
    @Published var diagnostics: [Diagnostic] = []
    
    private let projectStore = ProjectStore()
    
    init() {
        loadProjects()
    }
    
    func loadProjects() {
        projects = projectStore.loadProjects()
        recentProjects = projectStore.loadRecentProjects()
    }
    
    func createProject(name: String) -> Project? {
        guard let project = projectStore.createProject(name: name) else {
            return nil
        }
        projects.append(project)
        recentProjects.insert(project, at: 0)
        return project
    }
    
    func openProject(_ project: Project) {
        currentProject = project
        recentProjects.removeAll { $0.id == project.id }
        recentProjects.insert(project, at: 0)
        projectStore.saveRecentProjects(recentProjects)
    }
    
    func deleteProject(_ project: Project) {
        projectStore.deleteProject(project)
        projects.removeAll { $0.id == project.id }
        recentProjects.removeAll { $0.id == project.id }
        if currentProject?.id == project.id {
            currentProject = nil
        }
    }
    
    func duplicateProject(_ project: Project) -> Project? {
        guard let newProject = projectStore.duplicateProject(project) else {
            return nil
        }
        projects.append(newProject)
        recentProjects.insert(newProject, at: 0)
        return newProject
    }
    
    func addDiagnostic(_ diagnostic: Diagnostic) {
        diagnostics.append(diagnostic)
    }
    
    func clearDiagnostics() {
        diagnostics.removeAll()
    }
}

struct Project: Identifiable, Codable {
    var id: UUID
    var name: String
    var createdAt: Date
    var modifiedAt: Date
    var files: [ProjectFile]
    var assets: [Asset]
    
    init(id: UUID = UUID(), name: String, createdAt: Date = Date(), modifiedAt: Date = Date(), files: [ProjectFile] = [], assets: [Asset] = []) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
        self.files = files
        self.assets = assets
    }
}

struct ProjectFile: Identifiable, Codable {
    var id: UUID
    var name: String
    var path: String
    var content: String
    var fileType: FileType
    var parentId: UUID?
    
    init(id: UUID = UUID(), name: String, path: String, content: String = "", fileType: FileType = .luaz, parentId: UUID? = nil) {
        self.id = id
        self.name = name
        self.path = path
        self.content = content
        self.fileType = fileType
        self.parentId = parentId
    }
}

enum FileType: String, Codable {
    case luaz = "luaz"
    case lua = "lua"
    case folder = "folder"
    case image = "image"
    case audio = "audio"
}

struct Asset: Identifiable, Codable {
    var id: UUID
    var name: String
    var path: String
    var assetType: AssetType
    var size: Int64
    
    init(id: UUID = UUID(), name: String, path: String, assetType: AssetType, size: Int64 = 0) {
        self.id = id
        self.name = name
        self.path = path
        self.assetType = assetType
        self.size = size
    }
}

enum AssetType: String, Codable {
    case image
    case audio
    case font
}

struct Diagnostic: Identifiable {
    let id: UUID
    var file: String
    var line: Int
    var column: Int
    var severity: Severity
    var message: String
    var luazLine: Int?
    
    init(id: UUID = UUID(), file: String, line: Int, column: Int, severity: Severity, message: String, luazLine: Int? = nil) {
        self.id = id
        self.file = file
        self.line = line
        self.column = column
        self.severity = severity
        self.message = message
        self.luazLine = luazLine
    }
}

enum Severity {
    case error
    case warning
    case info
}
