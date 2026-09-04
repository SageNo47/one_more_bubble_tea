import AppKit

final class FloatingPanel: NSPanel {
    override var canBecomeKey: Bool { true }
}

func makeFloatingPanel(size: NSSize, resizable: Bool = false) -> NSPanel {
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
    panel.isFloatingPanel = true
    panel.level = .statusBar
    panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
    panel.isOpaque = false
    panel.backgroundColor = .clear
    panel.hasShadow = false
    panel.hidesOnDeactivate = false
    return panel
}
