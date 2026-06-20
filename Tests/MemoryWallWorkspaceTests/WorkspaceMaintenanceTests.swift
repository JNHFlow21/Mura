import XCTest
@testable import MemoryWallWorkspace

final class WorkspaceMaintenanceTests: XCTestCase {
    func testPruneKeepsLatestWallpaperRendersAndProtectedCurrentWallpaper() throws {
        let layout = tempLayout()
        try layout.ensureDirectories()
        try Data([9, 9, 9]).write(to: layout.latestRenderURL)

        var renders: [URL] = []
        for index in 0..<7 {
            let url = layout.rendersDirectory.appendingPathComponent("wallpaper-\(index).png")
            try writeFixture(url, bytes: index + 1, date: Date(timeIntervalSince1970: TimeInterval(index)))
            renders.append(url)
        }

        let protectedCurrentWallpaper = renders[0]
        let result = try WorkspaceMaintenance(layout: layout).prune(
            policy: WorkspaceRetentionPolicy(
                maxWallpaperRenders: 3,
                maxPreviewRenders: 0,
                maxBoardSnapshots: 1,
                maxWallpaperSnapshots: 1
            ),
            additionalProtectedURLs: [protectedCurrentWallpaper]
        )

        XCTAssertEqual(result.deletedFiles, 3)
        XCTAssertTrue(FileManager.default.fileExists(atPath: layout.latestRenderURL.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: protectedCurrentWallpaper.path))

        let remainingWallpaperNames = try FileManager.default
            .contentsOfDirectory(at: layout.rendersDirectory, includingPropertiesForKeys: nil)
            .filter { $0.lastPathComponent.hasPrefix("wallpaper-") }
            .map(\.lastPathComponent)
            .sorted()
        XCTAssertEqual(remainingWallpaperNames, ["wallpaper-0.png", "wallpaper-4.png", "wallpaper-5.png", "wallpaper-6.png"])
    }

    func testPruneCapsSnapshots() throws {
        let layout = tempLayout()
        try layout.ensureDirectories()

        for index in 0..<5 {
            try writeFixture(
                layout.boardSnapshotsDirectory.appendingPathComponent("board-\(index).json"),
                bytes: 1,
                date: Date(timeIntervalSince1970: TimeInterval(index))
            )
            try writeFixture(
                layout.wallpaperSnapshotsDirectory.appendingPathComponent("wallpaper-\(index).json"),
                bytes: 1,
                date: Date(timeIntervalSince1970: TimeInterval(index))
            )
        }

        _ = try WorkspaceMaintenance(layout: layout).prune(
            policy: WorkspaceRetentionPolicy(
                maxWallpaperRenders: 1,
                maxPreviewRenders: 0,
                maxBoardSnapshots: 2,
                maxWallpaperSnapshots: 3
            )
        )

        XCTAssertEqual(try snapshotNames(in: layout.boardSnapshotsDirectory), ["board-3.json", "board-4.json"])
        XCTAssertEqual(try snapshotNames(in: layout.wallpaperSnapshotsDirectory), ["wallpaper-2.json", "wallpaper-3.json", "wallpaper-4.json"])
    }

    func testPruneTrimsLargeAuditLog() throws {
        let layout = tempLayout()
        try layout.ensureDirectories()
        let lines = (0..<300).map { #"{"event":\#($0),"message":"xxxxxxxxxxxxxxxxxxxxxxxx"}"# }.joined(separator: "\n") + "\n"
        try lines.write(to: layout.auditLogURL, atomically: true, encoding: .utf8)
        let originalSize = try fileSize(layout.auditLogURL)
        XCTAssertGreaterThan(originalSize, 2_048)

        let result = try WorkspaceMaintenance(layout: layout).prune(
            policy: WorkspaceRetentionPolicy(
                maxWallpaperRenders: 1,
                maxPreviewRenders: 0,
                maxBoardSnapshots: 1,
                maxWallpaperSnapshots: 1,
                maxAuditLogBytes: 2_048,
                keepAuditLogTailBytes: 1_024
            )
        )

        let trimmedSize = try fileSize(layout.auditLogURL)
        XCTAssertLessThan(trimmedSize, originalSize)
        XCTAssertLessThanOrEqual(trimmedSize, 1_024)
        XCTAssertGreaterThan(result.reclaimedBytes, 0)
    }

    private func snapshotNames(in directory: URL) throws -> [String] {
        try FileManager.default
            .contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            .map(\.lastPathComponent)
            .sorted()
    }

    private func writeFixture(_ url: URL, bytes: Int, date: Date) throws {
        try Data(repeating: UInt8(bytes % 255), count: bytes).write(to: url)
        try FileManager.default.setAttributes([.modificationDate: date], ofItemAtPath: url.path)
    }

    private func fileSize(_ url: URL) throws -> Int {
        let values = try url.resourceValues(forKeys: [.fileSizeKey])
        return values.fileSize ?? 0
    }

    private func tempLayout() -> WorkspaceLayout {
        WorkspaceLayout(root: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true))
    }
}
