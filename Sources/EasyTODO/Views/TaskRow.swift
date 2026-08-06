import AppKit
import SwiftData
import SwiftUI

struct TaskRow: View {
    @Bindable var task: TodoTask
    var onUpdate: () -> Void
    var onCompletionChanged: (_ task: TodoTask, _ oldValue: Bool, _ newValue: Bool) -> Void
    var onDelete: () -> Void

    @State private var isHoveringDelete = false
    @State private var isConfirmingDelete = false
    @State private var isEditingTitle = false
    @State private var draftTitle = ""
    @State private var editFocusRequest = 0

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
                .onChange(of: task.isCompleted) { oldValue, newValue in
                    onCompletionChanged(task, oldValue, newValue)
                }

            titleContent

            PriorityPicker(priority: priorityBinding)
                .opacity(task.isCompleted ? 0.6 : 1)

            Button {
                isConfirmingDelete = true
            } label: {
                AnimatedTrashIcon(isOpen: isHoveringDelete)
                    .frame(width: 28, height: 28)
                    .background {
                        Circle()
                            .fill(isHoveringDelete ? Color.red.opacity(0.12) : Color.clear)
                    }
                    .contentShape(Rectangle())
            }
            .buttonStyle(.borderless)
            .foregroundStyle(isHoveringDelete ? Color.red : Color.secondary)
            .opacity(isHoveringDelete ? 1 : 0.75)
            .help("Delete task")
            .accessibilityLabel("Delete task")
            .onHover { isHovering in
                isHoveringDelete = isHovering
            }
            .confirmationDialog(
                "Delete this task?",
                isPresented: $isConfirmingDelete,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive, action: onDelete)
                Button("Cancel", role: .cancel) {}
            } message: {
                Text(confirmDeleteMessage)
            }
        }
        .padding(.vertical, 7)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var titleContent: some View {
        if isEditingTitle {
            InlineTaskTitleTextField(
                text: $draftTitle,
                focusRequest: editFocusRequest,
                onCommit: commitTitleEdit,
                onCancel: cancelTitleEdit
            )
            .frame(maxWidth: .infinity, minHeight: 22)
        } else {
            Text(task.title.isEmpty ? "Untitled task" : task.title)
                .font(.system(size: 15, weight: .regular, design: .default))
                .strikethrough(task.isCompleted, color: .secondary)
                .foregroundStyle(task.isCompleted ? .secondary : .primary)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture(count: 2, perform: beginTitleEdit)
                .help("Double-click to edit")
        }
    }

    private func beginTitleEdit() {
        draftTitle = task.title
        isEditingTitle = true
        editFocusRequest += 1
    }

    private func commitTitleEdit() {
        guard isEditingTitle else { return }

        isEditingTitle = false
        task.title = draftTitle
        onUpdate()
    }

    private func cancelTitleEdit() {
        isEditingTitle = false
        draftTitle = task.title
    }

    private var confirmDeleteMessage: String {
        let title = task.title.trimmingCharacters(in: .whitespacesAndNewlines)
        return title.isEmpty ? "This task will be removed." : "\"\(title)\" will be removed."
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

private struct InlineTaskTitleTextField: NSViewRepresentable {
    @Binding var text: String
    let focusRequest: Int
    var onCommit: () -> Void
    var onCancel: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> NSTextField {
        let textField = NSTextField()
        textField.delegate = context.coordinator
        textField.isBordered = false
        textField.drawsBackground = false
        textField.isEditable = true
        textField.isSelectable = true
        textField.focusRingType = .none
        textField.font = NSFont.systemFont(ofSize: 15, weight: .regular)
        textField.usesSingleLineMode = true
        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return textField
    }

    func updateNSView(_ nsView: NSTextField, context: Context) {
        context.coordinator.parent = self

        if nsView.stringValue != text {
            nsView.stringValue = text
            nsView.currentEditor()?.string = text
        }

        guard context.coordinator.lastFocusRequest != focusRequest else { return }

        context.coordinator.lastFocusRequest = focusRequest
        context.coordinator.focus(nsView)
    }

    final class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: InlineTaskTitleTextField
        var lastFocusRequest = 0

        init(_ parent: InlineTaskTitleTextField) {
            self.parent = parent
        }

        func controlTextDidChange(_ notification: Notification) {
            guard let textField = notification.object as? NSTextField else { return }

            parent.text = textField.stringValue
        }

        func controlTextDidEndEditing(_ notification: Notification) {
            DispatchQueue.main.async {
                self.parent.onCommit()
            }
        }

        func control(
            _ control: NSControl,
            textView: NSTextView,
            doCommandBy commandSelector: Selector
        ) -> Bool {
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                if let textField = control as? NSTextField {
                    parent.text = textField.stringValue
                }

                parent.onCommit()
                return true
            }

            if commandSelector == #selector(NSResponder.cancelOperation(_:)) {
                parent.onCancel()
                return true
            }

            return false
        }

        func focus(_ textField: NSTextField) {
            DispatchQueue.main.async {
                guard let window = textField.window else { return }

                NSApp.activate(ignoringOtherApps: true)
                window.makeKeyAndOrderFront(nil)
                window.makeFirstResponder(textField)
                textField.selectText(nil)
            }
        }
    }
}

private struct AnimatedTrashIcon: View {
    let isOpen: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .stroke(lineWidth: 1.5)
                .frame(width: 12, height: 12)
                .offset(y: 4)

            Path { path in
                path.move(to: CGPoint(x: 9, y: 13))
                path.addLine(to: CGPoint(x: 9, y: 20))
                path.move(to: CGPoint(x: 14, y: 13))
                path.addLine(to: CGPoint(x: 14, y: 20))
                path.move(to: CGPoint(x: 19, y: 13))
                path.addLine(to: CGPoint(x: 19, y: 20))
            }
            .stroke(style: StrokeStyle(lineWidth: 1.2, lineCap: .round))

            RoundedRectangle(cornerRadius: 1, style: .continuous)
                .fill(.foreground)
                .frame(width: 14, height: 1.6)
                .rotationEffect(.degrees(isOpen ? -28 : 0), anchor: .leading)
                .offset(x: isOpen ? -1 : 0, y: isOpen ? -5 : -4)

            RoundedRectangle(cornerRadius: 1, style: .continuous)
                .fill(.foreground)
                .frame(width: 6, height: 1.5)
                .offset(y: isOpen ? -8 : -7)
                .opacity(isOpen ? 0.9 : 1)
        }
        .frame(width: 28, height: 28)
        .scaleEffect(isOpen ? 1.08 : 1)
        .animation(.spring(response: 0.22, dampingFraction: 0.62), value: isOpen)
    }
}
