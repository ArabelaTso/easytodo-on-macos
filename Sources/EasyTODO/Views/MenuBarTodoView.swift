import Foundation
import SwiftData
import SwiftUI

struct MenuBarTodoView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [
        SortDescriptor(\TodoTask.sortOrder),
        SortDescriptor(\TodoTask.createdAt)
    ]) private var tasks: [TodoTask]

    @State private var isQuickAddPresented = false
    @State private var taskPendingDeletion: TodoTask?

    private let calendar = Calendar.current
    private let dayRefreshTimer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    private var todayTasks: [TodoTask] {
        tasks.filter { task in
            task.isScheduled(on: .now, calendar: calendar)
        }
    }

    private var completedCount: Int {
        todayTasks.filter(\.isCompleted).count
    }

    private var orderedTasks: [TodoTask] {
        TaskListOrdering.ordered(todayTasks)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Today")
                    .font(.headline)

                Spacer()

                Text("\(completedCount) / \(todayTasks.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Button(action: showQuickAdd) {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .semibold))
                        .frame(width: 24, height: 24)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Add task")
                .popover(isPresented: $isQuickAddPresented, arrowEdge: .top) {
                    HeaderQuickAddPopover(
                        onSubmit: addTask,
                        onCancel: dismissQuickAdd
                    )
                }
            }

            Divider()

            if todayTasks.isEmpty {
                Text("No tasks yet")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ScrollView(.vertical) {
                    LazyVStack(alignment: .leading, spacing: 6) {
                        ForEach(orderedTasks) { task in
                            menuTaskRow(task)
                        }
                    }
                    .padding(.trailing, 2)
                }
                .frame(height: taskListHeight)
                .scrollIndicators(.automatic)
            }

            Divider()

            HStack(spacing: 8) {
                Button {
                    MenuBarManager.shared.closePopover()
                    WidgetWindowManager.shared.toggleWidget()
                } label: {
                    Label("Widget", systemImage: "rectangle.on.rectangle")
                }
                .buttonStyle(.bordered)

                Button {
                    MenuBarManager.shared.closePopover()
                    WindowManager.shared.showMainWindow()
                } label: {
                    Label("Full App", systemImage: "arrow.up.right.square")
                }
                .buttonStyle(.bordered)
            }
            .labelStyle(.titleAndIcon)
            .controlSize(.small)

        }
        .padding(14)
        .frame(width: 260)
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            WindowManager.shared.showMainWindow()
        }
        .onAppear(perform: runDailyTaskMaintenance)
        .onReceive(dayRefreshTimer) { _ in
            runDailyTaskMaintenance()
        }
        .confirmationDialog(
            "Delete this task?",
            isPresented: deleteConfirmationBinding,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive, action: deletePendingTask)
            Button("Cancel", role: .cancel) {
                taskPendingDeletion = nil
            }
        } message: {
            Text(confirmDeleteMessage)
        }
    }

    private var taskListHeight: CGFloat {
        min(CGFloat(orderedTasks.count) * 28, 220)
    }

    private var deleteConfirmationBinding: Binding<Bool> {
        Binding {
            taskPendingDeletion != nil
        } set: { isPresented in
            if !isPresented {
                taskPendingDeletion = nil
            }
        }
    }

    private var confirmDeleteMessage: String {
        guard let taskPendingDeletion else {
            return "This task will be removed."
        }

        let title = taskPendingDeletion.title.trimmingCharacters(in: .whitespacesAndNewlines)
        return title.isEmpty ? "This task will be removed." : "\"\(title)\" will be removed."
    }

    private func menuTaskRow(_ task: TodoTask) -> some View {
        HStack(spacing: 6) {
            Button {
                toggleCompletion(for: task)
            } label: {
                HStack {
                    Circle()
                        .fill(task.priority.color)
                        .frame(width: 8, height: 8)

                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(task.isCompleted ? Color.accentColor : Color.secondary)

                    Text(task.title.isEmpty ? "Untitled task" : task.title)
                        .lineLimit(1)

                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)

            Button {
                requestDelete(task)
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 22, height: 22)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Delete task")
        }
    }

    private func saveChanges() {
        do {
            try modelContext.save()
        } catch {
            assertionFailure("Unable to save menu bar task change: \(error)")
        }
    }

    private func toggleCompletion(for task: TodoTask) {
        let wasCompleted = task.isCompleted
        task.isCompleted.toggle()

        if !wasCompleted && task.isCompleted {
            TaskListOrdering.moveCompletedTaskToFront(task, in: todayTasks)
        } else if wasCompleted && !task.isCompleted {
            TaskListOrdering.moveReactivatedTaskToEnd(task, in: todayTasks)
        }

        saveChanges()

        if !wasCompleted && task.isCompleted {
            CompletionFeedbackPlayer.playTaskCompletedSound()
        }
    }

    private func requestDelete(_ task: TodoTask) {
        taskPendingDeletion = task
    }

    private func deletePendingTask() {
        guard let taskPendingDeletion else { return }

        delete(taskPendingDeletion)
        self.taskPendingDeletion = nil
    }

    private func delete(_ task: TodoTask) {
        modelContext.delete(task)
        saveChanges()
    }

    private func showQuickAdd() {
        isQuickAddPresented = true
    }

    private func dismissQuickAdd() {
        isQuickAddPresented = false
    }

    private func addTask(title: String) -> Bool {
        do {
            return try TaskCreation.addTask(title: title, in: modelContext, calendar: calendar) != nil
        } catch {
            assertionFailure("Unable to save menu bar task: \(error)")
            return false
        }
    }

    private func runDailyTaskMaintenance() {
        if TaskDayMaintenance.rolloverUnfinishedTasksToToday(tasks, calendar: calendar) {
            saveChanges()
        }
    }
}
