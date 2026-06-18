import Foundation

public struct DisplayProfile: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var name: String
    public var width: Int
    public var height: Int
    public var scale: Double
    public var isMain: Bool

    public init(id: String, name: String, width: Int, height: Int, scale: Double = 1, isMain: Bool = false) {
        self.id = id
        self.name = name
        self.width = width
        self.height = height
        self.scale = scale
        self.isMain = isMain
    }

    public static let fallback = DisplayProfile(id: "main", name: "Main Display", width: 1920, height: 1080, scale: 1, isMain: true)
}
