import Foundation

public struct MemoryWallPreferences: Codable, Equatable, Sendable {
    public var defaultFontSize: Double
    public var titleFontSize: Double
    public var fontFamily: String
    public var backgroundColor: String
    public var hotkeyDescription: String
    public var renderElementLimit: Int

    public init(defaultFontSize: Double = MemoryWallDefaults.defaultFontSize, titleFontSize: Double = MemoryWallDefaults.titleFontSize, fontFamily: String = MemoryWallDefaults.fontFamily, backgroundColor: String = MemoryWallDefaults.backgroundColor, hotkeyDescription: String = "⌥⌘B", renderElementLimit: Int = 250) {
        self.defaultFontSize = defaultFontSize
        self.titleFontSize = titleFontSize
        self.fontFamily = fontFamily
        self.backgroundColor = backgroundColor
        self.hotkeyDescription = hotkeyDescription
        self.renderElementLimit = renderElementLimit
    }
}
