import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    let onClose: () -> Void

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
        .frame(
            width: PanelMetrics.settingsSize.width,
            height: PanelMetrics.settingsSize.height
        )
    }

    private var header: some View {
        ZStack {
            Text("设置")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(AppTheme.textPrimary)

            HStack {
                Spacer()
                Button(action: onClose) {
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
                TimeTextField(
                    text: $viewModel.hourText,
                    accessibilityLabel: "小时",
                    filter: viewModel.filterTimeInput
                )
                Text(":")
                    .font(.system(size: 18, weight: .semibold, design: .monospaced))
                    .foregroundColor(AppTheme.textSecondary)
                TimeTextField(
                    text: $viewModel.minuteText,
                    accessibilityLabel: "分钟",
                    filter: viewModel.filterTimeInput
                )
                Text(":")
                    .font(.system(size: 18, weight: .semibold, design: .monospaced))
                    .foregroundColor(AppTheme.textSecondary)
                TimeTextField(
                    text: $viewModel.secondText,
                    accessibilityLabel: "秒钟",
                    filter: viewModel.filterTimeInput
                )
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var messageSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("提醒词", systemImage: "bubble.left.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(AppTheme.textPrimary)
                .frame(height: 18)

            TextField("例如：今天要不要来一杯奶茶呀？", text: $viewModel.message)
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
        HStack(alignment: .bottom, spacing: 12) {
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
        switch viewModel.feedback {
        case .idle:
            return nil
        case let .success(message):
            return (message, "checkmark.circle.fill", AppTheme.success)
        case let .error(message):
            return (message, "exclamationmark.circle.fill", AppTheme.danger)
        }
    }

    private func save() {
        withAnimation(.easeOut(duration: 0.16)) {
            viewModel.save()
        }
    }
}

private struct TimeTextField: View {
    @Binding var text: String
    let accessibilityLabel: String
    let filter: (String) -> String

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
                let filtered = filter(newValue)
                if filtered != newValue {
                    text = filtered
                }
            }
    }
}
