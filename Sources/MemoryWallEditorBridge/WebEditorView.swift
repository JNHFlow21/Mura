import Foundation
import MemoryWallCore
import SwiftUI
import WebKit

public struct WebEditorView: NSViewRepresentable {
    public let board: BoardDocument
    public let locator: LocalEditorAssetLocator
    public let onMessage: (EditorBridgeMessage) -> Void
    public let onError: (Error) -> Void

    public init(board: BoardDocument, locator: LocalEditorAssetLocator = LocalEditorAssetLocator(), onMessage: @escaping (EditorBridgeMessage) -> Void = { _ in }, onError: @escaping (Error) -> Void = { _ in }) {
        self.board = board
        self.locator = locator
        self.onMessage = onMessage
        self.onError = onError
    }

    public func makeCoordinator() -> WebEditorCoordinator {
        WebEditorCoordinator(onMessage: onMessage, onError: onError)
    }

    public func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.userContentController.add(context.coordinator, name: "memoryWall")
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.setValue(false, forKey: "drawsBackground")
        do {
            let url = try locator.indexURL()
            let root = try locator.resourceRootURL()
            webView.loadFileURL(url, allowingReadAccessTo: root)
        } catch {
            onError(error)
            webView.loadHTMLString(Self.fallbackHTML, baseURL: nil)
        }
        return webView
    }

    public func updateNSView(_ webView: WKWebView, context: Context) {
        guard let data = try? JSONEncoder().encode(board), let json = String(data: data, encoding: .utf8) else { return }
        let escaped = json.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "`", with: "\\`")
        webView.evaluateJavaScript("window.memoryWallLoadBoard && window.memoryWallLoadBoard(`\(escaped)`);") { _, error in
            if let error { onError(error) }
        }
    }

    public static let fallbackHTML = """
    <!doctype html><meta charset='utf-8'><body style='font-family: system-ui; background:#fff8df;'><h1>Desktop Memory Wall</h1><p>Editor asset missing; rebuild app resources.</p></body>
    """
}
