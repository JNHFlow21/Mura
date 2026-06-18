import Foundation
import MemoryWallCore

public struct AuditEvent: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var date: Date
    public var actor: String
    public var action: String
    public var target: String
    public var metadata: [String: JSONValue]

    public init(id: String = UUID().uuidString, date: Date = Date(), actor: String, action: String, target: String, metadata: [String: JSONValue] = [:]) {
        self.id = id
        self.date = date
        self.actor = actor
        self.action = action
        self.target = target
        self.metadata = metadata
    }
}

public protocol AuditLogging {
    func append(_ event: AuditEvent) throws
    func readAll(limit: Int?) throws -> [AuditEvent]
}

public struct FileAuditLog: AuditLogging {
    public let layout: WorkspaceLayout
    public let fileManager: FileManager

    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    public init(layout: WorkspaceLayout, fileManager: FileManager = .default) {
        self.layout = layout
        self.fileManager = fileManager
    }

    public func append(_ event: AuditEvent) throws {
        try layout.ensureDirectories(fileManager: fileManager)
        let data = try Self.encoder.encode(event)
        var line = data
        line.append(0x0A)
        if !fileManager.fileExists(atPath: layout.auditLogURL.path) {
            fileManager.createFile(atPath: layout.auditLogURL.path, contents: nil)
        }
        let handle = try FileHandle(forWritingTo: layout.auditLogURL)
        defer { try? handle.close() }
        try handle.seekToEnd()
        try handle.write(contentsOf: line)
    }

    public func readAll(limit: Int? = nil) throws -> [AuditEvent] {
        guard fileManager.fileExists(atPath: layout.auditLogURL.path) else { return [] }
        let text = try String(contentsOf: layout.auditLogURL, encoding: .utf8)
        let events = try text.split(separator: "\n").map { line in
            try BoardCodec.decoder.decode(AuditEvent.self, from: Data(line.utf8))
        }
        guard let limit else { return events }
        return Array(events.suffix(limit))
    }
}
