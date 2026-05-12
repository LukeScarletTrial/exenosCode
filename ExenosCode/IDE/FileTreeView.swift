import SwiftUI

struct FileTreeView: View {
    let project: Project
    @Binding var selectedFile: ProjectFile?
    @State private var expandedFolders: Set<UUID> = []
    @State private var showingCreateFileSheet = false
    @State private var showingCreateFolderSheet = false
    @State private var newFileName = ""
    @State private var newFolderName = ""
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Files")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.6))
                
                Spacer()
                
                Menu {
                    Button("New File") { showingCreateFileSheet = true }
                    Button("New Folder") { showingCreateFolderSheet = true }
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 14))
                        .foregroundColor(Color(red: 0, green: 0.94, blue: 1))
                }
            }
            .padding(12)
            .background(Color(red: 0.08, green: 0.08, blue: 0.12))
            
            Divider()
            
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    ForEach(fileTree) { node in
                        FileTreeNode(
                            node: node,
                            selectedFile: $selectedFile,
                            expandedFolders: $expandedFolders,
                            project: project
                        )
                    }
                }
                .padding(8)
            }
        }
        .background(Color(red: 0.04, green: 0.04, blue: 0.06))
        .sheet(isPresented: $showingCreateFileSheet) {
            createFileSheet
        }
        .sheet(isPresented: $showingCreateFolderSheet) {
            createFolderSheet
        }
    }
    
    private var fileTree: [FileNode] {
        let rootFiles = project.files.filter { $0.parentId == nil }
        return rootFiles.map { buildTree(for: $0, in: project) }
    }
    
    private func buildTree(for file: ProjectFile, in project: Project) -> FileNode {
        let children = project.files
            .filter { $0.parentId == file.id }
            .map { buildTree(for: $0, in: project) }
        
        return FileNode(file: file, children: children)
    }
    
    private var createFileSheet: some View {
        NavigationView {
            Form {
                Section {
                    TextField("File Name", text: $newFileName)
                        .textInputAutocapitalization(.never)
                } header: {
                    Text("New LuaZ File")
                } footer: {
                    Text("Enter a name for your new file (e.g., 'script.luaz')")
                }
            }
            .navigationTitle("New File")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showingCreateFileSheet = false
                        newFileName = ""
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createFile()
                    }
                    .disabled(newFileName.isEmpty)
                }
            }
        }
    }
    
    private var createFolderSheet: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Folder Name", text: $newFolderName)
                        .textInputAutocapitalization(.words)
                } header: {
                    Text("New Folder")
                }
            }
            .navigationTitle("New Folder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showingCreateFolderSheet = false
                        newFolderName = ""
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createFolder()
                    }
                    .disabled(newFolderName.isEmpty)
                }
            }
        }
    }
    
    private func createFile() {
        guard !newFileName.isEmpty else { return }
        
        let fileName = newFileName.hasSuffix(".luaz") ? newFileName : "\(newFileName).luaz"
        let newFile = ProjectFile(name: fileName, path: "scripts/\(fileName)", fileType: .luaz)
        
        var updatedProject = project
        updatedProject.files.append(newFile)
        updatedProject.modifiedAt = Date()
        
        let projectStore = ProjectStore()
        projectStore.saveProject(updatedProject)
        
        showingCreateFileSheet = false
        newFileName = ""
    }
    
    private func createFolder() {
        guard !newFolderName.isEmpty else { return }
        
        let newFolder = ProjectFile(name: newFolderName, path: "scripts/\(newFolderName)/", fileType: .folder)
        
        var updatedProject = project
        updatedProject.files.append(newFolder)
        updatedProject.modifiedAt = Date()
        
        let projectStore = ProjectStore()
        projectStore.saveProject(updatedProject)
        
        showingCreateFolderSheet = false
        newFolderName = ""
    }
}

struct FileNode: Identifiable {
    let id = UUID()
    let file: ProjectFile
    let children: [FileNode]
}

struct FileTreeNode: View {
    let node: FileNode
    @Binding var selectedFile: ProjectFile?
    @Binding var expandedFolders: Set<UUID>
    let project: Project
    @State private var showingDeleteAlert = false
    @State private var showingRenameSheet = false
    @State private var newName = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: {
                if node.file.fileType == .folder {
                    if expandedFolders.contains(node.file.id) {
                        expandedFolders.remove(node.file.id)
                    } else {
                        expandedFolders.insert(node.file.id)
                    }
                } else {
                    selectedFile = node.file
                }
            }) {
                HStack(spacing: 8) {
                    if node.file.fileType == .folder {
                        Image(systemName: expandedFolders.contains(node.file.id) ? "chevron.down" : "chevron.right")
                            .font(.system(size: 10))
                            .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.6))
                            .frame(width: 16)
                    } else {
                        Spacer()
                            .frame(width: 16)
                    }
                    
                    Image(systemName: fileIcon(for: node.file.fileType))
                        .font(.system(size: 12))
                        .foregroundColor(fileTypeColor(for: node.file.fileType))
                        .frame(width: 20)
                    
                    Text(node.file.name)
                        .font(.system(size: 13))
                        .foregroundColor(selectedFile?.id == node.file.id ? .white : Color(red: 0.7, green: 0.7, blue: 0.8))
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Menu {
                        Button("Rename") {
                            newName = node.file.name
                            showingRenameSheet = true
                        }
                        
                        Button(role: .destructive, action: { showingDeleteAlert = true }) {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 10))
                            .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.5))
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(selectedFile?.id == node.file.id ? Color(red: 0.15, green: 0.15, blue: 0.2) : Color.clear)
                .cornerRadius(4)
            }
            .buttonStyle(PlainButtonStyle())
            .contextMenu {
                Button("Rename") {
                    newName = node.file.name
                    showingRenameSheet = true
                }
                
                Button(role: .destructive, action: { showingDeleteAlert = true }) {
                    Label("Delete", systemImage: "trash")
                }
            }
            
            if node.file.fileType == .folder && expandedFolders.contains(node.file.id) {
                ForEach(node.children) { child in
                    FileTreeNode(
                        node: child,
                        selectedFile: $selectedFile,
                        expandedFolders: $expandedFolders,
                        project: project
                    )
                    .padding(.leading, 16)
                }
            }
        }
        .sheet(isPresented: $showingRenameSheet) {
            renameSheet
        }
        .alert("Delete File", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteFile()
            }
        } message: {
            Text("Are you sure you want to delete \(node.file.name)?")
        }
    }
    
    private var renameSheet: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Name", text: $newName)
                } header: {
                    Text("Rename")
                }
            }
            .navigationTitle("Rename")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showingRenameSheet = false
                        newName = ""
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Rename") {
                        renameFile()
                    }
                    .disabled(newName.isEmpty)
                }
            }
        }
    }
    
    private func renameFile() {
        guard !newName.isEmpty else { return }
        
        var updatedProject = project
        if let index = updatedProject.files.firstIndex(where: { $0.id == node.file.id }) {
            updatedProject.files[index].name = newName
            updatedProject.modifiedAt = Date()
            
            let projectStore = ProjectStore()
            projectStore.saveProject(updatedProject)
        }
        
        showingRenameSheet = false
        newName = ""
    }
    
    private func deleteFile() {
        var updatedProject = project
        updatedProject.files.removeAll { $0.id == node.file.id || isDescendant(of: node.file, in: project.files) }
        updatedProject.modifiedAt = Date()
        
        let projectStore = ProjectStore()
        projectStore.saveProject(updatedProject)
        
        if selectedFile?.id == node.file.id {
            selectedFile = nil
        }
    }
    
    private func isDescendant(of file: ProjectFile, in files: [ProjectFile]) -> Bool {
        var descendants: Set<UUID> = []
        var queue = files.filter { $0.parentId == file.id }
        
        while !queue.isEmpty {
            let current = queue.removeFirst()
            descendants.insert(current.id)
            queue.append(contentsOf: files.filter { $0.parentId == current.id })
        }
        
        return descendants.contains(file.id)
    }
    
    private func fileIcon(for fileType: FileType) -> String {
        switch fileType {
        case .luaz: return "doc.text"
        case .lua: return "doc.text"
        case .folder: return "folder.fill"
        case .image: return "photo"
        case .audio: return "speaker.wave.2"
        }
    }
    
    private func fileTypeColor(for fileType: FileType) -> Color {
        switch fileType {
        case .luaz: return Color(red: 0.55, green: 0.35, blue: 1)
        case .lua: return Color(red: 0, green: 0.7, blue: 0.4)
        case .folder: return Color(red: 0.8, green: 0.6, blue: 0.2)
        case .image: return Color(red: 0, green: 0.94, blue: 1)
        case .audio: return Color(red: 1, green: 0.35, blue: 0.55)
        }
    }
}
