import Foundation
import MemoryWallCore

public enum RenderPurpose: String, Codable, Sendable {
    case preview
    case wallpaper
}

public struct RenderBudget: Codable, Equatable, Sendable {
    public var maxElements: Int
    public var maxPixels: Int

    public init(maxElements: Int = 250, maxPixels: Int = 16_000_000) {
        self.maxElements = maxElements
        self.maxPixels = maxPixels
    }

    public func validate(board: BoardDocument, display: DisplayProfile) throws {
        if board.elements.count > maxElements {
            throw RenderError.budgetExceeded("Board has \(board.elements.count) elements; limit is \(maxElements).")
        }
        let pixels = display.width * display.height
        if pixels > maxPixels {
            throw RenderError.budgetExceeded("Display has \(pixels) pixels; limit is \(maxPixels).")
        }
    }
}

public struct RenderJob: Sendable {
    public var board: BoardDocument
    public var display: DisplayProfile
    public var outputURL: URL
    public var purpose: RenderPurpose
    public var budget: RenderBudget

    public init(board: BoardDocument, display: DisplayProfile, outputURL: URL, purpose: RenderPurpose = .preview, budget: RenderBudget = RenderBudget()) {
        self.board = board
        self.display = display
        self.outputURL = outputURL
        self.purpose = purpose
        self.budget = budget
    }
}

public enum RenderError: LocalizedError, Equatable {
    case cannotCreateBitmap
    case cannotEncodePNG
    case budgetExceeded(String)

    public var errorDescription: String? {
        switch self {
        case .cannotCreateBitmap: return "Could not allocate bitmap renderer."
        case .cannotEncodePNG: return "Could not encode rendered board as PNG."
        case .budgetExceeded(let message): return message
        }
    }
}
