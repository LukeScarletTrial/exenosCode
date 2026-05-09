import SwiftUI
import SpriteKit
import SceneKit

struct EditorWorkspaceView: View {
    @ObservedObject var appModel: AppModel

    var body: some View {
        if appModel.selectedProject == nil {
            homeScreen
        } else {
            #if os(macOS)
            HSplitView {
                projectSidebar
                editorPane
                previewPane
            }
            #else
            NavigationSplitView {
                projectSidebar
            } content: {
                editorPane
            } detail: {
                previewPane
            }
            #endif
        }
    }

    private var homeScreen: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Text("Exenos Code")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                        Spacer()
                        Button("New Project") {
                            appModel.createProject()
                        }
                        .buttonStyle(.borderedProminent)
                    }

                    Text("Open a project to edit Lua scripts, manage assets, and run your game live.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    ForEach(appModel.projects) { project in
                        Button {
                            appModel.openProject(project.id)
                        } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(project.name)
                                    .font(.title3.weight(.semibold))
                                Text(project.summary)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(14)
                            .background(Color(uiColor: .secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(20)
            }
            .background(Color(uiColor: .systemGroupedBackground))
        }
    }

    private var projectSidebar: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(appModel.selectedProject?.name ?? "Projects")
                    .font(.headline)
                Spacer()
                Button("Home") {
                    appModel.selectedProjectID = nil
                }
                .buttonStyle(.bordered)
            }

            if let project = appModel.selectedProject {
                List {
                    ForEach(project.rootNodes) { node in
                        nodeView(node, depth: 0)
                    }
                }
                .listStyle(.plain)
            }
        }
        .padding(12)
        .navigationTitle("Files")
    }

    @ViewBuilder
    private func nodeView(_ node: ProjectFileModel, depth: CGFloat) -> some View {
        if node.kind == .folder {
            DisclosureGroup {
                ForEach(node.children) { child in
                    nodeView(child, depth: depth + 1)
                }
            } label: {
                Label(node.name, systemImage: "folder")
                    .padding(.leading, depth * 6)
            }
        } else {
            Button {
                appModel.selectFile(path: node.path)
            } label: {
                HStack {
                    Label(node.name, systemImage: node.kind == .lua ? "doc.plaintext" : "photo")
                    Spacer()
                }
                .padding(.leading, depth * 6)
                .padding(.vertical, 4)
                .background(appModel.selectedFilePath == node.path ? Color.accentColor.opacity(0.12) : .clear)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
        }
    }

    private var editorPane: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(appModel.selectedFile?.name ?? "No file selected")
                        .font(.headline)
                    Text(appModel.selectedFilePath ?? "")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            if appModel.selectedFileIsLua {
                SyntaxHighlightingTextEditor(text: $appModel.sourceCode)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                if !appModel.autocompleteOptions.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(appModel.autocompleteOptions, id: \.self) { suggestion in
                                Button(suggestion) {
                                    appModel.applyAutocomplete(suggestion)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                        }
                    }
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "photo.on.rectangle")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                    Text("Asset preview placeholder")
                        .font(.headline)
                    Text("Asset import and preview can be expanded here.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(uiColor: .secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Text(appModel.consoleOutput)
                .font(.system(.caption, design: .monospaced))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
                .background(Color(uiColor: .secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding(12)
        .frame(minWidth: 360)
    }

    private var previewPane: some View {
        VStack(spacing: 12) {
            Picker("Renderer", selection: $appModel.selectedRenderer) {
                ForEach(RendererKind.allCases) { renderer in
                    Text(renderer.rawValue).tag(renderer)
                }
            }
            .pickerStyle(.segmented)

            Group {
                if appModel.selectedRenderer == .spriteKit2D {
                    SpritePreviewView(runtime: appModel.spriteRuntime)
                } else {
                    ScenePreviewView(runtime: appModel.sceneRuntime)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            HStack(spacing: 12) {
                Button("Run") {
                    appModel.runCode()
                }
                .buttonStyle(.borderedProminent)
                .disabled(appModel.selectedProject == nil)

                Button(appModel.engineState == .paused ? "Resume" : "Pause") {
                    appModel.pauseOrResume()
                }
                .buttonStyle(.bordered)

                Button("Stop") {
                    appModel.stop()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(12)
        .frame(minWidth: 320)
    }
}
