import SwiftData
import SwiftUI

struct TaskRow: View {
    @Bindable var task: TodoTask
    var onUpdate: () -> Void
    var onDelete: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(task.priority.color)
                .frame(width: 4, height: 24)
                .opacity(task.isCompleted ? 0.45 : 1)

            Image(systemName: "line.3.horizontal")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.tertiary)
                .frame(width: 14)

            CheckBox(isOn: $task.isCompleted)
                .onChange(of: task.isCompleted) { _, _ in
                    onUpdate()
                }

            TextField("Task", text: $task.title)
                .textFieldStyle(.plain)
                .font(.system(size: 15, weight: .regular, design: .default))
                .strikethrough(task.isCompleted, color: .secondary)
                .foregroundStyle(task.isCompleted ? .secondary : .primary)

            PriorityPicker(priority: priorityBinding)

            Button(role: .destructive) {
                onDelete()
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 12, weight: .medium))
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .opacity(0.75)
            .accessibilityLabel("Delete task")
        }
        .padding(.vertical, 7)
        .contentShape(Rectangle())
    }

    private var priorityBinding: Binding<TaskPriority> {
        Binding {
            task.priority
        } set: { newPriority in
            task.priority = newPriority
            onUpdate()
        }
    }
}
