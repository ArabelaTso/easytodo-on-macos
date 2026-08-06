import AppKit
import SwiftUI

struct AddTaskView: View {
    @Binding var title: String
    let focus: FocusState<Bool>.Binding
    var placeholder = "Add Task"
    var onActivate: (() -> Void)?
    var onSubmit: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "plus")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 24, height: 24)

            TextField(placeholder, text: $title)
                .textFieldStyle(.plain)
                .font(.system(size: 15, weight: .regular, design: .default))
                .focused(focus)
                .onSubmit(onSubmit)
                .onTapGesture(perform: activate)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .onTapGesture(perform: activate)
    }

    private func activate() {
        NSApp.activate(ignoringOtherApps: true)
        onActivate?()

        DispatchQueue.main.async {
            focus.wrappedValue = true
        }
    }
}
