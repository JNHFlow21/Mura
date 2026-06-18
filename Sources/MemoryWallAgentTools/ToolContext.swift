import Foundation
import MemoryWallCore
import MemoryWallRenderer
import MemoryWallWallpaper
import MemoryWallWorkspace

public struct ToolContext {
    public var layout: WorkspaceLayout
    public var boardStore: FileBoardStore
    public var templateStore: FileTemplateStore
    public var renderer: any BoardRendering
    public var displayService: any DisplayServicing
    public var wallpaperService: WallpaperService

    public init(layout: WorkspaceLayout, renderer: any BoardRendering = NativeBoardRenderer(), displayService: any DisplayServicing = AppKitDisplayService(), wallpaperBackend: any WallpaperBackend = AppKitWallpaperBackend()) {
        self.layout = layout
        self.boardStore = FileBoardStore(layout: layout)
        self.templateStore = FileTemplateStore(layout: layout)
        self.renderer = renderer
        self.displayService = displayService
        self.wallpaperService = WallpaperService(layout: layout, backend: wallpaperBackend)
    }

    public static func live(workspace: URL?) -> ToolContext {
        ToolContext(layout: workspace.map(WorkspaceLayout.init(root:)) ?? .default())
    }
}
