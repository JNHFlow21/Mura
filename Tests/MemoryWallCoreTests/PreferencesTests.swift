import XCTest
import MemoryWallCore

final class PreferencesTests: XCTestCase {
    func testDefaultsFavorLargeHandDrawnWall() {
        let preferences = MemoryWallPreferences()
        XCTAssertGreaterThanOrEqual(preferences.defaultFontSize, 90)
        XCTAssertEqual(preferences.backgroundColor, "#fff8df")
        XCTAssertGreaterThan(preferences.renderElementLimit, 100)
    }
}
