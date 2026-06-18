import XCTest
import MemoryWallAgentTools
import MemoryWallCore
import MemoryWallRenderer
import MemoryWallWallpaper
import MemoryWallWorkspace

final class ToolRegistryTests: XCTestCase {
    func testBoardReadAndPatchUseSameWorkspace() throws {
        let layout = WorkspaceLayout(root: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true))
        let registry = ToolRegistry(context: ToolContext(layout: layout, renderer: NativeBoardRenderer(), displayService: StaticDisplayService()))
        XCTAssertTrue(registry.run(arguments: ["status", "--json"]).ok)
        let patch = registry.run(arguments: ["board", "patch", "--text", "测试提醒", "--json"])
        XCTAssertTrue(patch.ok, patch.message)
        let board = try FileBoardStore(layout: layout).loadActiveBoard()
        XCTAssertTrue(board.elements.contains { $0.text == "测试提醒" })
    }

    func testRenderPreviewWritesImageWithoutApplyingWallpaper() throws {
        let layout = WorkspaceLayout(root: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true))
        let registry = ToolRegistry(context: ToolContext(layout: layout, renderer: NativeBoardRenderer(), displayService: StaticDisplayService()))
        let result = registry.run(arguments: ["render", "preview", "--width", "320", "--height", "180", "--json"])
        XCTAssertTrue(result.ok, result.message)
        XCTAssertTrue(FileManager.default.fileExists(atPath: layout.previewsDirectory.appendingPathComponent("preview-320x180.png").path))
    }
}
