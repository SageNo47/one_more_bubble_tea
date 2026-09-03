import SwiftUI

struct PetView: View {
    @ObservedObject var milkTeaStore: MilkTeaStore
    @ObservedObject var scheduler: ReminderScheduler

    let onShowSettings: () -> Void
    let onShowReminder: (String?) -> Void
    let onQuit: () -> Void

    var body: some View {
        AnimatedMilkTea(milkTea: milkTeaStore.selectedMilkTea)
            .contextMenu {
                Button("设置…", action: onShowSettings)
                Divider()
                Button("关闭", action: onQuit)
            }
            .onTapGesture(perform: onShowSettings)
            .onChange(of: scheduler.showReminder) { show in
                if show {
                    onShowReminder(scheduler.pendingMessage)
                    scheduler.didPresentReminder()
                }
            }
            .frame(width: PetMetrics.width, height: PetMetrics.height)
    }
}
