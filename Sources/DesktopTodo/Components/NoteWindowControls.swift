import SwiftUI

struct NoteWindowControls: View {
    @State private var hoveredAction: WindowControlAction?

    var body: some View {
        HStack(spacing: 6) {
            controlButton(.close)
            controlButton(.minimize)
            controlButton(.zoom)
        }
        .fixedSize()
    }

    private func controlButton(_ action: WindowControlAction) -> some View {
        Button {
            switch action {
            case .close:
                WindowManager.shared.closeMainWindow()
            case .minimize:
                WindowManager.shared.minimizeMainWindow()
            case .zoom:
                WindowManager.shared.zoomMainWindow()
            }
        } label: {
            Image(systemName: action.systemImage)
                .font(.system(size: 7, weight: .bold))
                .foregroundStyle(.primary.opacity(hoveredAction == action ? 0.58 : 0.32))
                .frame(width: 16, height: 16)
                .background {
                    Circle()
                        .fill(.primary.opacity(hoveredAction == action ? 0.08 : 0.035))
                }
        }
        .buttonStyle(.plain)
        .onHover { isHovering in
            hoveredAction = isHovering ? action : nil
        }
        .accessibilityLabel(action.accessibilityLabel)
    }
}

private enum WindowControlAction: Hashable {
    case close
    case minimize
    case zoom

    var systemImage: String {
        switch self {
        case .close:
            "xmark"
        case .minimize:
            "minus"
        case .zoom:
            "arrow.up.left.and.arrow.down.right"
        }
    }

    var accessibilityLabel: String {
        switch self {
        case .close:
            "Close window"
        case .minimize:
            "Minimize window"
        case .zoom:
            "Zoom window"
        }
    }
}
