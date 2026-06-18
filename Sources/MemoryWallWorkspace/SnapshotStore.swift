import Foundation
import MemoryWallCore

public struct BoardSnapshot: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var date: Date
    public var reason: String
    public var boardID: String
    public var fileURL: URL

    public init(id: String = UUID().uuidString, date: Date = Date(), reason: String, boardID: String, fileURL: URL) {
        self.id = id
        self.date = date
        self.reason = reason
        self.boardID = boardID
        self.fileURL = fileURL
    }
}

public protocol BoardSnapshotStoring {
    @discardableResult func createSnapshot(board: BoardDocument, reason: String) throws -> BoardSnapshot
    func latestSnapshot() throws -> BoardSnapshot?
}

public struct FileSnapshotStore: BoardSnapshotStoring {
    public let layout: WorkspaceLayout
    public let fileManager: FileManager

    public init(layout: WorkspaceLayout, fileManager: FileManager = .default) {
        self.layout = layout
        self.fileManager = fileManager
    }

    @discardableResult
    public func createSnapshot(board: BoardDocument, reason: String) throws -> BoardSnapshot {
        try layout.ensureDirectories(fileManager: fileManager)
        let timestamp = Self.timestampFormatter.string(from: Date())
        let safeReason = reason.replacingOccurrences(of: "[^a-zA-Z0-9-]+", with: "-", options: .regularExpression)
        let url = layout.boardSnapshotsDirectory.appendingPathComponent("\(timestamp)-\(safeReason)-\(board.id).json")
        try BoardCodec.encoder.encode(board).writeAtomically(to: url)
        return BoardSnapshot(date: Date(), reason: reason, boardID: board.id, fileURL: url)
    }

    public func latestSnapshot() throws -> BoardSnapshot? {
        guard fileManager.fileExists(atPath: layout.boardSnapshotsDirectory.path) else { return nil }
        let urls = try fileManager.contentsOfDirectory(at: layout.boardSnapshotsDirectory, includingPropertiesForKeys: [.contentModificationDateKey])
            .filter { $0.pathExtension == "json" }
            .sorted { lhs, rhs in
                let l = (try? lhs.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
                let r = (try? rhs.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
                return l < r
            }
        guard let last = urls.last else { return nil }
        let board = try BoardCodec.decoder.decode(BoardDocument.self, from: Data(contentsOf: last))
        let date = (try? last.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date()
        return BoardSnapshot(date: date, reason: "latest", boardID: board.id, fileURL: last)
    }

    private static let timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return formatter
    }()
}
