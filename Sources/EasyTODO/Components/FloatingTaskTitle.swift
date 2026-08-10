@preconcurrency import AppKit
import SwiftUI

struct FloatingTaskTitle: View {
    let title: String
    var isCompleted = false
    var font: Font = .system(size: 15, weight: .regular, design: .default)
    var longTitleThreshold = 24
    var onDoubleClick: (() -> Void)?

    @State private var isHovering = false

    private var displayTitle: String {
        title.isEmpty ? "Untitled task" : title
    }

    private var shouldShowFloatingText: Bool {
        displayTitle.count > longTitleThreshold && isHovering
    }

    var body: some View {
        if let onDoubleClick {
            titleView
                .onTapGesture(count: 2, perform: onDoubleClick)
        } else {
            titleView
        }
    }

    private var titleView: some View {
        Text(displayTitle)
            .font(font)
            .foregroundStyle(isCompleted ? Color.secondary : Color.primary)
            .strikethrough(isCompleted, color: .secondary)
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onHover { hovering in
                guard displayTitle.count > longTitleThreshold else { return }
                isHovering = hovering
            }
            .background {
                FloatingTextPresenter(text: displayTitle, isPresented: shouldShowFloatingText)
            }
            .help(displayTitle)
    }
}

private struct FloatingTextPresenter: NSViewRepresentable {
    let text: String
    let isPresented: Bool

    func makeNSView(context: Context) -> FloatingTextAnchorView {
        FloatingTextAnchorView()
    }

    func updateNSView(_ nsView: FloatingTextAnchorView, context: Context) {
        nsView.update(text: text, isPresented: isPresented)
    }
}

private final class FloatingTextAnchorView: NSView {
    private var panel: NSPanel?
    private var currentText = ""

    func update(text: String, isPresented: Bool) {
        currentText = text

        if isPresented {
            showPanel(text: text)
        } else {
            hidePanel()
        }
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()

        if window == nil {
            hidePanel()
        }
    }

    private func showPanel(text: String) {
        guard let window, let frame = floatingFrame(for: text) else { return }

        let panel = panel ?? makePanel()
        panel.appearance = window.effectiveAppearance
        panel.contentView = labelView(text: text, size: frame.size)
        panel.setFrame(frame, display: true)
        panel.orderFrontRegardless()
        self.panel = panel
    }

    private func hidePanel() {
        panel?.orderOut(nil)
        panel = nil
    }

    private func makePanel() -> NSPanel {
        let panel = NSPanel(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.ignoresMouseEvents = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient, .ignoresCycle]
        panel.isReleasedWhenClosed = false
        return panel
    }

    private func labelView(text: String, size: NSSize) -> NSView {
        let label = NSTextField(labelWithString: text)
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .labelColor
        label.drawsBackground = false
        label.isBordered = false
        label.lineBreakMode = .byCharWrapping
        label.maximumNumberOfLines = 8
        label.frame = NSRect(origin: .zero, size: size)
        label.autoresizingMask = [.width, .height]
        return label
    }

    private func floatingFrame(for text: String) -> NSRect? {
        guard let window else { return nil }

        let size = labelSize(for: text)
        let rectInWindow = convert(bounds, to: nil)
        let originOnScreen = window.convertPoint(toScreen: rectInWindow.origin)
        let sourceFrame = NSRect(origin: originOnScreen, size: rectInWindow.size)
        let visibleFrame = window.screen?.visibleFrame ?? NSScreen.main?.visibleFrame ?? sourceFrame
        let margin: CGFloat = 8
        let gap: CGFloat = 6
        let x = min(
            max(sourceFrame.minX, visibleFrame.minX + margin),
            visibleFrame.maxX - size.width - margin
        )
        let preferredY = sourceFrame.maxY + gap
        let y = min(preferredY, visibleFrame.maxY - size.height - margin)

        return NSRect(origin: NSPoint(x: x, y: max(y, visibleFrame.minY + margin)), size: size)
    }

    private func labelSize(for text: String) -> NSSize {
        let maxWidth: CGFloat = 280
        let font = NSFont.systemFont(ofSize: 12, weight: .medium)
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        let bounds = NSAttributedString(string: text, attributes: attributes).boundingRect(
            with: NSSize(width: maxWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading]
        )
        let lineHeight = ceil(font.ascender - font.descender + font.leading)
        let width = min(max(ceil(bounds.width), 72), maxWidth)
        let height = min(max(ceil(bounds.height), lineHeight), lineHeight * 8)

        return NSSize(width: width, height: height)
    }
}
