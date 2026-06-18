import XCTest
@testable import MemoryWallWallpaper

final class HotkeyServiceTests: XCTestCase {
    func testInMemoryHotkeyRegistersAndTriggers() {
        let service = InMemoryHotkeyService()
        var didTrigger = false
        let status = service.register(description: "⌥⌘B") { didTrigger = true }
        XCTAssertTrue(status.isRegistered)
        service.triggerForTests()
        XCTAssertTrue(didTrigger)
        service.unregister()
        XCTAssertFalse(service.status().isRegistered)
    }

    func testDefaultCarbonShortcutParsing() {
        #if canImport(Carbon)
        XCTAssertNotNil(CarbonHotkeyService.parse(description: "⌥⌘B"))
        XCTAssertNil(CarbonHotkeyService.parse(description: "⌘X"))
        #endif
    }
}
