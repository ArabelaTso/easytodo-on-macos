import AppKit
import SwiftData
import SwiftUI

struct MenuBarTodoView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [
        SortDescriptor(\TodoTask.sortOrder),
        SortDescriptor(\TodoTask.createdAt)
    ]) private var tasks: [TodoTask]

    private var completedCount: Int {
        tasks.filter(\.isCompleted).count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Today")
                    .font(.headline)

                Spacer()

                Text("\(completedCount) / \(tasks.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()

            if tasks.isEmpty {
                Text("No tasks yet")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ForEach(tasks.prefix(8)) { task in
                    Button {
                        task.isCompleted.toggle()
                        saveChanges()
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

            HStack {
                Button("Show") {
                    WindowManager.shared.showMainWindow()
                }

                Button("New Task") {
                    WindowManager.shared.showMainWindow()
                    NotificationCenter.default.post(name: .desktopTodoFocusNewTask, object: nil)
                }

                Spacer()

                Button("Quit") {
                    NSApp.terminate(nil)
                }
            }
        }
        .padding(14)
        .frame(width: 260)
    }

    private func saveChanges() {
        do {
            try modelContext.save()
        } catch {
            assertionFailure("Unable to save menu bar task change: \(error)")
        }
    }
}
