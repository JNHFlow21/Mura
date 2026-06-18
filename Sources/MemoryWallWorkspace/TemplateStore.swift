import Foundation
import MemoryWallCore

public protocol TemplateStoring {
    func ensureDefaultTemplates() throws
    func listTemplates() throws -> [MemoryWallTemplate]
    func loadTemplate(id: String) throws -> MemoryWallTemplate
    func applyTemplate(id: String, boardStore: FileBoardStore, actor: String) throws -> BoardDocument
}

public enum TemplateError: LocalizedError, Equatable {
    case missingTemplate(String)

    public var errorDescription: String? {
        switch self {
        case .missingTemplate(let id): return "Missing template: \(id)"
        }
    }
}

public struct FileTemplateStore: TemplateStoring {
    public let layout: WorkspaceLayout
    public let fileManager: FileManager

    public init(layout: WorkspaceLayout, fileManager: FileManager = .default) {
        self.layout = layout
        self.fileManager = fileManager
    }

    public func ensureDefaultTemplates() throws {
        try layout.ensureDirectories(fileManager: fileManager)
        for template in MemoryWallTemplate.defaultTemplates() {
            let url = urlForTemplate(id: template.id)
            if !fileManager.fileExists(atPath: url.path) {
                try BoardCodec.encoder.encode(template).writeAtomically(to: url)
            }
        }
    }

    public func listTemplates() throws -> [MemoryWallTemplate] {
        try ensureDefaultTemplates()
        let urls = try fileManager.contentsOfDirectory(at: layout.templatesDirectory, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "json" }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
        return try urls.map { try BoardCodec.decoder.decode(MemoryWallTemplate.self, from: Data(contentsOf: $0)) }
    }

    public func loadTemplate(id: String) throws -> MemoryWallTemplate {
        try ensureDefaultTemplates()
        let url = urlForTemplate(id: id)
        guard fileManager.fileExists(atPath: url.path) else { throw TemplateError.missingTemplate(id) }
        return try BoardCodec.decoder.decode(MemoryWallTemplate.self, from: Data(contentsOf: url))
    }

    public func applyTemplate(id: String, boardStore: FileBoardStore, actor: String = "app") throws -> BoardDocument {
        let template = try loadTemplate(id: id)
        var board = template.board
        board.id = UUID().uuidString
        board.touch()
        try boardStore.replaceActiveBoard(board, actor: actor, reason: "template.apply.\(id)", snapshotFirst: true)
        return board
    }

    private func urlForTemplate(id: String) -> URL {
        layout.templatesDirectory.appendingPathComponent("\(id).json")
    }
}
