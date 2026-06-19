import Foundation
import MemoryWallCore
import SwiftUI
import WebKit

public struct WebEditorView: NSViewRepresentable {
    public let board: BoardDocument
    public let displays: [DisplayProfile]
    public let boardsByDisplayID: [String: BoardDocument]
    public let selectedDisplayID: String
    public let locator: LocalEditorAssetLocator
    public let onMessage: (EditorBridgeMessage) -> Void
    public let onError: (Error) -> Void

    public init(
        board: BoardDocument,
        displays: [DisplayProfile]? = nil,
        boardsByDisplayID: [String: BoardDocument] = [:],
        selectedDisplayID: String? = nil,
        locator: LocalEditorAssetLocator = LocalEditorAssetLocator(),
        onMessage: @escaping (EditorBridgeMessage) -> Void = { _ in },
        onError: @escaping (Error) -> Void = { _ in }
    ) {
        self.board = board
        let defaultDisplay = board.metadata.displayProfile
        let resolvedDisplays = displays?.isEmpty == false ? displays! : [defaultDisplay]
        let resolvedSelectedID = selectedDisplayID ?? defaultDisplay.id
        self.displays = resolvedDisplays
        var resolvedBoards = boardsByDisplayID
        if resolvedBoards[resolvedSelectedID] == nil {
            resolvedBoards[resolvedSelectedID] = board
        }
        self.boardsByDisplayID = resolvedBoards
        self.selectedDisplayID = resolvedSelectedID
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
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let nativeContext = EditorNativeContext(displays: displays, selectedDisplayID: selectedDisplayID, boardsByDisplayID: boardsByDisplayID, board: board)
        guard let data = try? encoder.encode(nativeContext), let json = String(data: data, encoding: .utf8) else { return }
        guard context.coordinator.markNativeBoardLoadStarted(json) else { return }
        let escaped = json
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "`", with: "\\`")
            .replacingOccurrences(of: "${", with: "\\${")
        let script = """
        (function() {
          const json = `\(escaped)`;
          const editorDOMReady = Boolean(document.getElementById('scene') && document.getElementById('textEditor'));
          window.__memoryWallNativeContextJSON = json;
          if (window.memoryWallLoadContext) {
            window.memoryWallLoadContext(json);
            return 'loaded';
          }
          window.__memoryWallNativeBoardJSON = JSON.stringify(JSON.parse(json).board);
          if (location.protocol === 'file:' || editorDOMReady) {
            return 'cached';
          }
          return 'pending';
        })();
        """
        webView.evaluateJavaScript(script) { result, error in
            if let error {
                context.coordinator.markNativeBoardLoadFailed(json)
                onError(error)
                return
            }
            if let status = result as? String, status == "pending" {
                context.coordinator.markNativeBoardLoadFailed(json)
            }
        }
    }

    public static let fallbackHTML = """
    <!doctype html><meta charset='utf-8'><body style='font-family: system-ui; background:#fff8df;'><h1>Desktop Memory Wall</h1><p>Editor asset missing; rebuild app resources.</p></body>
    """
}

public struct EditorNativeContext: Codable, Equatable, Sendable {
    public var displays: [DisplayProfile]
    public var selectedDisplayID: String
    public var boardsByDisplayID: [String: BoardDocument]
    public var board: BoardDocument

    public init(displays: [DisplayProfile], selectedDisplayID: String, boardsByDisplayID: [String: BoardDocument], board: BoardDocument) {
        self.displays = displays
        self.selectedDisplayID = selectedDisplayID
        self.boardsByDisplayID = boardsByDisplayID
        self.board = board
    }
}
