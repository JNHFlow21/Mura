import Foundation

public struct MemoryWallPreferences: Codable, Equatable, Sendable {
    public var defaultFontSize: Double
    public var titleFontSize: Double
    public var fontFamily: String
    public var backgroundColor: String
    public var hotkeyDescription: String
    public var renderElementLimit: Int

    public init(defaultFontSize: Double = 92, titleFontSize: Double = 128, fontFamily: String = "Virgil", backgroundColor: String = "#fff8df", hotkeyDescription: String = "⌥⌘B", renderElementLimit: Int = 250) {
        self.defaultFontSize = defaultFontSize
        self.titleFontSize = titleFontSize
        self.fontFamily = fontFamily
        self.backgroundColor = backgroundColor
        self.hotkeyDescription = hotkeyDescription
        self.renderElementLimit = renderElementLimit
    }
}
