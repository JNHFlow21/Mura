import Foundation
import MemoryWallCore

public enum EditorBridgeError: LocalizedError, Equatable {
    case invalidMessage(String)
    case missingAsset(String)

    public var errorDescription: String? {
        switch self {
        case .invalidMessage(let message): return "Invalid editor bridge message: \(message)"
        case .missingAsset(let message): return "Missing editor asset: \(message)"
        }
    }
}

public struct EditorBridgeMessage: Codable, Equatable, Sendable {
    public enum Kind: String, Codable, Sendable {
        case ready
        case boardChanged
        case exportPNG
        case error
    }

    public var kind: Kind
    public var board: BoardDocument?
    public var payload: [String: JSONValue]

    public init(kind: Kind, board: BoardDocument? = nil, payload: [String: JSONValue] = [:]) {
        self.kind = kind
        self.board = board
        self.payload = payload
    }

    public static func decode(json: String) throws -> EditorBridgeMessage {
        guard let data = json.data(using: .utf8) else { throw EditorBridgeError.invalidMessage("Message is not UTF-8") }
        do { return try JSONDecoder().decode(EditorBridgeMessage.self, from: data) }
        catch { throw EditorBridgeError.invalidMessage(error.localizedDescription) }
    }
}

public struct LocalEditorAssetLocator {
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
}
