import Foundation

public struct HotkeyStatus: Codable, Equatable, Sendable {
    public var description: String
    public var isRegistered: Bool
    public var conflictMessage: String?

    public init(description: String, isRegistered: Bool, conflictMessage: String? = nil) {
        self.description = description
        self.isRegistered = isRegistered
        self.conflictMessage = conflictMessage
    }
}

public protocol HotkeyServicing {
    func register(description: String, handler: @escaping () -> Void) -> HotkeyStatus
    func unregister()
    func status() -> HotkeyStatus
}

public final class InMemoryHotkeyService: HotkeyServicing {
    private var current = HotkeyStatus(description: "⌥⌘B", isRegistered: false)
    private var handler: (() -> Void)?

    public init() {}

    public func register(description: String, handler: @escaping () -> Void) -> HotkeyStatus {
        self.handler = handler
        current = HotkeyStatus(description: description, isRegistered: true)
        return current
    }

    public func unregister() {
        handler = nil
        current.isRegistered = false
    }

    public func status() -> HotkeyStatus { current }

    public func triggerForTests() { handler?() }
}

#if canImport(Carbon)
import Carbon

public final class CarbonHotkeyService: HotkeyServicing {
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    private var callback: (() -> Void)?
    private var current = HotkeyStatus(description: "⌥⌘B", isRegistered: false)

    public init() {}
    deinit { unregister() }

    public func register(description: String, handler: @escaping () -> Void) -> HotkeyStatus {
        unregister()
        guard let parsed = Self.parse(description: description) else {
            current = HotkeyStatus(description: description, isRegistered: false, conflictMessage: "Unsupported shortcut format. Use ⌥⌘B for v1.")
            return current
        }

        callback = handler
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let installStatus = InstallEventHandler(GetApplicationEventTarget(), { _, _, userData in
            guard let userData else { return noErr }
            let service = Unmanaged<CarbonHotkeyService>.fromOpaque(userData).takeUnretainedValue()
            service.callback?()
            return noErr
        }, 1, &eventType, UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()), &eventHandlerRef)
        guard installStatus == noErr else {
            current = HotkeyStatus(description: description, isRegistered: false, conflictMessage: "Could not install hotkey handler (\(installStatus)).")
            return current
        }

        let hotKeyID = EventHotKeyID(signature: Self.signature, id: 1)
        var ref: EventHotKeyRef?
        let registerStatus = RegisterEventHotKey(parsed.keyCode, parsed.modifiers, hotKeyID, GetApplicationEventTarget(), 0, &ref)
        guard registerStatus == noErr, let ref else {
            if let eventHandlerRef { RemoveEventHandler(eventHandlerRef) }
            eventHandlerRef = nil
            current = HotkeyStatus(description: description, isRegistered: false, conflictMessage: "Shortcut is unavailable or conflicts with another app (\(registerStatus)).")
            return current
        }

        hotKeyRef = ref
        current = HotkeyStatus(description: description, isRegistered: true)
        return current
    }

    public func unregister() {
        if let hotKeyRef { UnregisterEventHotKey(hotKeyRef) }
        if let eventHandlerRef { RemoveEventHandler(eventHandlerRef) }
        hotKeyRef = nil
        eventHandlerRef = nil
        callback = nil
        current.isRegistered = false
    }

    public func status() -> HotkeyStatus { current }

    public static func parse(description: String) -> (keyCode: UInt32, modifiers: UInt32)? {
        let normalized = description.replacingOccurrences(of: " ", with: "").lowercased()
        guard normalized == "⌥⌘b" || normalized == "option+command+b" || normalized == "cmd+option+b" else { return nil }
        return (UInt32(kVK_ANSI_B), UInt32(optionKey | cmdKey))
    }

    private static let signature: OSType = {
        let scalars = Array("DMW1".unicodeScalars).map { OSType($0.value) }
        return (scalars[0] << 24) | (scalars[1] << 16) | (scalars[2] << 8) | scalars[3]
    }()
}
#endif
