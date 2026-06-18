import MemoryWallCore
import MemoryWallEditorBridge
import SwiftUI

struct EditWindowScene: View {
    @ObservedObject var store: AppStateStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Desktop Memory Wall")
                        .font(.title.bold())
                    Text("大字、手写感、本地保存；退出后变成静态桌面壁纸。")
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("取消") { store.cancelEditor(); dismiss() }
                Button("保存并应用壁纸") { store.saveDraftAndApplyWallpaper(); if store.lastError == nil { dismiss() } }
                    .keyboardShortcut("s", modifiers: [.command])
                    .buttonStyle(.borderedProminent)
            }
            .padding()

            HStack(spacing: 0) {
                WebEditorView(board: store.board) { _ in
                } onError: { error in
                    Task { @MainActor in store.lastError = error.localizedDescription }
                }
                .frame(minWidth: 540)

                VStack(alignment: .leading, spacing: 12) {
                    Text("可编辑文字")
                        .font(.headline)
                    TextEditor(text: $store.draftText)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .scrollContentBackground(.hidden)
                        .background(Color.white.opacity(0.35))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    Text("提示：第一行会按标题大字渲染，其余行按任务大字渲染。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .frame(width: 420)
                .background(.thinMaterial)
            }
            if let error = store.lastError {
                Text(error).foregroundStyle(.red).padding(8)
            }
        }
        .frame(minWidth: 1120, minHeight: 760)
        .onDisappear { store.isEditorPresented = false }
    }
}
