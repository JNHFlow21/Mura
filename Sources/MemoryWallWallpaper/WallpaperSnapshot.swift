import Foundation
import MemoryWallCore

public struct WallpaperSnapshot: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var createdAt: Date
    public var display: DisplayProfile
    public var previousImageURL: URL?
    public var appliedImageURL: URL?
    public var options: [String: String]

    public init(id: String = UUID().uuidString, createdAt: Date = Date(), display: DisplayProfile, previousImageURL: URL?, appliedImageURL: URL?, options: [String: String] = [:]) {
        self.id = id
        self.createdAt = createdAt
        self.display = display
        self.previousImageURL = previousImageURL
        self.appliedImageURL = appliedImageURL
        self.options = options
    }
}

public enum WallpaperError: LocalizedError, Equatable {
    case confirmationRequired(String)
    case noSnapshot
    case missingImage(URL)
    case backend(String)

    public var errorDescription: String? {
        switch self {
        case .confirmationRequired(let action): return "Confirmation required for \(action). Pass --confirm."
        case .noSnapshot: return "No wallpaper snapshot is available to restore."
        case .missingImage(let url): return "Missing wallpaper image at \(url.path)."
        case .backend(let message): return message
        }
    }
}
