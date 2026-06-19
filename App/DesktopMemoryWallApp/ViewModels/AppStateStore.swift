import Foundation
import MemoryWallCore
import MemoryWallEditorBridge
import MemoryWallRenderer
import MemoryWallWallpaper
import MemoryWallWorkspace
import SwiftUI

@MainActor
final class AppStateStore: ObservableObject {
    @Published var board: BoardDocument = .defaultMemoryWall()
    @Published var preferences = MemoryWallPreferences()
    @Published var isEditorPresented = false
    @Published var statusMessage = "Ready"
    @Published var lastError: String?

    let layout: WorkspaceLayout
    let boardStore: FileBoardStore
    let renderer: NativeBoardRenderer
    let displayService: AppKitDisplayService
    let wallpaperService: WallpaperService
    let hotkeyService: any HotkeyServicing

    init(layout: WorkspaceLayout = .default()) {
        self.layout = layout
        self.boardStore = FileBoardStore(layout: layout)
        self.renderer = NativeBoardRenderer()
        self.displayService = AppKitDisplayService()
        self.wallpaperService = WallpaperService(layout: layout)
        #if canImport(Carbon)
        self.hotkeyService = CarbonHotkeyService()
        #else
        self.hotkeyService = InMemoryHotkeyService()
        #endif
        reload()
        _ = hotkeyService.register(description: preferences.hotkeyDescription) { [weak self] in
            Task { @MainActor in self?.openEditor() }
        }
    }

    func reload() {
        do {
            try boardStore.ensureWorkspace()
            board = try boardStore.loadActiveBoard()
            preferences = try boardStore.loadPreferences()
            statusMessage = "Workspace ready"
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
    }

    func openEditor() {
        if !isEditorPresented {
            reload()
            prepareBlankBoardForActiveDisplayIfNeeded()
            isEditorPresented = true
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    private func prepareBlankBoardForActiveDisplayIfNeeded() {
        let display = displayService.mainDisplay()
        var shouldSave = false
        var next = board
        if next.metadata.activeTemplateID != nil && looksLikeStarterTemplate(next) {
            next = .blank(display: display)
            shouldSave = true
        } else if next.elements.isEmpty && (next.canvasWidth != display.width || next.canvasHeight != display.height || next.metadata.displayProfile != display) {
            next = .blank(display: display)
            shouldSave = true
        } else if next.canvasWidth != display.width || next.canvasHeight != display.height || next.metadata.displayProfile != display {
            next.retargetCanvas(to: display, preserveElements: true)
            shouldSave = true
        }
        if shouldSave {
            do {
                try boardStore.saveActiveBoard(next, actor: "app", reason: "editor.prepare.blank-canvas")
                board = next
            } catch {
                lastError = error.localizedDescription
            }
        }
    }

    private func looksLikeStarterTemplate(_ candidate: BoardDocument) -> Bool {
        let starterFragments = ["今天只做", "别忘：", "今天最重要", "等待："]
        return candidate.elements.contains { element in starterFragments.contains { element.text.contains($0) } }
    }

    func cancelEditor() {
        isEditorPresented = false
        reload()
        statusMessage = "Edit cancelled"
    }

    func handleEditorMessage(_ message: EditorBridgeMessage) {
        switch message.kind {
        case .ready:
            statusMessage = "Canvas ready"
            lastError = nil
        case .boardChanged:
            statusMessage = "Editing canvas"
        case .exportPNG:
            saveExportAndApplyWallpaper(message)
        case .cancel:
            cancelEditor()
        case .error:
            lastError = message.payload["message"]?.stringValue ?? "Editor reported an unknown error"
            statusMessage = "Editor error"
        }
    }

    func saveExportAndApplyWallpaper(_ message: EditorBridgeMessage) {
        do {
            guard var exportedBoard = message.board else { throw EditorBridgeError.invalidMessage("exportPNG did not include board JSON") }
            guard let dataURL = message.pngDataURL else { throw EditorBridgeError.invalidPNGPayload("Missing pngDataURL") }
            let pngData = try EditorExportCodec.pngData(fromDataURL: dataURL)
            let display = displayService.mainDisplay()
            exportedBoard.metadata.activeTemplateID = nil
            exportedBoard.metadata.displayProfile = DisplayProfile(id: display.id, name: display.name, width: exportedBoard.canvasWidth, height: exportedBoard.canvasHeight, scale: display.scale, isMain: display.isMain)
            exportedBoard.backgroundColor = exportedBoard.backgroundColor.isEmpty ? preferences.backgroundColor : exportedBoard.backgroundColor
            try boardStore.saveActiveBoard(exportedBoard, actor: "app", reason: "editor.canvas-export")
            try layout.ensureDirectories()
            try pngData.write(to: layout.latestRenderURL, options: [.atomic])
            let output = RenderOutput(fileURL: layout.latestRenderURL, width: exportedBoard.canvasWidth, height: exportedBoard.canvasHeight, purpose: .wallpaper, byteCount: pngData.count)
            _ = try wallpaperService.apply(render: output, display: display, confirm: true, actor: "app")
            board = exportedBoard
            isEditorPresented = false
            statusMessage = "Saved canvas and applied wallpaper"
            lastError = nil
        } catch {
            lastError = error.localizedDescription
            statusMessage = "Save failed"
        }
    }

    func savePreferences() {
        do {
            try boardStore.savePreferences(preferences)
            _ = hotkeyService.register(description: preferences.hotkeyDescription) { [weak self] in
                Task { @MainActor in self?.openEditor() }
            }
            statusMessage = "Preferences saved"
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
    }

    func renderPreviewOnly() {
        do {
            let display = displayService.mainDisplay()
            let output = try renderer.render(RenderJob(board: board, display: display, outputURL: layout.previewsDirectory.appendingPathComponent("app-preview.png"), purpose: .preview))
            statusMessage = "Preview rendered: \(output.fileURL.path)"
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
    }

    func restoreWallpaper() {
        do {
            _ = try wallpaperService.restore(display: displayService.mainDisplay(), confirm: true, actor: "app")
            statusMessage = "Restored previous wallpaper"
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
    }
}
