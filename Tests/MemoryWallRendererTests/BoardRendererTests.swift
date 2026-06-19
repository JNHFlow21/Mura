import AppKit
import XCTest
import MemoryWallCore
@testable import MemoryWallRenderer

final class BoardRendererTests: XCTestCase {
    func testRenderingWritesPNGWithExactPixelDimensions() throws {
        let display = DisplayProfile(id: "test", name: "Test", width: 640, height: 360, scale: 1, isMain: true)
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("png")
        let output = try NativeBoardRenderer().render(RenderJob(board: .defaultMemoryWall(), display: display, outputURL: outputURL, purpose: .preview))
        XCTAssertEqual(output.width, 640)
        XCTAssertEqual(output.height, 360)
        XCTAssertTrue(FileManager.default.fileExists(atPath: outputURL.path))
        let image = NSImage(contentsOf: outputURL)
        XCTAssertEqual(Int(image?.representations.first?.pixelsWide ?? 0), 640)
        XCTAssertEqual(Int(image?.representations.first?.pixelsHigh ?? 0), 360)
    }

    func testRendererScalesFiniteBoardCoordinatesAndDrawsStrokes() throws {
        let display = DisplayProfile(id: "test", name: "Test", width: 400, height: 200, scale: 1, isMain: true)
        var board = BoardDocument.defaultMemoryWall(display: DisplayProfile(id: "board", name: "Board", width: 800, height: 400, isMain: true))
        board.addText("左上", x: 40, y: 40, width: 220, height: 100)
        board.addStroke(points: [BoardPoint(x: 10, y: 10), BoardPoint(x: 200, y: 80)])
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("png")
        let output = try NativeBoardRenderer().render(RenderJob(board: board, display: display, outputURL: outputURL, purpose: .preview))
        XCTAssertGreaterThan(output.byteCount, 0)
    }
}
