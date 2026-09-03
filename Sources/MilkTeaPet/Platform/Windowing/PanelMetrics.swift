import AppKit

enum PetMetrics {
    static let width: CGFloat = 112
    static let height: CGFloat = 140
}

enum PanelMetrics {
    static let reminderSize = NSSize(width: 268, height: 128)
    static let recordEffectSize = NSSize(width: 96, height: 96)
    static let recordEffectLifetime: TimeInterval = 1.65
    static let settingsSize = NSSize(width: 400, height: 300)
    static let screenMargin: CGFloat = 12
}
