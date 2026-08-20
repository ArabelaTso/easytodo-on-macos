@preconcurrency import AppKit
import SwiftUI

struct FloatingTaskTitle: NSViewRepresentable {
    let title: String
    var isCompleted = false
    var fontSize: CGFloat = 15
    var fontWeight: NSFont.Weight = .regular
    var longTitleThreshold = 24
    var onDoubleClick: (() -> Void)?

    func makeNSView(context: Context) -> FloatingTaskTitleView {
        let view = FloatingTaskTitleView()
        view.update(
            title: displayTitle,
            isCompleted: isCompleted,
            font: .systemFont(ofSize: fontSize, weight: fontWeight),
            longTitleThreshold: longTitleThreshold,
            onDoubleClick: onDoubleClick
        )
        return view
    }

    func updateNSView(_ nsView: FloatingTaskTitleView, context: Context) {
        nsView.update(
            title: displayTitle,
            isCompleted: isCompleted,
            font: .systemFont(ofSize: fontSize, weight: fontWeight),
            longTitleThreshold: longTitleThreshold,
            onDoubleClick: onDoubleClick
        )
    }

    private var displayTitle: String {
        title.isEmpty ? "Untitled task" : title
    }
}

final class FloatingTaskTitleView: NSView {
    private let label = NSTextField(labelWithString: "")
    private var trackingArea: NSTrackingArea?
    private var panel: NSPanel?
    private var title = ""
    private var isCompleted = false
    private var font = NSFont.systemFont(ofSize: 15, weight: .regular)
    private var longTitleThreshold = 24
    private var onDoubleClick: (() -> Void)?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        label.translatesAutoresizingMaskIntoConstraints = false
        label.lineBreakMode = .byTruncatingTail
        label.maximumNumberOfLines = 1
        label.isSelectable = false
        label.drawsBackground = false
        label.isBordered = false
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        addSubview(label)

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor),
            label.trailingAnchor.constraint(equalTo: trailingAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var acceptsFirstResponder: Bool { true }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        guard onDoubleClick != nil, bounds.contains(point) else { return nil }
        return self
    }

    override func mouseDown(with event: NSEvent) {
        if event.clickCount >= 2 {
            hidePanel()
            onDoubleClick?()
            return
        }

        super.mouseDown(with: event)
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()

        if let trackingArea {
            removeTrackingArea(trackingArea)
        }

        let area = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
        trackingArea = area
    }

    override func mouseEntered(with event: NSEvent) {
        guard shouldShowFloatingText else { return }
        showPanel()
    }

    override func mouseExited(with event: NSEvent) {
        hidePanel()
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()

        if window == nil {
            hidePanel()
        }
    }

    func update(
        title: String,
        isCompleted: Bool,
        font: NSFont,
        longTitleThreshold: Int,
        onDoubleClick: (() -> Void)?
    ) {
        self.title = title
        self.isCompleted = isCompleted
        self.font = font
        self.longTitleThreshold = longTitleThreshold
        self.onDoubleClick = onDoubleClick

        label.attributedStringValue = attributedTitle(title, isCompleted: isCompleted)
        label.toolTip = title

        if !shouldShowFloatingText {
            hidePanel()
        }
    }

    private var shouldShowFloatingText: Bool {
        title.count > longTitleThreshold
    }

    private func attributedTitle(_ title: String, isCompleted: Bool) -> NSAttributedString {
        let color = isCompleted ? NSColor.secondaryLabelColor : NSColor.labelColor
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .strikethroughStyle: isCompleted ? NSUnderlineStyle.single.rawValue : 0,
            .strikethroughColor: NSColor.secondaryLabelColor
        ]
        return NSAttributedString(string: title, attributes: attributes)
    }

    private func showPanel() {
        guard let window, let frame = floatingFrame(), frame.width > 0, frame.height > 0 else { return }

        let panel = panel ?? makePanel()
        panel.appearance = window.effectiveAppearance
        panel.level = NSWindow.Level(rawValue: max(NSWindow.Level.floating.rawValue, window.level.rawValue + 1))
        panel.contentView = labelView(size: frame.size)
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
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient, .ignoresCycle]
        panel.isReleasedWhenClosed = false
        return panel
    }

    private func labelView(size: NSSize) -> NSView {
        let label = NSTextField(labelWithString: title)
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

    private func floatingFrame() -> NSRect? {
        guard let window, !bounds.isEmpty else { return nil }

        let size = labelSize()
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

    private func labelSize() -> NSSize {
        let maxWidth: CGFloat = 280
        let floatingFont = NSFont.systemFont(ofSize: 12, weight: .medium)
        let attributes: [NSAttributedString.Key: Any] = [.font: floatingFont]
        let bounds = NSAttributedString(string: title, attributes: attributes).boundingRect(
            with: NSSize(width: maxWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading]
        )
        let lineHeight = ceil(floatingFont.ascender - floatingFont.descender + floatingFont.leading)
        let width = min(max(ceil(bounds.width), 72), maxWidth)
        let height = min(max(ceil(bounds.height), lineHeight), lineHeight * 8)

        return NSSize(width: width, height: height)
    }
}
