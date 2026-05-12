import Foundation
import SwiftUI

class ProjectStore {
    private let fileManager = FileManager.default
    private let documentsURL: URL
    
    init() {
        documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        ensureDirectoryExists(at: documentsURL)
    }
    
    private func projectDirectory(for project: Project) -> URL {
        return documentsURL.appendingPathComponent(project.id.uuidString)
    }
    
    private func scriptsDirectory(for project: Project) -> URL {
        return projectDirectory(for: project).appendingPathComponent("scripts")
    }
    
    private func assetsDirectory(for project: Project) -> URL {
        return projectDirectory(for: project).appendingPathComponent("assets")
    }
    
    private func ensureDirectoryExists(at url: URL) {
        try? fileManager.createDirectory(at: url, withIntermediateDirectories: true)
    }
    
    func loadProjects() -> [Project] {
        var projects: [Project] = []
        
        guard let directories = try? fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: [.isDirectoryKey]) else {
            return projects
        }
        
        for directory in directories {
            guard let isDirectory = try? directory.resourceValues(forKeys: [.isDirectoryKey]).isDirectory, isDirectory else {
                continue
            }
            
            if let metadataURL = directory.appendingPathComponent("metadata.json").optionalURL,
               let data = try? Data(contentsOf: metadataURL),
               let project = try? JSONDecoder().decode(Project.self, from: data) {
                projects.append(project)
            }
        }
        
        return projects.sorted { $0.modifiedAt > $1.modifiedAt }
    }
    
    func loadRecentProjects() -> [Project] {
        guard let metadataURL = documentsURL.appendingPathComponent("recent.json").optionalURL,
              let data = try? Data(contentsOf: metadataURL),
              let projectIds = try? JSONDecoder().decode([UUID].self, from: data) else {
            return []
        }
        
        let allProjects = loadProjects()
        return allProjects.filter { projectIds.contains($0.id) }
    }
    
    func saveRecentProjects(_ projects: [Project]) {
        let ids = projects.map { $0.id }
        let data = try? JSONEncoder().encode(ids)
        let url = documentsURL.appendingPathComponent("recent.json")
        try? data?.write(to: url)
    }
    
    func createProject(name: String) -> Project? {
        let project = Project(name: name)
        let projectDir = projectDirectory(for: project)
        
        ensureDirectoryExists(at: projectDir)
        ensureDirectoryExists(at: scriptsDirectory(for: project))
        ensureDirectoryExists(at: assetsDirectory(for: project))
        
        let mainScript = ProjectFile(name: "main.luaz", path: "scripts/main.luaz", content: """
function setup()
    
end

function draw()
    
end
""")
        
        var updatedProject = project
        updatedProject.files = [mainScript]
        updatedProject.modifiedAt = Date()
        
        if saveProject(updatedProject) {
            return updatedProject
        }
        
        return nil
    }
    
    func saveProject(_ project: Project) -> Bool {
        let projectDir = projectDirectory(for: project)
        let metadataURL = projectDir.appendingPathComponent("metadata.json")
        
        guard let data = try? JSONEncoder().encode(project) else {
            return false
        }
        
        try? data.write(to: metadataURL)
        
        for file in project.files {
            let fileURL = projectDir.appendingPathComponent(file.path)
            ensureDirectoryExists(at: fileURL.deletingLastPathComponent())
            try? file.content.write(to: fileURL, atomically: true, encoding: .utf8)
        }
        
        return true
    }
    
    func loadProjectFile(_ file: ProjectFile, from project: Project) -> String? {
        let fileURL = projectDirectory(for: project).appendingPathComponent(file.path)
        return try? String(contentsOf: fileURL, encoding: .utf8)
    }
    
    func saveProjectFile(_ file: ProjectFile, content: String, in project: Project) -> Bool {
        let fileURL = projectDirectory(for: project).appendingPathComponent(file.path)
        ensureDirectoryExists(at: fileURL.deletingLastPathComponent())
        
        guard (try? content.write(to: fileURL, atomically: true, encoding: .utf8)) != nil else {
            return false
        }
        
        var updatedProject = project
        if let index = updatedProject.files.firstIndex(where: { $0.id == file.id }) {
            updatedProject.files[index].content = content
            updatedProject.modifiedAt = Date()
            saveProject(updatedProject)
        }
        
        return true
    }
    
    func deleteProject(_ project: Project) {
        let projectDir = projectDirectory(for: project)
        try? fileManager.removeItem(at: projectDir)
    }
    
    func duplicateProject(_ project: Project) -> Project? {
        var newProject = project
        newProject.id = UUID()
        newProject.name = "\(project.name) Copy"
        newProject.createdAt = Date()
        newProject.modifiedAt = Date()
        
        var newFiles: [ProjectFile] = []
        for file in project.files {
            var newFile = file
            newFile.id = UUID()
            newFiles.append(newFile)
        }
        newProject.files = newFiles
        
        var newAssets: [Asset] = []
        for asset in project.assets {
            var newAsset = asset
            newAsset.id = UUID()
            newAssets.append(newAsset)
        }
        newProject.assets = newAssets
        
        if saveProject(newProject) {
            let oldDir = projectDirectory(for: project)
            let newDir = projectDirectory(for: newProject)
            
            if let enumerator = fileManager.enumerator(at: oldDir, includingPropertiesForKeys: nil) {
                for case let url as URL in enumerator {
                    let relativePath = url.relativePath(from: oldDir)
                    let destinationURL = newDir.appendingPathComponent(relativePath)
                    ensureDirectoryExists(at: destinationURL.deletingLastPathComponent())
                    try? fileManager.copyItem(at: url, to: destinationURL)
                }
            }
            
            return newProject
        }
        
        return nil
    }
    
    func importAsset(from url: URL, to project: Project, as name: String?) -> Asset? {
        let assetsDir = assetsDirectory(for: project)
        let fileName = name ?? url.lastPathComponent
        let destinationURL = assetsDir.appendingPathComponent(fileName)
        
        ensureDirectoryExists(at: assetsDir)
        
        guard let data = try? Data(contentsOf: url) else {
            return nil
        }
        
        try? data.write(to: destinationURL)
        
        let attributes = try? fileManager.attributesOfItem(atPath: destinationURL.path)
        let fileSize = attributes?[.size] as? Int64 ?? 0
        
        let assetType: AssetType
        if url.pathExtension.lowercased() == "png" || url.pathExtension.lowercased() == "jpg" || url.pathExtension.lowercased() == "jpeg" {
            assetType = .image
        } else if url.pathExtension.lowercased() == "mp3" || url.pathExtension.lowercased() == "wav" {
            assetType = .audio
        } else {
            assetType = .image
        }
        
        let asset = Asset(name: fileName, path: "assets/\(fileName)", assetType: assetType, size: fileSize)
        
        var updatedProject = project
        updatedProject.assets.append(asset)
        updatedProject.modifiedAt = Date()
        saveProject(updatedProject)
        
        return asset
    }
}

extension URL {
    func relativePath(from base: URL) -> String {
        let components = pathComponents
        let baseComponents = base.pathComponents
        var relativeComponents: [String] = []
        
        var i = 0
        while i < baseComponents.count && i < components.count && components[i] == baseComponents[i] {
            i += 1
        }
        
        while i < components.count {
            relativeComponents.append(components[i])
            i += 1
        }
        
        return relativeComponents.joined(separator: "/")
    }
}

extension URL {
    var optionalURL: URL? {
        return fileManager.fileExists(atPath: path) ? self : nil
    }
}

extension FileManager {
    func fileExists(atPath path: String) -> Bool {
        return fileExists(atPath: path, isDirectory: nil)
    }
}
