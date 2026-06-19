import SwiftUI

struct MenuBarSceneContent: View {
    @ObservedObject var store: AppStateStore
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button("打开编辑器") { store.openEditor(); openWindow(id: "editor") }
        Divider()
        Text(store.statusMessage)
        if let error = store.lastError {
            Text(error).foregroundStyle(.red)
        }
        Divider()
        Button("退出") { NSApplication.shared.terminate(nil) }
    }
}
