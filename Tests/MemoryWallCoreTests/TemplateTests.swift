import XCTest
import MemoryWallCore

final class TemplateTests: XCTestCase {
    func testDefaultTemplatesIncludeFocusLayout() {
        let templates = MemoryWallTemplate.defaultTemplates()
        XCTAssertTrue(templates.contains { $0.id == "default-memory-wall" })
        XCTAssertTrue(templates.contains { $0.id == "today-focus" })
        XCTAssertTrue(templates.flatMap(\.board.elements).contains { $0.text.contains("别忘") })
    }
}
