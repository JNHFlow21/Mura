import XCTest
import MemoryWallCore
@testable import MemoryWallEditorBridge

final class EditorBridgeTests: XCTestCase {
    func testDecodesReadyMessage() throws {
        let message = try EditorBridgeMessage.decode(json: "{\"kind\":\"ready\",\"payload\":{}}")
        XCTAssertEqual(message.kind, EditorBridgeMessage.Kind.ready)
    }

    func testDecodesExportMessageWithBoardAndPNGDataURL() throws {
        let board = BoardDocument.defaultMemoryWall()
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let boardData = try encoder.encode(board)
        let boardJSON = String(data: boardData, encoding: .utf8)!
        let json = "{\"kind\":\"exportPNG\",\"board\":\(boardJSON),\"payload\":{\"pngDataURL\":\"data:image/png;base64,QUJD\"}}"
        let message = try EditorBridgeMessage.decode(json: json)
        XCTAssertEqual(message.kind, EditorBridgeMessage.Kind.exportPNG)
        XCTAssertEqual(message.board?.elements.count, 0)
        XCTAssertEqual(try EditorExportCodec.pngData(fromDataURL: try XCTUnwrap(message.pngDataURL)), Data("ABC".utf8))
    }

    func testDecodesExportMessageWithTextAndFreedrawElements() throws {
        var board = BoardDocument.defaultMemoryWall()
        board.addText("WKTEST", x: 120, y: 160)
        board.addStroke(points: [BoardPoint(x: 10, y: 10), BoardPoint(x: 80, y: 60), BoardPoint(x: 120, y: 40)])
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let boardJSON = String(data: try encoder.encode(board), encoding: .utf8)!
        let json = "{\"kind\":\"exportPNG\",\"board\":\(boardJSON),\"payload\":{\"pngDataURL\":\"data:image/png;base64,QUJD\"}}"
        let message = try EditorBridgeMessage.decode(json: json)
        XCTAssertEqual(message.board?.elements.map(\.type), [.text, .freedraw])
        XCTAssertEqual(message.board?.elements.first?.text, "WKTEST")
        XCTAssertEqual(message.board?.elements.last?.extra["points"]?.arrayValue?.count, 3)
    }

    func testDecodesDisplayExports() throws {
        let main = DisplayProfile(id: "main", name: "Main", width: 1920, height: 1080, scale: 2, isMain: true)
        let side = DisplayProfile(id: "side", name: "Side", width: 1280, height: 720, scale: 1, isMain: false)
        var mainBoard = BoardDocument.blank(display: main)
        mainBoard.addText("Main", x: 10, y: 20)
        let sideBoard = BoardDocument.blank(display: side)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let mainJSON = String(data: try encoder.encode(mainBoard), encoding: .utf8)!
        let sideJSON = String(data: try encoder.encode(sideBoard), encoding: .utf8)!
        let json = """
        {
          "kind":"exportPNG",
          "board":\(mainJSON),
          "payload":{"selectedDisplayID":"main"},
          "displayExports":[
            {"displayID":"main","board":\(mainJSON),"pngDataURL":"data:image/png;base64,QUJD","width":1920,"height":1080},
            {"displayID":"side","board":\(sideJSON),"pngDataURL":"data:image/png;base64,REVG","width":1280,"height":720}
          ]
        }
        """
        let message = try EditorBridgeMessage.decode(json: json)
        XCTAssertEqual(message.displayExports?.count, 2)
        XCTAssertEqual(message.displayExports?.first?.displayID, "main")
        XCTAssertEqual(message.displayExports?.last?.board.canvasWidth, 1280)
        XCTAssertEqual(try EditorExportCodec.pngData(fromDataURL: try XCTUnwrap(message.displayExports?.last?.pngDataURL)), Data("DEF".utf8))
    }

    func testDecodesEditorDatesWithFractionalSeconds() throws {
        let json = """
        {
          "kind":"exportPNG",
          "board":{
            "id":"js-board",
            "schemaVersion":2,
            "metadata":{"title":"Desktop Memory Wall","createdAt":"2026-06-19T05:46:07.123Z","updatedAt":"2026-06-19T05:46:08.456Z","activeTemplateID":null,"displayProfile":{"id":"main","name":"Main Display","width":1920,"height":1080,"scale":1,"isMain":true}},
            "canvasWidth":1920,
            "canvasHeight":1080,
            "backgroundColor":"#fff8df",
            "elements":[],
            "appState":{"viewBackgroundColor":"#fff8df","currentItemFontFamily":"LXGW WenKai","theme":"light"},
            "files":{},
            "rawExcalidraw":{"type":"desktop-memory-wall-canvas","version":2}
          },
          "payload":{"pngDataURL":"data:image/png;base64,QUJD"}
        }
        """
        let message = try EditorBridgeMessage.decode(json: json)
        XCTAssertEqual(message.kind, EditorBridgeMessage.Kind.exportPNG)
        XCTAssertEqual(message.board?.id, "js-board")
        XCTAssertEqual(message.board?.canvasWidth, 1920)
    }

    func testRejectsInvalidBridgeMessages() {
        XCTAssertThrowsError(try EditorBridgeMessage.decode(json: "not-json"))
        XCTAssertThrowsError(try EditorExportCodec.pngData(fromDataURL: "data:image/jpeg;base64,AAAA"))
    }

    @MainActor
    func testCoordinatorMarksCachedNativeBoardLoadsAsLoaded() {
        let coordinator = WebEditorCoordinator()
        XCTAssertTrue(coordinator.markNativeBoardLoadStarted("board-json"))
        XCTAssertFalse(coordinator.markNativeBoardLoadStarted("board-json"))
        XCTAssertFalse(coordinator.markNativeBoardLoadStarted("newer-native-json"))
        XCTAssertEqual(coordinator.lastLoadedBoardJSON, "board-json")
    }

    @MainActor
    func testCoordinatorAllowsRetryAfterNativeBoardLoadFailure() {
        let coordinator = WebEditorCoordinator()
        XCTAssertTrue(coordinator.markNativeBoardLoadStarted("board-json"))
        coordinator.markNativeBoardLoadFailed("board-json")
        XCTAssertNil(coordinator.lastLoadedBoardJSON)
        XCTAssertTrue(coordinator.markNativeBoardLoadStarted("board-json"))
    }

    func testBundledEditorAndFontAssetsExist() throws {
        let locator = LocalEditorAssetLocator()
        let index = try locator.indexURL()
        let font = try locator.fontURL()
        XCTAssertTrue(FileManager.default.fileExists(atPath: index.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: font.path))
    }
}
