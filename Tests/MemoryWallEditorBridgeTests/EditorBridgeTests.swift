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

    func testBundledEditorAndFontAssetsExist() throws {
        let locator = LocalEditorAssetLocator()
        let index = try locator.indexURL()
        let font = try locator.fontURL()
        XCTAssertTrue(FileManager.default.fileExists(atPath: index.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: font.path))
    }
}
