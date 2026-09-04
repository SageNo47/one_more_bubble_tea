import AppKit

final class FloatingPanel: NSPanel {
    override var canBecomeKey: Bool { true }
}

func makeFloatingPanel(
    size: NSSize,
    resizable: Bool = false,
    alwaysOnTop: Bool = true
) -> NSPanel {
    var styleMask: NSWindow.StyleMask = [.borderless, .nonactivatingPanel]
    if resizable {
        styleMask.insert(.resizable)
    }

    let panel = FloatingPanel(
        contentRect: NSRect(origin: .zero, size: size),
        styleMask: styleMask,
        backing: .buffered,
        defer: false
    )
    panel.isFloatingPanel = alwaysOnTop
    panel.level = alwaysOnTop ? .statusBar : .normal
    panel.collectionBehavior = alwaysOnTop
        ? [.canJoinAllSpaces, .stationary, .ignoresCycle]
        : [.moveToActiveSpace]
    panel.isOpaque = false
    panel.backgroundColor = .clear
    panel.hasShadow = false
    panel.hidesOnDeactivate = false
    return panel
}
