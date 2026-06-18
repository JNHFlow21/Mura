import AppKit
import Foundation
import MemoryWallCore

public protocol BoardRendering {
    func render(_ job: RenderJob) throws -> RenderOutput
}

public struct NativeBoardRenderer: BoardRendering {
    public init() {}

    public func render(_ job: RenderJob) throws -> RenderOutput {
        try job.budget.validate(board: job.board, display: job.display)
        try FileManager.default.createDirectory(at: job.outputURL.deletingLastPathComponent(), withIntermediateDirectories: true)

        guard let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: job.display.width,
            pixelsHigh: job.display.height,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else { throw RenderError.cannotCreateBitmap }

        guard let context = NSGraphicsContext(bitmapImageRep: bitmap) else { throw RenderError.cannotCreateBitmap }
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = context
        defer {
            NSGraphicsContext.restoreGraphicsState()
            NSGraphicsContext.current = nil
        }

        let canvas = NSRect(x: 0, y: 0, width: job.display.width, height: job.display.height)
        backgroundColor(for: job.board).setFill()
        canvas.fill()

        for element in job.board.elements {
            draw(element: element, canvasHeight: CGFloat(job.display.height))
        }

        guard let data = bitmap.representation(using: .png, properties: [:]) else { throw RenderError.cannotEncodePNG }
        try data.write(to: job.outputURL, options: [.atomic])
        return RenderOutput(fileURL: job.outputURL, width: job.display.width, height: job.display.height, purpose: job.purpose, byteCount: data.count)
    }

    private func backgroundColor(for board: BoardDocument) -> NSColor {
        if let hex = board.appState["viewBackgroundColor"]?.stringValue {
            return NSColor(hex: hex) ?? NSColor(calibratedRed: 1.0, green: 0.97, blue: 0.87, alpha: 1)
        }
        return NSColor(calibratedRed: 1.0, green: 0.97, blue: 0.87, alpha: 1)
    }

    private func draw(element: BoardElement, canvasHeight: CGFloat) {
        let rect = NSRect(x: element.x, y: canvasHeight - CGFloat(element.y + element.height), width: element.width, height: element.height)
        switch element.type {
        case .text:
            drawText(element, rect: rect)
        case .rectangle:
            drawRectangle(element, rect: rect)
        case .line, .arrow, .freedraw:
            drawStroke(element, rect: rect)
        }
    }

    private func drawText(_ element: BoardElement, rect: NSRect) {
        let font = NSFont(name: "Marker Felt", size: CGFloat(element.fontSize))
            ?? NSFont(name: "Chalkboard SE", size: CGFloat(element.fontSize))
            ?? NSFont.systemFont(ofSize: CGFloat(element.fontSize), weight: .bold)
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .byWordWrapping
        paragraph.alignment = .left
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor(hex: element.strokeColor) ?? .black,
            .paragraphStyle: paragraph
        ]
        NSString(string: element.text).draw(in: rect, withAttributes: attrs)
    }

    private func drawRectangle(_ element: BoardElement, rect: NSRect) {
        let path = NSBezierPath(roundedRect: rect, xRadius: 18, yRadius: 18)
        if element.backgroundColor != "transparent", let fill = NSColor(hex: element.backgroundColor) {
            fill.withAlphaComponent(0.22).setFill()
            path.fill()
        }
        (NSColor(hex: element.strokeColor) ?? .black).setStroke()
        path.lineWidth = 5
        path.stroke()
    }

    private func drawStroke(_ element: BoardElement, rect: NSRect) {
        let path = NSBezierPath()
        path.move(to: NSPoint(x: rect.minX, y: rect.midY))
        path.line(to: NSPoint(x: rect.maxX, y: rect.midY))
        (NSColor(hex: element.strokeColor) ?? .black).setStroke()
        path.lineWidth = max(3, CGFloat(element.fontSize / 16))
        path.stroke()
    }
}

extension NSColor {
    convenience init?(hex: String) {
        var text = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if text == "transparent" { return nil }
        if text.hasPrefix("#") { text.removeFirst() }
        guard text.count == 6 || text.count == 8, let value = UInt64(text, radix: 16) else { return nil }
        let hasAlpha = text.count == 8
        let r = CGFloat((value >> (hasAlpha ? 24 : 16)) & 0xff) / 255
        let g = CGFloat((value >> (hasAlpha ? 16 : 8)) & 0xff) / 255
        let b = CGFloat((value >> (hasAlpha ? 8 : 0)) & 0xff) / 255
        let a = hasAlpha ? CGFloat(value & 0xff) / 255 : 1
        self.init(calibratedRed: r, green: g, blue: b, alpha: a)
    }
}
