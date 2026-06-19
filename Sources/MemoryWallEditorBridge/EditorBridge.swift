import Foundation
import MemoryWallCore

public enum EditorBridgeError: LocalizedError, Equatable {
    case invalidMessage(String)
    case missingAsset(String)
    case invalidPNGPayload(String)

    public var errorDescription: String? {
        switch self {
        case .invalidMessage(let message): return "Invalid editor bridge message: \(message)"
        case .missingAsset(let message): return "Missing editor asset: \(message)"
        case .invalidPNGPayload(let message): return "Invalid PNG export payload: \(message)"
        }
    }
}

public struct EditorBridgeMessage: Codable, Equatable, Sendable {
    public enum Kind: String, Codable, Sendable {
        case ready
        case boardChanged
        case exportPNG
        case cancel
        case error
    }

    public var kind: Kind
    public var board: BoardDocument?
    public var payload: [String: JSONValue]
    public var displayExports: [EditorDisplayExport]?

    public init(kind: Kind, board: BoardDocument? = nil, payload: [String: JSONValue] = [:], displayExports: [EditorDisplayExport]? = nil) {
        self.kind = kind
        self.board = board
        self.payload = payload
        self.displayExports = displayExports
    }

    public static func decode(json: String) throws -> EditorBridgeMessage {
        guard let data = json.data(using: .utf8) else { throw EditorBridgeError.invalidMessage("Message is not UTF-8") }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            if let seconds = try? container.decode(Double.self) { return Date(timeIntervalSinceReferenceDate: seconds) }
            if let text = try? container.decode(String.self) {
                let fractional = ISO8601DateFormatter()
                fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                let plain = ISO8601DateFormatter()
                plain.formatOptions = [.withInternetDateTime]
                if let date = fractional.date(from: text) ?? plain.date(from: text) {
                    return date
                }
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Expected a numeric or ISO-8601 date")
        }
        do { return try decoder.decode(EditorBridgeMessage.self, from: data) }
        catch { throw EditorBridgeError.invalidMessage(error.localizedDescription) }
    }

    public var pngDataURL: String? { payload["pngDataURL"]?.stringValue }

}

public struct EditorDisplayExport: Codable, Equatable, Sendable {
    public var displayID: String
    public var board: BoardDocument
    public var pngDataURL: String
    public var width: Int
    public var height: Int

    public init(displayID: String, board: BoardDocument, pngDataURL: String, width: Int, height: Int) {
        self.displayID = displayID
        self.board = board
        self.pngDataURL = pngDataURL
        self.width = width
        self.height = height
    }
}

public struct LocalEditorAssetLocator {
    public static let fontFileName = "LXGWWenKai-Regular.ttf"
    public var bundle: Bundle

    public init(bundle: Bundle? = nil) {
        self.bundle = bundle ?? Bundle.module
    }

    public func indexURL() throws -> URL {
        if let url = bundle.url(forResource: "index", withExtension: "html", subdirectory: "Editor") {
            return url
        }
        if let url = bundle.url(forResource: "index", withExtension: "html") {
            return url
        }
        throw EditorBridgeError.missingAsset("Editor/index.html was not found in bundle resources")
    }

    public func resourceRootURL() throws -> URL {
        try indexURL().deletingLastPathComponent().deletingLastPathComponent()
    }

    public func fontURL() throws -> URL {
        if let url = bundle.url(forResource: "LXGWWenKai-Regular", withExtension: "ttf", subdirectory: "Fonts") {
            return url
        }
        if let url = bundle.url(forResource: "LXGWWenKai-Regular", withExtension: "ttf") {
            return url
        }
        let root = try resourceRootURL()
        let sibling = root.appendingPathComponent("Fonts", isDirectory: true).appendingPathComponent(Self.fontFileName)
        if FileManager.default.fileExists(atPath: sibling.path) { return sibling }
        throw EditorBridgeError.missingAsset("Fonts/\(Self.fontFileName) was not found in bundle resources")
    }

    public func diagnostics() -> [String: JSONValue] {
        let index = try? indexURL()
        let font = try? fontURL()
        return [
            "editorAsset": .string(index?.path ?? "missing"),
            "editorAssetExists": .bool(index.map { FileManager.default.fileExists(atPath: $0.path) } ?? false),
            "fontAsset": .string(font?.path ?? "missing"),
            "fontAssetExists": .bool(font.map { FileManager.default.fileExists(atPath: $0.path) } ?? false),
            "fontFamily": .string(MemoryWallDefaults.fontFamily)
        ]
    }
}

public enum EditorExportCodec {
    public static func pngData(fromDataURL dataURL: String) throws -> Data {
        let prefix = "data:image/png;base64,"
        guard dataURL.hasPrefix(prefix) else { throw EditorBridgeError.invalidPNGPayload("Expected data:image/png base64 URL") }
        let base64 = String(dataURL.dropFirst(prefix.count))
        guard let data = Data(base64Encoded: base64), !data.isEmpty else { throw EditorBridgeError.invalidPNGPayload("Could not decode base64 PNG data") }
        return data
    }
}
