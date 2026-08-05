import AppKit
import SwiftData
import SwiftUI

@MainActor
final class WidgetWindowManager {
    static let shared = WidgetWindowManager()

    private var modelContainer: ModelContainer?
    private var widgetWindow: NSPanel?

    private init() {}

    func configure(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    func showWidget() {
        guard let modelContainer else {
            NSLog("EasyTODO widget cannot open before SwiftData is configured.")
            WindowManager.shared.showMainWindow()
            return
        }

        if let widgetWindow {
            show(window: widgetWindow)
            return
        }

        let size = NSSize(width: 236, height: 312)
        let panel = WidgetPanel(
            contentRect: preferredFrame(size: size),
            styleMask: [.borderless, .fullSizeContentView, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.identifier = NSUserInterfaceItemIdentifier("easy-todo-widget-window")
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isMovableByWindowBackground = true
        panel.isReleasedWhenClosed = false
        panel.hidesOnDeactivate = false
        panel.animationBehavior = .utilityWindow

        let hostingController = NSHostingController(
            rootView: WidgetTodoView()
                .modelContainer(modelContainer)
        )
        hostingController.view.frame = NSRect(origin: .zero, size: size)
        hostingController.view.wantsLayer = true
        hostingController.view.layer?.isOpaque = false
        hostingController.view.layer?.backgroundColor = NSColor.clear.cgColor
        panel.contentView = hostingController.view

        widgetWindow = panel
        show(window: panel)
    }

    func toggleWidget() {
        if widgetWindow?.isVisible == true {
            closeWidget()
        } else {
            showWidget()
        }
    }

    func closeWidget() {
        widgetWindow?.orderOut(nil)
    }

    private func show(window: NSPanel) {
        if window.isMiniaturized {
            window.deminiaturize(nil)
        }

        window.orderFrontRegardless()
    }

    private func preferredFrame(size: NSSize) -> NSRect {
        let visibleFrame = preferredScreen().visibleFrame
        let margin: CGFloat = 24
        let origin = NSPoint(
            x: visibleFrame.maxX - size.width - margin,
            y: visibleFrame.maxY - size.height - margin
        )

        return NSRect(origin: origin, size: size)
    }

    private func preferredScreen() -> NSScreen {
        let mouseLocation = NSEvent.mouseLocation

        return NSScreen.screens.first { screen in
            NSMouseInRect(mouseLocation, screen.frame, false)
        } ?? NSScreen.main ?? NSScreen.screens[0]
    }
}

private final class WidgetPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
