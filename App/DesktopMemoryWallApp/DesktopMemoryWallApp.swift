import SwiftUI

@main
struct DesktopMemoryWallApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var store = AppStateStore()

    var body: some Scene {
        MenuBarExtra("Mura", image: "MuraMenuBarIcon") {
            MenuBarSceneContent(store: store)
        }
        .menuBarExtraStyle(.menu)

        Window("Mura", id: "editor") {
            EditWindowScene(store: store)
                .onAppear { store.isEditorPresented = true }
        }
        .defaultSize(width: EditorWindowMetrics.fixedFrameSize.width, height: EditorWindowMetrics.fixedFrameSize.height)

        Settings {
            SettingsSceneView(store: store)
        }
    }
}

enum EditorWindowMetrics {
    static let fixedFrameSize = CGSize(width: 1295, height: 719)
}
