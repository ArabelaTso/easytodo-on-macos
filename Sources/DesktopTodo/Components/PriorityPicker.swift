import SwiftUI

struct PriorityPicker: View {
    @Binding var priority: TaskPriority

    var body: some View {
        Menu {
            ForEach(TaskPriority.allCases) { option in
                Button {
                    priority = option
                } label: {
                    Label(option.title, systemImage: option.systemImage)
                }
            }
        } label: {
            Image(systemName: priority.systemImage)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(priority.color)
                .frame(width: 24, height: 24)
                .contentShape(Rectangle())
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
        .accessibilityLabel("Priority: \(priority.title)")
    }
}
