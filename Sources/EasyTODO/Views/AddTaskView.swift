import SwiftUI

struct AddTaskView: View {
    @Binding var title: String
    let focus: FocusState<Bool>.Binding
    var onSubmit: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "plus")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 24, height: 24)

            TextField("Add Task", text: $title)
                .textFieldStyle(.plain)
                .font(.system(size: 15, weight: .regular, design: .default))
                .focused(focus)
                .onSubmit(onSubmit)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .onTapGesture {
            focus.wrappedValue = true
        }
    }
}
