import Foundation

public struct BoardElement: Codable, Equatable, Identifiable, Sendable {
    public enum ElementType: String, Codable, Sendable {
        case text
        case rectangle
        case arrow
        case line
        case freedraw
    }

    public var id: String
    public var type: ElementType
    public var x: Double
    public var y: Double
    public var width: Double
    public var height: Double
    public var text: String
    public var fontSize: Double
    public var strokeColor: String
    public var backgroundColor: String
    public var roughness: Double
    public var extra: [String: JSONValue]

    public init(
        id: String = UUID().uuidString,
        type: ElementType = .text,
        x: Double,
        y: Double,
        width: Double,
        height: Double,
        text: String = "",
        fontSize: Double = 88,
        strokeColor: String = "#111827",
        backgroundColor: String = "transparent",
        roughness: Double = 1,
        extra: [String: JSONValue] = [:]
    ) {
        self.id = id
        self.type = type
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.text = text
        self.fontSize = fontSize
        self.strokeColor = strokeColor
        self.backgroundColor = backgroundColor
        self.roughness = roughness
        self.extra = extra
    }
}
