import AppKit
import MilkTeaDomain
import SwiftUI

@MainActor
final class SettingsWindowController {
    private(set) var panel: NSPanel?

    func show(
        relativeTo petWindow: NSWindow,
        settingsRepository: any SettingsRepository,
        selectedMilkTeaID: String,
        onSettingsSaved: @escaping () -> Void
    ) {
        if let panel {
            panel.makeKeyAndOrderFront(nil)
            return
        }

        let panel = makeFloatingPanel(
            size: PanelMetrics.settingsSize,
            resizable: true,
            alwaysOnTop: false
        )
        panel.contentMinSize = PanelMetrics.settingsMinimumSize
        panel.isMovable = true
        panel.isMovableByWindowBackground = true

        let viewModel = SettingsViewModel(
            settingsRepository: settingsRepository,
            selectedMilkTeaID: selectedMilkTeaID,
            onSettingsSaved: onSettingsSaved
        )
        let hosting = NSHostingView(
            rootView: SettingsView(
                viewModel: viewModel,
                onClose: { [weak self] in self?.close() }
            )
        )
        hosting.frame = NSRect(origin: .zero, size: PanelMetrics.settingsSize)
        hosting.autoresizingMask = [.width, .height]
        panel.contentView = hosting
        WindowPlacer.center(panel, onScreenContaining: petWindow.frame)
        panel.makeKeyAndOrderFront(nil)
        self.panel = panel
    }

    func close() {
        panel?.orderOut(nil)
        panel = nil
    }
}
