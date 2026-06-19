import Foundation
import MemoryWallCore
import MemoryWallEditorBridge
import MemoryWallRenderer
import MemoryWallWallpaper
import MemoryWallWorkspace

public enum ToolRegistryError: LocalizedError, Equatable {
    case unknownCommand(String)
    case missingArgument(String)
    case invalidArgument(String)

    public var errorDescription: String? {
        switch self {
        case .unknownCommand(let command): return "Unknown command: \(command)"
        case .missingArgument(let argument): return "Missing argument: \(argument)"
        case .invalidArgument(let argument): return "Invalid argument: \(argument)"
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
            case "templates", "template": return .failure("Templates were removed from Desktop Memory Wall v2. Use `board blank`, `board patch --text --x --y`, or `board stroke --points`.")
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
            "canvasWidth": .number(Double(board.canvasWidth)),
            "canvasHeight": .number(Double(board.canvasHeight)),
            "backgroundColor": .string(board.backgroundColor),
            "fontFamily": .string(board.appState["currentItemFontFamily"]?.stringValue ?? MemoryWallDefaults.fontFamily),
            "elementCount": .number(Double(board.elements.count)),
            "mainDisplay": display.jsonValue,
            "latestRenderExists": .bool(latestRenderExists)
        ]))
    }

    private func diagnostics() throws -> ToolResult {
        let board = try context.boardStore.loadActiveBoard()
        let auditEvents = (try? FileAuditLog(layout: context.layout).readAll(limit: 5)) ?? []
        var editor = LocalEditorAssetLocator().diagnostics()
        let editorReady = (editor["editorAssetExists"] == .bool(true))
        let fontReady = (editor["fontAssetExists"] == .bool(true))
        editor["ready"] = .bool(editorReady && fontReady)
        return .success("diagnostics", data: .object([
            "workspace": .string(context.layout.root.path),
            "activeBoard": .object([
                "id": .string(board.id),
                "title": .string(board.metadata.title),
                "elements": .number(Double(board.elements.count)),
                "canvasWidth": .number(Double(board.canvasWidth)),
                "canvasHeight": .number(Double(board.canvasHeight))
            ]),
            "displayCount": .number(Double(context.displayService.displays().count)),
            "latestRender": .string(context.layout.latestRenderURL.path),
            "latestRenderExists": .bool(FileManager.default.fileExists(atPath: context.layout.latestRenderURL.path)),
            "editor": .object(editor),
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
        case "blank", "reset":
            let display = context.displayService.mainDisplay()
            let width = Int(remaining.removeValue(after: "--width") ?? "") ?? display.width
            let height = Int(remaining.removeValue(after: "--height") ?? "") ?? display.height
            let profile = DisplayProfile(id: display.id, name: display.name, width: width, height: height, scale: display.scale, isMain: display.isMain)
            let board = BoardDocument.blank(display: profile)
            try context.boardStore.replaceActiveBoard(board, actor: "dmwctl", reason: "board.blank", snapshotFirst: true)
            return .success("board.blank", data: .object(["boardID": .string(board.id), "canvasWidth": .number(Double(width)), "canvasHeight": .number(Double(height)), "elementCount": .number(0)]))
        case "patch", "text":
            guard let text = remaining.removeValue(after: "--text") else { throw ToolRegistryError.missingArgument("--text") }
            let x = Double(remaining.removeValue(after: "--x") ?? "") ?? 120
            let y = Double(remaining.removeValue(after: "--y") ?? "") ?? 120
            let width = Double(remaining.removeValue(after: "--width") ?? "") ?? 900
            let height = Double(remaining.removeValue(after: "--height") ?? "") ?? 140
            let fontSize = Double(remaining.removeValue(after: "--font-size") ?? "") ?? MemoryWallDefaults.defaultFontSize
            let color = remaining.removeValue(after: "--color") ?? MemoryWallDefaults.inkColor
            var board = try context.boardStore.loadActiveBoard()
            let element = board.addText(text, x: x, y: y, width: width, height: height, fontSize: fontSize, color: color)
            try context.boardStore.saveActiveBoard(board, actor: "dmwctl", reason: "board.patch.text")
            return .success("board.patch", data: .object(["boardID": .string(board.id), "elementID": .string(element.id), "elementCount": .number(Double(board.elements.count)), "x": .number(x), "y": .number(y)]))
        case "stroke":
            guard let raw = remaining.removeValue(after: "--points") else { throw ToolRegistryError.missingArgument("--points") }
            let points = try parsePoints(raw)
            let color = remaining.removeValue(after: "--color") ?? MemoryWallDefaults.inkColor
            let width = Double(remaining.removeValue(after: "--width") ?? "") ?? 8
            var board = try context.boardStore.loadActiveBoard()
            let element = board.addStroke(points: points, color: color, width: width)
            try context.boardStore.saveActiveBoard(board, actor: "dmwctl", reason: "board.patch.stroke")
            return .success("board.stroke", data: .object(["boardID": .string(board.id), "elementID": .string(element.id), "elementCount": .number(Double(board.elements.count))]))
        case "write":
            guard let file = remaining.removeValue(after: "--file") else { throw ToolRegistryError.missingArgument("--file") }
            var board = try BoardCodec.decoder.decode(BoardDocument.self, from: Data(contentsOf: URL(fileURLWithPath: file)))
            board.metadata.activeTemplateID = nil
            try context.boardStore.replaceActiveBoard(board, actor: "dmwctl", reason: "board.write", snapshotFirst: true)
            return .success("board.write", data: .object(["boardID": .string(board.id)]))
        default:
            throw ToolRegistryError.unknownCommand("board \(subcommand)")
        }
    }

    private func parsePoints(_ raw: String) throws -> [BoardPoint] {
        let points = raw.split(separator: ";").compactMap { token -> BoardPoint? in
            let parts = token.split(separator: ",")
            guard parts.count == 2, let x = Double(parts[0].trimmingCharacters(in: .whitespaces)), let y = Double(parts[1].trimmingCharacters(in: .whitespaces)) else { return nil }
            return BoardPoint(x: x, y: y)
        }
        guard points.count >= 2 else { throw ToolRegistryError.invalidArgument("--points must look like '10,10;40,50' and include at least two points") }
        return points
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
