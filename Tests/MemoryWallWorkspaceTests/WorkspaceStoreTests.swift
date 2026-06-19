import XCTest
import MemoryWallCore
@testable import MemoryWallWorkspace

final class WorkspaceStoreTests: XCTestCase {
    func testEnsureWorkspaceCreatesBlankHumanReadableFiles() throws {
        let layout = tempLayout()
        let store = FileBoardStore(layout: layout)
        try store.ensureWorkspace()
        XCTAssertTrue(FileManager.default.fileExists(atPath: layout.activeBoardURL.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: layout.contextURL.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: layout.auditLogURL.path))
        let board = try store.loadActiveBoard()
        XCTAssertEqual(board.elements.count, 0)
        XCTAssertNil(board.metadata.activeTemplateID)
    }

    func testSaveAndLoadActiveBoardPreservesUnknownFields() throws {
        let layout = tempLayout()
        let store = FileBoardStore(layout: layout)
        var board = BoardDocument.defaultMemoryWall()
        board.rawExcalidraw["unknown"] = .object(["value": .number(42)])
        try store.saveActiveBoard(board, actor: "test", reason: "unit")
        let loaded = try store.loadActiveBoard()
        XCTAssertEqual(loaded.rawExcalidraw["unknown"], .object(["value": .number(42)]))
    }

    func testCorruptBoardIsRecoverableErrorAndDoesNotDeleteSnapshots() throws {
        let layout = tempLayout()
        let store = FileBoardStore(layout: layout)
        let board = BoardDocument.defaultMemoryWall()
        _ = try store.snapshotStore.createSnapshot(board: board, reason: "before-corrupt")
        try layout.ensureDirectories()
        try Data("{".utf8).write(to: layout.activeBoardURL)
        XCTAssertThrowsError(try store.loadActiveBoard()) { error in
            guard case WorkspaceError.corruptBoard = error else { return XCTFail("unexpected error: \(error)") }
        }
        XCTAssertNotNil(try store.snapshotStore.latestSnapshot())
    }

    func testAuditLogUsesJsonLines() throws {
        let layout = tempLayout()
        let log = FileAuditLog(layout: layout)
        try log.append(AuditEvent(actor: "test", action: "unit", target: "board"))
        try log.append(AuditEvent(actor: "test", action: "unit2", target: "board"))
        let events = try log.readAll(limit: nil)
        XCTAssertEqual(events.map(\.action), ["unit", "unit2"])
        let raw = try String(contentsOf: layout.auditLogURL, encoding: .utf8)
        XCTAssertEqual(raw.split(separator: "\n").count, 2)
    }

    private func tempLayout() -> WorkspaceLayout {
        WorkspaceLayout(root: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true))
    }
}
