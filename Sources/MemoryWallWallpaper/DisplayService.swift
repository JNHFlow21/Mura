import AppKit
import Foundation
import MemoryWallCore

public protocol DisplayServicing {
    func displays() -> [DisplayProfile]
    func mainDisplay() -> DisplayProfile
}

public struct AppKitDisplayService: DisplayServicing {
    public init() {}

    public func displays() -> [DisplayProfile] {
        let main = NSScreen.main
        let screens = NSScreen.screens
        guard !screens.isEmpty else { return [.fallback] }
        return screens.enumerated().map { index, screen in
            let frame = screen.frame
            let scale = screen.backingScaleFactor
            let deviceID = (screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.stringValue ?? "display-\(index)"
            return DisplayProfile(
                id: deviceID,
                name: screen.localizedName,
                width: Int(frame.width * scale),
                height: Int(frame.height * scale),
                scale: Double(scale),
                isMain: screen == main
            )
        }
    }

    public func mainDisplay() -> DisplayProfile {
        displays().first(where: { $0.isMain }) ?? displays().first ?? .fallback
    }
}

public struct StaticDisplayService: DisplayServicing {
    public var profiles: [DisplayProfile]

    public init(profiles: [DisplayProfile] = [.fallback]) {
        self.profiles = profiles
    }

    public func displays() -> [DisplayProfile] { profiles }
    public func mainDisplay() -> DisplayProfile { profiles.first(where: { $0.isMain }) ?? profiles.first ?? .fallback }
}
