import SwiftUI

struct SettingsSceneView: View {
    @ObservedObject var store: AppStateStore

    var body: some View {
        Form {
            TextField("默认快捷键", text: Binding(get: { store.preferences.hotkeyDescription }, set: { store.preferences.hotkeyDescription = $0 }))
            Stepper("正文大小：\(Int(store.preferences.defaultFontSize))", value: $store.preferences.defaultFontSize, in: 48...180, step: 4)
            Stepper("标题大小：\(Int(store.preferences.titleFontSize))", value: $store.preferences.titleFontSize, in: 72...220, step: 4)
            Text("工作区：\(store.layout.root.path)")
                .font(.footnote)
                .textSelection(.enabled)
            Button("保存设置") { store.savePreferences() }
        }
        .padding()
        .frame(width: 480)
    }
}
