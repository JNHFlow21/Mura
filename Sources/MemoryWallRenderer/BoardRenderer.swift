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

        let scaleX = CGFloat(job.display.width) / CGFloat(max(1, job.board.canvasWidth))
        let scaleY = CGFloat(job.display.height) / CGFloat(max(1, job.board.canvasHeight))
        for element in job.board.elements {
            draw(element: element, canvasHeight: CGFloat(job.display.height), scaleX: scaleX, scaleY: scaleY)
        }

        guard let data = bitmap.representation(using: .png, properties: [:]) else { throw RenderError.cannotEncodePNG }
        try data.write(to: job.outputURL, options: [.atomic])
        return RenderOutput(fileURL: job.outputURL, width: job.display.width, height: job.display.height, purpose: job.purpose, byteCount: data.count)
    }

    private func backgroundColor(for board: BoardDocument) -> NSColor {
        if let color = NSColor(hex: board.backgroundColor) { return color }
        if let hex = board.appState["viewBackgroundColor"]?.stringValue {
            return NSColor(hex: hex) ?? NSColor(calibratedRed: 1.0, green: 0.97, blue: 0.87, alpha: 1)
        }
        return NSColor(calibratedRed: 1.0, green: 0.97, blue: 0.87, alpha: 1)
    }

    private func draw(element: BoardElement, canvasHeight: CGFloat, scaleX: CGFloat, scaleY: CGFloat) {
        let rect = NSRect(x: CGFloat(element.x) * scaleX, y: canvasHeight - CGFloat(element.y + element.height) * scaleY, width: CGFloat(element.width) * scaleX, height: CGFloat(element.height) * scaleY)
        switch element.type {
        case .text:
            drawText(element, rect: rect, scaleY: scaleY)
        case .rectangle:
            drawRectangle(element, rect: rect)
        case .line, .arrow, .freedraw:
            drawStroke(element, rect: rect, canvasHeight: canvasHeight, scaleX: scaleX, scaleY: scaleY)
        }
    }

    private func drawText(_ element: BoardElement, rect: NSRect, scaleY: CGFloat) {
        let fontSize = max(1, CGFloat(element.fontSize) * scaleY)
        let font = NSFont(name: MemoryWallDefaults.fontFamily, size: fontSize)
            ?? NSFont(name: "LXGW WenKai", size: fontSize)
            ?? NSFont(name: "Marker Felt", size: fontSize)
            ?? NSFont(name: "Chalkboard SE", size: fontSize)
            ?? NSFont.systemFont(ofSize: fontSize, weight: .bold)
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

    private func drawStroke(_ element: BoardElement, rect: NSRect, canvasHeight: CGFloat, scaleX: CGFloat, scaleY: CGFloat) {
        let path = NSBezierPath()
        let points = element.extra["points"]?.arrayValue?.compactMap { value -> BoardPoint? in
            guard let object = value.objectValue,
                  let x = object["x"]?.doubleValue,
                  let y = object["y"]?.doubleValue else { return nil }
            return BoardPoint(x: x, y: y)
        } ?? []
        if let first = points.first {
            path.move(to: NSPoint(x: CGFloat(first.x) * scaleX, y: canvasHeight - CGFloat(first.y) * scaleY))
            for point in points.dropFirst() {
                path.line(to: NSPoint(x: CGFloat(point.x) * scaleX, y: canvasHeight - CGFloat(point.y) * scaleY))
            }
        } else {
            path.move(to: NSPoint(x: rect.minX, y: rect.midY))
            path.line(to: NSPoint(x: rect.maxX, y: rect.midY))
        }
        (NSColor(hex: element.strokeColor) ?? .black).setStroke()
        path.lineCapStyle = .round
        path.lineJoinStyle = .round
        path.lineWidth = max(2, CGFloat(element.fontSize) * ((scaleX + scaleY) / 2))
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
