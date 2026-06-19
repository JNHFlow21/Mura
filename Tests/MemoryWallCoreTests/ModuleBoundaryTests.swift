import XCTest
import MemoryWallCore

final class ModuleBoundaryTests: XCTestCase {
    func testCoreContainsOnlyPortableModels() {
        let preferences = MemoryWallPreferences()
        XCTAssertEqual(preferences.fontFamily, MemoryWallDefaults.fontFamily)
        XCTAssertEqual(DisplayProfile.fallback.width, 1920)
    }
}
