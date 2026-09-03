import AppKit
import XCTest
@testable import MilkTeaPet

final class WindowPlacerTests: XCTestCase {
    func testUsesAboveWhenThereIsEnoughSpace() {
        let result = WindowPlacer.placement(
            childSize: NSSize(width: 268, height: 128),
            relativeTo: NSRect(x: 400, y: 300, width: 112, height: 140),
            visibleFrame: NSRect(x: 0, y: 0, width: 1000, height: 800),
            preferredEdge: .above,
            gap: 8,
            margin: 12
        )

        XCTAssertEqual(result.edge, .above)
        XCTAssertEqual(result.origin.y, 448)
    }

    func testFallsBackBelowNearTopEdge() {
        let result = WindowPlacer.placement(
            childSize: NSSize(width: 268, height: 128),
            relativeTo: NSRect(x: 400, y: 630, width: 112, height: 140),
            visibleFrame: NSRect(x: 0, y: 0, width: 1000, height: 800),
            preferredEdge: .above,
            gap: 8,
            margin: 12
        )

        XCTAssertEqual(result.edge, .below)
        XCTAssertEqual(result.origin.y, 494)
    }

    func testClampsHorizontalPositionToVisibleFrame() {
        let result = WindowPlacer.placement(
            childSize: NSSize(width: 268, height: 128),
            relativeTo: NSRect(x: -50, y: 300, width: 112, height: 140),
            visibleFrame: NSRect(x: 0, y: 0, width: 1000, height: 800),
            preferredEdge: .above,
            gap: 8,
            margin: 12
        )

        XCTAssertEqual(result.origin.x, 12)
    }
}
