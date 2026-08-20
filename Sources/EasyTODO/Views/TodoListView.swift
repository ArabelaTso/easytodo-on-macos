@preconcurrency import AppKit
import SwiftData
import SwiftUI

struct TodoListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Query(sort: [
        SortDescriptor(\TodoTask.sortOrder),
        SortDescriptor(\TodoTask.createdAt)
    ]) private var tasks: [TodoTask]

    @AppStorage(EasyTODOSettings.alwaysOnTop) private var alwaysOnTop = true
    @AppStorage(EasyTODOSettings.hiddenDockIcon) private var hiddenDockIcon = false
    @AppStorage(EasyTODOSettings.showMenuBar) private var showMenuBar = true
    @AppStorage(EasyTODOSettings.transparency) private var transparency = 0.80

    @State private var selectedDate = Date()
    @State private var isCalendarPresented = false
    @State private var isHeaderQuickAddPresented = false
    @State private var deletedTaskToRestore: DeletedTaskSnapshot?
    @State private var undoKeyMonitor: Any?
    @State private var fireworksTrigger = 0

    private let calendar = Calendar.current
    private let dayRefreshTimer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    private var completedCount: Int {
        displayedTasks.filter(\.isCompleted).count
    }

    private var orderedTasks: [TodoTask] {
        displayedTasks
    }

    private var displayedTasks: [TodoTask] {
        TaskListOrdering.ordered(tasksScheduled(on: selectedDate))
    }

    private var hasActiveAndCompletedTasks: Bool {
        displayedTasks.contains { !$0.isCompleted } && displayedTasks.contains { $0.isCompleted }
    }

    private var headerTitle: String {
        if calendar.isDateInToday(selectedDate) {
            return "Today's TODOs"
        }

        return selectedDate.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
    }

    var body: some View {
        ZStack {
            noteSurface

            VStack(spacing: 0) {
                header

                Divider()
                    .padding(.horizontal, 14)

                List {
                    if displayedTasks.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "calendar.badge.plus")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundStyle(.secondary)

                            Text("No tasks for \(shortDate(for: selectedDate))")
                                .font(.system(size: 14, weight: .semibold))

                            Text("Use the + button to plan this day.")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 36)
                        .listRowInsets(EdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 10))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }

                    ForEach(orderedTasks) { task in
                        VStack(spacing: 0) {
                            if shouldShowCompletedSeparator(before: task) {
                                completedSeparator
                            }

                            TaskRow(
                                task: task,
                                onUpdate: saveChanges,
                                onCompletionChanged: handleCompletionChange,
                                onMoveToDate: moveTask,
                                onRepeatRuleChanged: updateRepeatRule
                            ) {
                                delete(task)
                            }
                        }
                        .listRowInsets(EdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 10))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }
                    .onMove(perform: moveTasks)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)

            }
            CompletionFireworksView(trigger: fireworksTrigger)
        }
        .frame(minWidth: 280, idealWidth: 340, minHeight: 320, idealHeight: 480)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .contextMenu {
            Button {
                WindowManager.shared.closeMainWindow()
            } label: {
                Label("Close Window", systemImage: "xmark")
            }

            Button {
                WindowManager.shared.minimizeMainWindow()
            } label: {
                Label("Minimize Window", systemImage: "minus")
            }

            Button {
                WindowManager.shared.zoomMainWindow()
            } label: {
                Label("Zoom Window", systemImage: "arrow.up.left.and.arrow.down.right")
            }

            Button {
                WidgetWindowManager.shared.showWidget()
                WindowManager.shared.closeMainWindow()
            } label: {
                Label("Change to Widget", systemImage: "rectangle.on.rectangle")
            }

            Divider()

            Button {
                alwaysOnTop.toggle()
                WindowManager.shared.applyWindowSettings()
            } label: {
                Label("Always on Top", systemImage: alwaysOnTop ? "checkmark.circle.fill" : "circle")
            }

            Menu {
                transparencyMenuButton(title: "100%", value: 1.0)
                transparencyMenuButton(title: "80%", value: 0.80)
                transparencyMenuButton(title: "50%", value: 0.50)
            } label: {
                Label("Transparency: \(transparencyTitle)", systemImage: "slider.horizontal.3")
            }

            if deletedTaskToRestore != nil {
                Divider()

                Button {
                    undoLastDeletedTask()
                } label: {
                    Label("Undo Delete", systemImage: "arrow.uturn.backward")
                }
            }
        }
        .background(
            WindowAccessor { window in
                WindowManager.shared.configureMainWindow(window)
            }
        )
        .sheet(isPresented: $isCalendarPresented) {
            CalendarPlannerView(
                tasks: tasks,
                selectedDate: $selectedDate,
                onAddTask: { title, date in
                    _ = addTask(title: title, for: date)
                },
                onUpdate: saveChanges,
                onCompletionChanged: handleCompletionChange,
                onDelete: delete,
                onMoveTasks: { date, source, destination in
                    moveTasks(on: date, from: source, to: destination)
                }
            )
        }
        .onAppear {
            runDailyTaskMaintenance()
            installUndoDeleteKeyboardMonitor()
            WindowManager.shared.applyWindowSettings()
            WindowManager.shared.applyActivationPolicy()
        }
        .onDisappear {
            removeUndoDeleteKeyboardMonitor()
        }
        .onReceive(NotificationCenter.default.publisher(for: .easyTODOFocusNewTask)) { _ in
            WindowManager.shared.showMainWindow()
            focusNewTaskInput()
        }
        .onReceive(NotificationCenter.default.publisher(for: .easyTODOUndoDeleteTask)) { _ in
            undoLastDeletedTask()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.willResignActiveNotification)) { _ in
            saveChanges()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification)) { _ in
            saveChanges()
        }
        .onReceive(dayRefreshTimer) { _ in
            runDailyTaskMaintenance()
        }
        .onChange(of: alwaysOnTop) { _, _ in
            WindowManager.shared.applyWindowSettings()
        }
        .onChange(of: transparency) { _, _ in
            WindowManager.shared.applyWindowSettings()
        }
        .onChange(of: hiddenDockIcon) { _, _ in
            WindowManager.shared.applyActivationPolicy()
        }
        .onChange(of: showMenuBar) { _, _ in
            WindowManager.shared.applyActivationPolicy()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                runDailyTaskMaintenance()
            } else {
                saveChanges()
            }
        }
    }

    private var noteSurface: some View {
        ZStack {
            Color(nsColor: .windowBackgroundColor)

            BlurBackground()
                .opacity(0.10)

            LinearGradient(
                colors: [
                    Color(red: 0.98, green: 0.78, blue: 0.38).opacity(0.16),
                    Color(red: 0.95, green: 0.89, blue: 0.70).opacity(0.08),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .ignoresSafeArea()
        .contentShape(Rectangle())
        .onTapGesture(count: 2, perform: switchToWidget)
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Button {
                isCalendarPresented = true
            } label: {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(headerTitle)
                            .font(.system(size: 17, weight: .semibold, design: .default))

                        Image(systemName: "calendar")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }

                    Text("\(completedCount) / \(displayedTasks.count) complete - Open calendar")
                        .font(.system(size: 12, weight: .medium, design: .default))
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Open calendar")

            Spacer()

            Button(action: showHeaderQuickAdd) {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Add task")
            .popover(isPresented: $isHeaderQuickAddPresented, arrowEdge: .top) {
                HeaderQuickAddPopover(
                    onSubmit: { title in
                        addTask(title: title, for: selectedDate) != nil
                    },
                    onCancel: dismissHeaderQuickAdd
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }

    private func showHeaderQuickAdd() {
        WindowManager.shared.showMainWindow()
        isHeaderQuickAddPresented = true
    }

    private func dismissHeaderQuickAdd() {
        isHeaderQuickAddPresented = false
    }

    private func switchToWidget() {
        WidgetWindowManager.shared.showWidget()
        WindowManager.shared.closeMainWindow()
    }

    private var transparencyTitle: String {
        "\(Int((transparency * 100).rounded()))%"
    }

    private func transparencyMenuButton(title: String, value: Double) -> some View {
        Button {
            transparency = value
            WindowManager.shared.applyWindowSettings()
        } label: {
            Label(title, systemImage: isSelectedTransparency(value) ? "checkmark.circle.fill" : "circle")
        }
    }

    private func isSelectedTransparency(_ value: Double) -> Bool {
        abs(transparency - value) < 0.001
    }

    private var completedSeparator: some View {
        Rectangle()
            .fill(.secondary.opacity(0.24))
            .frame(height: 1)
            .padding(.vertical, 9)
            .padding(.leading, 28)
    }

    private func shouldShowCompletedSeparator(before task: TodoTask) -> Bool {
        guard hasActiveAndCompletedTasks, task.isCompleted else { return false }
        return orderedTasks.first(where: \.isCompleted) === task
    }

    private func focusNewTaskInput() {
        showHeaderQuickAdd()
    }

    private func delete(_ task: TodoTask) {
        dismissHeaderQuickAdd()
        deletedTaskToRestore = DeletedTaskSnapshot(task: task, calendar: calendar)
        modelContext.delete(task)
        saveChanges()
    }

    private func undoLastDeletedTask() {
        guard let deletedTaskToRestore else { return }

        let restoredTask = deletedTaskToRestore.task()
        modelContext.insert(restoredTask)
        selectedDate = deletedTaskToRestore.scheduledDate
        self.deletedTaskToRestore = nil
        saveChanges()
    }

    private func installUndoDeleteKeyboardMonitor() {
        guard undoKeyMonitor == nil else { return }

        undoKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if isHeaderQuickAddPresented, event.keyCode == 53 {
                dismissHeaderQuickAdd()
                return nil
            }

            guard isUndoDeleteShortcut(event), deletedTaskToRestore != nil else {
                return event
            }

            undoLastDeletedTask()
            return nil
        }
    }

    private func removeUndoDeleteKeyboardMonitor() {
        guard let undoKeyMonitor else { return }

        NSEvent.removeMonitor(undoKeyMonitor)
        self.undoKeyMonitor = nil
    }

    private func isUndoDeleteShortcut(_ event: NSEvent) -> Bool {
        guard event.charactersIgnoringModifiers?.lowercased() == "z" else {
            return false
        }

        return event.modifierFlags.intersection(.deviceIndependentFlagsMask).contains(.control)
    }

    private func moveTasks(from source: IndexSet, to destination: Int) {
        moveTasks(on: selectedDate, from: source, to: destination)
    }

    private func moveTasks(on date: Date, from source: IndexSet, to destination: Int) {
        TaskListOrdering.moveTasks(from: source, to: destination, in: tasksScheduled(on: date))
        saveChanges()
    }

    private func moveTask(_ task: TodoTask, to date: Date) {
        TaskScheduling.move(task, to: date, among: tasks, calendar: calendar)
        saveChanges()
    }

    private func updateRepeatRule(_ task: TodoTask, to repeatRule: TaskRepeatRule) {
        do {
            try TaskRepeatScheduler.setRepeatRule(
                repeatRule,
                for: task,
                tasks: tasks,
                in: modelContext,
                calendar: calendar
            )
        } catch {
            assertionFailure("Unable to update task repeat rule: \(error)")
        }
    }

    private func handleCompletionChange(task: TodoTask, oldValue: Bool, newValue: Bool) {
        let taskDate = task.scheduledDay(in: calendar)

        if !oldValue && newValue {
            TaskListOrdering.moveCompletedTaskToFront(task, in: tasksScheduled(on: taskDate))
        } else if oldValue && !newValue {
            TaskListOrdering.moveReactivatedTaskToEnd(task, in: tasksScheduled(on: taskDate))
        }

        saveChanges()

        guard !oldValue && newValue else { return }

        CompletionFeedbackPlayer.playTaskCompletedSound()
        fireworksTrigger += 1
    }

    private func addTask(title: String, for date: Date) -> TodoTask? {
        do {
            let task = try TaskCreation.addTask(title: title, scheduledDate: date, in: modelContext, calendar: calendar)

            return task
        } catch {
            assertionFailure("Unable to save task: \(error)")
            return nil
        }
    }

    private func tasksScheduled(on date: Date) -> [TodoTask] {
        tasks.filter { task in
            task.isScheduled(on: date, calendar: calendar)
        }
    }

    private func runDailyTaskMaintenance() {
        let today = calendar.startOfDay(for: .now)
        var didChange = false

        for task in tasks where task.scheduledDate == nil {
            task.scheduledDate = today
            didChange = true
        }

        didChange = TaskDayMaintenance.rolloverUnfinishedTasksToToday(
            tasks,
            today: today,
            calendar: calendar
        ) || didChange

        if selectedDate < today {
            selectedDate = today
        }

        if didChange {
            saveChanges()
        }
    }

    private func shortDate(for date: Date) -> String {
        if calendar.isDateInToday(date) {
            return "Today"
        }

        return date.formatted(.dateTime.month(.abbreviated).day())
    }

    private func saveChanges() {
        do {
            try modelContext.save()
        } catch {
            assertionFailure("Unable to save tasks: \(error)")
        }
    }
}

private struct DeletedTaskSnapshot {
    let title: String
    let isCompleted: Bool
    let sortOrder: Int
    let createdAt: Date
    let scheduledDate: Date
    let priority: TaskPriority
    let repeatRule: TaskRepeatRule
    let recurrenceGroupID: String?

    init(task: TodoTask, calendar: Calendar) {
        title = task.title
        isCompleted = task.isCompleted
        sortOrder = task.sortOrder
        createdAt = task.createdAt
        scheduledDate = task.scheduledDay(in: calendar)
        priority = task.priority
        repeatRule = task.repeatRule
        recurrenceGroupID = task.recurrenceGroupID
    }

    func task() -> TodoTask {
        TodoTask(
            title: title,
            isCompleted: isCompleted,
            sortOrder: sortOrder,
            createdAt: createdAt,
            scheduledDate: scheduledDate,
            priority: priority,
            repeatRule: repeatRule,
            recurrenceGroupID: recurrenceGroupID
        )
    }
}
