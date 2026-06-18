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
}
