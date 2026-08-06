@preconcurrency import AppKit
import SwiftUI

struct HeaderQuickAddPopover: View {
    @State private var title = ""
    @State private var focusRequest = 0

    var onSubmit: (String) -> Bool
    var onCancel: () -> Void

    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: "plus")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)

            QuickAddTaskTextField(
                text: $title,
                focusRequest: focusRequest,
                onSubmit: submitTitle,
                onCancel: onCancel
            )
            .frame(maxWidth: .infinity, minHeight: 24)

            HStack(spacing: 4) {
                shortcutHint("Return")
                shortcutHint("Esc")
            }
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 10)
        .frame(width: 286)
        .onAppear(perform: focusInput)
    }

    private func submitTitle() {
        guard onSubmit(title) else {
            focusInput()
            return
        }

        title = ""
        focusInput()
    }

    private func focusInput() {
        focusRequest += 1
    }

    private func shortcutHint(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background {
                Capsule()
                    .fill(.primary.opacity(0.06))
            }
    }
}

private struct QuickAddTaskTextField: NSViewRepresentable {
    @Binding var text: String
    let focusRequest: Int
    var onSubmit: () -> Void
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
        textField.isEnabled = true
        textField.isSelectable = true
        textField.focusRingType = .none
        textField.placeholderString = "Add task..."
        textField.font = NSFont.systemFont(ofSize: 14, weight: .medium)
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
        var parent: QuickAddTaskTextField
        var lastFocusRequest = 0

        init(_ parent: QuickAddTaskTextField) {
            self.parent = parent
        }

        func controlTextDidChange(_ notification: Notification) {
            guard let textField = notification.object as? NSTextField else { return }

            parent.text = textField.stringValue
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

                let onSubmit = parent.onSubmit
                DispatchQueue.main.async {
                    onSubmit()
                }
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
                textField.currentEditor()?.moveToEndOfDocument(nil)
            }
        }
    }
}
