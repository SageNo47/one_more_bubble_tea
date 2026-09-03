import SwiftUI
import AppKit

// MARK: - 中性通用配色

enum AppTheme {
    static let windowBackground = Color(red: 0.965, green: 0.958, blue: 0.948)
    static let surface = Color(red: 0.995, green: 0.992, blue: 0.986)
    static let surfaceMuted = Color(red: 0.935, green: 0.925, blue: 0.912)
    static let border = Color(red: 0.82, green: 0.80, blue: 0.77)
    static let windowBorder = Color(red: 0.62, green: 0.57, blue: 0.52)
    static let textPrimary = Color(red: 0.18, green: 0.17, blue: 0.16)
    static let textSecondary = Color(red: 0.43, green: 0.41, blue: 0.38)
    static let accent = Color(red: 0.38, green: 0.31, blue: 0.27)
    static let danger = Color(red: 0.76, green: 0.22, blue: 0.20)
    static let success = Color(red: 0.22, green: 0.48, blue: 0.31)
}

// MARK: - App 入口

@main
struct MilkTeaPetApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

// MARK: - 无边框置顶宠物窗口

let petWidth: CGFloat = 112
let petHeight: CGFloat = 140

enum PanelMetrics {
    static let reminderSize = NSSize(width: 268, height: 128)
    static let settingsSize = NSSize(width: 400, height: 300)
    static let screenMargin: CGFloat = 12
}

final class PetPanel: NSPanel {
    init() {
        super.init(contentRect: NSRect(x: 0, y: 0, width: petWidth, height: petHeight),
                   styleMask: [.borderless, .nonactivatingPanel],
                   backing: .buffered, defer: false)
        isFloatingPanel = true
        level = .statusBar
        collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        isMovableByWindowBackground = true
        hidesOnDeactivate = false

        // 默认放在屏幕右上角
        if let screen = NSScreen.main {
            let x = screen.frame.maxX - petWidth - 30
            let y = screen.frame.maxY - petHeight - 120
            setFrameOrigin(NSPoint(x: x, y: y))
        }
    }

    override var canBecomeKey: Bool { true }
}

// MARK: - 子窗口定位
// 使用宠物实际所在的屏幕，并把窗口完整限制在菜单栏与 Dock 之外的可见区域。

enum WindowPlacer {
    enum Edge: Equatable {
        case above
        case below
    }

    struct Result {
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

// MARK: - 无边框小面板

final class FloatingPanel: NSPanel {
    override var canBecomeKey: Bool { true }
}

func makeFloatingPanel(size: NSSize) -> NSPanel {
    let panel = FloatingPanel(contentRect: NSRect(origin: .zero, size: size),
                           styleMask: [.borderless, .nonactivatingPanel],
                           backing: .buffered, defer: false)
    panel.isFloatingPanel = true
    panel.level = .statusBar
    panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
    panel.isOpaque = false
    panel.backgroundColor = .clear
    panel.hasShadow = false
    panel.hidesOnDeactivate = false
    return panel
}

// MARK: - 提醒气泡窗口（优先显示在宠物上方，空间不足时显示在下方）

final class ReminderWindowController {
    static let shared = ReminderWindowController()

    private(set) var panel: NSPanel?
    private weak var petWindow: NSWindow?
    private var hostingView: NSHostingView<ReminderBubble>?
    private var petMoveObserver: NSObjectProtocol?
    private var bubbleEdge: WindowPlacer.Edge?
    private var message = ""

    func show(relativeTo petWindow: NSWindow, message: String? = nil) {
        close()
        self.message = message ?? PetSettings.loadMessage()

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

        // 内容视图挂载完成后再读取实时位置并显示，避免出现位于初始原点的首帧。
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
    }

    private func observePetMovement() {
        guard let petWindow else { return }
        petMoveObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didMoveNotification,
            object: petWindow,
            queue: .main
        ) { [weak self] _ in
            self?.reposition()
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
        ReminderBubble(text: message, edge: edge) { [weak self] in
            self?.close()
        }
    }
}

// MARK: - 设置窗口（独立居中显示）

final class SettingsWindowController: NSObject {
    static let shared = SettingsWindowController()
    private(set) var panel: NSPanel?

    func show(
        relativeTo petWindow: NSWindow,
        onSettingsSaved: @escaping () -> Void,
        milkTeaStore: MilkTeaStore
    ) {
        if let panel {
            panel.makeKeyAndOrderFront(nil)
            return
        }

        let panel = makeFloatingPanel(size: PanelMetrics.settingsSize)
        panel.isMovable = true
        panel.isMovableByWindowBackground = true
        let hosting = NSHostingView(rootView:
            SettingsView(onSettingsSaved: onSettingsSaved)
                .environmentObject(milkTeaStore)
                .frame(width: PanelMetrics.settingsSize.width,
                       height: PanelMetrics.settingsSize.height))
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

// MARK: - App 生命周期

final class AppDelegate: NSObject, NSApplicationDelegate {
    var panel: PetPanel?
    let scheduler = ReminderScheduler()
    let milkTeaStore = MilkTeaStore()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let panel = PetPanel()
        let reminderScheduler = scheduler
        let sharedMilkTeaStore = milkTeaStore
        let hosting = NSHostingView(rootView:
            PetView(
                onShowSettings: { [weak panel] in
                    guard let panel else { return }
                    SettingsWindowController.shared.show(
                        relativeTo: panel,
                        onSettingsSaved: reminderScheduler.reschedule,
                        milkTeaStore: sharedMilkTeaStore
                    )
                },
                onShowReminder: { [weak panel] message in
                    guard let panel else { return }
                    ReminderWindowController.shared.show(
                        relativeTo: panel,
                        message: message
                    )
                },
                scheduler: reminderScheduler
            )
                .environmentObject(reminderScheduler)
                .environmentObject(sharedMilkTeaStore))
        hosting.frame = NSRect(x: 0, y: 0, width: petWidth, height: petHeight)
        panel.contentView = hosting
        panel.orderFrontRegardless()
        self.panel = panel

        scheduler.start()
    }
}

// MARK: - 宠物视图

struct PetView: View {
    let onShowSettings: () -> Void
    let onShowReminder: (String?) -> Void

    @ObservedObject var scheduler: ReminderScheduler
    @EnvironmentObject private var milkTeaStore: MilkTeaStore

    var body: some View {
        AnimatedMilkTea(milkTea: milkTeaStore.selectedMilkTea)
            .contextMenu {
                Button("设置…", action: onShowSettings)
                Divider()
                Button("关闭") {
                    NSApp.terminate(nil)
                }
            }
            .onTapGesture(perform: onShowSettings)
            .onChange(of: scheduler.showReminder) { show in
                if show {
                    showReminder()
                }
            }
            .frame(width: petWidth, height: petHeight)
    }

    private func showReminder() {
        onShowReminder(scheduler.pendingMessage)
        scheduler.didPresentReminder()
    }
}

// MARK: - 提醒气泡

struct ReminderBubble: View {
    let text: String
    let edge: WindowPlacer.Edge
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            if edge == .below {
                tail
                    .rotationEffect(.degrees(180))
            }

            bubbleBody

            if edge == .above {
                tail
            }
        }
        .frame(width: PanelMetrics.reminderSize.width,
               height: PanelMetrics.reminderSize.height,
               alignment: edge == .above ? .bottom : .top)
    }

    private var bubbleBody: some View {
        VStack(spacing: 14) {
            Text(text)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(AppTheme.textPrimary)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .lineLimit(2)
                .frame(maxWidth: .infinity)

            HStack(spacing: 8) {
                BubbleButton(title: "来一杯", isPrimary: true, action: onClose)
                BubbleButton(title: "今天不喝", isPrimary: false, action: onClose)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(width: PanelMetrics.reminderSize.width, height: 120)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppTheme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(AppTheme.windowBorder, lineWidth: 2)
        )
    }

    private var tail: some View {
        Triangle()
            .fill(AppTheme.surface)
            .frame(width: 14, height: 8)
            .overlay(
                Triangle()
                    .stroke(AppTheme.windowBorder, lineWidth: 2)
            )
    }
}

struct BubbleButton: View {
    let title: String
    let isPrimary: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(isPrimary ? .white : AppTheme.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 32)
                .background(isPrimary ? AppTheme.accent : AppTheme.surfaceMuted)
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(isPrimary ? Color.clear : AppTheme.border, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.closeSubpath()
        return p
    }
}

// MARK: - 设置窗口

enum SaveFeedback: Equatable {
    case idle
    case success(String)
    case error(String)
}

struct SettingsView: View {
    let onSettingsSaved: () -> Void

    @EnvironmentObject private var milkTeaStore: MilkTeaStore

    @State private var hourText = "15"
    @State private var minuteText = "00"
    @State private var secondText = "00"
    @State private var message = ""
    @State private var feedback: SaveFeedback = .idle

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppTheme.windowBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(AppTheme.windowBorder, lineWidth: 2)
                )
                .padding(1)

            VStack(spacing: 0) {
                header
                Spacer().frame(height: 12)
                timeSection.padding(.horizontal, 8)
                Spacer().frame(height: 20)
                messageSection.padding(.horizontal, 8)
                Spacer().frame(height: 20)
                footer.padding(.horizontal, 8)
            }
            .padding(16)
        }
        .frame(width: PanelMetrics.settingsSize.width,
               height: PanelMetrics.settingsSize.height)
        .onAppear(perform: loadSettings)
        .onChange(of: hourText) { _ in clearFeedback() }
        .onChange(of: minuteText) { _ in clearFeedback() }
        .onChange(of: secondText) { _ in clearFeedback() }
        .onChange(of: message) { _ in clearFeedback() }
    }

    private var header: some View {
        ZStack {
            Text("设置")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(AppTheme.textPrimary)

            HStack {
                Spacer()

                Button {
                    SettingsWindowController.shared.close()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(AppTheme.textSecondary)
                        .frame(width: 28, height: 28)
                        .background(Circle().fill(AppTheme.surfaceMuted))
                }
                .buttonStyle(.plain)
                .help("关闭")
                .accessibilityLabel("关闭")
            }
        }
        .frame(height: 32)
    }

    private var timeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("提醒时间", systemImage: "clock.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(AppTheme.textPrimary)
                .frame(height: 18)

            HStack(spacing: 8) {
                TimeTextField(text: $hourText, accessibilityLabel: "小时")
                Text(":")
                    .font(.system(size: 18, weight: .semibold, design: .monospaced))
                    .foregroundColor(AppTheme.textSecondary)
                TimeTextField(text: $minuteText, accessibilityLabel: "分钟")
                Text(":")
                    .font(.system(size: 18, weight: .semibold, design: .monospaced))
                    .foregroundColor(AppTheme.textSecondary)
                TimeTextField(text: $secondText, accessibilityLabel: "秒钟")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var messageSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("提醒词", systemImage: "bubble.left.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(AppTheme.textPrimary)
                .frame(height: 18)

            TextField("例如：今天要不要来一杯奶茶呀？", text: $message)
                .textFieldStyle(.plain)
                .font(.system(size: 14))
                .foregroundColor(AppTheme.textPrimary)
                .padding(.horizontal, 12)
                .frame(height: 48)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(AppTheme.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(AppTheme.border, lineWidth: 1)
                )
                .accessibilityLabel("提醒词")
                .onSubmit(save)
        }
    }

    private var footer: some View {
        HStack(spacing: 12) {
            if let feedbackMessage {
                Label(feedbackMessage.text, systemImage: feedbackMessage.icon)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(feedbackMessage.color)
                    .lineLimit(1)
                    .transition(.opacity)
            }

            Spacer(minLength: 8)

            Button(action: save) {
                Text("保存")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 96, height: 40)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(AppTheme.accent)
                    )
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.defaultAction)
        }
        .frame(height: 40)
    }

    private var feedbackMessage: (text: String, icon: String, color: Color)? {
        switch feedback {
        case .idle:
            return nil
        case let .success(message):
            return (message, "checkmark.circle.fill", AppTheme.success)
        case let .error(message):
            return (message, "exclamationmark.circle.fill", AppTheme.danger)
        }
    }

    private func save() {
        guard let hour = Int(hourText), (0...23).contains(hour),
              let minute = Int(minuteText), (0...59).contains(minute),
              let second = Int(secondText), (0...59).contains(second) else {
            withAnimation(.easeOut(duration: 0.16)) {
                feedback = .error("请输入有效时间")
            }
            return
        }

        let trimmedMessage = message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMessage.isEmpty else {
            withAnimation(.easeOut(duration: 0.16)) {
                feedback = .error("提醒词不能为空")
            }
            return
        }

        hourText = String(format: "%02d", hour)
        minuteText = String(format: "%02d", minute)
        secondText = String(format: "%02d", second)
        message = trimmedMessage
        PetSettings.save(
            ReminderSettings(
                hour: hour,
                minute: minute,
                second: second,
                message: trimmedMessage,
                selectedMilkTeaID: milkTeaStore.selectedMilkTeaID
            )
        )
        onSettingsSaved()
        withAnimation(.easeOut(duration: 0.16)) {
            feedback = .success("已保存")
        }
    }

    private func loadSettings() {
        let settings = PetSettings.load()
        hourText = String(format: "%02d", settings.hour)
        minuteText = String(format: "%02d", settings.minute)
        secondText = String(format: "%02d", settings.second)
        message = settings.message
        feedback = .idle
    }

    private func clearFeedback() {
        if feedback != .idle {
            feedback = .idle
        }
    }
}

// MARK: - 直接输入时间

struct TimeTextField: View {
    @Binding var text: String
    let accessibilityLabel: String

    var body: some View {
        TextField("00", text: $text)
            .textFieldStyle(.plain)
            .font(.system(size: 17, weight: .semibold, design: .monospaced))
            .foregroundColor(AppTheme.textPrimary)
            .multilineTextAlignment(.center)
            .frame(width: 58, height: 40)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(AppTheme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(AppTheme.border, lineWidth: 1)
            )
            .accessibilityLabel(accessibilityLabel)
            .onChange(of: text) { newValue in
                let digits = String(newValue.filter(\.isNumber).prefix(2))
                if digits != newValue {
                    text = digits
                }
            }
    }
}
