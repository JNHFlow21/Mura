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
    public var elements: [BoardElement]
    public var appState: [String: JSONValue]
    public var files: [String: JSONValue]
    public var rawExcalidraw: [String: JSONValue]

    public init(
        id: String = UUID().uuidString,
        schemaVersion: Int = 1,
        metadata: BoardMetadata,
        elements: [BoardElement],
        appState: [String: JSONValue] = [:],
        files: [String: JSONValue] = [:],
        rawExcalidraw: [String: JSONValue] = [:]
    ) {
        self.id = id
        self.schemaVersion = schemaVersion
        self.metadata = metadata
        self.elements = elements
        self.appState = appState
        self.files = files
        self.rawExcalidraw = rawExcalidraw
    }

    public static func defaultMemoryWall(now: Date = Date()) -> BoardDocument {
        BoardDocument(
            metadata: BoardMetadata(title: "Desktop Memory Wall", createdAt: now, updatedAt: now, activeTemplateID: "default-memory-wall"),
            elements: [
                BoardElement(x: 120, y: 105, width: 1480, height: 170, text: "今天只做这 3 件事", fontSize: 128),
                BoardElement(x: 160, y: 330, width: 1300, height: 110, text: "1. ", fontSize: 92),
                BoardElement(x: 160, y: 470, width: 1300, height: 110, text: "2. ", fontSize: 92),
                BoardElement(x: 160, y: 610, width: 1300, height: 110, text: "3. ", fontSize: 92),
                BoardElement(x: 120, y: 820, width: 900, height: 90, text: "别忘：", fontSize: 72, strokeColor: "#b91c1c")
            ],
            appState: [
                "viewBackgroundColor": .string("#fff8df"),
                "currentItemFontFamily": .string("Virgil"),
                "theme": .string("light")
            ],
            rawExcalidraw: [
                "type": .string("excalidraw"),
                "version": .number(2)
            ]
        )
    }

    public mutating func touch(_ date: Date = Date()) {
        metadata.updatedAt = date
    }

    public mutating func appendReminder(_ text: String, fontSize: Double = 92) {
        let y = 330 + Double(elements.filter { $0.type == .text }.count) * 130
        elements.append(BoardElement(x: 160, y: y, width: 1400, height: 120, text: text, fontSize: fontSize))
        touch()
    }
}
