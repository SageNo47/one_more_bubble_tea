import AppKit
import SwiftUI

final class PetPanel: NSPanel {
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: PetMetrics.width, height: PetMetrics.height),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        isFloatingPanel = true
        level = .statusBar
        collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        isMovableByWindowBackground = true
        hidesOnDeactivate = false

        if let screen = NSScreen.main {
            let x = screen.frame.maxX - PetMetrics.width - 30
            let y = screen.frame.maxY - PetMetrics.height - 120
            setFrameOrigin(NSPoint(x: x, y: y))
        }
    }

    override var canBecomeKey: Bool { true }
}

@MainActor
final class PetWindowController {
    private(set) var panel: PetPanel?

    private let milkTeaStore: MilkTeaStore
    private let scheduler: ReminderScheduler
    private let onShowSettings: () -> Void
    private let onShowHistory: () -> Void
    private let onShowReminder: (String?) -> Void
    private let onQuit: () -> Void

    init(
        milkTeaStore: MilkTeaStore,
        scheduler: ReminderScheduler,
        onShowSettings: @escaping () -> Void,
        onShowHistory: @escaping () -> Void,
        onShowReminder: @escaping (String?) -> Void,
        onQuit: @escaping () -> Void
    ) {
        self.milkTeaStore = milkTeaStore
        self.scheduler = scheduler
        self.onShowSettings = onShowSettings
        self.onShowHistory = onShowHistory
        self.onShowReminder = onShowReminder
        self.onQuit = onQuit
    }

    func show() {
        if let panel {
            panel.orderFrontRegardless()
            return
        }

        let panel = PetPanel()
        let hosting = NSHostingView(
            rootView: PetView(
                milkTeaStore: milkTeaStore,
                scheduler: scheduler,
                onShowSettings: onShowSettings,
                onShowHistory: onShowHistory,
                onShowReminder: onShowReminder,
                onQuit: onQuit
            )
        )
        hosting.frame = NSRect(x: 0, y: 0, width: PetMetrics.width, height: PetMetrics.height)
        panel.contentView = hosting
        panel.orderFrontRegardless()
        self.panel = panel
    }
}
