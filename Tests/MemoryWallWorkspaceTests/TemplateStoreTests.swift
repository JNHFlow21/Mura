import XCTest
import MemoryWallCore
import MemoryWallWorkspace

final class TemplateStoreTests: XCTestCase {
    func testTemplateApplySnapshotsPreviousBoard() throws {
        let layout = WorkspaceLayout(root: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true))
        let boardStore = FileBoardStore(layout: layout)
        let templateStore = FileTemplateStore(layout: layout)
        try boardStore.ensureWorkspace()
        let applied = try templateStore.applyTemplate(id: "today-focus", boardStore: boardStore, actor: "test")
        XCTAssertEqual(applied.metadata.activeTemplateID, "today-focus")
        XCTAssertNotNil(try boardStore.snapshotStore.latestSnapshot())
    }
}
