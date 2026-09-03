import AppKit
import SwiftUI

struct RecordEffectPlacement {
    static func origin(
        effectSize: NSSize,
        relativeTo petFrame: NSRect,
        visibleFrame: NSRect,
        margin: CGFloat = PanelMetrics.screenMargin
    ) -> NSPoint {
        let proposedX = petFrame.midX - effectSize.width / 2
        let proposedY = petFrame.maxY - 18
        let maximumX = max(visibleFrame.minX + margin, visibleFrame.maxX - margin - effectSize.width)
        let maximumY = max(visibleFrame.minY + margin, visibleFrame.maxY - margin - effectSize.height)

        return NSPoint(
            x: min(max(proposedX, visibleFrame.minX + margin), maximumX),
            y: min(max(proposedY, visibleFrame.minY + margin), maximumY)
        )
    }
}

struct RecordEffectView: View {
    var body: some View {
        ZStack {
            RecordEffectBubble(delay: 0)
            RecordEffectBubble(delay: 0.76)
        }
        .accessibilityHidden(true)
    }
}

private struct RecordEffectBubble: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let delay: TimeInterval

    @State private var opacity = 0.0
    @State private var scale = 0.62
    @State private var verticalOffset: CGFloat = 14
    @State private var rotation = 7.0

    var body: some View {
        Text("+1")
            .font(.system(size: 36, weight: .heavy, design: .rounded))
            .tracking(-1)
            .foregroundColor(AppTheme.recordEffect)
            .opacity(opacity)
            .scaleEffect(scale)
            .rotationEffect(.degrees(rotation))
            .offset(y: verticalOffset)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear(perform: startAnimation)
    }

    private func startAnimation() {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            withAnimation(reduceMotion ? .easeOut(duration: 0.16) : .spring(response: 0.34, dampingFraction: 0.62)) {
                opacity = 1
                scale = 1
                rotation = reduceMotion ? 0 : -4
            }

            withAnimation(.easeOut(duration: reduceMotion ? 0.55 : 0.82)) {
                verticalOffset = reduceMotion ? -8 : -34
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.48) {
                withAnimation(.easeIn(duration: 0.26)) {
                    opacity = 0
                }
            }
        }
    }
}

@MainActor
final class RecordEffectWindowController {
    private(set) var panel: NSPanel?

    private var autoCloseTask: Task<Void, Never>?

    func show(relativeTo petWindow: NSWindow) {
        close()

        let panel = makeFloatingPanel(size: PanelMetrics.recordEffectSize)
        panel.ignoresMouseEvents = true
        panel.animationBehavior = .none

        let hosting = NSHostingView(rootView: RecordEffectView())
        hosting.frame = NSRect(origin: .zero, size: PanelMetrics.recordEffectSize)
        hosting.autoresizingMask = [.width, .height]
        panel.contentView = hosting

        let visibleFrame = petWindow.screen?.visibleFrame
            ?? NSScreen.main?.visibleFrame
            ?? petWindow.frame.insetBy(dx: -PanelMetrics.recordEffectSize.width, dy: -PanelMetrics.recordEffectSize.height)
        panel.setFrameOrigin(
            RecordEffectPlacement.origin(
                effectSize: PanelMetrics.recordEffectSize,
                relativeTo: petWindow.frame,
                visibleFrame: visibleFrame
            )
        )
        panel.orderFrontRegardless()
        self.panel = panel

        autoCloseTask = Task { @MainActor [weak self] in
            try? await Task.sleep(
                nanoseconds: UInt64(PanelMetrics.recordEffectLifetime * 1_000_000_000)
            )
            guard !Task.isCancelled else { return }
            self?.dismissPanel()
        }
    }

    func close() {
        autoCloseTask?.cancel()
        autoCloseTask = nil
        dismissPanel()
    }

    private func dismissPanel() {
        panel?.orderOut(nil)
        panel = nil
        autoCloseTask = nil
    }
}
