import SwiftUI

struct PriorityPicker: View {
    @Binding var priority: TaskPriority
    @State private var isShowingPalette = false

    var body: some View {
        Button {
            isShowingPalette.toggle()
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
        .buttonStyle(.plain)
        .fixedSize()
        .popover(isPresented: $isShowingPalette, arrowEdge: .bottom) {
            HStack(spacing: 8) {
                ForEach(TaskPriority.allCases) { option in
                    Button {
                        priority = option
                        isShowingPalette = false
                    } label: {
                        Circle()
                            .fill(option.color)
                            .frame(width: 14, height: 14)
                            .padding(5)
                            .overlay {
                                Circle()
                                    .strokeBorder(
                                        priority == option ? option.color.opacity(0.55) : Color.clear,
                                        lineWidth: 1.5
                                    )
                            }
                            .shadow(
                                color: priority == option ? option.color.opacity(0.24) : Color.clear,
                                radius: 3,
                                x: 0,
                                y: 1
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Priority color \(option.rawValue)")
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(.regularMaterial)
        }
        .accessibilityLabel("Change priority color")
    }
}
