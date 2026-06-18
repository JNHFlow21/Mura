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
    @Published var draftText = ""
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
            draftText = board.elements.filter { $0.type == .text }.map(\.text).joined(separator: "\n")
            statusMessage = "Workspace ready"
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
    }

    func openEditor() {
        if !isEditorPresented {
            reload()
            isEditorPresented = true
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    func cancelEditor() {
        isEditorPresented = false
        reload()
        statusMessage = "Edit cancelled"
    }

    func saveDraftAndApplyWallpaper() {
        do {
            var newBoard = board
            let lines = draftText.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
            newBoard.elements = lines.enumerated().map { index, line in
                let isTitle = index == 0
                return BoardElement(x: isTitle ? 120 : 160, y: isTitle ? 105 : 330 + Double(index - 1) * 140, width: 1500, height: isTitle ? 170 : 120, text: line, fontSize: isTitle ? preferences.titleFontSize : preferences.defaultFontSize, strokeColor: line.contains("别忘") ? "#b91c1c" : "#111827")
            }.filter { !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            if newBoard.elements.isEmpty { newBoard = .defaultMemoryWall() }
            try boardStore.saveActiveBoard(newBoard, actor: "app", reason: "editor.save")
            board = newBoard
            let display = displayService.mainDisplay()
            let output = try renderer.render(RenderJob(board: newBoard, display: display, outputURL: layout.latestRenderURL, purpose: .wallpaper))
            _ = try wallpaperService.apply(render: output, display: display, confirm: true, actor: "app")
            isEditorPresented = false
            statusMessage = "Saved and applied wallpaper"
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
