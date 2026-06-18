import XCTest
import MemoryWallCore
import MemoryWallRenderer

final class PerformanceBudgetTests: XCTestCase {
    func testRenderBudgetRejectsTooManyElements() {
        var board = BoardDocument.defaultMemoryWall()
        board.elements = (0..<5).map { BoardElement(x: 0, y: Double($0 * 10), width: 10, height: 10, text: "x") }
        XCTAssertThrowsError(try RenderBudget(maxElements: 4).validate(board: board, display: .fallback))
    }
}
