import XCTest
@testable import MemoryWallCore

final class BoardDocumentTests: XCTestCase {
    func testDefaultBoardIsBlankFiniteCanvas() {
        let display = DisplayProfile(id: "retina", name: "Studio", width: 3840, height: 2160, scale: 2, isMain: true)
        let board = BoardDocument.defaultMemoryWall(display: display, now: Date(timeIntervalSince1970: 0))
        XCTAssertNil(board.metadata.activeTemplateID)
        XCTAssertEqual(board.canvasWidth, 3840)
        XCTAssertEqual(board.canvasHeight, 2160)
        XCTAssertEqual(board.backgroundColor, MemoryWallDefaults.backgroundColor)
        XCTAssertEqual(board.elements, [])
        XCTAssertEqual(board.appState["currentItemFontFamily"], JSONValue.string(MemoryWallDefaults.fontFamily))
    }

    func testAddTextPlacesElementAtExplicitCoordinatesAndTouchesBoard() {
        var board = BoardDocument.defaultMemoryWall(now: Date(timeIntervalSince1970: 0))
        let element = board.addText("给妈妈打电话", x: 320, y: 240, width: 900, height: 150)
        XCTAssertEqual(element.x, 320)
        XCTAssertEqual(element.y, 240)
        XCTAssertTrue(board.elements.contains { $0.text == "给妈妈打电话" && $0.fontSize >= 90 })
        XCTAssertGreaterThan(board.metadata.updatedAt, Date(timeIntervalSince1970: 0))
    }

    func testRetargetCanvasScalesElementsAndStrokePoints() {
        var board = BoardDocument.defaultMemoryWall(display: DisplayProfile(id: "old", name: "Old", width: 100, height: 100, isMain: true))
        board.addText("x", x: 10, y: 20, width: 30, height: 40)
        board.addStroke(points: [BoardPoint(x: 10, y: 10), BoardPoint(x: 30, y: 50)])
        board.retargetCanvas(to: DisplayProfile(id: "new", name: "New", width: 200, height: 300, isMain: true), preserveElements: true)
        XCTAssertEqual(board.canvasWidth, 200)
        XCTAssertEqual(board.canvasHeight, 300)
        XCTAssertEqual(board.elements[0].x, 20)
        XCTAssertEqual(board.elements[0].y, 60)
        let points = board.elements[1].extra["points"]?.arrayValue
        XCTAssertEqual(points?.first?.objectValue?["x"], JSONValue.number(20))
        XCTAssertEqual(points?.last?.objectValue?["y"], JSONValue.number(150))
    }

    func testDecodingOldBoardsBackfillsCanvasFields() throws {
        let json = """
        {
          "id":"old",
          "schemaVersion":1,
          "metadata":{"title":"Old","createdAt":"2026-06-19T00:00:00Z","updatedAt":"2026-06-19T00:00:00Z","activeTemplateID":"default-memory-wall","displayProfile":{"id":"main","name":"Main","width":2560,"height":1440,"scale":2,"isMain":true}},
          "elements":[],
          "appState":{"viewBackgroundColor":"#fff8df"},
          "files":{},
          "rawExcalidraw":{}
        }
        """.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let board = try decoder.decode(BoardDocument.self, from: json)
        XCTAssertEqual(board.canvasWidth, 2560)
        XCTAssertEqual(board.canvasHeight, 1440)
        XCTAssertEqual(board.backgroundColor, "#fff8df")
        XCTAssertEqual(board.appState["currentItemFontFamily"], JSONValue.string(MemoryWallDefaults.fontFamily))
    }

    func testPreservesUnknownJSONValues() throws {
        var board = BoardDocument.defaultMemoryWall()
        board.rawExcalidraw["future"] = .object(["flag": .bool(true), "nested": .array([.number(1), .string("x")])])
        let data = try JSONEncoder().encode(board)
        let decoded = try JSONDecoder().decode(BoardDocument.self, from: data)
        XCTAssertEqual(decoded.rawExcalidraw["future"], board.rawExcalidraw["future"])
    }
}
