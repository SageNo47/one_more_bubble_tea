import MilkTeaDomain
import SwiftUI

struct DrinkHistoryView: View {
    @ObservedObject var viewModel: DrinkHistoryViewModel
    @ObservedObject var milkTeaStore: MilkTeaStore

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
                Rectangle()
                    .fill(AppTheme.border.opacity(0.7))
                    .frame(height: 1)
                GeometryReader { geometry in
                    HStack(spacing: 0) {
                        calendarPane
                            .frame(width: calendarWidth(for: geometry.size.width))
                        Rectangle()
                            .fill(AppTheme.border.opacity(0.7))
                            .frame(width: 1)
                        detailPane
                    }
                }
            }
            .padding(2)
        }
        .frame(
            minWidth: PanelMetrics.drinkHistoryMinimumSize.width,
            minHeight: PanelMetrics.drinkHistoryMinimumSize.height
        )
        .onAppear(perform: viewModel.load)
    }

    private func calendarWidth(for totalWidth: CGFloat) -> CGFloat {
        min(
            PanelMetrics.drinkHistoryCalendarWidth,
            max(440, totalWidth * 2 / 3)
        )
    }

    private var header: some View {
        ZStack {
            Text("喝了么")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
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
            .padding(.horizontal, 14)
        }
        .frame(height: 48)
    }

    private var calendarPane: some View {
        VStack(spacing: 0) {
            monthToolbar
                .padding(.horizontal, 18)
                .frame(height: 62)

            Rectangle()
                .fill(AppTheme.border.opacity(0.55))
                .frame(height: 1)

            statisticsBar
                .frame(height: 50)

            Rectangle()
                .fill(AppTheme.border.opacity(0.55))
                .frame(height: 1)

            weekdayHeader
                .frame(height: 34)

            calendarGrid
        }
    }

    private var monthToolbar: some View {
        HStack(spacing: 12) {
            SquareIconButton(systemName: "chevron.left", help: "上个月") {
                withAnimation(.easeOut(duration: 0.16)) {
                    viewModel.showPreviousMonth()
                }
            }

            Text(viewModel.displayedMonthTitle)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.accent)
                .frame(minWidth: 150)

            SquareIconButton(systemName: "chevron.right", help: "下个月") {
                withAnimation(.easeOut(duration: 0.16)) {
                    viewModel.showNextMonth()
                }
            }

            Spacer(minLength: 8)

            Button("今天") {
                withAnimation(.easeOut(duration: 0.16)) {
                    viewModel.showToday()
                }
            }
            .buttonStyle(.plain)
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(AppTheme.textPrimary)
            .frame(width: 68, height: 34)
            .background(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(AppTheme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .stroke(AppTheme.border, lineWidth: 1)
            )
        }
    }

    private var statisticsBar: some View {
        HStack(spacing: 18) {
            statistic(title: "本周", count: viewModel.weekCount)
            Rectangle()
                .fill(AppTheme.border)
                .frame(width: 1, height: 18)
            statistic(title: "本月", count: viewModel.monthCount)
        }
        .frame(maxWidth: .infinity)
    }

    private func statistic(title: String, count: Int) -> some View {
        HStack(spacing: 6) {
            MilkTeaArtwork(milkTea: milkTeaStore.selectedMilkTea)
                .frame(width: 14, height: 20)
            Text(title)
                .font(.system(size: 13, weight: .medium))
            Text("\(count)")
                .font(.system(size: 20, weight: .bold, design: .rounded))
            Text("杯")
                .font(.system(size: 13, weight: .medium))
        }
        .foregroundColor(AppTheme.textPrimary)
    }

    private var weekdayHeader: some View {
        HStack(spacing: 0) {
            ForEach(["一", "二", "三", "四", "五", "六", "日"], id: \.self) { title in
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var calendarGrid: some View {
        GeometryReader { geometry in
            let days = viewModel.calendarDays
            let rowCount = max(1, days.count / 7)
            let cellHeight = geometry.size.height / CGFloat(rowCount)

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7),
                spacing: 0
            ) {
                ForEach(days) { day in
                    CalendarDayCell(
                        item: day,
                        isSelected: day.day == viewModel.selectedDay,
                        milkTea: milkTeaStore.selectedMilkTea,
                        height: cellHeight
                    ) {
                        withAnimation(.easeOut(duration: 0.14)) {
                            viewModel.select(day.day)
                        }
                    }
                }
            }
        }
    }

    private var detailPane: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 7) {
                    Text(viewModel.selectedDayTitle)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(AppTheme.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.88)
                    Text(viewModel.selectedDaySummary)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppTheme.textPrimary)
                }

                Spacer(minLength: 4)

                Button(action: { _ = viewModel.addDrink() }) {
                    Text("+ 一杯")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(width: 84, height: 40)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(viewModel.canAddSelectedDay ? AppTheme.recordEffect : AppTheme.border)
                        )
                }
                .buttonStyle(.plain)
                .disabled(!viewModel.canAddSelectedDay)
                .help(viewModel.canAddSelectedDay ? "为所选日期增加一杯" : "不能为未来日期增加记录")
            }

            if let errorMessage = viewModel.errorMessage {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.circle.fill")
                    Text(errorMessage)
                        .lineLimit(2)
                    Spacer(minLength: 0)
                    Button(action: viewModel.dismissError) {
                        Image(systemName: "xmark")
                    }
                    .buttonStyle(.plain)
                }
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(AppTheme.danger)
                .padding(.top, 14)
            }

            Rectangle()
                .fill(AppTheme.border.opacity(0.6))
                .frame(height: 1)
                .padding(.vertical, 18)

            if viewModel.isLoading {
                ProgressView()
                    .controlSize(.small)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.selectedDayRecords.isEmpty {
                emptyDetail
            } else {
                recordList
            }
        }
        .padding(20)
    }

    private var emptyDetail: some View {
        VStack(spacing: 10) {
            MilkTeaArtwork(milkTea: milkTeaStore.selectedMilkTea)
                .opacity(0.36)
                .frame(width: 34, height: 46)
            Text(viewModel.selectedDay > viewModel.today ? "未来再来记录吧" : "当天还没有记录")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var recordList: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(viewModel.selectedDayRecords) { record in
                    DrinkRecordRow(
                        record: record,
                        milkTea: milkTeaStore.selectedMilkTea
                    ) {
                        withAnimation(.easeOut(duration: 0.14)) {
                            viewModel.delete(record)
                        }
                    }
                }
            }
        }
    }
}

private struct SquareIconButton: View {
    let systemName: String
    let help: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(AppTheme.accent)
                .frame(width: 36, height: 36)
                .background(
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(AppTheme.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .stroke(AppTheme.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .help(help)
    }
}

private struct CalendarDayCell: View {
    let item: DrinkCalendarDay
    let isSelected: Bool
    let milkTea: MilkTea
    let height: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Text("\(item.day.day)")
                    .font(.system(size: 15, weight: item.isToday ? .semibold : .regular, design: .rounded))
                    .foregroundColor(AppTheme.textPrimary)

                if item.drinkCount > 0 {
                    HStack(spacing: 2) {
                        MilkTeaArtwork(milkTea: milkTea)
                            .frame(width: 10, height: 14)
                        Text("\(item.drinkCount)")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(AppTheme.accent)
                    }
                    .padding(.horizontal, 6)
                    .frame(height: 20)
                    .background(
                        Capsule().fill(AppTheme.surfaceMuted)
                    )
                } else {
                    Color.clear.frame(height: 20)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isSelected ? AppTheme.surface : Color.clear)
                    .padding(4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(isSelected ? AppTheme.accent : Color.clear, lineWidth: 1.5)
                    .padding(4)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .opacity(item.isInDisplayedMonth ? (item.isFuture ? 0.42 : 1) : 0.28)
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(AppTheme.border.opacity(0.38))
                .frame(width: 0.5)
        }
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(AppTheme.border.opacity(0.38))
                .frame(height: 0.5)
        }
        .accessibilityLabel("\(item.day.month)月\(item.day.day)日，\(item.drinkCount)杯")
    }
}

private struct DrinkRecordRow: View {
    let record: DrinkRecord
    let milkTea: MilkTea
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            MilkTeaArtwork(milkTea: milkTea)
                .frame(width: 22, height: 30)

            Text(timeText)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(AppTheme.textPrimary)

            Spacer(minLength: 8)

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppTheme.accent)
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(AppTheme.windowBackground))
                    .overlay(Circle().stroke(AppTheme.border, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .help("删除这杯记录")
            .accessibilityLabel("删除 \(timeText) 的记录")
        }
        .padding(.horizontal, 12)
        .frame(height: 58)
        .background(
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .fill(AppTheme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .stroke(AppTheme.border.opacity(0.8), lineWidth: 1)
        )
    }

    private var timeText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: record.createdAt)
    }
}
