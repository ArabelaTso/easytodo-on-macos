import SwiftData
import SwiftUI

struct TodoListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [
        SortDescriptor(\TodoTask.sortOrder),
        SortDescriptor(\TodoTask.createdAt)
    ]) private var tasks: [TodoTask]

    @AppStorage(DesktopTodoSettings.alwaysOnTop) private var alwaysOnTop = true
    @AppStorage(DesktopTodoSettings.hiddenDockIcon) private var hiddenDockIcon = false
    @AppStorage(DesktopTodoSettings.showMenuBar) private var showMenuBar = true
    @AppStorage(DesktopTodoSettings.transparency) private var transparency = 0.90

    @State private var newTaskTitle = ""
    @FocusState private var isAddingTaskFocused: Bool

    private var completedCount: Int {
        tasks.filter(\.isCompleted).count
    }

    var body: some View {
        ZStack {
            BlurBackground()

            VStack(spacing: 0) {
                header

                Divider()
                    .padding(.horizontal, 14)

                List {
                    ForEach(tasks) { task in
                        TaskRow(task: task, onUpdate: saveChanges) {
                            delete(task)
                        }
                        .listRowInsets(EdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 10))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }
                    .onMove(perform: moveTasks)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)

                Divider()
                    .padding(.horizontal, 14)

                AddTaskView(
                    title: $newTaskTitle,
                    focus: $isAddingTaskFocused,
                    onSubmit: addTask
                )
            }
        }
        .frame(minWidth: 280, idealWidth: 340, minHeight: 320, idealHeight: 480)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .background(
            WindowAccessor { window in
                WindowManager.shared.configureMainWindow(window)
            }
        )
        .onAppear {
            WindowManager.shared.applyWindowSettings()
            WindowManager.shared.applyActivationPolicy()
        }
        .onReceive(NotificationCenter.default.publisher(for: .desktopTodoFocusNewTask)) { _ in
            WindowManager.shared.showMainWindow()
            isAddingTaskFocused = true
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
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Today")
                    .font(.system(size: 22, weight: .semibold, design: .default))

                Text("\(completedCount) / \(tasks.count) complete")
                    .font(.system(size: 12, weight: .medium, design: .default))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                isAddingTaskFocused = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("Add task")
        }
        .padding(.horizontal, 16)
        .padding(.top, 18)
        .padding(.bottom, 12)
    }

    private func addTask() {
        let trimmedTitle = newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            isAddingTaskFocused = true
            return
        }

        let nextSortOrder = (tasks.map(\.sortOrder).max() ?? -1) + 1
        modelContext.insert(TodoTask(title: trimmedTitle, sortOrder: nextSortOrder))
        newTaskTitle = ""
        saveChanges()
        isAddingTaskFocused = true
    }

    private func delete(_ task: TodoTask) {
        modelContext.delete(task)
        saveChanges()
    }

    private func moveTasks(from source: IndexSet, to destination: Int) {
        var reorderedTasks = tasks
        reorderedTasks.move(fromOffsets: source, toOffset: destination)

        for (index, task) in reorderedTasks.enumerated() {
            task.sortOrder = index
        }

        saveChanges()
    }

    private func saveChanges() {
        do {
            try modelContext.save()
        } catch {
            assertionFailure("Unable to save tasks: \(error)")
        }
    }
}
