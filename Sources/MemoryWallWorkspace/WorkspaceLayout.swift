import Foundation
import MemoryWallCore

public struct WorkspaceLayout: Equatable, Sendable {
    public let root: URL

    public init(root: URL) {
        self.root = root.standardizedFileURL
    }

    public static func `default`() -> WorkspaceLayout {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Application Support", isDirectory: true)
        return WorkspaceLayout(root: base.appendingPathComponent("DesktopMemoryWall", isDirectory: true))
    }

    public var boardsDirectory: URL { root.appendingPathComponent("boards", isDirectory: true) }
    public var displayBoardsDirectory: URL { boardsDirectory.appendingPathComponent("displays", isDirectory: true) }
    public var activeBoardURL: URL { boardsDirectory.appendingPathComponent("active-board.json") }
    public var preferencesURL: URL { root.appendingPathComponent("preferences.json") }
    public var rendersDirectory: URL { root.appendingPathComponent("renders", isDirectory: true) }
    public var previewsDirectory: URL { rendersDirectory.appendingPathComponent("previews", isDirectory: true) }
    public var latestRenderURL: URL { rendersDirectory.appendingPathComponent("latest-wallpaper.png") }
    public func boardURL(forDisplayID displayID: String) -> URL {
        displayBoardsDirectory.appendingPathComponent("\(Self.safePathComponent(displayID)).json")
    }
    public func wallpaperRenderURL(id: String = UUID().uuidString, date: Date = Date()) -> URL {
        let milliseconds = Int(date.timeIntervalSince1970 * 1000)
        let safeID = id.replacingOccurrences(of: "/", with: "-")
        return rendersDirectory.appendingPathComponent("wallpaper-\(milliseconds)-\(safeID).png")
    }
    public func wallpaperRenderURL(forDisplayID displayID: String, id: String = UUID().uuidString, date: Date = Date()) -> URL {
        let milliseconds = Int(date.timeIntervalSince1970 * 1000)
        return rendersDirectory.appendingPathComponent("wallpaper-\(Self.safePathComponent(displayID))-\(milliseconds)-\(Self.safePathComponent(id)).png")
    }
    public var snapshotsDirectory: URL { root.appendingPathComponent("snapshots", isDirectory: true) }
    public var boardSnapshotsDirectory: URL { snapshotsDirectory.appendingPathComponent("boards", isDirectory: true) }
    public var wallpaperSnapshotsDirectory: URL { snapshotsDirectory.appendingPathComponent("wallpapers", isDirectory: true) }
    public var logsDirectory: URL { root.appendingPathComponent("logs", isDirectory: true) }
    public var auditLogURL: URL { logsDirectory.appendingPathComponent("audit.jsonl") }
    public var docsDirectory: URL { root.appendingPathComponent("docs", isDirectory: true) }
    public var agentDocsDirectory: URL { docsDirectory.appendingPathComponent("agent", isDirectory: true) }
    public var contextURL: URL { agentDocsDirectory.appendingPathComponent("context.md") }

    public func ensureDirectories(fileManager: FileManager = .default) throws {
        for directory in [root, boardsDirectory, displayBoardsDirectory, rendersDirectory, previewsDirectory, snapshotsDirectory, boardSnapshotsDirectory, wallpaperSnapshotsDirectory, logsDirectory, docsDirectory, agentDocsDirectory] {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }
    }

    public func ensureSeedFiles(fileManager: FileManager = .default) throws {
        try ensureDirectories(fileManager: fileManager)
        if !fileManager.fileExists(atPath: activeBoardURL.path) {
            try BoardCodec.encoder.encode(BoardDocument.defaultMemoryWall()).writeAtomically(to: activeBoardURL)
        }
        if !fileManager.fileExists(atPath: preferencesURL.path) {
            try BoardCodec.encoder.encode(MemoryWallPreferences()).writeAtomically(to: preferencesURL)
        }
        if !fileManager.fileExists(atPath: contextURL.path) {
            try defaultAgentContext.write(to: contextURL, atomically: true, encoding: .utf8)
        }
        if !fileManager.fileExists(atPath: auditLogURL.path) {
            fileManager.createFile(atPath: auditLogURL.path, contents: nil)
        }
    }

    public static func safePathComponent(_ value: String) -> String {
        let pattern = "[^a-zA-Z0-9._-]+"
        let sanitized = value.replacingOccurrences(of: pattern, with: "-", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-."))
        return sanitized.isEmpty ? "display" : sanitized
    }
}

public enum BoardCodec {
    public static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    public static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}

private let defaultAgentContext = """
# Mura Agent Context

- Keep reminders extremely large and readable from desktop distance.
- Prefer a hand-drawn Excalidraw-like feel: warm paper background, dark ink, minimal color accents.
- The active board starts blank; agents should place text or strokes explicitly by coordinate.
- Keep everything local-first. Do not sync, upload, or infer private reminders without explicit user intent.
- Agents should preview before changing wallpaper and require confirmation before destructive visible actions.
"""

extension Data {
    func writeAtomically(to url: URL) throws {
        try write(to: url, options: [.atomic])
    }
}
