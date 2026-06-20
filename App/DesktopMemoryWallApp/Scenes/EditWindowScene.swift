import AppKit
import MemoryWallCore
import MemoryWallEditorBridge
import SwiftUI

struct EditWindowScene: View {
    @ObservedObject var store: AppStateStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            WebEditorView(
                board: store.editorBoard ?? store.board,
                displays: store.displays,
                boardsByDisplayID: store.editorBoardsByDisplayID,
                selectedDisplayID: store.selectedDisplayID
            ) { message in
                Task { @MainActor in store.handleEditorMessage(message) }
            } onError: { error in
                Task { @MainActor in store.lastError = error.localizedDescription }
            }
            if let error = store.lastError {
                Text(error)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.red.opacity(0.86), in: RoundedRectangle(cornerRadius: 10))
                    .padding(16)
            }
        }
        .frame(minWidth: 960, minHeight: 640)
        .background(FixedEditorWindowConfigurator())
        .onChange(of: store.isEditorPresented) { _, presented in
            if !presented { dismiss() }
        }
        .onAppear { store.presentEditorWindow() }
        .onDisappear { store.editorWindowDidDisappear() }
    }
}

private struct FixedEditorWindowConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        DispatchQueue.main.async { configure(view.window) }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async { configure(nsView.window) }
    }

    private func configure(_ window: NSWindow?) {
        guard let window else { return }
        window.identifier = NSUserInterfaceItemIdentifier(EditorWindowMetrics.windowIdentifier)
        let target = EditorWindowMetrics.fixedFrameSize
        let current = window.frame
        let targetFrame = NSRect(
            x: current.midX - target.width / 2,
            y: current.midY - target.height / 2,
            width: target.width,
            height: target.height
        )
        if abs(current.width - target.width) > 0.5 || abs(current.height - target.height) > 0.5 {
            window.setFrame(targetFrame, display: true)
        }
        window.minSize = target
        window.maxSize = target
        window.isRestorable = false
        window.styleMask.remove(.resizable)
        window.standardWindowButton(.zoomButton)?.isEnabled = false
    }
}
