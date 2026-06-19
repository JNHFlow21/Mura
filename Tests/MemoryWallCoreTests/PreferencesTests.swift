import XCTest
import MemoryWallCore

final class PreferencesTests: XCTestCase {
    func testDefaultsFavorLargeWenkaiCanvas() {
        let preferences = MemoryWallPreferences()
        XCTAssertGreaterThanOrEqual(preferences.defaultFontSize, 90)
        XCTAssertEqual(preferences.backgroundColor, "#fff8df")
        XCTAssertEqual(preferences.fontFamily, "LXGW WenKai")
        XCTAssertGreaterThan(preferences.renderElementLimit, 100)
    }
}
