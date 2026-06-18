import Foundation
import MemoryWallCore

public enum WorkspaceError: LocalizedError, Equatable {
    case corruptBoard(String)
    case missingBoard(URL)

    public var errorDescription: String? {
        switch self {
        case .corruptBoard(let message): return "Board JSON is corrupt: \(message)"
        case .missingBoard(let url): return "Missing board at \(url.path)"
        }
    }
}

public protocol BoardStoring {
    func ensureWorkspace() throws
    func loadActiveBoard() throws -> BoardDocument
    func saveActiveBoard(_ board: BoardDocument, actor: String, reason: String) throws
    func replaceActiveBoard(_ board: BoardDocument, actor: String, reason: String, snapshotFirst: Bool) throws
    func loadPreferences() throws -> MemoryWallPreferences
    func savePreferences(_ preferences: MemoryWallPreferences) throws
}

public struct FileBoardStore: BoardStoring {
    public let layout: WorkspaceLayout
    public let fileManager: FileManager
    public let snapshotStore: FileSnapshotStore
    public let auditLog: FileAuditLog

    public init(layout: WorkspaceLayout, fileManager: FileManager = .default) {
        self.layout = layout
        self.fileManager = fileManager
        self.snapshotStore = FileSnapshotStore(layout: layout, fileManager: fileManager)
        self.auditLog = FileAuditLog(layout: layout, fileManager: fileManager)
    }

    public func ensureWorkspace() throws {
        try layout.ensureSeedFiles(fileManager: fileManager)
    }

    public func loadActiveBoard() throws -> BoardDocument {
        try ensureWorkspace()
        guard fileManager.fileExists(atPath: layout.activeBoardURL.path) else { throw WorkspaceError.missingBoard(layout.activeBoardURL) }
        do {
            return try BoardCodec.decoder.decode(BoardDocument.self, from: Data(contentsOf: layout.activeBoardURL))
        } catch {
            throw WorkspaceError.corruptBoard(error.localizedDescription)
        }
    }

    public func saveActiveBoard(_ board: BoardDocument, actor: String = "app", reason: String = "save") throws {
        var updated = board
        updated.touch()
        try layout.ensureDirectories(fileManager: fileManager)
        try BoardCodec.encoder.encode(updated).writeAtomically(to: layout.activeBoardURL)
        try auditLog.append(AuditEvent(actor: actor, action: "board.save", target: layout.activeBoardURL.path, metadata: ["reason": .string(reason), "boardID": .string(updated.id)]))
    }

    public func replaceActiveBoard(_ board: BoardDocument, actor: String = "app", reason: String = "replace", snapshotFirst: Bool = true) throws {
        if snapshotFirst, let current = try? loadActiveBoard() {
            _ = try snapshotStore.createSnapshot(board: current, reason: reason)
        }
        try saveActiveBoard(board, actor: actor, reason: reason)
    }

    public func loadPreferences() throws -> MemoryWallPreferences {
        try ensureWorkspace()
        return try BoardCodec.decoder.decode(MemoryWallPreferences.self, from: Data(contentsOf: layout.preferencesURL))
    }

    public func savePreferences(_ preferences: MemoryWallPreferences) throws {
        try layout.ensureDirectories(fileManager: fileManager)
        try BoardCodec.encoder.encode(preferences).writeAtomically(to: layout.preferencesURL)
        try auditLog.append(AuditEvent(actor: "app", action: "preferences.save", target: layout.preferencesURL.path))
    }
}
