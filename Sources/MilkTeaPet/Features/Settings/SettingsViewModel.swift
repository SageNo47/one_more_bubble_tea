import Combine
import Foundation
import MilkTeaDomain

enum SaveFeedback: Equatable {
    case idle
    case success(String)
    case error(String)
}

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var hourText = "15" {
        didSet { inputDidChange() }
    }
    @Published var minuteText = "00" {
        didSet { inputDidChange() }
    }
    @Published var secondText = "00" {
        didSet { inputDidChange() }
    }
    @Published var message = "" {
        didSet { inputDidChange() }
    }
    @Published private(set) var feedback: SaveFeedback = .idle

    private let settingsRepository: any SettingsRepository
    private let selectedMilkTeaID: MilkTea.ID
    private let onSettingsSaved: () -> Void
    private var isApplyingStoredValues = false

    init(
        settingsRepository: any SettingsRepository,
        selectedMilkTeaID: MilkTea.ID,
        onSettingsSaved: @escaping () -> Void
    ) {
        self.settingsRepository = settingsRepository
        self.selectedMilkTeaID = selectedMilkTeaID
        self.onSettingsSaved = onSettingsSaved
        reload()
    }

    func reload() {
        let settings = settingsRepository.load()
        isApplyingStoredValues = true
        hourText = String(format: "%02d", settings.hour)
        minuteText = String(format: "%02d", settings.minute)
        secondText = String(format: "%02d", settings.second)
        message = settings.message
        feedback = .idle
        isApplyingStoredValues = false
    }

    func save() {
        guard let hour = Int(hourText), (0...23).contains(hour),
              let minute = Int(minuteText), (0...59).contains(minute),
              let second = Int(secondText), (0...59).contains(second) else {
            feedback = .error("请输入有效时间")
            return
        }

        let trimmedMessage = message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMessage.isEmpty else {
            feedback = .error("提醒词不能为空")
            return
        }

        isApplyingStoredValues = true
        hourText = String(format: "%02d", hour)
        minuteText = String(format: "%02d", minute)
        secondText = String(format: "%02d", second)
        message = trimmedMessage
        isApplyingStoredValues = false

        settingsRepository.save(
            ReminderSettings(
                hour: hour,
                minute: minute,
                second: second,
                message: trimmedMessage,
                selectedMilkTeaID: selectedMilkTeaID
            )
        )
        onSettingsSaved()
        feedback = .success("已保存")
    }

    func filterTimeInput(_ value: String) -> String {
        String(value.filter(\.isNumber).prefix(2))
    }

    private func inputDidChange() {
        if !isApplyingStoredValues, feedback != .idle {
            feedback = .idle
        }
    }
}
