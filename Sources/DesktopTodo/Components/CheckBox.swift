import SwiftUI

struct CheckBox: View {
    @Binding var isOn: Bool

    var body: some View {
        Button {
            isOn.toggle()
        } label: {
            Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(isOn ? Color.accentColor : Color.secondary)
                .frame(width: 24, height: 24)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isOn ? "Mark incomplete" : "Mark complete")
    }
}
