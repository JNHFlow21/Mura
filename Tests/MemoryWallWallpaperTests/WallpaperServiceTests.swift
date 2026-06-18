import Foundation
import XCTest
import MemoryWallCore
import MemoryWallRenderer
@testable import MemoryWallWallpaper
import MemoryWallWorkspace

final class WallpaperServiceTests: XCTestCase {
    func testApplyRecordsPreviousWallpaperBeforeSettingNewImage() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let layout = WorkspaceLayout(root: root)
        try layout.ensureDirectories()
        let previous = root.appendingPathComponent("previous.png")
        let next = root.appendingPathComponent("next.png")
        try Data([1,2,3]).write(to: previous)
        try Data([4,5,6]).write(to: next)
        let backend = FakeWallpaperBackend(previous: previous)
        let service = WallpaperService(layout: layout, backend: backend)
        let output = RenderOutput(fileURL: next, width: 100, height: 100, purpose: .wallpaper, byteCount: 3)
        let snapshot = try service.apply(render: output, display: .fallback, confirm: true, actor: "test")
        XCTAssertEqual(snapshot.previousImageURL, previous)
        XCTAssertEqual(backend.setCalls.last, next)
        XCTAssertNotNil(try service.latestSnapshot())
    }

    func testApplyRequiresConfirmation() throws {
        let layout = WorkspaceLayout(root: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true))
        let service = WallpaperService(layout: layout, backend: FakeWallpaperBackend(previous: nil))
        XCTAssertThrowsError(try service.apply(render: RenderOutput(fileURL: URL(fileURLWithPath: "/tmp/missing.png"), width: 1, height: 1, purpose: .wallpaper, byteCount: 0), display: .fallback, confirm: false))
    }
}

final class FakeWallpaperBackend: WallpaperBackend {
    let previous: URL?
    var setCalls: [URL] = []
    init(previous: URL?) { self.previous = previous }
    func currentImageURL(for display: DisplayProfile) throws -> URL? { previous }
    func setImageURL(_ url: URL, for display: DisplayProfile, options: [String : String]) throws { setCalls.append(url) }
}
