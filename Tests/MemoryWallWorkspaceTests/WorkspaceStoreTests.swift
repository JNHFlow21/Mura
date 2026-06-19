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

    func testWallpaperRenderURLIsUniqueAndKeepsLatestRenderStable() {
        let layout = tempLayout()
        let first = layout.wallpaperRenderURL(id: "first", date: Date(timeIntervalSince1970: 1))
        let second = layout.wallpaperRenderURL(id: "second", date: Date(timeIntervalSince1970: 2))
        XCTAssertNotEqual(first, second)
        XCTAssertEqual(layout.latestRenderURL.lastPathComponent, "latest-wallpaper.png")
        XCTAssertEqual(first.deletingLastPathComponent(), layout.rendersDirectory)
        XCTAssertTrue(first.lastPathComponent.hasPrefix("wallpaper-"))
    }

    func testDisplayBoardsSaveAndLoadIndependently() throws {
        let layout = tempLayout()
        let store = FileBoardStore(layout: layout)
        let main = DisplayProfile(id: "main/display", name: "Main", width: 1920, height: 1080, scale: 2, isMain: true)
        let side = DisplayProfile(id: "side:display", name: "Side", width: 1280, height: 720, scale: 1, isMain: false)

        var mainBoard = BoardDocument.blank(display: main)
        mainBoard.addText("Main only", x: 20, y: 30)
        var sideBoard = BoardDocument.blank(display: side)
        sideBoard.addText("Side only", x: 40, y: 50)

        try store.saveBoard(mainBoard, for: main, actor: "test", reason: "unit")
        try store.saveBoard(sideBoard, for: side, actor: "test", reason: "unit")

        XCTAssertTrue(FileManager.default.fileExists(atPath: layout.boardURL(forDisplayID: main.id).path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: layout.boardURL(forDisplayID: side.id).path))
        XCTAssertNotEqual(layout.boardURL(forDisplayID: main.id), layout.boardURL(forDisplayID: side.id))
        XCTAssertEqual(try store.loadBoard(for: main).elements.first?.text, "Main only")
        XCTAssertEqual(try store.loadBoard(for: side).elements.first?.text, "Side only")
    }

    func testDisplayWallpaperRenderURLIncludesDisplayIdentifier() {
        let layout = tempLayout()
        let first = layout.wallpaperRenderURL(forDisplayID: "Display/1", id: "render", date: Date(timeIntervalSince1970: 1))
        let second = layout.wallpaperRenderURL(forDisplayID: "Display:2", id: "render", date: Date(timeIntervalSince1970: 1))
        XCTAssertNotEqual(first, second)
        XCTAssertTrue(first.lastPathComponent.contains("Display-1"))
        XCTAssertTrue(second.lastPathComponent.contains("Display-2"))
    }

    private func tempLayout() -> WorkspaceLayout {
        WorkspaceLayout(root: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true))
    }
}
