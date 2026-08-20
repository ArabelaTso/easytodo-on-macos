import Foundation
import SwiftData
import SwiftUI

struct WidgetTodoView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [
        SortDescriptor(\TodoTask.sortOrder),
        SortDescriptor(\TodoTask.createdAt)
    ]) private var tasks: [TodoTask]

    @AppStorage(EasyTODOSettings.theme) private var theme = ThemeOption.light.rawValue

    private let calendar = Calendar.current
    private let dayRefreshTimer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    private var todayTasks: [TodoTask] {
        tasks.filter { task in
            task.isScheduled(on: .now, calendar: calendar)
        }
    }

    private var orderedTasks: [TodoTask] {
        TaskListOrdering.ordered(todayTasks)
    }

    private var activeCount: Int {
        todayTasks.filter { !$0.isCompleted }.count
    }

    private var completedCount: Int {
        todayTasks.filter(\.isCompleted).count
    }

    private var progress: Double {
        guard !todayTasks.isEmpty else { return 0 }
        return Double(completedCount) / Double(todayTasks.count)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            progressBar

            if todayTasks.isEmpty {
                emptyState
            } else {
                taskList
            }

            footer
        }
        .padding(14)
        .frame(width: 236)
        .background(widgetSurface)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(.white.opacity(0.12), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.10), radius: 18, x: 0, y: 10)
        .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .contextMenu {
            Button {
                WindowManager.shared.showMainWindow()
            } label: {
                Label("Open Main App", systemImage: "rectangle.expand.vertical")
            }

            Button {
                WidgetWindowManager.shared.closeWidget()
            } label: {
                Label("Close Widget", systemImage: "xmark")
            }
        }
        .onTapGesture(count: 2) {
            WindowManager.shared.showMainWindow()
        }
        .onAppear(perform: runDailyTaskMaintenance)
        .onReceive(dayRefreshTimer) { _ in
            runDailyTaskMaintenance()
        }
        .preferredColorScheme(preferredColorScheme)
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Today's TODOs")
                    .font(.system(size: 13, weight: .semibold))

                Text("\(activeCount) active - \(completedCount) done")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("\(completedCount)/\(todayTasks.count)")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(.primary.opacity(0.045), in: Capsule())
        }
    }

    private var progressBar: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.primary.opacity(0.08))

                Capsule()
                    .fill(Color(red: 0.95, green: 0.64, blue: 0.22))
                    .frame(width: proxy.size.width * progress)
            }
        }
        .frame(height: 5)
        .accessibilityLabel("Today progress")
        .accessibilityValue("\(completedCount) of \(todayTasks.count) complete")
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: "sparkle")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.secondary)

            Text("Clear day")
                .font(.system(size: 14, weight: .semibold))

            Text("Double-click to open the full list.")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 12)
    }

    private var taskList: some View {
        ScrollView(.vertical) {
            LazyVStack(spacing: 7) {
                ForEach(orderedTasks) { task in
                    taskButton(for: task)
                }
            }
            .padding(.trailing, 4)
        }
        .frame(maxHeight: 190)
        .scrollIndicators(.visible)
    }

    private var footer: some View {
        Button {
            WindowManager.shared.showMainWindow()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "arrow.up.right.square")
                    .font(.system(size: 11, weight: .semibold))

                Text("Open full app")
                    .font(.system(size: 12, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 7)
            .background(.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var widgetSurface: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
                .opacity(0.22)

            LinearGradient(
                colors: [
                    Color.white.opacity(0.08),
                    Color(red: 1.0, green: 0.78, blue: 0.35).opacity(0.06),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private func taskButton(for task: TodoTask) -> some View {
        Button {
            toggleCompletion(for: task)
        } label: {
            HStack(spacing: 8) {
                Circle()
                    .fill(task.priority.color)
                    .frame(width: 7, height: 7)

                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(task.isCompleted ? Color.accentColor : Color.secondary)

                FloatingTaskTitle(
                    title: task.title,
                    isCompleted: task.isCompleted,
                    fontSize: 13,
                    fontWeight: .medium,
                    longTitleThreshold: 18
                )

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 7)
            .background(.primary.opacity(task.isCompleted ? 0.018 : 0.032), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(task.title.isEmpty ? "Untitled task" : task.title)
        .accessibilityValue(task.isCompleted ? "Completed" : "Not completed")
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

    private func saveChanges() {
        do {
            try modelContext.save()
        } catch {
            assertionFailure("Unable to save widget task change: \(error)")
        }
    }

    private func runDailyTaskMaintenance() {
        if TaskDayMaintenance.rolloverUnfinishedTasksToToday(tasks, calendar: calendar) {
            saveChanges()
        }
    }

    private var preferredColorScheme: ColorScheme? {
        switch ThemeOption(rawValue: theme) ?? .light {
        case .light:
            .light
        case .dark:
            .dark
        }
    }
}
