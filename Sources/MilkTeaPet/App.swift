import SwiftUI
import AppKit

// MARK: - 像素风通用配色

enum PixelTheme {
    static let brown = Color(red: 0.36, green: 0.20, blue: 0.12)
    static let cream = Color(red: 0.98, green: 0.94, blue: 0.86)
    static let tea = Color(red: 0.87, green: 0.64, blue: 0.38)
    static let gray = Color(red: 0.92, green: 0.92, blue: 0.92)
    static let foam = Color(red: 1.00, green: 0.97, blue: 0.90)
    static let caramel = Color(red: 0.91, green: 0.63, blue: 0.32)
    static let caramelLight = Color(red: 0.98, green: 0.87, blue: 0.68)
    static let cocoa = Color(red: 0.29, green: 0.16, blue: 0.10)
    static let mutedBrown = Color(red: 0.52, green: 0.39, blue: 0.31)
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

// MARK: - 无边框置顶宠物窗口（尺寸贴合奶茶图案）

let petWidth: CGFloat = 112   // 16 像素 × 7
let petHeight: CGFloat = 140  // 20 像素 × 7

enum PanelMetrics {
    static let reminderSize = NSSize(width: 252, height: 190)
    static let settingsSize = NSSize(width: 400, height: 360)
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

// MARK: - 像素风无边框小面板

final class PixelPanel: NSPanel {
    override var canBecomeKey: Bool { true }
}

func makePixelPanel(size: NSSize) -> NSPanel {
    let panel = PixelPanel(contentRect: NSRect(origin: .zero, size: size),
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

        let panel = makePixelPanel(size: PanelMetrics.reminderSize)
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

// MARK: - 设置窗口（独立居中显示，像素风）

final class SettingsWindowController: NSObject {
    static let shared = SettingsWindowController()
    private(set) var panel: NSPanel?

    func show(
        relativeTo petWindow: NSWindow,
        onSettingsSaved: @escaping () -> Void,
        onTestReminder: @escaping (String) -> Void
    ) {
        if let panel {
            panel.makeKeyAndOrderFront(nil)
            return
        }

        let panel = makePixelPanel(size: PanelMetrics.settingsSize)
        panel.isMovable = true
        panel.isMovableByWindowBackground = true
        let hosting = NSHostingView(rootView:
            SettingsView(
                onSettingsSaved: onSettingsSaved,
                onTestReminder: onTestReminder
            )
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

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let panel = PetPanel()
        let reminderScheduler = scheduler
        let hosting = NSHostingView(rootView:
            PetView(
                onShowSettings: { [weak panel] in
                    guard let panel else { return }
                    SettingsWindowController.shared.show(
                        relativeTo: panel,
                        onSettingsSaved: reminderScheduler.reschedule,
                        onTestReminder: reminderScheduler.testReminder
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
                .environmentObject(reminderScheduler))
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

    var body: some View {
        AnimatedMilkTea(pixelSize: 7)
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

// MARK: - 像素风卡片容器
// 米色底 + 棕色粗边框 + 右下硬边阴影块，模仿像素画风格

struct PixelCard<Content: View>: View {
    var cornerRadius: CGFloat = 0
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(16)
            .background(PixelTheme.cream)
            .overlay(
                Rectangle()
                    .stroke(PixelTheme.brown, lineWidth: 3)
            )
            .background(alignment: .bottomTrailing) {
                Rectangle()
                    .fill(PixelTheme.brown)
                    .offset(x: 4, y: 4)
            }
            .padding(.trailing, 4)
            .padding(.bottom, 4)
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
                    .offset(y: 2)
            }

            PixelCard {
                VStack(spacing: 10) {
                    Text("🧋 奶茶提醒")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(PixelTheme.brown)
                    Text(text)
                        .font(.system(size: 13))
                        .foregroundColor(PixelTheme.brown)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineLimit(4)

                    HStack(spacing: 10) {
                        PixelButton(title: "来一杯", background: PixelTheme.tea,
                                    foreground: .white, action: onClose)
                        PixelButton(title: "今天不喝", background: PixelTheme.gray,
                                    foreground: PixelTheme.brown, action: onClose)
                    }
                }
                .frame(maxWidth: .infinity)
            }

            if edge == .above {
                tail.offset(y: -2)
            }
        }
        .padding(.horizontal, 4)
        .frame(width: PanelMetrics.reminderSize.width,
               height: PanelMetrics.reminderSize.height,
               alignment: edge == .above ? .bottom : .top)
    }

    private var tail: some View {
        Triangle()
            .fill(PixelTheme.cream)
            .frame(width: 16, height: 10)
            .overlay(
                Triangle()
                    .stroke(PixelTheme.brown, lineWidth: 3)
            )
    }
}

// MARK: - 像素风按钮

struct PixelButton: View {
    let title: String
    var background: Color = PixelTheme.tea
    var foreground: Color = .white
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(foreground)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(background)
                .overlay(
                    Rectangle().stroke(PixelTheme.brown, lineWidth: 2)
                )
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

// MARK: - 设置窗口（珍珠奶茶主题）

struct SettingsView: View {
    let onSettingsSaved: () -> Void
    let onTestReminder: (String) -> Void

    @State private var hourText = "15"
    @State private var minuteText = "00"
    @State private var message = ""
    @State private var feedback = "设置只会保存在这台 Mac 上"
    @State private var feedbackIsError = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(PixelTheme.foam)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(PixelTheme.cocoa, lineWidth: 3)
                )
                .shadow(color: PixelTheme.cocoa.opacity(0.28), radius: 0, x: 5, y: 5)
                .padding(7)

            Circle()
                .fill(PixelTheme.caramel.opacity(0.12))
                .frame(width: 82, height: 82)
                .offset(x: 168, y: -142)

            Circle()
                .fill(PixelTheme.brown.opacity(0.08))
                .frame(width: 46, height: 46)
                .offset(x: 184, y: 154)

            VStack(spacing: 13) {
                header
                timeSection
                messageSection
                footer
            }
            .padding(.horizontal, 27)
            .padding(.vertical, 23)
        }
        .frame(width: PanelMetrics.settingsSize.width,
               height: PanelMetrics.settingsSize.height)
        .onAppear {
            message = PetSettings.loadMessage()
            if let components = PetSettings.loadTime() {
                hourText = String(format: "%02d", components.hour ?? 15)
                minuteText = String(format: "%02d", components.minute ?? 0)
            }
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            MiniBobaCupIcon()

            VStack(alignment: .leading, spacing: 2) {
                Text("奶茶时间")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(PixelTheme.cocoa)
                Text("给今天留一点甜")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(PixelTheme.mutedBrown)
            }

            Spacer()

            Button {
                SettingsWindowController.shared.close()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(PixelTheme.cocoa)
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(PixelTheme.caramelLight.opacity(0.72)))
            }
            .buttonStyle(.plain)
            .help("关闭")
        }
    }

    private var timeSection: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Label("提醒时间", systemImage: "clock.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(PixelTheme.cocoa)

                HStack(spacing: 8) {
                    Text("每天提醒一次")
                        .font(.system(size: 10))
                        .foregroundColor(PixelTheme.mutedBrown)

                    Button(action: testReminder) {
                        Label("测试气泡", systemImage: "play.fill")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(PixelTheme.brown)
                            .padding(.horizontal, 7)
                            .frame(height: 22)
                            .background(
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(Color.white.opacity(0.72))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .stroke(PixelTheme.caramel.opacity(0.72), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .help("使用当前提醒词预览气泡，不计入每日提醒")
                }
            }

            Spacer(minLength: 8)

            HStack(alignment: .top, spacing: 7) {
                TimeTextField(text: $hourText, label: "时", accessibilityLabel: "小时")
                Text(":")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(PixelTheme.brown)
                    .padding(.top, 6)
                TimeTextField(text: $minuteText, label: "分", accessibilityLabel: "分钟")
            }
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 11)
        .background(
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .fill(PixelTheme.caramelLight.opacity(0.52))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .stroke(PixelTheme.caramel.opacity(0.55), lineWidth: 1.5)
        )
    }

    private var messageSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("提醒词", systemImage: "bubble.left.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(PixelTheme.cocoa)

            TextField("例如：今天要不要来一杯奶茶呀？", text: $message, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .foregroundColor(PixelTheme.cocoa)
                .lineLimit(2...3)
                .padding(.horizontal, 11)
                .padding(.vertical, 9)
                .frame(minHeight: 55, alignment: .topLeading)
                .background(
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(Color.white.opacity(0.82))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .stroke(PixelTheme.caramel.opacity(0.58), lineWidth: 1.5)
                )
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .fill(PixelTheme.cream.opacity(0.78))
        )
    }

    private var footer: some View {
        HStack(spacing: 12) {
            Text(feedback)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(feedbackIsError ? .red : PixelTheme.mutedBrown)
                .lineLimit(1)

            Spacer(minLength: 8)

            Button(action: save) {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                    Text("保存设置")
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 15)
                .frame(height: 34)
                .background(
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(PixelTheme.brown)
                )
            }
            .buttonStyle(.plain)
        }
    }

    private func save() {
        guard let hour = Int(hourText), (0...23).contains(hour),
              let minute = Int(minuteText), (0...59).contains(minute) else {
            feedback = "请输入 00:00–23:59 之间的时间"
            feedbackIsError = true
            return
        }

        let trimmedMessage = message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMessage.isEmpty else {
            feedback = "提醒词不能为空哦"
            feedbackIsError = true
            return
        }

        hourText = String(format: "%02d", hour)
        minuteText = String(format: "%02d", minute)
        message = trimmedMessage
        PetSettings.saveTime("\(hourText):\(minuteText)")
        PetSettings.saveMessage(trimmedMessage)
        onSettingsSaved()
        feedback = "保存好啦，记得准时喝水或奶茶 ✓"
        feedbackIsError = false
    }

    private func testReminder() {
        let trimmedMessage = message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMessage.isEmpty else {
            feedback = "请先输入提醒词再测试"
            feedbackIsError = true
            return
        }

        onTestReminder(trimmedMessage)
        feedback = "测试气泡已显示，不计入每日提醒"
        feedbackIsError = false
    }
}

// MARK: - 直接输入时间

struct TimeTextField: View {
    @Binding var text: String
    let label: String
    let accessibilityLabel: String

    var body: some View {
        VStack(spacing: 3) {
            TextField("00", text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 19, weight: .bold, design: .monospaced))
                .foregroundColor(PixelTheme.brown)
                .multilineTextAlignment(.center)
                .frame(width: 48, height: 34)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.white.opacity(0.9))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(PixelTheme.brown.opacity(0.65), lineWidth: 1.5)
                )
                .accessibilityLabel(accessibilityLabel)
                .onChange(of: text) { newValue in
                    let digits = String(newValue.filter(\.isNumber).prefix(2))
                    if digits != newValue {
                        text = digits
                    }
                }

            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(PixelTheme.mutedBrown)
        }
    }
}

// MARK: - 奶茶主题小图标

struct MiniBobaCupIcon: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(red: 0.91, green: 0.35, blue: 0.34))
                .frame(width: 5, height: 27)
                .rotationEffect(.degrees(7))
                .offset(x: 6, y: -13)

            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(PixelTheme.tea)

                HStack(spacing: 3) {
                    ForEach(0..<4, id: \.self) { _ in
                        Circle()
                            .fill(PixelTheme.cocoa)
                            .frame(width: 5, height: 5)
                    }
                }
                .padding(.bottom, 5)
            }
            .frame(width: 34, height: 35)
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(PixelTheme.cocoa, lineWidth: 2)
            )
            .offset(y: 6)

            Capsule()
                .fill(PixelTheme.cream)
                .frame(width: 40, height: 7)
                .overlay(Capsule().stroke(PixelTheme.cocoa, lineWidth: 2))
                .offset(y: -11)
        }
        .frame(width: 48, height: 48)
        .background(
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .fill(PixelTheme.caramelLight.opacity(0.62))
        )
    }
}
