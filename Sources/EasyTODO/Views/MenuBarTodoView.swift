import Foundation
import SwiftData
import SwiftUI

struct MenuBarTodoView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [
        SortDescriptor(\TodoTask.sortOrder),
        SortDescriptor(\TodoTask.createdAt)
    ]) private var tasks: [TodoTask]

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
            }

            Divider()

            if todayTasks.isEmpty {
                Text("No tasks yet")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ForEach(orderedTasks.prefix(8)) { task in
                    Button {
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
                    }
                    .buttonStyle(.plain)
                }
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
    }

    private func saveChanges() {
        do {
            try modelContext.save()
        } catch {
            assertionFailure("Unable to save menu bar task change: \(error)")
        }
    }

    private func runDailyTaskMaintenance() {
        if TaskDayMaintenance.rolloverUnfinishedTasksToToday(tasks, calendar: calendar) {
            saveChanges()
        }
    }
}
