import Foundation

public struct MemoryWallTemplate: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var name: String
    public var board: BoardDocument

    public init(id: String, name: String, board: BoardDocument) {
        self.id = id
        self.name = name
        self.board = board
    }

    public static func defaultTemplates() -> [MemoryWallTemplate] {
        let defaultBoard = BoardDocument.defaultMemoryWall()
        var today = defaultBoard
        today.id = UUID().uuidString
        today.metadata.title = "Today Focus"
        today.metadata.activeTemplateID = "today-focus"
        today.elements.append(BoardElement(x: 1070, y: 820, width: 620, height: 90, text: "等待：", fontSize: 72, strokeColor: "#1d4ed8"))
        return [
            MemoryWallTemplate(id: "default-memory-wall", name: "Default Memory Wall", board: defaultBoard),
            MemoryWallTemplate(id: "today-focus", name: "Today Focus", board: today)
        ]
    }
}
