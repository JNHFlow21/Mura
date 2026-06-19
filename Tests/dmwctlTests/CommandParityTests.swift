import XCTest
import MemoryWallAgentTools
import MemoryWallRenderer
import MemoryWallWallpaper
import MemoryWallWorkspace

final class CommandParityTests: XCTestCase {
    func testDocumentedPrimitiveCommandsAreAccepted() {
        let layout = WorkspaceLayout(root: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true))
        let registry = ToolRegistry(context: ToolContext(layout: layout, renderer: NativeBoardRenderer(), displayService: StaticDisplayService()))
        XCTAssertTrue(registry.run(arguments: ["status", "--json"]).ok)
        XCTAssertTrue(registry.run(arguments: ["board", "read", "--json"]).ok)
        XCTAssertTrue(registry.run(arguments: ["board", "blank", "--width", "1920", "--height", "1080", "--json"]).ok)
        XCTAssertTrue(registry.run(arguments: ["board", "patch", "--text", "hello", "--x", "10", "--y", "20", "--json"]).ok)
        XCTAssertTrue(registry.run(arguments: ["board", "stroke", "--points", "10,10;20,20", "--json"]).ok)
        XCTAssertTrue(registry.run(arguments: ["displays", "list", "--json"]).ok)
        XCTAssertFalse(registry.run(arguments: ["templates", "list", "--json"]).ok)
        XCTAssertTrue(registry.run(arguments: ["diagnostics", "--json"]).ok)
    }
}
