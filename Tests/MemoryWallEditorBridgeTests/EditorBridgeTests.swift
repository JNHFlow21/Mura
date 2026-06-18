import XCTest
import MemoryWallCore
@testable import MemoryWallEditorBridge

final class EditorBridgeTests: XCTestCase {
    func testDecodesReadyMessage() throws {
        let message = try EditorBridgeMessage.decode(json: "{\"kind\":\"ready\",\"payload\":{}}")
        XCTAssertEqual(message.kind, .ready)
    }

    func testRejectsInvalidBridgeMessages() {
        XCTAssertThrowsError(try EditorBridgeMessage.decode(json: "not-json"))
    }

    func testBundledEditorAssetExists() throws {
        let url = try LocalEditorAssetLocator().indexURL()
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
    }
}
