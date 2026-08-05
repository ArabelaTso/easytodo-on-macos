import SwiftData
import SwiftUI

private enum CalendarPerspective: String, CaseIterable, Identifiable {
    case day = "Day"
    case month = "Month"
    case year = "Year"

    var id: String { rawValue }
}

struct CalendarPlannerView: View {
    @Environment(\.dismiss) private var dismiss

    let tasks: [TodoTask]
    @Binding var selectedDate: Date
    var onAddTask: (_ title: String, _ date: Date) -> Void
    var onUpdate: () -> Void
    var onCompletionChanged: (_ task: TodoTask, _ oldValue: Bool, _ newValue: Bool) -> Void
    var onDelete: (_ task: TodoTask) -> Void
    var onMoveTasks: (_ date: Date, _ source: IndexSet, _ destination: Int) -> Void

    @State private var perspective: CalendarPerspective = .month
    @State private var visibleMonth = Date()
    @State private var newTaskTitle = ""
    @FocusState private var isAddingTaskFocused: Bool

    private let calendar = Calendar.current
    private let gridColumns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)
    private let monthColumns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)

    var body: some View {
        VStack(spacing: 0) {
            header

            Divider()

            Picker("Calendar view", selection: $perspective) {
                ForEach(CalendarPerspective.allCases) { perspective in
                    Text(perspective.rawValue).tag(perspective)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding(.horizontal, 18)
            .padding(.vertical, 12)

            Divider()

            content
        }
        .frame(width: 560)
        .frame(minHeight: 620)
        .onAppear {
            selectDate(selectedDate)
        }
        .onChange(of: selectedDate) { _, newDate in
            visibleMonth = monthStart(for: newDate)
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Calendar")
                    .font(.system(size: 22, weight: .semibold))

                Text(headerSubtitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button("Today") {
                selectDate(.now, perspective: .day)
            }
            .controlSize(.small)

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .accessibilityLabel("Close calendar")
        }
        .padding(.horizontal, 18)
        .padding(.top, 18)
        .padding(.bottom, 14)
    }

    @ViewBuilder
    private var content: some View {
        switch perspective {
        case .day:
            dayView
        case .month:
            monthView
        case .year:
            yearView
        }
    }

    private var dayView: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Button {
                    moveSelectedDay(by: -1)
                } label: {
                    Image(systemName: "chevron.left")
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Previous day")

                DatePicker(
                    "Selected day",
                    selection: selectedDateBinding,
                    displayedComponents: [.date]
                )
                .labelsHidden()

                Button {
                    moveSelectedDay(by: 1)
                } label: {
                    Image(systemName: "chevron.right")
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Next day")

                Spacer()

                Text(dayTitle(for: selectedDate))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)

            Divider()

            if dayTasks.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundStyle(.secondary)

                    Text("No tasks for this day")
                        .font(.system(size: 15, weight: .semibold))

                    Text("Add one below to plan ahead.")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(24)
            } else {
                List {
                    ForEach(dayTasks) { task in
                        TaskRow(
                            task: task,
                            onUpdate: onUpdate,
                            onCompletionChanged: onCompletionChanged
                        ) {
                            onDelete(task)
                        }
                        .listRowInsets(EdgeInsets(top: 0, leading: 14, bottom: 0, trailing: 12))
                        .listRowSeparator(.hidden)
                    }
                    .onMove { source, destination in
                        onMoveTasks(selectedDate, source, destination)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }

            Divider()

            AddTaskView(
                title: $newTaskTitle,
                focus: $isAddingTaskFocused,
                placeholder: "Add Task for \(shortDate(for: selectedDate))",
                onSubmit: addTaskForSelectedDate
            )
        }
    }

    private var monthView: some View {
        ScrollView {
            VStack(spacing: 14) {
                HStack {
                    Button {
                        moveVisibleMonth(by: -1)
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    .buttonStyle(.borderless)
                    .accessibilityLabel("Previous month")

                    Spacer()

                    Text(monthTitle(for: visibleMonth))
                        .font(.system(size: 18, weight: .semibold))

                    Spacer()

                    Button {
                        moveVisibleMonth(by: 1)
                    } label: {
                        Image(systemName: "chevron.right")
                    }
                    .buttonStyle(.borderless)
                    .accessibilityLabel("Next month")
                }

                LazyVGrid(columns: gridColumns, spacing: 8) {
                    ForEach(weekdaySymbols, id: \.self) { symbol in
                        Text(symbol)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                    }

                    ForEach(0..<leadingBlankDays, id: \.self) { _ in
                        Color.clear
                            .frame(height: 82)
                    }

                    ForEach(monthDates, id: \.self) { date in
                        monthDayCell(for: date)
                    }
                }
            }
            .padding(18)
        }
    }

    private var yearView: some View {
        ScrollView {
            VStack(spacing: 14) {
                HStack {
                    Button {
                        moveVisibleYear(by: -1)
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    .buttonStyle(.borderless)
                    .accessibilityLabel("Previous year")

                    Spacer()

                    Text(yearTitle(for: visibleMonth))
                        .font(.system(size: 18, weight: .semibold))

                    Spacer()

                    Button {
                        moveVisibleYear(by: 1)
                    } label: {
                        Image(systemName: "chevron.right")
                    }
                    .buttonStyle(.borderless)
                    .accessibilityLabel("Next year")
                }

                LazyVGrid(columns: monthColumns, spacing: 10) {
                    ForEach(monthsInVisibleYear, id: \.self) { month in
                        yearMonthCell(for: month)
                    }
                }
            }
            .padding(18)
        }
    }

    private var headerSubtitle: String {
        switch perspective {
        case .day:
            "Day view - \(dayTitle(for: selectedDate))"
        case .month:
            "Month view - \(monthTitle(for: visibleMonth))"
        case .year:
            "Year view - \(yearTitle(for: visibleMonth))"
        }
    }

    private var selectedDateBinding: Binding<Date> {
        Binding {
            selectedDate
        } set: { newDate in
            selectDate(newDate)
        }
    }

    private var dayTasks: [TodoTask] {
        tasks(on: selectedDate)
    }

    private var weekdaySymbols: [String] {
        let symbols = calendar.shortStandaloneWeekdaySymbols
        let firstWeekdayIndex = calendar.firstWeekday - 1
        return Array(symbols[firstWeekdayIndex...]) + Array(symbols[..<firstWeekdayIndex])
    }

    private var leadingBlankDays: Int {
        guard let firstDay = monthDates.first else { return 0 }
        return (calendar.component(.weekday, from: firstDay) - calendar.firstWeekday + 7) % 7
    }

    private var monthDates: [Date] {
        let start = monthStart(for: visibleMonth)
        guard let range = calendar.range(of: .day, in: .month, for: start) else {
            return []
        }

        return range.compactMap { day -> Date? in
            calendar.date(bySetting: .day, value: day, of: start)
        }
    }

    private var monthsInVisibleYear: [Date] {
        let start = yearStart(for: visibleMonth)
        return (0..<12).compactMap { offset in
            calendar.date(byAdding: .month, value: offset, to: start)
        }
    }

    private func monthDayCell(for date: Date) -> some View {
        let tasks = tasks(on: date)
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
        let isToday = calendar.isDateInToday(date)

        return Button {
            selectDate(date, perspective: .day)
        } label: {
            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .firstTextBaseline) {
                    Text("\(calendar.component(.day, from: date))")
                        .font(.system(size: 13, weight: isToday ? .bold : .semibold))
                        .foregroundStyle(isToday ? Color.accentColor : Color.primary)

                    Spacer()

                    if !tasks.isEmpty {
                        Text("\(tasks.filter(\.isCompleted).count)/\(tasks.count)")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                }

                if tasks.isEmpty {
                    Text("No tasks")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                } else {
                    ForEach(tasks.prefix(2)) { task in
                        HStack(spacing: 4) {
                            Circle()
                                .fill(task.priority.color)
                                .frame(width: 5, height: 5)

                            Text(task.title.isEmpty ? "Untitled" : task.title)
                                .font(.system(size: 9, weight: .medium))
                                .foregroundStyle(task.isCompleted ? .secondary : .primary)
                                .strikethrough(task.isCompleted, color: .secondary)
                                .lineLimit(1)
                        }
                    }

                    if tasks.count > 2 {
                        Text("+\(tasks.count - 2) more")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(8)
            .frame(maxWidth: .infinity, minHeight: 82, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isSelected ? Color.accentColor.opacity(0.14) : Color.primary.opacity(0.035))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(isSelected ? Color.accentColor.opacity(0.7) : Color.primary.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func yearMonthCell(for month: Date) -> some View {
        let tasks = tasks(inMonth: month)
        let completed = tasks.filter(\.isCompleted).count
        let isCurrentMonth = calendar.isDate(month, equalTo: .now, toGranularity: .month)

        return Button {
            visibleMonth = monthStart(for: month)
            selectedDate = monthStart(for: month)
            perspective = .month
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(month.formatted(.dateTime.month(.abbreviated)))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(isCurrentMonth ? Color.accentColor : Color.primary)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.tertiary)
                }

                Text(tasks.isEmpty ? "No tasks" : "\(completed) / \(tasks.count) complete")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)

                ProgressView(value: tasks.isEmpty ? 0 : Double(completed), total: Double(max(tasks.count, 1)))
                    .controlSize(.small)
            }
            .padding(12)
            .frame(maxWidth: .infinity, minHeight: 98, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isCurrentMonth ? Color.accentColor.opacity(0.12) : Color.primary.opacity(0.035))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isCurrentMonth ? Color.accentColor.opacity(0.6) : Color.primary.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func addTaskForSelectedDate() {
        let trimmedTitle = newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            isAddingTaskFocused = true
            return
        }

        onAddTask(trimmedTitle, selectedDate)
        newTaskTitle = ""
        isAddingTaskFocused = true
    }

    private func tasks(on date: Date) -> [TodoTask] {
        sortedTasks(tasks.filter { task in
            task.isScheduled(on: date, calendar: calendar)
        })
    }

    private func tasks(inMonth month: Date) -> [TodoTask] {
        let start = monthStart(for: month)
        guard let interval = calendar.dateInterval(of: .month, for: start) else {
            return []
        }

        return sortedTasks(tasks.filter { task in
            interval.contains(task.scheduledDay(in: calendar))
        })
    }

    private func sortedTasks(_ tasks: [TodoTask]) -> [TodoTask] {
        TaskListOrdering.ordered(tasks)
    }

    private func selectDate(_ date: Date, perspective: CalendarPerspective? = nil) {
        selectedDate = calendar.startOfDay(for: date)
        visibleMonth = monthStart(for: date)

        if let perspective {
            self.perspective = perspective
        }
    }

    private func moveSelectedDay(by value: Int) {
        guard let date = calendar.date(byAdding: .day, value: value, to: selectedDate) else {
            return
        }

        selectDate(date)
    }

    private func moveVisibleMonth(by value: Int) {
        guard let date = calendar.date(byAdding: .month, value: value, to: visibleMonth) else {
            return
        }

        visibleMonth = monthStart(for: date)
    }

    private func moveVisibleYear(by value: Int) {
        guard let date = calendar.date(byAdding: .year, value: value, to: visibleMonth) else {
            return
        }

        visibleMonth = monthStart(for: date)
    }

    private func monthStart(for date: Date) -> Date {
        calendar.dateInterval(of: .month, for: date)?.start ?? calendar.startOfDay(for: date)
    }

    private func yearStart(for date: Date) -> Date {
        calendar.dateInterval(of: .year, for: date)?.start ?? calendar.startOfDay(for: date)
    }

    private func dayTitle(for date: Date) -> String {
        if calendar.isDateInToday(date) {
            return "Today"
        }

        return date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day().year())
    }

    private func monthTitle(for date: Date) -> String {
        date.formatted(.dateTime.month(.wide).year())
    }

    private func yearTitle(for date: Date) -> String {
        date.formatted(.dateTime.year())
    }

    private func shortDate(for date: Date) -> String {
        if calendar.isDateInToday(date) {
            return "Today"
        }

        return date.formatted(.dateTime.month(.abbreviated).day())
    }
}
