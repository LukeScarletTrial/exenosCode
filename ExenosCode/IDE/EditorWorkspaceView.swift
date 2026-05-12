import SwiftUI

struct EditorWorkspaceView: View {
    @EnvironmentObject var appModel: AppModel
    @State private var selectedFile: ProjectFile?
    @State private var showingAssetImport = false
    @State private var showingFileTree = true
    
    var body: some View {
        if let project = appModel.currentProject {
            GeometryReader { geometry in
                HSplitView {
                    if showingFileTree {
                        FileTreeView(project: project, selectedFile: Binding(
                            get: { selectedFile },
                            set: { selectedFile = $0 }
                        ))
                            .frame(minWidth: 250, idealWidth: 300)
                    }
                    
                    VStack(spacing: 0) {
                        ToolbarView(
                            project: project,
                            selectedFile: selectedFile,
                            showingFileTree: $showingFileTree,
                            showingAssetImport: $showingAssetImport
                        )
                        
                        if let file = selectedFile {
                            CodeEditorView(file: file, project: project)
                        } else {
                            emptyEditorView
                        }
                    }
                }
            }
            .navigationTitle(project.name)
            .navigationBarHidden(true)
            .sheet(isPresented: $showingAssetImport) {
                AssetImportView(project: project)
            }
        }
    }
    
    private var emptyEditorView: some View {
        ZStack {
            Color(red: 0.04, green: 0.04, blue: 0.06)
            
            VStack(spacing: 16) {
                Image(systemName: "doc.text")
                    .font(.system(size: 48))
                    .foregroundColor(Color(red: 0.3, green: 0.3, blue: 0.4))
                
                Text("No file selected")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.6))
                
                Text("Select a file from the file tree to edit")
                    .font(.system(size: 14))
                    .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.5))
            }
        }
    }
}

struct ToolbarView: View {
    let project: Project
    @Binding var selectedFile: ProjectFile?
    @Binding var showingFileTree: Bool
    @Binding var showingAssetImport: Bool
    @EnvironmentObject var appModel: AppModel
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: { showingFileTree.toggle() }) {
                Image(systemName: showingFileTree ? "sidebar.left" : "sidebar.left.slash")
                    .foregroundColor(Color(red: 0, green: 0.94, blue: 1))
            }
            
            Divider()
                .frame(height: 24)
            
            if let file = selectedFile {
                HStack(spacing: 8) {
                    Image(systemName: fileIcon(for: file.fileType))
                        .font(.system(size: 12))
                        .foregroundColor(fileTypeColor(for: file.fileType))
                    
                    Text(file.name)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                }
            } else {
                Text("No file selected")
                    .font(.system(size: 14))
                    .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.6))
            }
            
            Spacer()
            
            if appModel.isRunning {
                Button(action: stopProject) {
                    Label("Stop", systemImage: "stop.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(red: 1, green: 0.35, blue: 0.55))
                        .cornerRadius(6)
                }
            } else {
                Button(action: runProject) {
                    Label("Run", systemImage: "play.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(red: 0, green: 0.94, blue: 1))
                        .cornerRadius(6)
                }
            }
            
            Button(action: { showingAssetImport = true }) {
                Image(systemName: "plus")
                    .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.6))
            }
        }
        .padding(12)
        .background(Color(red: 0.08, green: 0.08, blue: 0.12))
    }
    
    private func runProject() {
        appModel.isRunning = true
    }
    
    private func stopProject() {
        appModel.isRunning = false
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
