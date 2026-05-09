import SwiftUI
import SpriteKit
import SceneKit

struct EditorWorkspaceView: View {
    @ObservedObject var appModel: AppModel

    var body: some View {
        HSplitView {
            VStack(spacing: 12) {
                SyntaxHighlightingTextEditor(text: $appModel.sourceCode)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                Text(appModel.consoleOutput)
                    .font(.system(.caption, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(12)
            .frame(minWidth: 420)

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
            .frame(minWidth: 420)
        }
    }
}
