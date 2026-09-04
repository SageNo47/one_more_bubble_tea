import AppKit
import SwiftUI

@MainActor
final class ReminderWindowController {
    private(set) var panel: NSPanel?

    private weak var petWindow: NSWindow?
    private var hostingView: NSHostingView<ReminderBubble>?
    private var petMoveObserver: NSObjectProtocol?
    private var bubbleEdge: WindowPlacer.Edge?
    private var message = ""
    private var onAccept: () throws -> Void = {}
    private var onDecline: () -> Void = {}

    func show(
        relativeTo petWindow: NSWindow,
        message: String,
        onAccept: @escaping () throws -> Void,
        onDecline: @escaping () -> Void
    ) {
        close()
        self.message = message
        self.onAccept = onAccept
        self.onDecline = onDecline

        let panel = makeFloatingPanel(size: PanelMetrics.reminderSize)
        panel.animationBehavior = .none
        let hosting = NSHostingView(rootView: makeBubble(edge: .above))
        hosting.frame = NSRect(origin: .zero, size: PanelMetrics.reminderSize)
        hosting.autoresizingMask = [.width, .height]
        panel.contentView = hosting

        self.petWindow = petWindow
        hostingView = hosting
        self.panel = panel
        observePetMovement()
        reposition()
        panel.orderFrontRegardless()
    }

    func close() {
        if let petMoveObserver {
            NotificationCenter.default.removeObserver(petMoveObserver)
        }
        petMoveObserver = nil
        panel?.orderOut(nil)
        panel = nil
        hostingView = nil
        petWindow = nil
        bubbleEdge = nil
        onAccept = {}
        onDecline = {}
    }

    private func observePetMovement() {
        guard let petWindow else { return }
        petMoveObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didMoveNotification,
            object: petWindow,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.reposition()
            }
        }
    }

    private func reposition() {
        guard let panel, let petWindow else { return }
        let placement = WindowPlacer.place(
            panel,
            relativeTo: petWindow.frame,
            preferredEdge: .above,
            gap: 8
        )
        if bubbleEdge != placement.edge {
            bubbleEdge = placement.edge
            hostingView?.rootView = makeBubble(edge: placement.edge)
        }
    }

    private func makeBubble(edge: WindowPlacer.Edge) -> ReminderBubble {
        ReminderBubble(
            text: message,
            edge: edge,
            onAccept: { [weak self] in
                guard let self else { return }
                try self.onAccept()
                self.close()
            },
            onDecline: { [weak self] in
                guard let self else { return }
                self.onDecline()
                self.close()
            }
        )
    }
}
