import AppKit

enum WindowPlacer {
    enum Edge: Equatable {
        case above
        case below
    }

    struct Result: Equatable {
        let origin: NSPoint
        let edge: Edge
    }

    @discardableResult
    static func place(
        _ child: NSWindow,
        relativeTo pet: NSRect,
        preferredEdge: Edge,
        gap: CGFloat
    ) -> Result {
        let visibleFrame = screen(containing: pet)?.visibleFrame
            ?? NSScreen.main?.visibleFrame
            ?? pet.insetBy(dx: -child.frame.width, dy: -child.frame.height)
        let result = placement(
            childSize: child.frame.size,
            relativeTo: pet,
            visibleFrame: visibleFrame,
            preferredEdge: preferredEdge,
            gap: gap,
            margin: PanelMetrics.screenMargin
        )
        child.setFrameOrigin(result.origin)
        return result
    }

    static func placement(
        childSize: NSSize,
        relativeTo pet: NSRect,
        visibleFrame: NSRect,
        preferredEdge: Edge,
        gap: CGFloat,
        margin: CGFloat
    ) -> Result {
        let usableFrame = visibleFrame.insetBy(dx: margin, dy: margin)
        let aboveY = pet.maxY + gap
        let belowY = pet.minY - gap - childSize.height
        let fitsAbove = aboveY + childSize.height <= usableFrame.maxY
        let fitsBelow = belowY >= usableFrame.minY

        let edge: Edge
        switch preferredEdge {
        case .above where fitsAbove:
            edge = .above
        case .below where fitsBelow:
            edge = .below
        case .above where fitsBelow:
            edge = .below
        case .below where fitsAbove:
            edge = .above
        default:
            let spaceAbove = usableFrame.maxY - pet.maxY
            let spaceBelow = pet.minY - usableFrame.minY
            edge = spaceAbove >= spaceBelow ? .above : .below
        }

        let desiredY = edge == .above ? aboveY : belowY
        let desiredX = pet.midX - childSize.width / 2
        return Result(
            origin: NSPoint(
                x: clamped(desiredX, min: usableFrame.minX, max: usableFrame.maxX - childSize.width),
                y: clamped(desiredY, min: usableFrame.minY, max: usableFrame.maxY - childSize.height)
            ),
            edge: edge
        )
    }

    static func center(_ child: NSWindow, onScreenContaining pet: NSRect) {
        let visibleFrame = screen(containing: pet)?.visibleFrame
            ?? NSScreen.main?.visibleFrame
            ?? pet.insetBy(dx: -child.frame.width, dy: -child.frame.height)
        child.setFrameOrigin(
            NSPoint(
                x: visibleFrame.midX - child.frame.width / 2,
                y: visibleFrame.midY - child.frame.height / 2
            )
        )
    }

    private static func screen(containing rect: NSRect) -> NSScreen? {
        let screensByOverlap = NSScreen.screens.map { screen in
            let intersection = screen.frame.intersection(rect)
            let area = intersection.isNull ? 0 : intersection.width * intersection.height
            return (screen, area)
        }
        if let bestMatch = screensByOverlap.max(by: { $0.1 < $1.1 }), bestMatch.1 > 0 {
            return bestMatch.0
        }

        let center = NSPoint(x: rect.midX, y: rect.midY)
        return NSScreen.screens.min { lhs, rhs in
            squaredDistance(from: center, to: lhs.frame) < squaredDistance(from: center, to: rhs.frame)
        }
    }

    private static func clamped(_ value: CGFloat, min lowerBound: CGFloat, max upperBound: CGFloat) -> CGFloat {
        guard lowerBound <= upperBound else { return lowerBound }
        return Swift.min(Swift.max(value, lowerBound), upperBound)
    }

    private static func squaredDistance(from point: NSPoint, to rect: NSRect) -> CGFloat {
        let nearestX = clamped(point.x, min: rect.minX, max: rect.maxX)
        let nearestY = clamped(point.y, min: rect.minY, max: rect.maxY)
        let dx = point.x - nearestX
        let dy = point.y - nearestY
        return dx * dx + dy * dy
    }
}
