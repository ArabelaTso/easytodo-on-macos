import SwiftUI

struct PriorityPicker: View {
    @Binding var priority: TaskPriority

    var body: some View {
        Menu {
            ForEach(TaskPriority.allCases) { option in
                Button {
                    priority = option
                } label: {
                    Circle()
                        .fill(option.color)
                        .frame(width: 12, height: 12)
                        .padding(.vertical, 3)
                }
                .accessibilityLabel("Priority color \(option.rawValue)")
            }
        } label: {
            Circle()
                .fill(priority.color)
                .frame(width: 12, height: 12)
                .padding(6)
                .overlay {
                    Circle()
                        .strokeBorder(priority.color.opacity(0.45), lineWidth: 1.5)
                }
                .shadow(color: priority.color.opacity(0.26), radius: 4, x: 0, y: 1)
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
        .accessibilityLabel("Change priority color")
    }
}
