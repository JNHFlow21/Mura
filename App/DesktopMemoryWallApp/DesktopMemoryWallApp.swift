import SwiftUI

@main
struct DesktopMemoryWallApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var store = AppStateStore()

    var body: some Scene {
        MenuBarExtra("Memory Wall", systemImage: "rectangle.and.pencil.and.ellipsis") {
            MenuBarSceneContent(store: store)
        }
        .menuBarExtraStyle(.menu)

        WindowGroup("Desktop Memory Wall", id: "editor") {
            EditWindowScene(store: store)
                .onAppear { store.isEditorPresented = true }
        }
        .defaultSize(width: 1120, height: 760)

        Settings {
            SettingsSceneView(store: store)
        }
    }
}
