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
    func loadBoard(for display: DisplayProfile) throws -> BoardDocument
    func loadBoards(for displays: [DisplayProfile]) throws -> [String: BoardDocument]
    func saveActiveBoard(_ board: BoardDocument, actor: String, reason: String) throws
    func saveBoard(_ board: BoardDocument, for display: DisplayProfile, actor: String, reason: String) throws
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

    public func loadBoard(for display: DisplayProfile) throws -> BoardDocument {
        try ensureWorkspace()
        let url = layout.boardURL(forDisplayID: display.id)
        guard fileManager.fileExists(atPath: url.path) else {
            return .blank(display: display)
        }
        do {
            var board = try BoardCodec.decoder.decode(BoardDocument.self, from: Data(contentsOf: url))
            if board.metadata.displayProfile.id != display.id {
                board.metadata.displayProfile = display
            }
            if board.canvasWidth != display.width || board.canvasHeight != display.height {
                board.retargetCanvas(to: display, preserveElements: true)
            }
            return board
        } catch {
            throw WorkspaceError.corruptBoard(error.localizedDescription)
        }
    }

    public func loadBoards(for displays: [DisplayProfile]) throws -> [String: BoardDocument] {
        var boards: [String: BoardDocument] = [:]
        for display in displays {
            boards[display.id] = try loadBoard(for: display)
        }
        return boards
    }

    public func saveActiveBoard(_ board: BoardDocument, actor: String = "app", reason: String = "save") throws {
        var updated = board
        updated.touch()
        try layout.ensureDirectories(fileManager: fileManager)
        try BoardCodec.encoder.encode(updated).writeAtomically(to: layout.activeBoardURL)
        try auditLog.append(AuditEvent(actor: actor, action: "board.save", target: layout.activeBoardURL.path, metadata: ["reason": .string(reason), "boardID": .string(updated.id)]))
    }

    public func saveBoard(_ board: BoardDocument, for display: DisplayProfile, actor: String = "app", reason: String = "save") throws {
        var updated = board
        updated.metadata.activeTemplateID = nil
        updated.metadata.displayProfile = display
        if updated.canvasWidth != display.width || updated.canvasHeight != display.height {
            updated.retargetCanvas(to: display, preserveElements: true)
        } else {
            updated.touch()
        }
        try layout.ensureDirectories(fileManager: fileManager)
        let url = layout.boardURL(forDisplayID: display.id)
        try BoardCodec.encoder.encode(updated).writeAtomically(to: url)
        try auditLog.append(AuditEvent(actor: actor, action: "board.save.display", target: url.path, metadata: ["reason": .string(reason), "boardID": .string(updated.id), "display": .string(display.id)]))
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
