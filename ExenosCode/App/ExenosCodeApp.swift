import SwiftUI

@main
struct ExenosCodeApp: App {
    @StateObject private var appModel = AppModel()

    var body: some Scene {
        WindowGroup {
            EditorWorkspaceView(appModel: appModel)
        }
    }
}
