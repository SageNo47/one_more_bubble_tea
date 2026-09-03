import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var coordinator: AppCoordinator?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        do {
            let dependencies = try AppDependencies.live()
            let coordinator = AppCoordinator(dependencies: dependencies)
            coordinator.start()
            self.coordinator = coordinator
        } catch {
            let alert = NSAlert()
            alert.alertStyle = .critical
            alert.messageText = "MilkTeaPet 无法启动"
            alert.informativeText = "本地数据存储初始化失败：\(error.localizedDescription)"
            alert.runModal()
            NSApp.terminate(nil)
        }
    }
}
