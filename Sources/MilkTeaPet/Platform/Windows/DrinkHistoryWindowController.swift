import AppKit
import MilkTeaDomain
import SwiftUI

@MainActor
final class DrinkHistoryWindowController {
    private(set) var panel: NSPanel?

    private var viewModel: DrinkHistoryViewModel?

    func show(
        relativeTo petWindow: NSWindow,
        repository: any DrinkRecordRepository,
        milkTeaStore: MilkTeaStore,
        calendar: Calendar = .current,
        now: @escaping () -> Date = Date.init
    ) {
        if let panel {
            viewModel?.load()
            panel.makeKeyAndOrderFront(nil)
            return
        }

        let viewModel = DrinkHistoryViewModel(
            repository: repository,
            milkTeaID: { [weak milkTeaStore] in milkTeaStore?.selectedMilkTeaID },
            calendar: calendar,
            now: now
        )
        let panel = makeFloatingPanel(size: PanelMetrics.drinkHistorySize)
        panel.isMovable = true
        panel.isMovableByWindowBackground = true

        let hosting = NSHostingView(
            rootView: DrinkHistoryView(
                viewModel: viewModel,
                milkTeaStore: milkTeaStore,
                onClose: { [weak self] in self?.close() }
            )
        )
        hosting.frame = NSRect(origin: .zero, size: PanelMetrics.drinkHistorySize)
        hosting.autoresizingMask = [.width, .height]
        panel.contentView = hosting
        WindowPlacer.center(panel, onScreenContaining: petWindow.frame)
        panel.makeKeyAndOrderFront(nil)

        self.viewModel = viewModel
        self.panel = panel
    }

    func reloadIfVisible() {
        guard panel != nil else { return }
        viewModel?.load()
    }

    func close() {
        panel?.orderOut(nil)
        panel = nil
        viewModel = nil
    }
}
