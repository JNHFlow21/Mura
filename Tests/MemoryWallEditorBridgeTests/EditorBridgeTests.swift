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
