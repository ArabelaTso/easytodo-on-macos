import AppKit
import SwiftUI

struct QuickAddPanelView: View {
    var onSubmit: (String) -> Void
    var onCancel: () -> Void

    @State private var title = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 10) {
            if let image = AppLogo.quickAddImage {
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(width: 28, height: 28)
            }

            Image(systemName: "plus")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 28, height: 28)

            TextField("Quick add a task...", text: $title)
                .textFieldStyle(.plain)
                .font(.system(size: 20, weight: .medium))
                .focused($isFocused)
                .onSubmit {
                    onSubmit(title)
                }

            Text("Return")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(.primary.opacity(0.06))
                )
        }
        .padding(.horizontal, 18)
        .frame(width: 520, height: 76)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(nsColor: .windowBackgroundColor).opacity(0.62))
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(.white.opacity(0.22), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.22), radius: 28, x: 0, y: 18)
        .onAppear {
            DispatchQueue.main.async {
                isFocused = true
            }
        }
        .onExitCommand(perform: onCancel)
    }
}
