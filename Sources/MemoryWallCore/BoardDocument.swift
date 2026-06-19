import Foundation

public struct BoardMetadata: Codable, Equatable, Sendable {
    public var title: String
    public var createdAt: Date
    public var updatedAt: Date
    public var activeTemplateID: String?
    public var displayProfile: DisplayProfile

    public init(title: String, createdAt: Date = Date(), updatedAt: Date = Date(), activeTemplateID: String? = nil, displayProfile: DisplayProfile = .fallback) {
        self.title = title
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.activeTemplateID = activeTemplateID
        self.displayProfile = displayProfile
    }
}

public struct BoardDocument: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var schemaVersion: Int
    public var metadata: BoardMetadata
    public var canvasWidth: Int
    public var canvasHeight: Int
    public var backgroundColor: String
    public var elements: [BoardElement]
    public var appState: [String: JSONValue]
    public var files: [String: JSONValue]
    public var rawExcalidraw: [String: JSONValue]

    public init(
        id: String = UUID().uuidString,
        schemaVersion: Int = MemoryWallDefaults.schemaVersion,
        metadata: BoardMetadata,
        canvasWidth: Int? = nil,
        canvasHeight: Int? = nil,
        backgroundColor: String = MemoryWallDefaults.backgroundColor,
        elements: [BoardElement],
        appState: [String: JSONValue] = [:],
        files: [String: JSONValue] = [:],
        rawExcalidraw: [String: JSONValue] = [:]
    ) {
        self.id = id
        self.schemaVersion = schemaVersion
        self.metadata = metadata
        self.canvasWidth = canvasWidth ?? metadata.displayProfile.width
        self.canvasHeight = canvasHeight ?? metadata.displayProfile.height
        self.backgroundColor = backgroundColor
        self.elements = elements
        var mergedAppState = appState
        if mergedAppState["viewBackgroundColor"] == nil { mergedAppState["viewBackgroundColor"] = .string(backgroundColor) }
        if mergedAppState["currentItemFontFamily"] == nil { mergedAppState["currentItemFontFamily"] = .string(MemoryWallDefaults.fontFamily) }
        if mergedAppState["theme"] == nil { mergedAppState["theme"] = .string("light") }
        self.appState = mergedAppState
        self.files = files
        self.rawExcalidraw = rawExcalidraw
    }

    private enum CodingKeys: String, CodingKey {
        case id, schemaVersion, metadata, canvasWidth, canvasHeight, backgroundColor, elements, appState, files, rawExcalidraw
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        schemaVersion = try container.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? 1
        metadata = try container.decode(BoardMetadata.self, forKey: .metadata)
        elements = try container.decodeIfPresent([BoardElement].self, forKey: .elements) ?? []
        appState = try container.decodeIfPresent([String: JSONValue].self, forKey: .appState) ?? [:]
        files = try container.decodeIfPresent([String: JSONValue].self, forKey: .files) ?? [:]
        rawExcalidraw = try container.decodeIfPresent([String: JSONValue].self, forKey: .rawExcalidraw) ?? [:]
        canvasWidth = try container.decodeIfPresent(Int.self, forKey: .canvasWidth) ?? metadata.displayProfile.width
        canvasHeight = try container.decodeIfPresent(Int.self, forKey: .canvasHeight) ?? metadata.displayProfile.height
        backgroundColor = try container.decodeIfPresent(String.self, forKey: .backgroundColor)
            ?? appState["viewBackgroundColor"]?.stringValue
            ?? MemoryWallDefaults.backgroundColor
        if appState["viewBackgroundColor"] == nil { appState["viewBackgroundColor"] = .string(backgroundColor) }
        if appState["currentItemFontFamily"] == nil { appState["currentItemFontFamily"] = .string(MemoryWallDefaults.fontFamily) }
        if appState["theme"] == nil { appState["theme"] = .string("light") }
    }

    public static func defaultMemoryWall(display: DisplayProfile = .fallback, now: Date = Date()) -> BoardDocument {
        blank(display: display, now: now)
    }

    public static func blank(display: DisplayProfile = .fallback, now: Date = Date()) -> BoardDocument {
        BoardDocument(
            metadata: BoardMetadata(title: MemoryWallDefaults.title, createdAt: now, updatedAt: now, activeTemplateID: nil, displayProfile: display),
            canvasWidth: display.width,
            canvasHeight: display.height,
            backgroundColor: MemoryWallDefaults.backgroundColor,
            elements: [],
            appState: [
                "viewBackgroundColor": .string(MemoryWallDefaults.backgroundColor),
                "currentItemFontFamily": .string(MemoryWallDefaults.fontFamily),
                "theme": .string("light")
            ],
            rawExcalidraw: [
                "type": .string("desktop-memory-wall-canvas"),
                "version": .number(Double(MemoryWallDefaults.schemaVersion))
            ]
        )
    }

    public mutating func retargetCanvas(to display: DisplayProfile, preserveElements: Bool = true) {
        let oldWidth = max(1, canvasWidth)
        let oldHeight = max(1, canvasHeight)
        let scaleX = Double(display.width) / Double(oldWidth)
        let scaleY = Double(display.height) / Double(oldHeight)
        metadata.displayProfile = display
        canvasWidth = display.width
        canvasHeight = display.height
        if preserveElements {
            elements = elements.map { element in
                var scaled = element
                scaled.x *= scaleX
                scaled.y *= scaleY
                scaled.width *= scaleX
                scaled.height *= scaleY
                if let points = scaled.extra["points"]?.arrayValue {
                    scaled.extra["points"] = .array(points.map { value in
                        guard let object = value.objectValue,
                              let x = object["x"]?.doubleValue,
                              let y = object["y"]?.doubleValue else { return value }
                        return .object(["x": .number(x * scaleX), "y": .number(y * scaleY)])
                    })
                }
                return scaled
            }
        } else {
            elements = []
        }
        touch()
    }

    public mutating func touch(_ date: Date = Date()) {
        metadata.updatedAt = date
    }

    @discardableResult
    public mutating func addText(_ text: String, x: Double, y: Double, width: Double = 900, height: Double = 140, fontSize: Double = MemoryWallDefaults.defaultFontSize, color: String = MemoryWallDefaults.inkColor) -> BoardElement {
        let element = BoardElement(x: x, y: y, width: width, height: height, text: text, fontSize: fontSize, strokeColor: color)
        elements.append(element)
        touch()
        return element
    }

    @discardableResult
    public mutating func addStroke(points: [BoardPoint], color: String = MemoryWallDefaults.inkColor, width: Double = 8) -> BoardElement {
        let bounds = BoardPoint.bounds(for: points)
        let element = BoardElement(
            type: .freedraw,
            x: bounds.x,
            y: bounds.y,
            width: bounds.width,
            height: bounds.height,
            fontSize: width,
            strokeColor: color,
            extra: ["points": .array(points.map { .object(["x": .number($0.x), "y": .number($0.y)]) })]
        )
        elements.append(element)
        touch()
        return element
    }

    public mutating func appendReminder(_ text: String, fontSize: Double = MemoryWallDefaults.defaultFontSize) {
        let y = 120 + Double(elements.filter { $0.type == .text }.count) * 140
        addText(text, x: 120, y: y, width: 1400, height: 130, fontSize: fontSize)
    }
}

public struct BoardPoint: Codable, Equatable, Sendable {
    public var x: Double
    public var y: Double

    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }

    public static func bounds(for points: [BoardPoint]) -> (x: Double, y: Double, width: Double, height: Double) {
        guard let first = points.first else { return (0, 0, 0, 0) }
        let minX = points.map(\.x).min() ?? first.x
        let maxX = points.map(\.x).max() ?? first.x
        let minY = points.map(\.y).min() ?? first.y
        let maxY = points.map(\.y).max() ?? first.y
        return (minX, minY, max(1, maxX - minX), max(1, maxY - minY))
    }
}
