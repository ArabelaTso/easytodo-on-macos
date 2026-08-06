import AppKit
import SwiftData
import SwiftUI

@MainActor
final class QuickAddPanelManager {
    static let shared = QuickAddPanelManager()

    private var modelContainer: ModelContainer?
    private var panel: NSPanel?
    private var localMouseMonitor: Any?
    private var globalMouseMonitor: Any?

    private init() {}

    func configure(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    func showQuickAdd() {
        guard modelContainer != nil else {
            NSLog("EasyTODO quick add panel cannot open before SwiftData is configured.")
            WindowManager.shared.showMainWindow()
            NotificationCenter.default.post(name: .easyTODOFocusNewTask, object: nil)
            return
        }

        if let panel {
            panel.setFrame(centeredFrame(size: panel.frame.size), display: true)
            showPanelOnCurrentSpace(panel)
            startDismissMonitoring(for: panel)
            return
        }

        let size = NSSize(width: 520, height: 76)
        let frame = centeredFrame(size: size)
        let panel = QuickAddPanel(
            contentRect: frame,
            styleMask: [.borderless, .fullSizeContentView, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .modalPanel
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient, .ignoresCycle]
        panel.isReleasedWhenClosed = false
        panel.hidesOnDeactivate = false
        panel.animationBehavior = .utilityWindow

        let hostingController = NSHostingController(
            rootView: QuickAddPanelView(
                onSubmit: { [weak self] title in
                    self?.addTask(title: title)
                    self?.hideQuickAdd()
                },
                onCancel: { [weak self] in
                    self?.hideQuickAdd()
                }
            )
        )
        hostingController.view.wantsLayer = true
        hostingController.view.layer?.backgroundColor = NSColor.clear.cgColor
        panel.contentView = hostingController.view

        self.panel = panel
        showPanelOnCurrentSpace(panel)
        startDismissMonitoring(for: panel)
    }

    func hideQuickAdd() {
        stopDismissMonitoring()
        panel?.orderOut(nil)
        panel = nil
    }

    private func addTask(title: String) {
        guard let modelContainer else { return }

        do {
            _ = try TaskCreation.addTask(title: title, in: modelContainer.mainContext)
        } catch {
            NSLog("EasyTODO failed to save quick add task: \(error)")
        }
    }

    private func centeredFrame(size: NSSize) -> NSRect {
        let screen = preferredScreen()
        let visibleFrame = screen.visibleFrame
        let origin = NSPoint(
            x: visibleFrame.midX - size.width / 2,
            y: visibleFrame.midY + visibleFrame.height * 0.12 - size.height / 2
        )

        return NSRect(origin: origin, size: size)
    }

    private func showPanelOnCurrentSpace(_ panel: NSPanel) {
        panel.orderFrontRegardless()
        panel.makeKeyAndOrderFront(nil)
    }

    private func startDismissMonitoring(for panel: NSPanel) {
        stopDismissMonitoring()

        let mouseEvents: NSEvent.EventTypeMask = [.leftMouseDown, .rightMouseDown, .otherMouseDown]

        localMouseMonitor = NSEvent.addLocalMonitorForEvents(matching: mouseEvents) { [weak self, weak panel] event in
            guard let self, let panel else { return event }

            if event.window !== panel {
                Task { @MainActor in
                    self.hideQuickAdd()
                }
            }

            return event
        }

        globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: mouseEvents) { [weak self, weak panel] _ in
            Task { @MainActor in
                guard let self, let panel, !panel.frame.contains(NSEvent.mouseLocation) else { return }
                self.hideQuickAdd()
            }
        }
    }

    private func stopDismissMonitoring() {
        if let localMouseMonitor {
            NSEvent.removeMonitor(localMouseMonitor)
            self.localMouseMonitor = nil
        }

        if let globalMouseMonitor {
            NSEvent.removeMonitor(globalMouseMonitor)
            self.globalMouseMonitor = nil
        }
    }

    private func preferredScreen() -> NSScreen {
        let mouseLocation = NSEvent.mouseLocation

        return NSScreen.screens.first { screen in
            NSMouseInRect(mouseLocation, screen.frame, false)
        } ?? NSScreen.main ?? NSScreen.screens[0]
    }
}

private final class QuickAddPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}
