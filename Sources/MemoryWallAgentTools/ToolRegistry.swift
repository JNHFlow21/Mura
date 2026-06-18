import Foundation
import MemoryWallCore
import MemoryWallRenderer
import MemoryWallWallpaper
import MemoryWallWorkspace

public enum ToolRegistryError: LocalizedError, Equatable {
    case unknownCommand(String)
    case missingArgument(String)

    public var errorDescription: String? {
        switch self {
        case .unknownCommand(let command): return "Unknown command: \(command)"
        case .missingArgument(let argument): return "Missing argument: \(argument)"
        }
    }
}

public final class ToolRegistry {
    public var context: ToolContext

    public init(context: ToolContext) {
        self.context = context
    }

    public func run(arguments: [String]) -> ToolResult {
        do {
            var args = arguments
            let json = args.removeFlag("--json")
            _ = json
            if let workspace = args.removeValue(after: "--workspace") {
                let layout = WorkspaceLayout(root: URL(fileURLWithPath: workspace))
                context = ToolContext(layout: layout, renderer: context.renderer, displayService: context.displayService)
            }
            guard let command = args.first else { throw ToolRegistryError.missingArgument("command") }
            args.removeFirst()
            switch command {
            case "status": return try status()
            case "diagnostics": return try diagnostics()
            case "displays": return try displays(args)
            case "board": return try board(args)
            case "render": return try render(args)
            case "wallpaper": return try wallpaper(args)
            case "templates", "template": return try templates(args)
            case "audit": return try audit(args)
            default: throw ToolRegistryError.unknownCommand(command)
            }
        } catch {
            return .failure(error.localizedDescription)
        }
    }

    private func status() throws -> ToolResult {
        try context.boardStore.ensureWorkspace()
        let board = try context.boardStore.loadActiveBoard()
        let display = context.displayService.mainDisplay()
        let latestRenderExists = FileManager.default.fileExists(atPath: context.layout.latestRenderURL.path)
        return .success("status", data: .object([
            "workspace": .string(context.layout.root.path),
            "boardID": .string(board.id),
            "boardTitle": .string(board.metadata.title),
            "elementCount": .number(Double(board.elements.count)),
            "mainDisplay": display.jsonValue,
            "latestRenderExists": .bool(latestRenderExists)
        ]))
    }

    private func diagnostics() throws -> ToolResult {
        let board = try context.boardStore.loadActiveBoard()
        let auditEvents = (try? FileAuditLog(layout: context.layout).readAll(limit: 5)) ?? []
        return .success("diagnostics", data: .object([
            "workspace": .string(context.layout.root.path),
            "activeBoard": .object(["id": .string(board.id), "title": .string(board.metadata.title), "elements": .number(Double(board.elements.count))]),
            "displayCount": .number(Double(context.displayService.displays().count)),
            "latestRender": .string(context.layout.latestRenderURL.path),
            "latestRenderExists": .bool(FileManager.default.fileExists(atPath: context.layout.latestRenderURL.path)),
            "editorAsset": .string("Resources/Editor/index.html"),
            "auditEvents": .number(Double(auditEvents.count))
        ]))
    }

    private func displays(_ args: [String]) throws -> ToolResult {
        guard args.first == "list" else { throw ToolRegistryError.unknownCommand("displays \(args.joined(separator: " "))") }
        return .success("displays.list", data: .array(context.displayService.displays().map(\.jsonValue)))
    }

    private func board(_ args: [String]) throws -> ToolResult {
        guard let subcommand = args.first else { throw ToolRegistryError.missingArgument("board subcommand") }
        var remaining = Array(args.dropFirst())
        switch subcommand {
        case "read":
            let board = try context.boardStore.loadActiveBoard()
            return .success("board.read", data: try board.asJSONValue())
        case "patch":
            guard let text = remaining.removeValue(after: "--text") else { throw ToolRegistryError.missingArgument("--text") }
            var board = try context.boardStore.loadActiveBoard()
            board.appendReminder(text)
            try context.boardStore.saveActiveBoard(board, actor: "dmwctl", reason: "board.patch")
            return .success("board.patch", data: .object(["boardID": .string(board.id), "elementCount": .number(Double(board.elements.count))]))
        case "write":
            guard let file = remaining.removeValue(after: "--file") else { throw ToolRegistryError.missingArgument("--file") }
            let board = try BoardCodec.decoder.decode(BoardDocument.self, from: Data(contentsOf: URL(fileURLWithPath: file)))
            try context.boardStore.replaceActiveBoard(board, actor: "dmwctl", reason: "board.write", snapshotFirst: true)
            return .success("board.write", data: .object(["boardID": .string(board.id)]))
        default:
            throw ToolRegistryError.unknownCommand("board \(subcommand)")
        }
    }

    private func render(_ args: [String]) throws -> ToolResult {
        guard args.first == "preview" else { throw ToolRegistryError.unknownCommand("render \(args.joined(separator: " "))") }
        var remaining = Array(args.dropFirst())
        let width = Int(remaining.removeValue(after: "--width") ?? "") ?? context.displayService.mainDisplay().width
        let height = Int(remaining.removeValue(after: "--height") ?? "") ?? context.displayService.mainDisplay().height
        let purpose: RenderPurpose = remaining.removeFlag("--wallpaper") ? .wallpaper : .preview
        let display = DisplayProfile(id: "preview", name: "Preview", width: width, height: height, scale: 1, isMain: true)
        let board = try context.boardStore.loadActiveBoard()
        let outputURL = purpose == .wallpaper ? context.layout.latestRenderURL : context.layout.previewsDirectory.appendingPathComponent("preview-\(width)x\(height).png")
        let output = try context.renderer.render(RenderJob(board: board, display: display, outputURL: outputURL, purpose: purpose))
        try FileAuditLog(layout: context.layout).append(AuditEvent(actor: "dmwctl", action: "render.preview", target: output.fileURL.path, metadata: ["purpose": .string(output.purpose.rawValue)]))
        return .success("render.preview", data: .object(["file": .string(output.fileURL.path), "width": .number(Double(output.width)), "height": .number(Double(output.height)), "bytes": .number(Double(output.byteCount))]))
    }

    private func wallpaper(_ args: [String]) throws -> ToolResult {
        guard let subcommand = args.first else { throw ToolRegistryError.missingArgument("wallpaper subcommand") }
        let confirm = args.contains("--confirm")
        let display = context.displayService.mainDisplay()
        switch subcommand {
        case "apply":
            let output = RenderOutput(fileURL: context.layout.latestRenderURL, width: display.width, height: display.height, purpose: .wallpaper, byteCount: (try? Data(contentsOf: context.layout.latestRenderURL).count) ?? 0)
            let snapshot = try context.wallpaperService.apply(render: output, display: display, confirm: confirm, actor: "dmwctl")
            return .success("wallpaper.apply", data: .object(["snapshotID": .string(snapshot.id)]))
        case "restore":
            let snapshot = try context.wallpaperService.restore(display: display, confirm: confirm, actor: "dmwctl")
            return .success("wallpaper.restore", data: .object(["snapshotID": .string(snapshot.id)]))
        default:
            throw ToolRegistryError.unknownCommand("wallpaper \(subcommand)")
        }
    }

    private func templates(_ args: [String]) throws -> ToolResult {
        guard let subcommand = args.first else { throw ToolRegistryError.missingArgument("template subcommand") }
        switch subcommand {
        case "list":
            let templates = try context.templateStore.listTemplates()
            return .success("templates.list", data: .array(templates.map { .object(["id": .string($0.id), "name": .string($0.name)]) }))
        case "apply":
            var remaining = Array(args.dropFirst())
            let id = remaining.removeValue(after: "--id") ?? remaining.first
            guard let id else { throw ToolRegistryError.missingArgument("--id") }
            let board = try context.templateStore.applyTemplate(id: id, boardStore: context.boardStore, actor: "dmwctl")
            return .success("template.apply", data: .object(["boardID": .string(board.id), "templateID": .string(id)]))
        default:
            throw ToolRegistryError.unknownCommand("template \(subcommand)")
        }
    }

    private func audit(_ args: [String]) throws -> ToolResult {
        guard args.first == "tail" else { throw ToolRegistryError.unknownCommand("audit \(args.joined(separator: " "))") }
        let events = try FileAuditLog(layout: context.layout).readAll(limit: 20)
        return .success("audit.tail", data: .array(try events.map { try $0.asJSONValue() }))
    }
}

extension Array where Element == String {
    @discardableResult
    mutating func removeFlag(_ flag: String) -> Bool {
        guard let index = firstIndex(of: flag) else { return false }
        remove(at: index)
        return true
    }

    mutating func removeValue(after flag: String) -> String? {
        guard let index = firstIndex(of: flag), self.indices.contains(index + 1) else { return nil }
        let value = self[index + 1]
        remove(at: index + 1)
        remove(at: index)
        return value
    }
}

extension Encodable {
    func asJSONValue() throws -> JSONValue {
        let data = try BoardCodec.encoder.encode(self)
        return try BoardCodec.decoder.decode(JSONValue.self, from: data)
    }
}

extension DisplayProfile {
    var jsonValue: JSONValue {
        .object([
            "id": .string(id),
            "name": .string(name),
            "width": .number(Double(width)),
            "height": .number(Double(height)),
            "scale": .number(scale),
            "isMain": .bool(isMain)
        ])
    }
}
