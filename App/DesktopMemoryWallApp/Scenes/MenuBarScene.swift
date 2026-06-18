import SwiftUI

struct MenuBarSceneContent: View {
    @ObservedObject var store: AppStateStore
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button("打开编辑模式") { store.openEditor(); openWindow(id: "editor") }
        Button("重新载入工作区") { store.reload() }
        Button("仅渲染预览") { store.renderPreviewOnly() }
        Button("恢复上一张壁纸") { store.restoreWallpaper() }
        Divider()
        Text(store.statusMessage)
        if let error = store.lastError {
            Text(error).foregroundStyle(.red)
        }
        Divider()
        Button("退出") { NSApplication.shared.terminate(nil) }
    }
}
