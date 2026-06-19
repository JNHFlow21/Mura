import XCTest
import MemoryWallAgentTools
import MemoryWallCore
import MemoryWallRenderer
import MemoryWallWallpaper
import MemoryWallWorkspace

final class ToolRegistryTests: XCTestCase {
    func testBoardReadAndCoordinatePatchUseSameWorkspace() throws {
        let layout = WorkspaceLayout(root: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true))
        let registry = ToolRegistry(context: ToolContext(layout: layout, renderer: NativeBoardRenderer(), displayService: StaticDisplayService()))
        XCTAssertTrue(registry.run(arguments: ["status", "--json"]).ok)
        let patch = registry.run(arguments: ["board", "patch", "--text", "测试提醒", "--x", "321", "--y", "222", "--json"])
        XCTAssertTrue(patch.ok, patch.message)
        let board = try FileBoardStore(layout: layout).loadActiveBoard()
        let element = try XCTUnwrap(board.elements.first { $0.text == "测试提醒" })
        XCTAssertEqual(element.x, 321)
        XCTAssertEqual(element.y, 222)
    }

    func testBoardStrokeWritesFreedrawPoints() throws {
        let layout = WorkspaceLayout(root: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true))
        let registry = ToolRegistry(context: ToolContext(layout: layout, renderer: NativeBoardRenderer(), displayService: StaticDisplayService()))
        XCTAssertTrue(registry.run(arguments: ["status", "--json"]).ok)
        let result = registry.run(arguments: ["board", "stroke", "--points", "10,10;20,30", "--json"])
        XCTAssertTrue(result.ok, result.message)
        let board = try FileBoardStore(layout: layout).loadActiveBoard()
        XCTAssertEqual(board.elements.first?.type, .freedraw)
        XCTAssertEqual(board.elements.first?.extra["points"]?.arrayValue?.count, 2)
    }

    func testRenderPreviewWritesImageWithoutApplyingWallpaper() throws {
        let layout = WorkspaceLayout(root: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true))
        let registry = ToolRegistry(context: ToolContext(layout: layout, renderer: NativeBoardRenderer(), displayService: StaticDisplayService()))
        let result = registry.run(arguments: ["render", "preview", "--width", "320", "--height", "180", "--json"])
        XCTAssertTrue(result.ok, result.message)
        XCTAssertTrue(FileManager.default.fileExists(atPath: layout.previewsDirectory.appendingPathComponent("preview-320x180.png").path))
    }

    func testTemplateCommandsAreDeprecated() {
        let layout = WorkspaceLayout(root: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true))
        let registry = ToolRegistry(context: ToolContext(layout: layout, renderer: NativeBoardRenderer(), displayService: StaticDisplayService()))
        let result = registry.run(arguments: ["templates", "list", "--json"])
        XCTAssertFalse(result.ok)
        XCTAssertTrue(result.message.contains("removed"))
    }
}
