import SwiftUI

struct ReminderBubble: View {
    let text: String
    let edge: WindowPlacer.Edge
    let onAccept: () throws -> Void
    let onDecline: () -> Void

    @State private var isAccepting = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            if edge == .below {
                tail.rotationEffect(.degrees(180))
            }

            bubbleBody

            if edge == .above {
                tail
            }
        }
        .frame(
            width: PanelMetrics.reminderSize.width,
            height: PanelMetrics.reminderSize.height,
            alignment: edge == .above ? .bottom : .top
        )
    }

    private var bubbleBody: some View {
        VStack(spacing: 14) {
            Text(errorMessage ?? text)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(errorMessage == nil ? AppTheme.textPrimary : AppTheme.danger)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .lineLimit(2)
                .frame(maxWidth: .infinity)

            HStack(spacing: 8) {
                BubbleButton(
                    title: isAccepting ? "记录中…" : "来一杯",
                    isPrimary: true,
                    isEnabled: !isAccepting,
                    action: accept
                )
                BubbleButton(title: "今天不喝", isPrimary: false, action: onDecline)
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
                Triangle().stroke(AppTheme.windowBorder, lineWidth: 2)
            )
    }

    private func accept() {
        guard !isAccepting else { return }
        isAccepting = true
        do {
            try onAccept()
        } catch {
            errorMessage = "记录失败，请重试"
            isAccepting = false
        }
    }
}

private struct BubbleButton: View {
    let title: String
    let isPrimary: Bool
    var isEnabled = true
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
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.62)
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}
