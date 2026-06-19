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
        .onChange(of: store.isEditorPresented) { _, presented in
            if !presented { dismiss() }
        }
        .onAppear { store.presentEditorWindow() }
        .onDisappear { store.editorWindowDidDisappear() }
    }
}
