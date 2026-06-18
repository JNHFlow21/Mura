import XCTest
@testable import MemoryWallCore

final class BoardDocumentTests: XCTestCase {
    func testDefaultBoardUsesLargeReadableText() {
        let board = BoardDocument.defaultMemoryWall(now: Date(timeIntervalSince1970: 0))
        XCTAssertEqual(board.metadata.activeTemplateID, "default-memory-wall")
        XCTAssertGreaterThanOrEqual(board.elements.first?.fontSize ?? 0, 120)
        XCTAssertTrue(board.elements.contains { $0.text.contains("今天只做") })
    }

    func testAppendReminderAddsLargeTextAndTouchesBoard() {
        var board = BoardDocument.defaultMemoryWall(now: Date(timeIntervalSince1970: 0))
        board.appendReminder("给妈妈打电话")
        XCTAssertTrue(board.elements.contains { $0.text == "给妈妈打电话" && $0.fontSize >= 90 })
        XCTAssertGreaterThan(board.metadata.updatedAt, Date(timeIntervalSince1970: 0))
    }

    func testPreservesUnknownJSONValues() throws {
        var board = BoardDocument.defaultMemoryWall()
        board.rawExcalidraw["future"] = .object(["flag": .bool(true), "nested": .array([.number(1), .string("x")])])
        let data = try JSONEncoder().encode(board)
        let decoded = try JSONDecoder().decode(BoardDocument.self, from: data)
        XCTAssertEqual(decoded.rawExcalidraw["future"], board.rawExcalidraw["future"])
    }
}
