import Foundation
import MilkTeaDomain

struct DrinkCalendarDay: Identifiable, Equatable {
    let day: LocalDay
    let isInDisplayedMonth: Bool
    let isToday: Bool
    let isFuture: Bool
    let drinkCount: Int

    var id: LocalDay { day }
}

@MainActor
final class DrinkHistoryViewModel: ObservableObject {
    @Published private(set) var records: [DrinkRecord] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isMutating = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var displayedMonth: LocalDay
    @Published private(set) var selectedDay: LocalDay

    private let repository: any DrinkRecordRepository
    private let milkTeaID: () -> String?
    private let now: () -> Date
    private var calendar: Calendar

    init(
        repository: any DrinkRecordRepository,
        milkTeaID: @escaping () -> String?,
        calendar: Calendar = .current,
        now: @escaping () -> Date = Date.init
    ) {
        self.repository = repository
        self.milkTeaID = milkTeaID
        self.now = now
        var calendar = calendar
        calendar.firstWeekday = 2
        calendar.minimumDaysInFirstWeek = 4
        self.calendar = calendar

        let today = LocalDay(date: now(), calendar: calendar)
        displayedMonth = LocalDay(year: today.year, month: today.month, day: 1)
        selectedDay = today
    }

    var today: LocalDay {
        LocalDay(date: now(), calendar: calendar)
    }

    var displayedMonthTitle: String {
        "\(displayedMonth.year)年\(displayedMonth.month)月"
    }

    var selectedDayTitle: String {
        guard let date = selectedDay.date(in: calendar) else {
            return "\(selectedDay.month)月\(selectedDay.day)日"
        }
        let weekday = calendar.component(.weekday, from: date)
        let names = ["周日", "周一", "周二", "周三", "周四", "周五", "周六"]
        return "\(selectedDay.month)月\(selectedDay.day)日 \(names[weekday - 1])"
    }

    var selectedDaySummary: String {
        if selectedDay > today {
            return "这一天还没到"
        }
        let prefix = selectedDay == today ? "今天" : "当天"
        return "\(prefix)喝了 \(selectedDayRecords.count) 杯"
    }

    var selectedDayRecords: [DrinkRecord] {
        records
            .filter { $0.day == selectedDay }
            .sorted {
                if $0.createdAt == $1.createdAt {
                    return $0.id.uuidString > $1.id.uuidString
                }
                return $0.createdAt > $1.createdAt
            }
    }

    var weekCount: Int {
        guard let range = DrinkStatisticsCalculator.weekRange(
            containing: today,
            calendar: calendar
        ) else { return 0 }
        return DrinkStatisticsCalculator.count(records, in: range)
    }

    var monthCount: Int {
        guard let range = DrinkStatisticsCalculator.monthRange(
            containing: displayedMonth,
            calendar: calendar
        ) else { return 0 }
        return DrinkStatisticsCalculator.count(records, in: range)
    }

    var canAddSelectedDay: Bool {
        selectedDay <= today && !isLoading && !isMutating
    }

    var calendarDays: [DrinkCalendarDay] {
        guard let firstDate = displayedMonth.date(in: calendar),
              let dayRange = calendar.range(of: .day, in: .month, for: firstDate) else {
            return []
        }

        let weekday = calendar.component(.weekday, from: firstDate)
        let leadingDays = (weekday - calendar.firstWeekday + 7) % 7
        let occupiedSlots = leadingDays + dayRange.count
        let slotCount = occupiedSlots <= 35 ? 35 : 42
        guard let gridStart = calendar.date(byAdding: .day, value: -leadingDays, to: firstDate) else {
            return []
        }

        let today = today
        return (0..<slotCount).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: gridStart) else {
                return nil
            }
            let day = LocalDay(date: date, calendar: calendar)
            return DrinkCalendarDay(
                day: day,
                isInDisplayedMonth: day.year == displayedMonth.year && day.month == displayedMonth.month,
                isToday: day == today,
                isFuture: day > today,
                drinkCount: DrinkStatisticsCalculator.count(records, on: day)
            )
        }
    }

    func load() {
        isLoading = true
        defer { isLoading = false }
        do {
            records = try repository.fetchAll()
            errorMessage = nil
        } catch {
            errorMessage = "记录加载失败，请稍后重试。"
        }
    }

    func select(_ day: LocalDay) {
        selectedDay = day
        if day.year != displayedMonth.year || day.month != displayedMonth.month {
            displayedMonth = LocalDay(year: day.year, month: day.month, day: 1)
        }
    }

    func showPreviousMonth() {
        moveDisplayedMonth(by: -1)
    }

    func showNextMonth() {
        moveDisplayedMonth(by: 1)
    }

    func showToday() {
        let today = today
        displayedMonth = LocalDay(year: today.year, month: today.month, day: 1)
        selectedDay = today
    }

    @discardableResult
    func addDrink() -> Bool {
        guard canAddSelectedDay else { return false }
        isMutating = true
        defer { isMutating = false }

        let record = DrinkRecord(
            day: selectedDay,
            createdAt: now(),
            milkTeaID: milkTeaID(),
            source: .manual
        )
        do {
            try repository.add(record)
            records.append(record)
            errorMessage = nil
            return true
        } catch {
            errorMessage = "新增记录失败，请重试。"
            return false
        }
    }

    func delete(_ record: DrinkRecord) {
        guard !isMutating else { return }
        isMutating = true
        defer { isMutating = false }
        do {
            try repository.delete(id: record.id)
            records.removeAll { $0.id == record.id }
            errorMessage = nil
        } catch {
            errorMessage = "删除记录失败，请重试。"
        }
    }

    func dismissError() {
        errorMessage = nil
    }

    private func moveDisplayedMonth(by value: Int) {
        guard let date = displayedMonth.date(in: calendar),
              let movedDate = calendar.date(byAdding: .month, value: value, to: date) else {
            return
        }
        let month = LocalDay(date: movedDate, calendar: calendar)
        displayedMonth = LocalDay(year: month.year, month: month.month, day: 1)
        selectedDay = displayedMonth
    }
}
