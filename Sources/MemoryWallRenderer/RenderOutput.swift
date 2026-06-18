import Foundation

public struct RenderOutput: Codable, Equatable, Sendable {
    public var fileURL: URL
    public var width: Int
    public var height: Int
    public var purpose: RenderPurpose
    public var createdAt: Date
    public var byteCount: Int

    public init(fileURL: URL, width: Int, height: Int, purpose: RenderPurpose, createdAt: Date = Date(), byteCount: Int) {
        self.fileURL = fileURL
        self.width = width
        self.height = height
        self.purpose = purpose
        self.createdAt = createdAt
        self.byteCount = byteCount
    }
}
