import XCTest
import MemoryWallAgentTools
import MemoryWallRenderer
import MemoryWallWallpaper
import MemoryWallWorkspace

final class DiagnosticsCommandTests: XCTestCase {
    func testDiagnosticsReportsWorkspaceBoardEditorAndFontReadiness() {
        let layout = WorkspaceLayout(root: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true))
        let registry = ToolRegistry(context: ToolContext(layout: layout, renderer: NativeBoardRenderer(), displayService: StaticDisplayService()))
        let result = registry.run(arguments: ["diagnostics", "--json"])
        XCTAssertTrue(result.ok, result.message)
        XCTAssertTrue(result.message.contains("diagnostics"))
        XCTAssertTrue(result.jsonDebugString.contains("fontAssetExists"))
        XCTAssertTrue(result.jsonDebugString.contains("editorAssetExists"))
    }
}

private extension ToolResult {
    var jsonDebugString: String { (try? jsonString()) ?? "" }
}
