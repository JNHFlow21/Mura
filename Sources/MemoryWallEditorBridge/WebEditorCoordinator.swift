import Foundation
import MemoryWallCore
import WebKit

public final class WebEditorCoordinator: NSObject, WKScriptMessageHandler {
    public var onMessage: (EditorBridgeMessage) -> Void
    public var onError: (Error) -> Void
    public var lastLoadedBoardJSON: String?

    public init(onMessage: @escaping (EditorBridgeMessage) -> Void = { _ in }, onError: @escaping (Error) -> Void = { _ in }) {
        self.onMessage = onMessage
        self.onError = onError
    }

    func markNativeBoardLoadStarted(_ json: String) -> Bool {
        guard lastLoadedBoardJSON != json else { return false }
        lastLoadedBoardJSON = json
        return true
    }

    func markNativeBoardLoadFailed(_ json: String) {
        if lastLoadedBoardJSON == json {
            lastLoadedBoardJSON = nil
        }
    }

    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let body = message.body as? String else {
            onError(EditorBridgeError.invalidMessage("Expected JSON string body"))
            return
        }
        do { onMessage(try EditorBridgeMessage.decode(json: body)) }
        catch { onError(error) }
    }
}
