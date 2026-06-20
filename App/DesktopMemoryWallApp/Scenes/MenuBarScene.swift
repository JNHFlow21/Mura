import SwiftUI

struct MenuBarSceneLabel: View {
    @ObservedObject var store: AppStateStore
    @Environment(\.openWindow) private var openWindow
    @State private var didRequestInitialWindow = false

    var body: some View {
        Image(systemName: "square.and.pencil")
            .onAppear {
                requestInitialEditorWindow()
            }
            .onReceive(NotificationCenter.default.publisher(for: .muraOpenEditorRequested)) { _ in
                openEditorWindow()
            }
    }

    private func requestInitialEditorWindow() {
        guard !didRequestInitialWindow else { return }
        didRequestInitialWindow = true
        DispatchQueue.main.async {
            openEditorWindow()
        }
    }

    private func openEditorWindow() {
        store.openEditor()
        openWindow(id: "editor")
    }
}

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
