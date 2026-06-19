import SwiftUI

struct MenuBarSceneContent: View {
    @ObservedObject var store: AppStateStore
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button("打开空白编辑器") { store.openEditor(); openWindow(id: "editor") }
        Button("重新读取保存内容") { store.reload() }
        Button("导出预览图（不换桌面）") { store.renderPreviewOnly() }
        Button("恢复保存前壁纸") { store.restoreWallpaper() }
        Divider()
        Text(store.statusMessage)
        if let error = store.lastError {
            Text(error).foregroundStyle(.red)
        }
        Divider()
        Button("退出") { NSApplication.shared.terminate(nil) }
    }
}
