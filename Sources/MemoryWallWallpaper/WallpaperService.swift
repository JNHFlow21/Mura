import AppKit
import Foundation
import MemoryWallCore
import MemoryWallRenderer
import MemoryWallWorkspace

public protocol WallpaperBackend {
    func currentImageURL(for display: DisplayProfile) throws -> URL?
    func setImageURL(_ url: URL, for display: DisplayProfile, options: [String: String]) throws
}

public struct AppKitWallpaperBackend: WallpaperBackend {
    public init() {}

    public func currentImageURL(for display: DisplayProfile) throws -> URL? {
        guard let screen = NSScreen.screen(matching: display) ?? NSScreen.main else { return nil }
        return NSWorkspace.shared.desktopImageURL(for: screen)
    }

    public func setImageURL(_ url: URL, for display: DisplayProfile, options: [String: String]) throws {
        guard let screen = NSScreen.screen(matching: display) ?? NSScreen.main else { throw WallpaperError.backend("No NSScreen found for display \(display.id)") }
        let mapped: [NSWorkspace.DesktopImageOptionKey: Any] = [
            .imageScaling: NSImageScaling.scaleAxesIndependently.rawValue,
            .allowClipping: false
        ]
        try NSWorkspace.shared.setDesktopImageURL(url, for: screen, options: mapped)
    }
}

public final class WallpaperService {
    public let layout: WorkspaceLayout
    public let backend: WallpaperBackend
    public let auditLog: FileAuditLog
    public let fileManager: FileManager

    public init(layout: WorkspaceLayout, backend: WallpaperBackend = AppKitWallpaperBackend(), fileManager: FileManager = .default) {
        self.layout = layout
        self.backend = backend
        self.auditLog = FileAuditLog(layout: layout, fileManager: fileManager)
        self.fileManager = fileManager
    }

    @discardableResult
    public func apply(render: RenderOutput, display: DisplayProfile, confirm: Bool, actor: String = "app") throws -> WallpaperSnapshot {
        guard confirm else { throw WallpaperError.confirmationRequired("wallpaper.apply") }
        guard fileManager.fileExists(atPath: render.fileURL.path) else { throw WallpaperError.missingImage(render.fileURL) }
        try layout.ensureDirectories(fileManager: fileManager)
        let previous = try backend.currentImageURL(for: display)
        let snapshot = WallpaperSnapshot(display: display, previousImageURL: previous, appliedImageURL: render.fileURL, options: ["imageScaling": "scaleAxesIndependently", "allowClipping": "false"])
        try write(snapshot: snapshot)
        do {
            try backend.setImageURL(render.fileURL, for: display, options: snapshot.options)
            try auditLog.append(AuditEvent(actor: actor, action: "wallpaper.apply", target: render.fileURL.path, metadata: ["display": .string(display.id)]))
            return snapshot
        } catch {
            throw WallpaperError.backend(error.localizedDescription)
        }
    }

    @discardableResult
    public func restore(display: DisplayProfile, confirm: Bool, actor: String = "app") throws -> WallpaperSnapshot {
        guard confirm else { throw WallpaperError.confirmationRequired("wallpaper.restore") }
        guard let snapshot = try latestSnapshot() else { throw WallpaperError.noSnapshot }
        guard let previous = snapshot.previousImageURL else { throw WallpaperError.noSnapshot }
        guard fileManager.fileExists(atPath: previous.path) else { throw WallpaperError.missingImage(previous) }
        try backend.setImageURL(previous, for: display, options: snapshot.options)
        try auditLog.append(AuditEvent(actor: actor, action: "wallpaper.restore", target: previous.path, metadata: ["display": .string(display.id), "snapshot": .string(snapshot.id)]))
        return snapshot
    }

    public func latestSnapshot() throws -> WallpaperSnapshot? {
        guard fileManager.fileExists(atPath: layout.wallpaperSnapshotsDirectory.path) else { return nil }
        let urls = try fileManager.contentsOfDirectory(at: layout.wallpaperSnapshotsDirectory, includingPropertiesForKeys: [.contentModificationDateKey])
            .filter { $0.pathExtension == "json" }
            .sorted { lhs, rhs in
                let l = (try? lhs.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
                let r = (try? rhs.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
                return l < r
            }
        guard let last = urls.last else { return nil }
        return try BoardCodec.decoder.decode(WallpaperSnapshot.self, from: Data(contentsOf: last))
    }

    private func write(snapshot: WallpaperSnapshot) throws {
        try layout.ensureDirectories(fileManager: fileManager)
        let url = layout.wallpaperSnapshotsDirectory.appendingPathComponent("\(Self.timestampFormatter.string(from: snapshot.createdAt))-\(snapshot.id).json")
        try BoardCodec.encoder.encode(snapshot).write(to: url, options: [.atomic])
    }

    private static let timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return formatter
    }()
}

private extension NSScreen {
    static func screen(matching display: DisplayProfile) -> NSScreen? {
        NSScreen.screens.first { screen in
            let deviceID = (screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.stringValue
            return deviceID == display.id || (display.isMain && screen == NSScreen.main)
        }
    }
}
