import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        if let icon = NSImage(named: "MuraLogo") {
            NSApp.applicationIconImage = icon
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if let editorWindow = sender.windows.first(where: { $0.identifier?.rawValue == EditorWindowMetrics.windowIdentifier }) {
            if editorWindow.isMiniaturized {
                editorWindow.deminiaturize(nil)
                sender.activate(ignoringOtherApps: true)
                return false
            }

            if editorWindow.isVisible {
                editorWindow.miniaturize(nil)
                return false
            }

            editorWindow.makeKeyAndOrderFront(nil)
            sender.activate(ignoringOtherApps: true)
            return false
        }

        NotificationCenter.default.post(name: .muraOpenEditorRequested, object: nil)
        return false
    }
}
