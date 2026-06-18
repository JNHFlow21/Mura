import Foundation
import MemoryWallCore

public struct ToolResult: Codable, Equatable, Sendable {
    public var ok: Bool
    public var message: String
    public var data: JSONValue

    public init(ok: Bool, message: String, data: JSONValue = .object([:])) {
        self.ok = ok
        self.message = message
        self.data = data
    }

    public static func success(_ message: String, data: JSONValue = .object([:])) -> ToolResult {
        ToolResult(ok: true, message: message, data: data)
    }

    public static func failure(_ message: String, data: JSONValue = .object([:])) -> ToolResult {
        ToolResult(ok: false, message: message, data: data)
    }

    public func jsonString() throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        let data = try encoder.encode(self)
        return String(data: data, encoding: .utf8) ?? "{}"
    }
}
